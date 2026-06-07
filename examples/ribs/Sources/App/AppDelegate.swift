import RIBs
import UIKit

final class RootDependencyImpl: UserListDependency {
    let userRepository: UserRepository = LiveUserRepository(
        baseURL: URL(string: "https://api.example.com")!
    )
}

final class RootListener: UserListListener {
    func userListDidFinish() { /* root: nothing to do */ }
}

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    private let rootListener = RootListener()
    private var router: UserListRouting?

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let dep = RootDependencyImpl()
        let builder = UserListBuilder(dependency: dep)
        let router = builder.build(withListener: rootListener)
        self.router = router
        router.interactable.activate()
        router.load()
        let nav = UINavigationController(rootViewController: router.viewControllable.uiviewController)
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = nav
        window.makeKeyAndVisible()
        self.window = window
        return true
    }
}
