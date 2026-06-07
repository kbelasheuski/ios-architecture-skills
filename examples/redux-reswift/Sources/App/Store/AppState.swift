import Foundation
import ReSwift

public struct AppState: Equatable {
    public var userList: UserListState = .init()
    public var userDetail: UserDetailState?

    public init() {}
}
