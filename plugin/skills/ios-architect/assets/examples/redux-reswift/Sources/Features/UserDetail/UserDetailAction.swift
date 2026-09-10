import Foundation
import ReSwift

public enum UserDetailAction: Action, Equatable {
    case load(User.ID)
    case loaded(User)
    case nameChanged(String)
    case saveTapped
    case saved(User)
    case failed(String)
    case dismissed
}
