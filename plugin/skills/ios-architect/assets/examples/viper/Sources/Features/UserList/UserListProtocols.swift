import Foundation

@MainActor
public protocol UserListViewProtocol: AnyObject {
    func display(rows: [UserListRowEntity])
    func displayLoading(_ loading: UserListLoading)
    func displayError(message: String)
}

@MainActor
public protocol UserListPresenterProtocol: AnyObject {
    func viewDidLoad() async
    func refresh() async
    func didDisplayRow(at index: Int)
    func didSelectRow(at index: Int)
}

public protocol UserListInteractorProtocol: AnyObject {
    func fetchUsers(page: Int) async throws -> UsersPage
}

@MainActor
public protocol UserListRouterProtocol: AnyObject {
    func showDetail(for id: User.ID)
}
