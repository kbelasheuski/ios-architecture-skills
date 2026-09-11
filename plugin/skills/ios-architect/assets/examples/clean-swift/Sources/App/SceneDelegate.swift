import UIKit

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options: UIScene.ConnectionOptions) {
        guard let ws = scene as? UIWindowScene else { return }
        let repo: UserRepository = LiveUserRepository(baseURL: URL(string: "https://api.example.com")!)
        let root = UserListConfigurator.make(repository: repo)
        let nav = UINavigationController(rootViewController: root)
        let w = UIWindow(windowScene: ws)
        w.rootViewController = nav
        w.makeKeyAndVisible()
        window = w
    }
}
