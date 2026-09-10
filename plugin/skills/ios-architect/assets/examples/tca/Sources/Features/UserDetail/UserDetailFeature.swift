import ComposableArchitecture
import Foundation

@Reducer
public struct UserDetailFeature: Sendable {

    @ObservableState
    public struct State: Equatable, Identifiable {
        public var user: User
        public var draftName: String
        public var isSaving: Bool = false
        public var errorMessage: String?

        public var id: User.ID { user.id }
        public var isDirty: Bool { user.name != draftName }
        public var canSave: Bool { isDirty && !draftName.isEmpty && !isSaving }

        public init(user: User) {
            self.user = user
            self.draftName = user.name
        }
    }

    public enum Action: BindableAction {
        case binding(BindingAction<State>)
        case saveTapped
        case cancelTapped
        case saveResponse(Result<User, Error>)
        case errorDismissed
        case delegate(Delegate)

        @CasePathable
        public enum Delegate: Equatable {
            case didSave(User)
        }
    }

    @Dependency(\.userClient) var userClient
    @Dependency(\.dismiss) var dismiss

    public init() {}

    public var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .binding:
                return .none

            case .saveTapped:
                guard state.canSave else { return .none }
                state.isSaving = true
                var draft = state.user
                draft.name = state.draftName
                let userToSave = draft
                return .run { send in
                    await send(.saveResponse(Result { try await userClient.update(userToSave) }))
                }

            case .cancelTapped:
                return .run { _ in await dismiss() }

            case let .saveResponse(.success(saved)):
                state.user = saved
                state.draftName = saved.name
                state.isSaving = false
                return .concatenate(
                    .send(.delegate(.didSave(saved))),
                    .run { _ in await dismiss() }
                )

            case let .saveResponse(.failure(error)):
                state.isSaving = false
                state.errorMessage = error.localizedDescription
                return .none

            case .errorDismissed:
                state.errorMessage = nil
                return .none

            case .delegate:
                return .none
            }
        }
    }
}
