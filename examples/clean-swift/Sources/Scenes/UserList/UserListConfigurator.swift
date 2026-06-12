import UIKit

@MainActor
enum UserListConfigurator {
    static func make(repository: UserRepository) -> UserListViewController {
        let vc = UserListViewController()
        let interactor = UserListInteractor(worker: UserListWorker(repository: repository))
        let presenter = UserListPresenter()
        let router = UserListRouter(repository: repository)

        vc.interactor = interactor
        vc.router = router
        interactor.presenter = presenter
        presenter.view = vc
        router.viewController = vc
        router.dataStore = interactor

        return vc
    }
}
