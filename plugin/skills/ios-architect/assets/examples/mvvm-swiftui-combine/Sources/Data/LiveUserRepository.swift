import Foundation

public final class LiveUserRepository: UserRepository {
    private let session: URLSession
    private let baseURL: URL
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    public init(session: URLSession = .shared, baseURL: URL) {
        self.session = session
        self.baseURL = baseURL
        self.decoder = JSONDecoder()
        self.encoder = JSONEncoder()
    }

    public func fetchUsers(page: Int) async throws -> UsersPage {
        guard var components = URLComponents(
            url: baseURL.appendingPathComponent("users"),
            resolvingAgainstBaseURL: false
        ) else {
            throw UserRepositoryError.network
        }
        components.queryItems = [.init(name: "page", value: String(page))]
        guard let url = components.url else {
            throw UserRepositoryError.network
        }
        let dto: UsersPageDTO = try await get(url)
        return dto.toDomain()
    }

    public func fetchUser(id: User.ID) async throws -> User {
        let dto: UserDTO = try await get(baseURL.appendingPathComponent("users/\(id.uuidString)"))
        return dto.toDomain()
    }

    public func update(_ user: User) async throws -> User {
        var req = URLRequest(url: baseURL.appendingPathComponent("users/\(user.id.uuidString)"))
        req.httpMethod = "PUT"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try encoder.encode(UserDTO(domain: user))
        let dto: UserDTO = try await send(req)
        return dto.toDomain()
    }

    private func get<T: Decodable>(_ url: URL) async throws -> T {
        try await send(URLRequest(url: url))
    }

    private func send<T: Decodable>(_ request: URLRequest) async throws -> T {
        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                throw UserRepositoryError.network
            }
            switch http.statusCode {
            case 200..<300:
                do {
                    return try decoder.decode(T.self, from: data)
                } catch is DecodingError {
                    throw UserRepositoryError.decoding
                }
            case 404:       throw UserRepositoryError.notFound
            default:        throw UserRepositoryError.server(http.statusCode)
            }
        } catch is URLError {
            throw UserRepositoryError.network
        }
    }
}

struct UserDTO: Codable {
    let id: UUID
    let name: String
    let email: String

    init(domain: User) {
        self.id = domain.id; self.name = domain.name; self.email = domain.email
    }

    func toDomain() -> User {
        User(id: id, name: name, email: email)
    }
}

struct UsersPageDTO: Codable {
    let users: [UserDTO]
    let page: Int
    let totalPages: Int

    func toDomain() -> UsersPage {
        UsersPage(users: users.map { $0.toDomain() }, page: page, totalPages: totalPages)
    }
}
