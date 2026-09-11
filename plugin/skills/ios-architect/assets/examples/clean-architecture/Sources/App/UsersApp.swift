import SwiftUI

@main
struct UsersApp: App {
    @State private var appDI = AppDIContainer()
    @State private var coordinator = UsersFlowCoordinator()

    var body: some Scene {
        WindowGroup {
            NavigationStack(path: $coordinator.path) {
                let scene = appDI.makeUsersSceneDIContainer()
                let actions = UserListActions(
                    showUserDetail: { user in coordinator.showDetail(for: user) }
                )
                UserListView(viewModel: scene.makeUserListViewModel(actions: actions))
                    .navigationDestination(for: UsersRoute.self) { route in
                        switch route {
                        case .userDetail(let id):
                            UserDetailView(
                                viewModel: scene.makeUserDetailViewModel(id: id) { _ in
                                    coordinator.pop()
                                }
                            )
                        }
                    }
            }
        }
    }
}
