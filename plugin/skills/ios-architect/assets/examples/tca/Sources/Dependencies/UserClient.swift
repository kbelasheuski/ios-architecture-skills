import ComposableArchitecture
import Foundation

@DependencyClient
public struct UserClient: Sendable {
    public var fetchUsers: @Sendable (_ page: Int) async throws -> UsersPage
    public var fetchUser: @Sendable (_ id: User.ID) async throws -> User
    public var update: @Sendable (_ user: User) async throws -> User
}

extension UserClient: DependencyKey {
    public static let liveValue: UserClient = {
        let repo = LiveUserRepository(baseURL: URL(string: "https://api.example.com")!)
        return UserClient(
            fetchUsers: { try await repo.fetchUsers(page: $0) },
            fetchUser: { try await repo.fetchUser(id: $0) },
            update: { try await repo.update($0) }
        )
    }()

    public static let previewValue = UserClient(
        fetchUsers: { _ in
            UsersPage(
                users: [
                    User(id: UUID(), name: "Ada", email: "ada@example.com"),
                    User(id: UUID(), name: "Grace", email: "grace@example.com")
                ],
                page: 1,
                totalPages: 1
            )
        },
        fetchUser: { id in User(id: id, name: "Ada", email: "ada@example.com") },
        update: { $0 }
    )

    public static let testValue = UserClient()    // unimplemented → XCTFail on call
}

extension DependencyValues {
    public var userClient: UserClient {
        get { self[UserClient.self] }
        set { self[UserClient.self] = newValue }
    }
}
