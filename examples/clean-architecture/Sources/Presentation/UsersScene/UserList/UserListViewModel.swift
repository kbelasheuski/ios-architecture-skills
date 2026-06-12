import Foundation
import Observation

public struct UserListActions {
    public let showUserDetail: @MainActor (User) -> Void
    public init(showUserDetail: @escaping @MainActor (User) -> Void) {
        self.showUserDetail = showUserDetail
    }
}

public enum UserListLoading: Equatable {
    case none, fullScreen, nextPage
}

@Observable
@MainActor
public final class UserListViewModel {

    // Outputs
    public private(set) var users: [User] = []
    public private(set) var loading: UserListLoading = .none
    public var errorMessage: String?

    public var isEmpty: Bool { users.isEmpty }
    public let screenTitle = NSLocalizedString("Users", comment: "")

    private var currentPage = 0
    private var totalPages = 1
    private var hasMorePages: Bool { currentPage < totalPages }
    private var nextPage: Int { hasMorePages ? currentPage + 1 : currentPage }

    private let fetchUsersUseCase: FetchUsersUseCase
    private let actions: UserListActions
    private var loadTask: Task<Void, Never>? {
        willSet { loadTask?.cancel() }
    }

    public init(fetchUsersUseCase: FetchUsersUseCase, actions: UserListActions) {
        self.fetchUsersUseCase = fetchUsersUseCase
        self.actions = actions
    }

    public func viewDidLoad() async {
        guard users.isEmpty else { return }
        await load(loading: .fullScreen, reset: true)
    }

    public func didPullToRefresh() async {
        await load(loading: .fullScreen, reset: true)
    }

    public func didLoadNextPageIfNeeded(currentUser: User) {
        guard hasMorePages, loading == .none,
              let idx = users.firstIndex(of: currentUser),
              idx >= max(users.count - 3, 0) else { return }
        loadTask = Task { await self.load(loading: .nextPage, reset: false) }
    }

    public func didSelectUser(at id: User.ID) {
        guard let user = users.first(where: { $0.id == id }) else { return }
        actions.showUserDetail(user)
    }

    public func errorDismissed() { errorMessage = nil }

    private func load(loading: UserListLoading, reset: Bool) async {
        self.loading = loading
        do {
            let page = try await fetchUsersUseCase.execute(page: reset ? 1 : nextPage)
            try Task.checkCancellation()
            if reset { users = page.users } else { users.append(contentsOf: page.users) }
            currentPage = page.page
            totalPages = page.totalPages
        } catch is CancellationError {
            // swallow
        } catch {
            errorMessage = error.localizedDescription
        }
        self.loading = .none
    }
}
