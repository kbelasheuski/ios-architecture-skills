import Foundation

@MainActor
public protocol UserDetailView: AnyObject {
    func display(name: String, email: String)
    func displaySaving(_ saving: Bool)
    func displayError(message: String)
    func setSaveEnabled(_ enabled: Bool)
    func dismiss()
}

@MainActor
public protocol UserDetailPresenting {
    func viewDidLoad() async
    func didChangeName(_ name: String)
    func save() async
}
