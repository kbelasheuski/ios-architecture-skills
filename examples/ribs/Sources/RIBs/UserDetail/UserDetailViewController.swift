import RIBs
import UIKit

public final class UserDetailViewController:
    UIViewController,
    UserDetailPresentable,
    UserDetailViewControllable,
    UITextFieldDelegate {
    public weak var listener: UserDetailPresentableListener?

    private let nameField = UITextField()
    private let emailLabel = UILabel()
    private let saveButton = UIBarButtonItem(barButtonSystemItem: .save, target: nil, action: nil)
    private let activity = UIActivityIndicatorView(style: .medium)

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        layout()
        saveButton.target = self
        saveButton.action = #selector(onSave)
        navigationItem.rightBarButtonItem = saveButton
        nameField.delegate = self
        nameField.addTarget(self, action: #selector(onNameChange), for: .editingChanged)
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

    public func display(name: String, email: String) {
        nameField.text = name
        emailLabel.text = email
        title = name
    }
    public func display(saving: Bool) {
        if saving { activity.startAnimating() } else { activity.stopAnimating() }
    }
    public func setSaveEnabled(_ enabled: Bool) { saveButton.isEnabled = enabled }
    public func displayError(_ message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(.init(title: "OK", style: .default))
        present(alert, animated: true)
    }

    @objc private func onSave() { listener?.save() }
    @objc private func onNameChange() { listener?.didChangeName(nameField.text ?? "") }
}
