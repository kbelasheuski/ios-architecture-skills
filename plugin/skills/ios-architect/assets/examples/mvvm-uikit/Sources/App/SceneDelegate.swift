import Combine
import UIKit

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    private var cancellables: Set<AnyCancellable> = []
    private let repository: UserRepository = LiveUserRepository(
        baseURL: URL(string: "https://api.example.com")!
    )

    func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }
        let nav = UINavigationController()
        let listVM = UserListViewModel(repository: repository)
        let listVC = UserListViewController(viewModel: listVM)
        listVM.userSelected
            .sink { [weak self, weak nav] id in
                guard let self else { return }
                let detail = UserDetailViewController(
                    viewModel: UserDetailViewModel(repository: self.repository, id: id)
                )
                nav?.pushViewController(detail, animated: true)
            }
            .store(in: &cancellables)
        nav.viewControllers = [listVC]
        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = nav
        window.makeKeyAndVisible()
        self.window = window
    }
}
