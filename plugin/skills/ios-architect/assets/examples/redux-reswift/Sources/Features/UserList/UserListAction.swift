import Foundation
import ReSwift

public enum UserListAction: Action, Equatable {
    case load(Loading)
    case loadStarted(Loading, requestID: UUID)
    case loaded(UsersPage, requestID: UUID)
    case failed(String, requestID: UUID)
    case selected(User.ID)
    case errorDismissed

    public enum Loading: Equatable { case fullScreen, nextPage }
}
