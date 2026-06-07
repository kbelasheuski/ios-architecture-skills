import Foundation
import ReSwift

public enum UserListAction: Action, Equatable {
    case load(Loading)
    case loaded(UsersPage)
    case failed(String)
    case selected(User.ID)
    case errorDismissed

    public enum Loading: Equatable { case fullScreen, nextPage }
}
