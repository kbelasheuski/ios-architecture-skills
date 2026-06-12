import Foundation
import Domain

public protocol FetchUserUseCase: Sendable {
    func callAsFunction(id: User.ID) async throws -> User
}

public struct FetchUserUseCaseLive: FetchUserUseCase {
    private let repository: UserRepository
    public init(repository: UserRepository) { self.repository = repository }
    public func callAsFunction(id: User.ID) async throws -> User {
        try await repository.fetchUser(id: id)
    }
}
