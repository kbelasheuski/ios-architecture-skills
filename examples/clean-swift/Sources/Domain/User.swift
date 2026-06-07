import Foundation

public struct User: Equatable, Identifiable, Sendable, Hashable {
    public let id: UUID
    public var name: String
    public var email: String

    public init(id: UUID, name: String, email: String) {
        self.id = id
        self.name = name
        self.email = email
    }
}

public struct UsersPage: Equatable, Sendable {
    public let users: [User]
    public let page: Int
    public let totalPages: Int

    public var hasMore: Bool { page < totalPages }

    public init(users: [User], page: Int, totalPages: Int) {
        self.users = users
        self.page = page
        self.totalPages = totalPages
    }
}
