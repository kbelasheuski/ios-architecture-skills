import Foundation

public func userListReducer(action: UserListAction, state: UserListState) -> UserListState {
    var s = state
    switch action {
    case .load:
        break
    case .loadStarted(let kind, let requestID):
        s.activeRequestID = requestID
        s.errorMessage = nil
        switch kind {
        case .fullScreen:
            s.loading = .fullScreen
            s.users = []
            s.page = 0
        case .nextPage:
            s.loading = .nextPage
        }
    case .loaded(let page, let requestID):
        guard s.activeRequestID == requestID else { return s }
        s.loading = .none
        s.activeRequestID = nil
        s.users.append(contentsOf: page.users)
        s.page = page.page
        s.totalPages = page.totalPages
    case .failed(let msg, let requestID):
        guard s.activeRequestID == requestID else { return s }
        s.loading = .none
        s.activeRequestID = nil
        s.errorMessage = msg
    case .errorDismissed:
        s.errorMessage = nil
    case .selected:
        break       // navigation handled outside the reducer
    }
    return s
}
