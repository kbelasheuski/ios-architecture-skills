import ComposableArchitecture
import Foundation

@Reducer
public struct UserListFeature: Sendable {

    @ObservableState
    public struct State: Equatable {
        public var users: IdentifiedArrayOf<User> = []
        public var page: Int = 0
        public var totalPages: Int = 1
        public var isLoading: Bool = false
        public var errorMessage: String?
        public var path = StackState<UserDetailFeature.State>()

        public var hasMore: Bool { page < totalPages }

        public init(
            users: IdentifiedArrayOf<User> = [],
            page: Int = 0,
            totalPages: Int = 1,
            isLoading: Bool = false,
            errorMessage: String? = nil
        ) {
            self.users = users
            self.page = page
            self.totalPages = totalPages
            self.isLoading = isLoading
            self.errorMessage = errorMessage
        }
    }

    public enum Action {
        case onAppear
        case refresh
        case rowTapped(User.ID)
        case loadNextPageIfNeeded(User.ID)
        case pageResponse(Result<UsersPage, Error>, isRefresh: Bool)
        case errorDismissed
        case path(StackActionOf<UserDetailFeature>)
    }

    @Dependency(\.userClient) var userClient

    private enum CancelID { case load }

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {

            case .onAppear:
                guard state.users.isEmpty, !state.isLoading else { return .none }
                return load(state: &state, isRefresh: true)

            case .refresh:
                return load(state: &state, isRefresh: true)

            case let .loadNextPageIfNeeded(id):
                guard state.hasMore, !state.isLoading else { return .none }
                let threshold = max(state.users.count - 3, 0)
                guard let idx = state.users.index(id: id), idx >= threshold else { return .none }
                return load(state: &state, isRefresh: false)

            case let .rowTapped(id):
                guard let user = state.users[id: id] else { return .none }
                state.path.append(UserDetailFeature.State(user: user))
                return .none

            case let .pageResponse(.success(page), isRefresh):
                state.isLoading = false
                if isRefresh { state.users = [] }
                state.users.append(contentsOf: page.users)
                state.page = page.page
                state.totalPages = page.totalPages
                return .none

            case let .pageResponse(.failure(error), _):
                state.isLoading = false
                state.errorMessage = error.localizedDescription
                return .none

            case .errorDismissed:
                state.errorMessage = nil
                return .none

            case .path(.element(id: _, action: .delegate(.didSave(let saved)))):
                state.users[id: saved.id] = saved
                return .none

            case .path:
                return .none
            }
        }
        .forEach(\.path, action: \.path) { UserDetailFeature() }
    }

    private func load(state: inout State, isRefresh: Bool) -> Effect<Action> {
        state.isLoading = true
        let target = isRefresh ? 1 : state.page + 1
        return .run { send in
            await send(.pageResponse(
                Result { try await userClient.fetchUsers(target) },
                isRefresh: isRefresh
            ))
        }
        .cancellable(id: CancelID.load, cancelInFlight: true)
    }
}
