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
        let root = UserListViewController(repository: repository)
        let nav = UINavigationController(rootViewController: root)
        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = nav
        window.makeKeyAndVisible()
        self.window = window
    }
}
