import Foundation
import ReSwift

public func appReducer(action: Action, state: AppState?) -> AppState {
    var nextState = state ?? AppState()
    guard let app = action as? AppAction else { return nextState }
    switch app {
    case .userList(let listAction):
        nextState.userList = userListReducer(action: listAction, state: nextState.userList)
    case .userDetail(let detailAction):
        nextState.userDetail = userDetailReducer(action: detailAction, state: nextState.userDetail)
    }
    return nextState
}
