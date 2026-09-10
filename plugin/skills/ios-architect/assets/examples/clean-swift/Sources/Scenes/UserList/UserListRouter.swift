import UIKit

@MainActor
public protocol UserListRoutingLogic { func routeToDetail() }

@MainActor
public protocol UserListDataPassing {
    var dataStore: UserListDataStore? { get }
}

@MainActor
final class UserListRouter: UserListRoutingLogic, UserListDataPassing {

    weak var viewController: UserListViewController?
    weak var dataStore: UserListDataStore?
    private let repository: UserRepository

    init(repository: UserRepository) {
        self.repository = repository
    }

    func routeToDetail() {
        guard let id = dataStore?.selectedUserID else { return }
        let vc = UserDetailConfigurator.make(repository: repository, userID: id)
        viewController?.navigationController?.pushViewController(vc, animated: true)
    }
}
