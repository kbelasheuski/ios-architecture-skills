import Foundation

@MainActor
public protocol UserListBusinessLogic: AnyObject {
    func fetchUsers(_ request: UserList.FetchUsers.Request) async
    func selectRow(_ request: UserList.SelectRow.Request)
}

@MainActor
public protocol UserListDataStore: AnyObject {
    var users: [User] { get }
    var selectedUserID: User.ID? { get }
}

@MainActor
public final class UserListInteractor: UserListBusinessLogic, UserListDataStore {

    public var presenter: UserListPresentationLogic!
    private let worker: UserListWorker

    public private(set) var users: [User] = []
    public private(set) var selectedUserID: User.ID?
    private var page = 0
    private var totalPages = 1
    private var hasMore: Bool { page < totalPages }
    private var isLoading = false

    public init(worker: UserListWorker) {
        self.worker = worker
    }

    public func fetchUsers(_ request: UserList.FetchUsers.Request) async {
        guard !isLoading else { return }
        guard request.reset || hasMore else { return }
        isLoading = true
        defer { isLoading = false }

        await presenter.present(.init(
            users: users,
            loading: request.reset ? .fullScreen : .nextPage,
            errorMessage: nil
        ))

        do {
            let target = request.reset ? 1 : page + 1
            let result = try await worker.fetchUsers(page: target)
            if request.reset {
                users = []
                page = 0
            }
            users.append(contentsOf: result.users)
            page = result.page
            totalPages = result.totalPages
            await presenter.present(.init(users: users, loading: .none, errorMessage: nil))
        } catch {
            await presenter.present(.init(
                users: users,
                loading: .none,
                errorMessage: error.localizedDescription
            ))
        }
    }

    public func selectRow(_ request: UserList.SelectRow.Request) {
        guard users.indices.contains(request.index) else { return }
        selectedUserID = users[request.index].id
    }
}
