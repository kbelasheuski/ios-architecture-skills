import Foundation
import ReSwift

public enum AppAction: Action {
    case userList(UserListAction)
    case userDetail(UserDetailAction)
}
