import Foundation

@MainActor
public protocol UserListPresentationLogic: AnyObject {
    func present(_ response: UserList.FetchUsers.Response) async
}

@MainActor
public final class UserListPresenter: UserListPresentationLogic {

    public weak var view: UserListDisplayLogic?

    public init() {}

    public func present(_ response: UserList.FetchUsers.Response) async {
        let rows = response.users.map {
            UserList.FetchUsers.ViewModel.Row(id: $0.id, title: $0.name, subtitle: $0.email)
        }
        view?.display(.init(rows: rows, loading: response.loading, errorMessage: response.errorMessage))
    }
}
