---
name: arch-mvvm-uikit
description: MVVM for UIKit using Combine. ViewModel exposes @Published outputs + command methods; ViewController binds via Combine sinks. Use for medium UIKit codebases comfortable with Combine.
---

# MVVM (UIKit, Combine)

**Source references:**
- Antoine van der Lee, *MVVM in UIKit* — https://www.avanderlee.com/swiftui/mvvm-architectural-coding-pattern-to-structure-views/
- Apple, *Combine* — https://developer.apple.com/documentation/combine

## When to use

- UIKit codebase, team comfortable with Combine.
- Mid-size apps likely to migrate to SwiftUI later (VM is portable).

## Folder structure

```
Features/
  UserList/
    UserListViewController.swift
    UserListViewModel.swift
  UserDetail/
    UserDetailViewController.swift
    UserDetailViewModel.swift
Domain/  Data/
```

## Reference implementation — full feature

```swift
// Features/UserList/UserListViewModel.swift
import Combine
import Foundation

@MainActor
public final class UserListViewModel {

    public enum Loading: Equatable { case none, fullScreen, nextPage }

    // Outputs
    @Published public private(set) var users: [User] = []
    @Published public private(set) var loading: Loading = .none
    @Published public var errorMessage: String?

    // Events (Coordinator/parent listens)
    public let userSelected = PassthroughSubject<User.ID, Never>()

    private let repository: UserRepository
    private var page = 0
    private var totalPages = 1
    private var loadTask: Task<Void, Never>? { willSet { loadTask?.cancel() } }
    private var hasMore: Bool { page < totalPages }

    public init(repository: UserRepository) { self.repository = repository }

    public func onAppear() {
        guard users.isEmpty else { return }
        load(loading: .fullScreen, reset: true)
    }

    public func refresh() { load(loading: .fullScreen, reset: true) }

    public func didDisplayRow(at index: Int) {
        guard hasMore, loading == .none, index >= max(users.count - 3, 0) else { return }
        load(loading: .nextPage, reset: false)
    }

    public func didSelectRow(at index: Int) {
        guard users.indices.contains(index) else { return }
        userSelected.send(users[index].id)
    }

    public func dismissError() { errorMessage = nil }

    private func load(loading: Loading, reset: Bool) {
        self.loading = loading
        loadTask = Task { [weak self] in
            guard let self else { return }
            do {
                let target = reset ? 1 : self.page + 1
                let result = try await repository.fetchUsers(page: target)
                try Task.checkCancellation()
                if reset { users = result.users } else { users.append(contentsOf: result.users) }
                page = result.page
                totalPages = result.totalPages
            } catch is CancellationError {
                // swallow
            } catch {
                errorMessage = error.localizedDescription
            }
            self.loading = .none
        }
    }
}

// Features/UserList/UserListViewController.swift
import Combine
import UIKit

public final class UserListViewController: UITableViewController {
    private let viewModel: UserListViewModel
    private var cancellables: Set<AnyCancellable> = []

    public init(viewModel: UserListViewModel) {
        self.viewModel = viewModel
        super.init(style: .plain)
    }
    required init?(coder: NSCoder) { fatalError() }

    public override func viewDidLoad() {
        super.viewDidLoad()
        title = "Users"
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(onPull), for: .valueChanged)
        bind()
        viewModel.onAppear()
    }

    private func bind() {
        viewModel.$users
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.tableView.reloadData() }
            .store(in: &cancellables)
        viewModel.$loading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] l in if l == .none { self?.refreshControl?.endRefreshing() } }
            .store(in: &cancellables)
        viewModel.$errorMessage
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] msg in self?.presentError(msg) }
            .store(in: &cancellables)
    }

    private func presentError(_ msg: String) {
        let a = UIAlertController(title: "Error", message: msg, preferredStyle: .alert)
        a.addAction(.init(title: "OK", style: .default) { [weak self] _ in self?.viewModel.dismissError() })
        present(a, animated: true)
    }

    @objc private func onPull() { viewModel.refresh() }

    public override func tableView(_ tv: UITableView, numberOfRowsInSection s: Int) -> Int { viewModel.users.count }
    public override func tableView(_ tv: UITableView, cellForRowAt ip: IndexPath) -> UITableViewCell {
        let cell = tv.dequeueReusableCell(withIdentifier: "cell", for: ip)
        var c = cell.defaultContentConfiguration()
        c.text = viewModel.users[ip.row].name
        c.secondaryText = viewModel.users[ip.row].email
        cell.contentConfiguration = c
        return cell
    }
    public override func tableView(_ tv: UITableView, didSelectRowAt ip: IndexPath) {
        tv.deselectRow(at: ip, animated: true)
        viewModel.didSelectRow(at: ip.row)
    }
    public override func tableView(_ tv: UITableView, willDisplay cell: UITableViewCell, forRowAt ip: IndexPath) {
        viewModel.didDisplayRow(at: ip.row)
    }
}

// Features/UserDetail/UserDetailViewModel.swift
@MainActor
public final class UserDetailViewModel {
    @Published public private(set) var user: User?
    @Published public var draftName: String = ""
    @Published public private(set) var isSaving = false
    @Published public var errorMessage: String?
    public let didSave = PassthroughSubject<User, Never>()

    public var isDirty: Bool { user?.name != draftName }
    public var canSave: Bool { isDirty && !draftName.isEmpty && !isSaving }

    private let repository: UserRepository
    private let id: User.ID

    public init(repository: UserRepository, id: User.ID) {
        self.repository = repository; self.id = id
    }

    public func onAppear() {
        guard user == nil else { return }
        Task { [weak self] in
            guard let self else { return }
            do {
                let u = try await repository.fetchUser(id: id)
                user = u; draftName = u.name
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    public func save() {
        guard var u = user, canSave else { return }
        u.name = draftName
        isSaving = true
        Task { [weak self] in
            guard let self else { return }
            do {
                let saved = try await repository.update(u)
                user = saved; draftName = saved.name
                didSave.send(saved)
            } catch {
                errorMessage = error.localizedDescription
            }
            isSaving = false
        }
    }
}

// Features/UserDetail/UserDetailViewController.swift — see arch-mvvm-c (same shape)
```

