import SwiftUI

@main
struct UsersApp: App {
    private let repository: UserRepository = LiveUserRepository(
        baseURL: URL(string: "https://api.example.com")!
    )

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                UserListView(
                    store: UserListStore(repository: repository)
                ) { user in
                    UserDetailView(
                        store: UserDetailStore(repository: repository, id: user.id)
                    )
                }
            }
        }
    }
}
