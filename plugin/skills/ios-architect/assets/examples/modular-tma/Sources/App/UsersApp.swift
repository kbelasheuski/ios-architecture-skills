import SwiftUI

@main
struct UsersApp: App {
    private let container = AppContainer()

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                container.userListFactory.makeUserList { user in
                    container.userDetailFactory.makeUserDetail(userID: user.id) { _ in }
                }
            }
        }
    }
}

@MainActor
final class AppContainer {
    let userListFactory: UserListFeatureFactory
    let userDetailFactory: UserDetailFeatureFactory

    init() {
        let repo: UserRepository = LiveUserRepository(
            baseURL: URL(string: "https://api.example.com")!
        )
        let fetchUsers = FetchUsersUseCaseLive(repository: repo)
        let fetchUser = FetchUserUseCaseLive(repository: repo)
        let updateUser = UpdateUserUseCaseLive(repository: repo)
        self.userListFactory = UserListFeatureFactoryLive(fetchUsers: fetchUsers)
        self.userDetailFactory = UserDetailFeatureFactoryLive(
            fetchUser: fetchUser,
            updateUser: updateUser
        )
    }
}
