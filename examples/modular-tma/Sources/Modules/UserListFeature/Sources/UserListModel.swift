import Foundation
import Observation
import Domain
import UserDomain

@Observable
@MainActor
final class UserListModel {

    enum LoadState: Equatable { case idle, loading, loaded, failed(String) }

    private(set) var users: [User] = []
    private(set) var state: LoadState = .idle
    private(set) var page = 0
    private(set) var hasMore = true

    private let fetchUsers: FetchUsersUseCase
    private var task: Task<Void, Never>?

    init(fetchUsers: FetchUsersUseCase) {
        self.fetchUsers = fetchUsers
    }

    func onAppear() async {
        guard users.isEmpty else { return }
        await load(reset: true)
    }

    func refresh() async {
        await load(reset: true)
    }

    func loadNextPageIfNeeded(currentItem: User) {
        guard hasMore, state != .loading,
              let idx = users.firstIndex(of: currentItem),
              idx >= max(users.count - 3, 0) else { return }
        task?.cancel()
        task = Task { await self.load(reset: false) }
    }

    private func load(reset: Bool) async {
        state = .loading
        let target = reset ? 1 : page + 1
        do {
            let result = try await fetchUsers(page: target)
            try Task.checkCancellation()
            if reset { users = result.users } else { users.append(contentsOf: result.users) }
            page = result.page
            hasMore = result.hasMore
            state = .loaded
        } catch is CancellationError {
            state = .idle
        } catch {
            state = .failed(error.localizedDescription)
        }
    }
}
