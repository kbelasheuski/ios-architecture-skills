import UIKit

final class UserDetailViewController: UIViewController, UITextFieldDelegate {

    private let repository: UserRepository
    private let userID: User.ID
    private(set) var user: User?
    private(set) var isSaving = false { didSet { updateSaveState() } }

    private let nameField = UITextField()
    private let emailLabel = UILabel()
    private let activity = UIActivityIndicatorView(style: .medium)

    init(repository: UserRepository, userID: User.ID) {
        self.repository = repository
        self.userID = userID
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        layout()
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .save,
            target: self,
            action: #selector(onSave)
        )
        nameField.delegate = self
        nameField.addTarget(self, action: #selector(nameChanged), for: .editingChanged)
        load()
    }

    private func layout() {
        nameField.borderStyle = .roundedRect
        emailLabel.textColor = .secondaryLabel
        activity.hidesWhenStopped = true
        let stack = UIStackView(arrangedSubviews: [nameField, emailLabel, activity])
        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
        ])
    }

    private func load() {
        Task { [weak self] in
            guard let self else { return }
            do {
                let u = try await repository.fetchUser(id: userID)
                user = u
                nameField.text = u.name
                emailLabel.text = u.email
                title = u.name
                updateSaveState()
            } catch {
                presentError(error)
            }
        }
    }

    @objc private func nameChanged() { updateSaveState() }

    private func updateSaveState() {
        let dirty = nameField.text != user?.name
        let nonEmpty = !(nameField.text ?? "").isEmpty
        navigationItem.rightBarButtonItem?.isEnabled = dirty && nonEmpty && !isSaving
        if isSaving { activity.startAnimating() } else { activity.stopAnimating() }
    }

    @objc private func onSave() {
        guard var u = user, let name = nameField.text else { return }
        u.name = name
        isSaving = true
        Task { [weak self] in
            guard let self else { return }
            defer { isSaving = false }
            do {
                _ = try await repository.update(u)
                navigationController?.popViewController(animated: true)
            } catch {
                presentError(error)
            }
        }
    }

    private func presentError(_ error: Error) {
        let alert = UIAlertController(title: "Error",
                                      message: error.localizedDescription,
                                      preferredStyle: .alert)
        alert.addAction(.init(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
