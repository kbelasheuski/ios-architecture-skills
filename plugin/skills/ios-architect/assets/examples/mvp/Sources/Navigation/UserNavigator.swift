import UIKit

@MainActor
final class UserNavigator: UserNavigating {

    weak var navigationController: UINavigationController?
    private let repository: UserRepository

    init(navigationController: UINavigationController, repository: UserRepository) {
        self.navigationController = navigationController
        self.repository = repository
    }

    func showDetail(for id: User.ID) {
        let vc = UserDetailViewController()
        let presenter = UserDetailPresenter(
            view: vc,
            repository: repository,
            id: id,
            onSaved: { _ in /* hook: trigger list refresh, etc. */ }
        )
        vc.presenter = presenter
        navigationController?.pushViewController(vc, animated: true)
    }
}
