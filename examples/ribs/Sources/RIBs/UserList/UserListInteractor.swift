import RIBs
import RxSwift
import Foundation

public protocol UserListListener: AnyObject {
    func userListDidFinish()
}

public protocol UserListRouting: ViewableRouting {
    func routeToDetail(userID: User.ID)
    func detachDetail()
}

public protocol UserListPresentable: Presentable {
    var listener: UserListPresentableListener? { get set }
    func display(rows: [UserListRow])
    func display(loading: UserListLoading)
    func displayError(_ message: String)
}

public protocol UserListPresentableListener: AnyObject {
    func didDisplayRow(at index: Int)
    func didSelectRow(at index: Int)
    func refresh()
}

public struct UserListRow: Equatable {
    public let id: User.ID
    public let title: String
    public let subtitle: String
}

public enum UserListLoading: Equatable { case none, fullScreen, nextPage }

public final class UserListInteractor:
    PresentableInteractor<UserListPresentable>,
    UserListInteractable,
    UserListPresentableListener {
    public weak var router: UserListRouting?
    public weak var listener: UserListListener?

    private let repository: UserRepository
    private var users: [User] = []
    private var page = 0
    private var totalPages = 1
    private var hasMore: Bool { page < totalPages }
    private var loading: UserListLoading = .none
    private let disposeBag = DisposeBag()

    public init(presenter: UserListPresentable, repository: UserRepository) {
        self.repository = repository
        super.init(presenter: presenter)
        presenter.listener = self
    }

    public override func didBecomeActive() {
        super.didBecomeActive()
        load(reset: true)
    }

    public func refresh() { load(reset: true) }

    public func didDisplayRow(at index: Int) {
        guard hasMore, loading == .none, index >= max(users.count - 3, 0) else { return }
        load(reset: false)
    }

    public func didSelectRow(at index: Int) {
        guard users.indices.contains(index) else { return }
        router?.routeToDetail(userID: users[index].id)
    }

    private func load(reset: Bool) {
        loading = reset ? .fullScreen : .nextPage
        presenter.display(loading: loading)
        let target = reset ? 1 : page + 1
        Single.fromAsync { [repository] in
            try await repository.fetchUsers(page: target)
        }
        .observe(on: MainScheduler.instance)
        .subscribe(
            onSuccess: { [weak self] page in
                guard let self else { return }
                if reset { self.users = [] }
                self.users.append(contentsOf: page.users)
                self.page = page.page
                self.totalPages = page.totalPages
                self.loading = .none
                self.presenter.display(rows: self.users.map {
                    .init(id: $0.id, title: $0.name, subtitle: $0.email)
                })
                self.presenter.display(loading: .none)
            },
            onFailure: { [weak self] error in
                self?.loading = .none
                self?.presenter.display(loading: .none)
                self?.presenter.displayError(error.localizedDescription)
            }
        )
        .disposed(by: disposeBag)
    }
}

extension UserListInteractor: UserDetailListener {
    public func userDetailDidFinish() { router?.detachDetail() }
}

// async/await ↔ Rx bridge
extension Single where Element: Sendable {
    static func fromAsync(_ op: @escaping @Sendable () async throws -> Element) -> Single<Element> {
        Single.create { observer in
            let task = Task {
                do { observer(.success(try await op())) } catch { observer(.failure(error)) }
            }
            return Disposables.create { task.cancel() }
        }
    }
}
