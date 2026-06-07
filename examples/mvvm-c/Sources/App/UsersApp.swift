import SwiftUI

@main
struct UsersApp: App {
    @State private var router = AppRouter()
    private let repository: UserRepository = LiveUserRepository(
        baseURL: URL(string: "https://api.example.com")!
    )

    var body: some Scene {
        WindowGroup {
            NavigationStack(path: $router.path) {
                UserListView(
                    model: UserListModel(
                        repository: repository,
                        onSelect: { id in router.push(.userDetail(id)) }
                    )
                )
                .navigationDestination(for: Route.self) { route in
                    switch route {
                    case .userDetail(let id):
                        UserDetailView(
                            model: UserDetailModel(
                                repository: repository,
                                id: id,
                                onSaved: { _ in router.pop() }
                            )
                        )
                    }
                }
            }
            .onOpenURL { router.handle($0) }
        }
    }
}
