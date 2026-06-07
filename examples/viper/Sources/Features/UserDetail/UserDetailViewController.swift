import UIKit

final class UserDetailViewController: UIViewController, UserDetailViewProtocol, UITextFieldDelegate {

    var presenter: UserDetailPresenterProtocol!
    private let nameField = UITextField()
    private let emailLabel = UILabel()
    private let saveButton = UIBarButtonItem(barButtonSystemItem: .save, target: nil, action: nil)
    private let activity = UIActivityIndicatorView(style: .medium)

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        layout()
        saveButton.target = self
        saveButton.action = #selector(onSave)
        navigationItem.rightBarButtonItem = saveButton
        nameField.delegate = self
        nameField.addTarget(self, action: #selector(onNameChange), for: .editingChanged)
        Task { await presenter.viewDidLoad() }
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

    func display(name: String, email: String) {
        nameField.text = name
        emailLabel.text = email
        title = name
    }
    func displaySaving(_ saving: Bool) {
        if saving { activity.startAnimating() } else { activity.stopAnimating() }
    }
    func displayError(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(.init(title: "OK", style: .default))
        present(alert, animated: true)
    }
    func setSaveEnabled(_ enabled: Bool) { saveButton.isEnabled = enabled }

    @objc private func onSave() { Task { await presenter.save() } }
    @objc private func onNameChange() { presenter.didChangeName(nameField.text ?? "") }
}
