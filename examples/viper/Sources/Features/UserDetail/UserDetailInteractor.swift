import Foundation

public final class UserDetailInteractor: UserDetailInteractorProtocol {
    private let repository: UserRepository

    public init(repository: UserRepository) {
        self.repository = repository
    }

    public func fetch(id: User.ID) async throws -> User {
        try await repository.fetchUser(id: id)
    }

    public func update(_ user: User) async throws -> User {
        try await repository.update(user)
    }
}
