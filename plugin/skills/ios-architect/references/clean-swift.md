# Clean Swift (VIP)

**Source references:**
- Raymond Law, *Clean Swift* — https://clean-swift.com/
- Essential Developer, *Clean Swift design pattern review* — https://www.essentialdeveloper.com/articles/clean-ios-architecture-part-7-vip-clean-swift-design-pattern-or-architecture/

## When to use

- TDD-committed UIKit teams.
- Long-lived codebases where data shape per layer is auditable.
- Reject for SwiftUI-first.

## Decision examples

- Use this for UIKit teams that want VIP request/response/view-model boundaries and TDD-friendly scenes.
- Reject it for SwiftUI-first apps unless the team already knows Clean Swift.
- First safe slice: introduce Request, Response, and ViewModel structs for one scene action.

## Folder structure

```
Scenes/
  UserList/
    UserListModels.swift
    UserListViewController.swift
    UserListInteractor.swift
    UserListPresenter.swift
    UserListRouter.swift
    UserListWorker.swift
    UserListConfigurator.swift
  UserDetail/
    ... (same seven files)
```

## Source-backed proof


| Source | Claim checked | Local proof |
| --- | --- | --- |
| https://clean-swift.com/ | The VIP request/response/view-model cycle is the reason this example separates interactor, presenter, worker, and models. | `examples/clean-swift/` |

## Reference implementation — full feature

