import Foundation
@testable import MVPExample

public final class FakeUserRepository: UserRepository, @unchecked Sendable {
    public var pages: [UsersPage]
    public var fetchUserHandler: (@Sendable (User.ID) throws -> User)?
    public var updateHandler: (@Sendable (User) throws -> User)?

    public private(set) var fetchPageCalls: [Int] = []
    public private(set) var fetchUserCalls: [User.ID] = []
    public private(set) var updateCalls: [User] = []

    public var delay: Duration = .zero

    public init(pages: [UsersPage] = [.fixture()]) {
        self.pages = pages
    }

    public func fetchUsers(page: Int) async throws -> UsersPage {
        if delay > .zero { try await Task.sleep(for: delay) }
        fetchPageCalls.append(page)
        guard let pageResult = pages.first(where: { $0.page == page }) else {
            throw UserRepositoryError.notFound
        }
        return pageResult
    }

    public func fetchUser(id: User.ID) async throws -> User {
        fetchUserCalls.append(id)
        if let handler = fetchUserHandler {
            return try handler(id)
        }
        let all = pages.flatMap(\.users)
        guard let user = all.first(where: { $0.id == id }) else {
            throw UserRepositoryError.notFound
        }
        return user
    }

    public func update(_ user: User) async throws -> User {
        updateCalls.append(user)
        if let handler = updateHandler {
            return try handler(user)
        }
        return user
    }
}
