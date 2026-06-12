import Foundation
import Observation

@Observable
@MainActor
public final class UserListStore {

    public enum LoadState: Equatable {
        case idle
        case loading
        case loaded
        case failed(String)
    }

    public struct State: Equatable {
        public var users: [User] = []
        public var loadState: LoadState = .idle
        public var page = 0
        public var hasMore = true
    }

    public enum Intent: Equatable {
        case onAppear
        case refresh
        case loadNextPageIfNeeded(User)
        case dismissError
    }

    public private(set) var state: State

    private let repository: UserRepository
    private var activeLoadID: UUID?

    public init(repository: UserRepository) {
        self.repository = repository
        self.state = State()
    }

    public func dispatch(_ intent: Intent) async {
        switch intent {
        case .onAppear:
            guard state.users.isEmpty else { return }
            await load(reset: true)
        case .refresh:
            await load(reset: true)
        case .loadNextPageIfNeeded(let user):
            guard state.hasMore,
                  state.loadState != .loading,
                  let index = state.users.firstIndex(of: user),
                  index >= max(state.users.count - 3, 0)
            else { return }
            await load(reset: false)
        case .dismissError:
            if case .failed = state.loadState {
                state.loadState = .idle
            }
        }
    }

    private func load(reset: Bool) async {
        let loadID = UUID()
        activeLoadID = loadID
        state.loadState = .loading
        let target = reset ? 1 : state.page + 1
        do {
            let result = try await repository.fetchUsers(page: target)
            try Task.checkCancellation()
            guard activeLoadID == loadID else { return }
            if reset {
                state.users = result.users
            } else {
                state.users.append(contentsOf: result.users)
            }
            state.page = result.page
            state.hasMore = result.hasMore
            state.loadState = .loaded
            activeLoadID = nil
        } catch is CancellationError {
            guard activeLoadID == loadID else { return }
            state.loadState = .idle
            activeLoadID = nil
        } catch {
            guard activeLoadID == loadID else { return }
            state.loadState = .failed(error.localizedDescription)
            activeLoadID = nil
        }
    }
}
