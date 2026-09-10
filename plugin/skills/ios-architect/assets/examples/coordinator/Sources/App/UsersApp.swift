import SwiftUI

@main
struct UsersApp: App {
    @State private var coordinator = AppCoordinator()
    private let repository: UserRepository = LiveUserRepository(
        baseURL: URL(string: "https://api.example.com")!
    )

    var body: some Scene {
        WindowGroup {
            NavigationStack(path: $coordinator.path) {
                UserListView(
                    model: UserListModel(
                        repository: repository,
                        onSelect: { id in coordinator.push(.userDetail(id)) }
                    )
                )
                .navigationDestination(for: AppRoute.self) { route in
                    switch route {
                    case .userDetail(let id):
                        UserDetailView(
                            model: UserDetailModel(
                                repository: repository,
                                id: id,
                                onSaved: { _ in coordinator.pop() }
                            )
                        )
                    }
                }
            }
            .onOpenURL { coordinator.handle($0) }
        }
    }
}
