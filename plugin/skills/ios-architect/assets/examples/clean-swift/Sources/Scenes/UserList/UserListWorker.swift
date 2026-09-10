import Foundation

public final class UserListWorker {
    private let repository: UserRepository

    public init(repository: UserRepository) {
        self.repository = repository
    }

    public func fetchUsers(page: Int) async throws -> UsersPage {
        try await repository.fetchUsers(page: page)
    }
}
