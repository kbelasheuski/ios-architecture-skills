import Foundation

@MainActor
public final class AppDIContainer {
    private lazy var repository: UserRepository = LiveUserRepository(
        baseURL: URL(string: "https://api.example.com")!
    )

    public init() {}

    public func makeUsersSceneDIContainer() -> UsersSceneDIContainer {
        UsersSceneDIContainer(repository: repository)
    }
}
