import Foundation

public protocol FetchUsersUseCase: Sendable {
    func execute(page: Int) async throws -> UsersPage
}

public struct DefaultFetchUsersUseCase: FetchUsersUseCase {
    private let repository: UserRepository

    public init(repository: UserRepository) {
        self.repository = repository
    }

    public func execute(page: Int) async throws -> UsersPage {
        // Business rule: clamp page to >= 1.
        try await repository.fetchUsers(page: max(1, page))
    }
}
