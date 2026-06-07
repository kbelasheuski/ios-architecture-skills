import Foundation

@MainActor
public final class UserListPresenter: UserListPresenterProtocol {

    public weak var view: UserListViewProtocol?
    private let interactor: UserListInteractorProtocol
    private let router: UserListRouterProtocol

    private var users: [User] = []
    private var page = 0
    private var totalPages = 1
    private var loading: UserListLoading = .none
    private var loadTask: Task<Void, Never>? {
        willSet { loadTask?.cancel() }
    }
    private var hasMore: Bool { page < totalPages }

    public init(
        view: UserListViewProtocol,
        interactor: UserListInteractorProtocol,
        router: UserListRouterProtocol
    ) {
        self.view = view
        self.interactor = interactor
        self.router = router
    }

    public func viewDidLoad() async {
        guard users.isEmpty else { return }
        await load(loading: .fullScreen, reset: true)
    }

    public func refresh() async {
        await load(loading: .fullScreen, reset: true)
    }

    public func didDisplayRow(at index: Int) {
        guard hasMore, loading == .none, index >= max(users.count - 3, 0) else { return }
        loadTask = Task { await self.load(loading: .nextPage, reset: false) }
    }

    public func didSelectRow(at index: Int) {
        guard users.indices.contains(index) else { return }
        router.showDetail(for: users[index].id)
    }

    private func load(loading: UserListLoading, reset: Bool) async {
        self.loading = loading
        view?.displayLoading(loading)
        do {
            let target = reset ? 1 : page + 1
            let result = try await interactor.fetchUsers(page: target)
            try Task.checkCancellation()
            if reset { users = result.users } else { users.append(contentsOf: result.users) }
            page = result.page
            totalPages = result.totalPages
            view?.display(rows: users.map {
                .init(id: $0.id, title: $0.name, subtitle: $0.email)
            })
        } catch is CancellationError {
            // swallow
        } catch {
            view?.displayError(message: error.localizedDescription)
        }
        self.loading = .none
        view?.displayLoading(.none)
    }
}
