import Foundation

public func userListReducer(action: UserListAction, state: UserListState) -> UserListState {
    var nextState = state
    switch action {
    case .load(.fullScreen):
        nextState.loading = .fullScreen
        nextState.users = []
        nextState.page = 0
    case .load(.nextPage):
        nextState.loading = .nextPage
    case .loaded(let page):
        nextState.loading = .none
        nextState.users.append(contentsOf: page.users)
        nextState.page = page.page
        nextState.totalPages = page.totalPages
    case .failed(let msg):
        nextState.loading = .none
        nextState.errorMessage = msg
    case .errorDismissed:
        nextState.errorMessage = nil
    case .selected:
        break       // navigation handled outside the reducer
    }
    return nextState
}
