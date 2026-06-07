import Foundation

@MainActor
public protocol UserDetailViewProtocol: AnyObject {
    func display(name: String, email: String)
    func displaySaving(_ saving: Bool)
    func displayError(message: String)
    func setSaveEnabled(_ enabled: Bool)
}

@MainActor
public protocol UserDetailPresenterProtocol: AnyObject {
    func viewDidLoad() async
    func didChangeName(_ name: String)
    func save() async
}

public protocol UserDetailInteractorProtocol: AnyObject {
    func fetch(id: User.ID) async throws -> User
    func update(_ user: User) async throws -> User
}

@MainActor
public protocol UserDetailRouterProtocol: AnyObject {
    func pop()
}
