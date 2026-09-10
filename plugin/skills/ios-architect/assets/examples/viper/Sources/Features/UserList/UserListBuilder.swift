import UIKit

enum UserListBuilder {
    @MainActor
    static func build(repository: UserRepository) -> UIViewController {
        let view = UserListViewController()
        let interactor = UserListInteractor(repository: repository)
        let router = UserListRouter(repository: repository)
        let presenter = UserListPresenter(view: view, interactor: interactor, router: router)
        view.presenter = presenter
        router.viewController = view
        return view
    }
}
