import UIKit

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }
        let repository: UserRepository = LiveUserRepository(
            baseURL: URL(string: "https://api.example.com")!
        )
        let nav = UINavigationController()
        let navigator = UserNavigator(navigationController: nav, repository: repository)
        let listVC = UserListViewController()
        listVC.presenter = UserListPresenter(view: listVC, repository: repository, navigator: navigator)
        nav.viewControllers = [listVC]
        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = nav
        window.makeKeyAndVisible()
        self.window = window
    }
}
