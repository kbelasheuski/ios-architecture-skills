import Combine
import UIKit

final class UserDetailViewController: UIViewController, UITextFieldDelegate {

    private let viewModel: UserDetailViewModel
    private var cancellables: Set<AnyCancellable> = []
    private let nameField = UITextField()
    private let emailLabel = UILabel()
    private let saveButton = UIBarButtonItem(barButtonSystemItem: .save, target: nil, action: nil)
    private let activity = UIActivityIndicatorView(style: .medium)

    init(viewModel: UserDetailViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        layout()
        saveButton.target = self
        saveButton.action = #selector(onSave)
        navigationItem.rightBarButtonItem = saveButton
        nameField.delegate = self
        nameField.addTarget(self, action: #selector(onNameChange), for: .editingChanged)
        bind()
        viewModel.onAppear()
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

    private func bind() {
        viewModel.$user
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] u in
                self?.nameField.text = u.name
                self?.emailLabel.text = u.email
                self?.title = u.name
                self?.saveButton.isEnabled = self?.viewModel.canSave ?? false
            }
            .store(in: &cancellables)

        viewModel.$isSaving
            .receive(on: DispatchQueue.main)
            .sink { [weak self] saving in
                if saving { self?.activity.startAnimating() } else { self?.activity.stopAnimating() }
                self?.saveButton.isEnabled = self?.viewModel.canSave ?? false
            }
            .store(in: &cancellables)

        viewModel.$errorMessage
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] msg in
                let a = UIAlertController(title: "Error", message: msg, preferredStyle: .alert)
                a.addAction(.init(title: "OK", style: .default))
                self?.present(a, animated: true)
            }
            .store(in: &cancellables)
    }

    @objc private func onSave() { viewModel.save() }
    @objc private func onNameChange() {
        viewModel.draftName = nameField.text ?? ""
        saveButton.isEnabled = viewModel.canSave
    }
}
