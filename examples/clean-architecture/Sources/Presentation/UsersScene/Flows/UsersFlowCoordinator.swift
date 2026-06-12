import Foundation
import Observation

public enum UsersRoute: Hashable {
    case userDetail(User.ID)
}

@Observable
@MainActor
public final class UsersFlowCoordinator {
    public var path: [UsersRoute] = []
    public init() {}

    public func showDetail(for user: User) {
        path.append(.userDetail(user.id))
    }

    @discardableResult
    public func pop() -> UsersRoute? {
        path.popLast()
    }
}
