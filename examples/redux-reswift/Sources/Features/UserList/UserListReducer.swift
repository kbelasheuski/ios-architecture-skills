import Foundation

public func userListReducer(action: UserListAction, state: UserListState) -> UserListState {
    var s = state
    switch action {
    case .load(.fullScreen):
        s.loading = .fullScreen
        s.users = []
        s.page = 0
    case .load(.nextPage):
        s.loading = .nextPage
    case .loaded(let page):
        s.loading = .none
        s.users.append(contentsOf: page.users)
        s.page = page.page
        s.totalPages = page.totalPages
    case .failed(let msg):
        s.loading = .none
        s.errorMessage = msg
    case .errorDismissed:
        s.errorMessage = nil
    case .selected:
        break       // navigation handled outside the reducer
    }
    return s
}
