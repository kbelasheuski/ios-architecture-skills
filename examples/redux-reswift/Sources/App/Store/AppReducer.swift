import Foundation
import ReSwift

public func appReducer(action: Action, state: AppState?) -> AppState {
    var s = state ?? AppState()
    guard let app = action as? AppAction else { return s }
    switch app {
    case .userList(let a):
        s.userList = userListReducer(action: a, state: s.userList)
    case .userDetail(let a):
        s.userDetail = userDetailReducer(action: a, state: s.userDetail)
    }
    return s
}
