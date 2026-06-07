import Foundation

public struct UserListState: Equatable, Sendable {
    public var users: [User] = []
    public var page: Int = 0
    public var totalPages: Int = 1
    public var loading: Loading = .none
    public var errorMessage: String?

    public enum Loading: Equatable, Sendable { case none, fullScreen, nextPage }
    public var hasMore: Bool { page < totalPages }

    public init(
        users: [User] = [],
        page: Int = 0,
        totalPages: Int = 1,
        loading: Loading = .none,
        errorMessage: String? = nil
    ) {
        self.users = users
        self.page = page
        self.totalPages = totalPages
        self.loading = loading
        self.errorMessage = errorMessage
    }
}
