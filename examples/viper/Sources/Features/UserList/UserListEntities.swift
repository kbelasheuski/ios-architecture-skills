import Foundation

public struct UserListRowEntity: Equatable {
    public let id: User.ID
    public let title: String
    public let subtitle: String
}

public enum UserListLoading: Equatable {
    case none, fullScreen, nextPage
}
