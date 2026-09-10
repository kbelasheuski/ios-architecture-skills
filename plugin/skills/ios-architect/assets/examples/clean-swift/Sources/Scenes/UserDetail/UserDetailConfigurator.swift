import UIKit

@MainActor
enum UserDetailConfigurator {
    static func make(repository: UserRepository, userID: User.ID) -> UIViewController {
        let vc = UserDetailViewController()
        let interactor = UserDetailInteractor(worker: UserDetailWorker(repository: repository))
        let presenter = UserDetailPresenter()
        let router = UserDetailRouter()

        vc.userID = userID
        vc.interactor = interactor
        vc.router = router
        interactor.presenter = presenter
        presenter.view = vc
        router.viewController = vc

        return vc
    }
}
