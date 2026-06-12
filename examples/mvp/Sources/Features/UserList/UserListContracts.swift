import Foundation

public struct UserListRowViewModel: Equatable {
    public let id: User.ID
    public let title: String
    public let subtitle: String
}

public enum UserListLoading: Equatable {
    case none, fullScreen, nextPage
}

@MainActor
public protocol UserListView: AnyObject {
    func display(rows: [UserListRowViewModel])
    func displayLoading(_ loading: UserListLoading)
    func displayError(message: String)
}

@MainActor
public protocol UserListPresenting {
    func viewDidLoad() async
    func refresh() async
    func didDisplayRow(at index: Int)
    func didSelectRow(at index: Int)
}

@MainActor
public protocol UserNavigating: AnyObject {
    func showDetail(for id: User.ID)
}
