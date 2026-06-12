import Foundation

public func userDetailReducer(action: UserDetailAction, state: UserDetailState?) -> UserDetailState? {
    var s = state ?? UserDetailState()
    switch action {
    case .load:
        s = .init()
    case .loaded(let u):
        s.user = u
        s.draftName = u.name
    case .nameChanged(let n):
        s.draftName = n
    case .saveTapped:
        s.isSaving = true
    case .saved(let u):
        s.user = u
        s.draftName = u.name
        s.isSaving = false
    case .failed(let msg):
        s.isSaving = false
        s.errorMessage = msg
    case .dismissed:
        return nil
    }
    return s
}
