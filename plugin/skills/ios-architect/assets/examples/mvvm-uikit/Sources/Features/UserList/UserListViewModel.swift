import Combine
import Foundation

@MainActor
public final class UserListViewModel {

    public enum Loading: Equatable { case none, fullScreen, nextPage }

    // Outputs
    @Published public private(set) var users: [User] = []
    @Published public private(set) var loading: Loading = .none
    @Published public var errorMessage: String?

    // Events
    public let userSelected = PassthroughSubject<User.ID, Never>()

    private let repository: UserRepository
    private var page = 0
    private var totalPages = 1
    private var loadTask: Task<Void, Never>? {
        willSet { loadTask?.cancel() }
    }
    private var hasMore: Bool { page < totalPages }

    public init(repository: UserRepository) {
        self.repository = repository
    }

    public func onAppear() {
        guard users.isEmpty else { return }
        load(loading: .fullScreen, reset: true)
    }

    public func refresh() {
        load(loading: .fullScreen, reset: true)
    }

    public func didDisplayRow(at index: Int) {
        guard hasMore, loading == .none, index >= max(users.count - 3, 0) else { return }
        load(loading: .nextPage, reset: false)
    }

    public func didSelectRow(at index: Int) {
        guard users.indices.contains(index) else { return }
        userSelected.send(users[index].id)
    }

    public func dismissError() { errorMessage = nil }

    private func load(loading: Loading, reset: Bool) {
        self.loading = loading
        loadTask = Task { [weak self] in
            guard let self else { return }
            do {
                let target = reset ? 1 : self.page + 1
                let result = try await repository.fetchUsers(page: target)
                try Task.checkCancellation()
                if reset { users = result.users } else { users.append(contentsOf: result.users) }
                page = result.page
                totalPages = result.totalPages
            } catch is CancellationError {
                // swallow
            } catch {
                errorMessage = error.localizedDescription
            }
            self.loading = .none
        }
    }
}