```swift
// Scenes/UserList/UserListModels.swift
import Foundation

enum UserList {
    enum FetchUsers {
        struct Request: Equatable { let reset: Bool }
        struct Response: Equatable {
            let users: [User]
            let loading: ViewModel.Loading
            let errorMessage: String?
        }
        struct ViewModel: Equatable {
            struct Row: Equatable { let id: User.ID; let title: String; let subtitle: String }
            enum Loading { case none, fullScreen, nextPage }
            let rows: [Row]
            let loading: Loading
            let errorMessage: String?
        }
    }
    enum SelectRow {
        struct Request { let index: Int }
    }
}

// Scenes/UserList/UserListWorker.swift
final class UserListWorker {
    private let repository: UserRepository
    init(repository: UserRepository) { self.repository = repository }
    func fetchUsers(page: Int) async throws -> UsersPage { try await repository.fetchUsers(page: page) }
}

// Scenes/UserList/UserListInteractor.swift
protocol UserListBusinessLogic: AnyObject {
    func fetchUsers(_ request: UserList.FetchUsers.Request) async
    func selectRow(_ request: UserList.SelectRow.Request)
}
protocol UserListDataStore: AnyObject {
    var users: [User] { get }
    var selectedUserID: User.ID? { get }
}

final class UserListInteractor: UserListBusinessLogic, UserListDataStore {
    var presenter: UserListPresentationLogic!
    private let worker: UserListWorker

    private(set) var users: [User] = []
    private(set) var selectedUserID: User.ID?
    private var page = 0
    private var totalPages = 1
    private var hasMore: Bool { page < totalPages }
    private var isLoading = false

    init(worker: UserListWorker) { self.worker = worker }

    func fetchUsers(_ request: UserList.FetchUsers.Request) async {
        guard !isLoading else { return }
        guard request.reset || hasMore else { return }
        isLoading = true
        defer { isLoading = false }

        await presenter.present(.init(users: users,
                                      loading: request.reset ? .fullScreen : .nextPage,
                                      errorMessage: nil))
        do {
            let target = request.reset ? 1 : page + 1
            let next = try await worker.fetchUsers(page: target)
            if request.reset { users = []; page = 0 }
            users.append(contentsOf: next.users)
            page = next.page
            totalPages = next.totalPages
            await presenter.present(.init(users: users, loading: .none, errorMessage: nil))
        } catch {
            await presenter.present(.init(users: users, loading: .none, errorMessage: error.localizedDescription))
        }
    }

    func selectRow(_ request: UserList.SelectRow.Request) {
        guard users.indices.contains(request.index) else { return }
        selectedUserID = users[request.index].id
    }
}

// Scenes/UserList/UserListPresenter.swift
protocol UserListPresentationLogic: AnyObject {
    func present(_ response: UserList.FetchUsers.Response) async
}

@MainActor
final class UserListPresenter: UserListPresentationLogic {
    weak var view: UserListDisplayLogic?

    func present(_ response: UserList.FetchUsers.Response) async {
        let rows = response.users.map {
            UserList.FetchUsers.ViewModel.Row(id: $0.id, title: $0.name, subtitle: $0.email)
        }
        view?.display(.init(rows: rows, loading: response.loading, errorMessage: response.errorMessage))
    }
}

// Scenes/UserList/UserListViewController.swift
import UIKit

protocol UserListDisplayLogic: AnyObject {
    func display(_ viewModel: UserList.FetchUsers.ViewModel)
}

final class UserListViewController: UITableViewController, UserListDisplayLogic {
    var interactor: UserListBusinessLogic!
    var router: (UserListRoutingLogic & UserListDataPassing)!
    private var rows: [UserList.FetchUsers.ViewModel.Row] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Users"
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(onPull), for: .valueChanged)
        Task { await interactor.fetchUsers(.init(reset: true)) }
    }
    @objc private func onPull() {
        Task { await interactor.fetchUsers(.init(reset: true)) }
    }

    func display(_ vm: UserList.FetchUsers.ViewModel) {
        rows = vm.rows
        tableView.reloadData()
        if vm.loading == .none { refreshControl?.endRefreshing() }
        if let msg = vm.errorMessage {
            let a = UIAlertController(title: "Error", message: msg, preferredStyle: .alert)
            a.addAction(.init(title: "OK", style: .default))
            present(a, animated: true)
        }
    }

    override func tableView(_ tv: UITableView, numberOfRowsInSection s: Int) -> Int { rows.count }
    override func tableView(_ tv: UITableView, cellForRowAt ip: IndexPath) -> UITableViewCell {
        let cell = tv.dequeueReusableCell(withIdentifier: "cell", for: ip)
        var c = cell.defaultContentConfiguration()
        c.text = rows[ip.row].title; c.secondaryText = rows[ip.row].subtitle
        cell.contentConfiguration = c
        return cell
    }
    override func tableView(_ tv: UITableView, didSelectRowAt ip: IndexPath) {
        tv.deselectRow(at: ip, animated: true)
        interactor.selectRow(.init(index: ip.row))
        router.routeToDetail()
    }
    override func tableView(_ tv: UITableView, willDisplay cell: UITableViewCell, forRowAt ip: IndexPath) {
        if ip.row >= rows.count - 3 {
            Task { await interactor.fetchUsers(.init(reset: false)) }
        }
    }
}

// Scenes/UserList/UserListRouter.swift
protocol UserListRoutingLogic { func routeToDetail() }
protocol UserListDataPassing { var dataStore: UserListDataStore? { get } }

@MainActor
final class UserListRouter: UserListRoutingLogic, UserListDataPassing {
    weak var viewController: UserListViewController?
    weak var dataStore: UserListDataStore?

    func routeToDetail() {
        guard let id = dataStore?.selectedUserID else { return }
        let vc = UserDetailConfigurator.make(userID: id)
        viewController?.navigationController?.pushViewController(vc, animated: true)
    }
}

// Scenes/UserList/UserListConfigurator.swift
@MainActor
enum UserListConfigurator {
    static func make(repository: UserRepository) -> UserListViewController {
        let vc = UserListViewController()
        let interactor = UserListInteractor(worker: UserListWorker(repository: repository))
        let presenter = UserListPresenter()
        let router = UserListRouter()

        vc.interactor = interactor
        vc.router = router
        interactor.presenter = presenter
        presenter.view = vc
        router.viewController = vc
        router.dataStore = interactor

        return vc
    }
}
```

`UserDetail` mirrors the same seven-file layout. `UserDetail.Save.Request/Response/ViewModel` describe the save flow; Worker wraps `repository.update`. (Omitted for brevity — apply the same scaffolding.)

### Tests

