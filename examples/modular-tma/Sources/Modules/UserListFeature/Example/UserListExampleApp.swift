import SwiftUI

// Mini-app — runs UserListFeature in isolation, no main App needed.
// Uses an in-memory PreviewFetchUsers so no network or full DI graph required.

@main
struct UserListExampleApp: App {
    private let factory = UserListFeatureFactoryLive(fetchUsers: PreviewFetchUsers())

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                factory.makeUserList { _ in
                    AnyView(Text("Detail stub (use UserDetailFeature in full app)"))
                }
            }
        }
    }
}

struct PreviewFetchUsers: FetchUsersUseCase {
    func callAsFunction(page: Int) async throws -> UsersPage {
        .fixture(
            users: (0..<10).map { .fixture(name: "User \($0)") },
            page: 1,
            totalPages: 1
        )
    }
}
