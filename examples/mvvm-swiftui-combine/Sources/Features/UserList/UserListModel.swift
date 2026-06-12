import Combine
import Foundation

@MainActor
public final class UserListModel: ObservableObject {

    public enum LoadState: Equatable {
        case idle
        case loading
        case loaded
        case failed(String)
    }

    @Published public private(set) var users: [User] = []
    @Published public private(set) var state: LoadState = .idle
    @Published public private(set) var page = 0
    @Published public private(set) var hasMore = true

    private let repository: UserRepository
    private var activeLoadID: UUID?

    public init(repository: UserRepository) {
        self.repository = repository
    }

    public func onAppear() async {
        guard users.isEmpty else { return }
        await load(reset: true)
    }

    public func refresh() async {
        await load(reset: true)
    }

    public func loadNextPageIfNeeded(currentItem: User) async {
        guard hasMore, state != .loading,
              let idx = users.firstIndex(of: currentItem),
              idx >= max(users.count - 3, 0) else { return }
        await load(reset: false)
    }

    public func dismissError() {
        if case .failed = state { state = .idle }
    }

    private func load(reset: Bool) async {
        let loadID = UUID()
        activeLoadID = loadID
        state = .loading
        let target = reset ? 1 : page + 1
        do {
            let result = try await repository.fetchUsers(page: target)
            try Task.checkCancellation()
            guard activeLoadID == loadID else { return }
            if reset { users = result.users } else { users.append(contentsOf: result.users) }
            page = result.page
            hasMore = result.hasMore
            state = .loaded
            activeLoadID = nil
        } catch is CancellationError {
            guard activeLoadID == loadID else { return }
            state = .idle
            activeLoadID = nil
        } catch {
            guard activeLoadID == loadID else { return }
            state = .failed(error.localizedDescription)
            activeLoadID = nil
        }
    }
}
