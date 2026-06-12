import Foundation

public protocol UserRepository: Sendable {
    func fetchUsers(page: Int) async throws -> UsersPage
    func fetchUser(id: User.ID) async throws -> User
    func update(_ user: User) async throws -> User
}

public enum UserRepositoryError: LocalizedError, Sendable, Equatable {
    case network
    case notFound
    case server(Int)
    case decoding

    public var errorDescription: String? {
        switch self {
        case .network:        return "No internet connection"
        case .notFound:       return "User not found"
        case .server(let c):  return "Server error (\(c))"
        case .decoding:       return "Invalid server response"
        }
    }
}
