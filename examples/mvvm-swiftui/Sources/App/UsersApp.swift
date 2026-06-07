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
                    model: UserListModel(repository: repository)
                ) { user in
                    UserDetailView(
                        model: UserDetailModel(repository: repository, id: user.id)
                    )
                }
            }
        }
    }
}
