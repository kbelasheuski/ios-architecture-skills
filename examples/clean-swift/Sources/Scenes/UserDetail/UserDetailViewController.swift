import UIKit

@MainActor
public protocol UserDetailDisplayLogic: AnyObject {
    func displayLoad(_ viewModel: UserDetail.Load.ViewModel)
    func displaySave(_ viewModel: UserDetail.Save.ViewModel)
}

final class UserDetailViewController: UIViewController, UserDetailDisplayLogic, UITextFieldDelegate {

    var interactor: UserDetailBusinessLogic!
    var router: UserDetailRoutingLogic!
    var userID: User.ID!

    private let nameField = UITextField()
    private let emailLabel = UILabel()
    private let saveButton = UIBarButtonItem(barButtonSystemItem: .save, target: nil, action: nil)
    private let activity = UIActivityIndicatorView(style: .medium)
    private var originalName: String = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        layout()
        saveButton.target = self
        saveButton.action = #selector(onSave)
        navigationItem.rightBarButtonItem = saveButton
        nameField.delegate = self
        nameField.addTarget(self, action: #selector(onNameChange), for: .editingChanged)
        Task { await interactor.load(.init(id: userID)) }
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

    func displayLoad(_ vm: UserDetail.Load.ViewModel) {
        if let msg = vm.errorMessage {
            let alert = UIAlertController(title: "Error", message: msg, preferredStyle: .alert)
            alert.addAction(.init(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }
        nameField.text = vm.name
        emailLabel.text = vm.email
        title = vm.name
        originalName = vm.name
        updateSaveEnabled()
    }

    func displaySave(_ vm: UserDetail.Save.ViewModel) {
        switch vm.status {
        case .idle:
            activity.stopAnimating()
        case .saving:
            activity.startAnimating()
            saveButton.isEnabled = false
        case .saved:
            activity.stopAnimating()
            router.pop()
        case .failed(let msg):
            activity.stopAnimating()
            let alert = UIAlertController(title: "Error", message: msg, preferredStyle: .alert)
            alert.addAction(.init(title: "OK", style: .default))
            present(alert, animated: true)
            updateSaveEnabled()
        }
    }

    private func updateSaveEnabled() {
        let dirty = nameField.text != originalName
        let nonEmpty = !(nameField.text ?? "").isEmpty
        saveButton.isEnabled = dirty && nonEmpty
    }

    @objc private func onNameChange() { updateSaveEnabled() }
    @objc private func onSave() {
        Task { await interactor.save(.init(name: nameField.text ?? "")) }
    }
}
