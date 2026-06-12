# Reference Feature Spec

Every architecture skill in this bundle implements the **same** reference feature. Code in each skill is production-grade and compilable (modulo Swift Package context). Conventions are modeled on canonical open-source references — each skill cites its source repo at the top.

## Domain model

```swift
import Foundation

public struct User: Equatable, Identifiable, Sendable, Hashable {
    public let id: UUID
    public var name: String
    public var email: String

    public init(id: UUID, name: String, email: String) {
        self.id = id; self.name = name; self.email = email
    }
}

public struct UsersPage: Equatable, Sendable {
    public let users: [User]
    public let page: Int
    public let totalPages: Int

    public var hasMore: Bool { page < totalPages }
}
```

## Repository contract

```swift
public protocol UserRepository: Sendable {
    func fetchUsers(page: Int) async throws -> UsersPage
    func fetchUser(id: User.ID) async throws -> User
    func update(_ user: User) async throws -> User
}

public enum UserRepositoryError: LocalizedError, Sendable {
    case network
    case notFound
    case server(Int)

    public var errorDescription: String? {
        switch self {
        case .network:       return "No internet connection"
        case .notFound:      return "User not found"
        case .server(let c): return "Server error (\(c))"
        }
    }
}
```

## Live repository (sketch — same across skills)

```swift
public final class LiveUserRepository: UserRepository {
    private let session: URLSession
    private let baseURL: URL
    private let decoder: JSONDecoder

    public init(session: URLSession = .shared, baseURL: URL) {
        self.session = session
        self.baseURL = baseURL
        self.decoder = JSONDecoder()
    }

    public func fetchUsers(page: Int) async throws -> UsersPage {
        var components = URLComponents(url: baseURL.appendingPathComponent("users"), resolvingAgainstBaseURL: false)!
        components.queryItems = [.init(name: "page", value: String(page))]
        return try await get(components.url!)
    }

    public func fetchUser(id: User.ID) async throws -> User {
        try await get(baseURL.appendingPathComponent("users/\(id.uuidString)"))
    }

    public func update(_ user: User) async throws -> User {
        var req = URLRequest(url: baseURL.appendingPathComponent("users/\(user.id.uuidString)"))
        req.httpMethod = "PUT"
        req.httpBody = try JSONEncoder().encode(user)
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        return try await send(req)
    }

    private func get<T: Decodable>(_ url: URL) async throws -> T {
        try await send(URLRequest(url: url))
    }

    private func send<T: Decodable>(_ request: URLRequest) async throws -> T {
        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else { throw UserRepositoryError.network }
            switch http.statusCode {
            case 200..<300: return try decoder.decode(T.self, from: data)
            case 404:       throw UserRepositoryError.notFound
            default:        throw UserRepositoryError.server(http.statusCode)
            }
        } catch is URLError {
            throw UserRepositoryError.network
        }
    }
}
```

## Fake repository (test/preview infra — same across skills)

```swift
public final class FakeUserRepository: UserRepository, @unchecked Sendable {
    public var pages: [UsersPage]
    public var updateHandler: (@Sendable (User) throws -> User)?
    public private(set) var fetchPageCalls: [Int] = []
    public private(set) var updateCalls: [User] = []
    public var delay: Duration = .zero

    public init(pages: [UsersPage] = [.init(users: [.fixture()], page: 1, totalPages: 1)]) {
        self.pages = pages
    }

    public func fetchUsers(page: Int) async throws -> UsersPage {
        if delay > .zero { try await Task.sleep(for: delay) }
        fetchPageCalls.append(page)
        guard let p = pages.first(where: { $0.page == page }) else { throw UserRepositoryError.notFound }
        return p
    }

    public func fetchUser(id: User.ID) async throws -> User {
        let all = pages.flatMap(\.users)
        guard let u = all.first(where: { $0.id == id }) else { throw UserRepositoryError.notFound }
        return u
    }

    public func update(_ user: User) async throws -> User {
        updateCalls.append(user)
        if let h = updateHandler { return try h(user) }
        return user
    }
}

public extension User {
    static func fixture(
        id: UUID = UUID(),
        name: String = "Ada Lovelace",
        email: String = "ada@example.com"
    ) -> User {
        .init(id: id, name: name, email: email)
    }
}

public extension UsersPage {
    static func fixture(
        users: [User] = [.fixture()],
        page: Int = 1,
        totalPages: Int = 1
    ) -> UsersPage {
        .init(users: users, page: page, totalPages: totalPages)
    }
}
```

## Screens

1. **UserListScreen** — paged list (`name`, `email`), pull-to-refresh, tap → detail, loading/error/empty states.
2. **UserDetailScreen** — name/email, editable name, Save → `update(_:)`, Cancel → discard + pop.

## Cross-cutting

- DI: every screen receives repository or use-cases via init; no globals/singletons.
- Concurrency: `async`/`await`, UI on `@MainActor`.
- Deployment target: iOS 17+ for every buildable example.
- Tests: each buildable example ships focused XCTest coverage for its boundary
  (list loading, detail save, routing, reducer/store transitions, or module rules).
