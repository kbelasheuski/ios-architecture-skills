import Foundation
import Domain

public protocol FetchUsersUseCase: Sendable {
    func callAsFunction(page: Int) async throws -> UsersPage
}

public struct FetchUsersUseCaseLive: FetchUsersUseCase {
    private let repository: UserRepository

    public init(repository: UserRepository) {
        self.repository = repository
    }

    public func callAsFunction(page: Int) async throws -> UsersPage {
        try await repository.fetchUsers(page: max(1, page))
    }
}
