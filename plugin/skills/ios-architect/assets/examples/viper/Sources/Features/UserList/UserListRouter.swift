import UIKit

@MainActor
final class UserListRouter: UserListRouterProtocol {

    weak var viewController: UIViewController?
    private let repository: UserRepository

    init(repository: UserRepository) {
        self.repository = repository
    }

    func showDetail(for id: User.ID) {
        let vc = UserDetailBuilder.build(repository: repository, userID: id)
        viewController?.navigationController?.pushViewController(vc, animated: true)
    }
}
