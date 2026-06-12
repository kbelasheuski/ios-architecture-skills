import UIKit

enum UserDetailBuilder {
    @MainActor
    static func build(repository: UserRepository, userID: User.ID) -> UIViewController {
        let view = UserDetailViewController()
        let interactor = UserDetailInteractor(repository: repository)
        let router = UserDetailRouter()
        let presenter = UserDetailPresenter(view: view, interactor: interactor, router: router, id: userID)
        view.presenter = presenter
        router.viewController = view
        return view
    }
}
