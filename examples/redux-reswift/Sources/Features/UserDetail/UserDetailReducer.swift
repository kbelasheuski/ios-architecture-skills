import Foundation

public func userDetailReducer(action: UserDetailAction, state: UserDetailState?) -> UserDetailState? {
    var nextState = state ?? UserDetailState()
    switch action {
    case .load:
        nextState = .init()
    case .loaded(let user):
        nextState.user = user
        nextState.draftName = user.name
    case .nameChanged(let name):
        nextState.draftName = name
    case .saveTapped:
        nextState.isSaving = true
    case .saved(let user):
        nextState.user = user
        nextState.draftName = user.name
        nextState.isSaving = false
    case .failed(let msg):
        nextState.isSaving = false
        nextState.errorMessage = msg
    case .dismissed:
        return nil
    }
    return nextState
}
