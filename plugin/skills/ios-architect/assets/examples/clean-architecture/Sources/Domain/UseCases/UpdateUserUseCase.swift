import Foundation

public protocol UpdateUserUseCase: Sendable {
    func execute(_ user: User) async throws -> User
}

public struct DefaultUpdateUserUseCase: UpdateUserUseCase {
    private let repository: UserRepository

    public init(repository: UserRepository) {
        self.repository = repository
    }

    public func execute(_ user: User) async throws -> User {
        let trimmed = user.name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { throw ValidationError.emptyName }
        var validated = user
        validated.name = trimmed
        return try await repository.update(validated)
    }

    public enum ValidationError: LocalizedError {
        case emptyName
        public var errorDescription: String? { "Name must not be empty" }
    }
}