(See `arch-mvvm-c` for `UserDetailViewController` and Coordinator integration — they're identical.)

### Tests

```swift
@MainActor
final class UserListViewModelTests: XCTestCase {
    func test_onAppear_loadsAndPublishesUsers() async {
        let repo = FakeUserRepository(pages: [.fixture(users: [.fixture(name: "Ada")])])
        let sut = UserListViewModel(repository: repo)
        sut.onAppear()
        await waitFor(sut.$users, count: 2)   // initial empty + populated
        XCTAssertEqual(sut.users.map(\.name), ["Ada"])
    }
    func test_selectRow_emitsUserSelected() async {
        let id = UUID()
        let repo = FakeUserRepository(pages: [.fixture(users: [.fixture(id: id)])])
        let sut = UserListViewModel(repository: repo)
        sut.onAppear()
        await waitFor(sut.$users, count: 2)
        var received: User.ID?
        let token = sut.userSelected.sink { received = $0 }
        sut.didSelectRow(at: 0)
        token.cancel()
        XCTAssertEqual(received, id)
    }
}
```

`waitFor` helper:
```swift
func waitFor<T>(_ p: Published<T>.Publisher, count: Int, timeout: TimeInterval = 1) async {
    var seen = 0
    let cancellable = p.sink { _ in seen += 1 }
    let start = Date()
    while seen < count, Date().timeIntervalSince(start) < timeout {
        await Task.yield()
    }
    cancellable.cancel()
}
```

## Pros / cons

**Pros**: VM is UIKit-import-free, testable, portable to SwiftUI.
**Cons**: Combine learning curve; navigation needs Coordinator; risk of fat VMs.

## Corner cases

- Cancel previous load task on every new `load` via `willSet { cancel() }`.
- `[weak self]` in every Task and Sink.
- `@MainActor` on VM eliminates `receive(on:)` requirement when VM is the publisher.
- Use `PassthroughSubject` for one-shot events (selection, save); use `@Published` for state.

## Anti-patterns

- VM importing UIKit.
- Combine pipelines built inside `cellForRowAt`.
- Replacing `[User]` whole-array on each page (use diffable data source for diff-based updates).

## Migration hand-off

- To MVVM-C: introduce Coordinator that subscribes to `userSelected`/`didSave`.
- To MVVM-SwiftUI: rewrite VC as `View`, swap `@Published` for `@Observable`.
- To TCA: P9 — VM → Reducer, `@Published` → `State`, methods → `Action`, async → `Effect`.

## Failure modes

- ViewModel imports UIKit and becomes a controller by another name.
- Combine subscriptions are created in cells or reused without cancellation.
- One-shot events are modeled as sticky `@Published` state.
- Navigation stays in the ViewController and cannot be tested.

## Review checklist

- Are outputs `@Published` state and one-shot events separated?
- Is the ViewModel `@MainActor` or otherwise main-thread safe?
- Are cancellables owned by the lifecycle that created them?
- Can the ViewModel be tested without UIKit?
- Is navigation ready to move into a Coordinator?