```swift
@MainActor
final class UserListInteractorTests: XCTestCase {
    func test_fetchUsers_emitsLoadingThenUsers() async throws {
        let presenter = SpyPresenter()
        let worker = UserListWorker(repository: FakeUserRepository(pages: [.fixture(users: [.fixture(name: "Ada")])]))
        let sut = UserListInteractor(worker: worker)
        sut.presenter = presenter
        await sut.fetchUsers(.init(reset: true))
        XCTAssertEqual(presenter.received.count, 2)   // .fullScreen loading, then loaded
        let last = try XCTUnwrap(presenter.received.last)
        XCTAssertEqual(last.loading, .none)
        XCTAssertEqual(last.users.first?.name, "Ada")
    }

    func test_refresh_doesNotDuplicateRows() async {
        let presenter = SpyPresenter()
        let worker = UserListWorker(repository: FakeUserRepository(pages: [.fixture(users: [.fixture(name: "Ada"), .fixture(name: "Grace")])]))
        let sut = UserListInteractor(worker: worker)
        sut.presenter = presenter
        await sut.fetchUsers(.init(reset: true))
        await sut.fetchUsers(.init(reset: true))
        XCTAssertEqual(sut.users.count, 2)
        XCTAssertEqual(presenter.received.last?.users.count, 2)
    }
}

@MainActor final class SpyPresenter: UserListPresentationLogic {
    var received: [UserList.FetchUsers.Response] = []
    func present(_ r: UserList.FetchUsers.Response) async { received.append(r) }
}
```


## Testing strategy

- Test Interactors with Worker spies/fakes and assert Request -> Response decisions.
- Cover Worker failure responses and verify the Presenter maps errors into user-safe ViewModels.
- Test Presenters as pure formatting units: Response in, ViewModel out.
- Keep ViewController tests focused on wiring actions to Interactor requests.

## Concrete test matrix


| Scenario | Assertion | Test seam |
| --- | --- | --- |
| Initial list load | Assert Interactor creates the response and Presenter creates the display view model. | Worker fake plus presenter spy |
| Repository failure | Assert failure response is presented through the VIP error path. | Presenter spy error assertion |
| User tap | Assert routing data passes through the scene router without presenter navigation logic. | Router spy |
| Detail save | Assert Worker update result flows through Response to ViewModel. | Worker fake update assertion |

## Concurrency and cancellation

- Workers own async repository/network calls; Interactors coordinate cancellation and business decisions.
- Presenters and ViewControllers publish UI-facing results on the main actor.
- Keep request identity explicit so late worker responses cannot overwrite a newer refresh or save.

## Pros / cons

**Pros**: Strict unidirectional V→I→P→V; great TDD fit; templates generate boilerplate; per-boundary models make contracts explicit.
**Cons**: Triples type count; Router is bolted on; cognitive load comparable to VIPER.

## Corner cases

- `DataStore` exposes Interactor state to the Router without coupling to UI.
- `Worker` is the only async network surface — Interactor awaits Worker, never `repository` directly (lets you swap Workers in tests).
- **Presenter is stateless.** The Interactor owns `users`; the `Response` carries the full current snapshot, so the Presenter re-maps the whole list each call. A Presenter that accumulates rows in its own cache duplicates them on refresh (Interactor resets, Presenter does not).
- Interactor presents `.fullScreen` / `.nextPage` loading *before* awaiting the Worker, then the loaded snapshot with `.none` — otherwise the loading state is dead and never reaches the View.
- Presenter is `@MainActor` because it touches `view?.display(...)`.
- Configurator wires everything in one place — never let Interactor construct Worker via a global.

## Anti-patterns

- Presenter holding `User` model.
- View calling Presenter directly.
- Skipping Request/Response and passing primitives.
- Importing `UIKit` outside the View layer.

## Migration hand-off

- To MVVM-UIKit: collapse Interactor + Presenter → ViewModel; drop Request/Response/ViewModel structs; map Worker to a repository property.
- To Clean Architecture: promote Worker → Use Case; Interactor's rules → Domain.
- To TCA: Interactor + Presenter → Reducer; Router → `StackState` Path reducer.

## Failure modes

- Presenter accumulates state and duplicates Interactor state.
- Request/Response/ViewModel structs become pass-through noise.
- Worker owns business rules that belong in the Interactor or Domain.
- Router and DataStore are not wired, so navigation needs view hacks.

## Review checklist

- Does the View talk only to the Interactor?
- Does the Presenter format data without storing domain state?
- Are Worker calls async-safe and failure-aware?
- Are Request/Response/ViewModel types useful contracts?
- Is routing data exposed through DataStore, not the View?
