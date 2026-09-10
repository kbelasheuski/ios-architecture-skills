import XCTest
@testable import MVCExample

@MainActor
final class UserListViewControllerTests: XCTestCase {

    func test_viewDidLoad_loadsFirstPage() async {
        let repo = FakeUserRepository(pages: [
            .fixture(users: [.fixture(name: "Ada"), .fixture(name: "Grace")],
                     page: 1, totalPages: 1)
        ])
        let sut = UserListViewController(repository: repo)
        _ = sut.view                           // force lifecycle
        await sut.awaitCurrentLoadForTesting()
        XCTAssertEqual(sut.users.map(\.name), ["Ada", "Grace"])
        XCTAssertEqual(repo.fetchPageCalls, [1])
    }

    func test_pagination_triggersNextPage() async {
        let page1 = UsersPage.fixture(users: (0..<10).map { .fixture(name: "U\($0)") },
                                      page: 1, totalPages: 2)
        let page2 = UsersPage.fixture(users: [.fixture(name: "U10")], page: 2, totalPages: 2)
        let repo = FakeUserRepository(pages: [page1, page2])
        let sut = UserListViewController(repository: repo)
        _ = sut.view
        await sut.awaitCurrentLoadForTesting()

        // Simulate willDisplay at row near end.
        sut.tableView(sut.tableView,
                      willDisplay: UITableViewCell(),
                      forRowAt: IndexPath(row: 8, section: 0))
        await sut.awaitCurrentLoadForTesting()

        XCTAssertEqual(repo.fetchPageCalls, [1, 2])
        XCTAssertEqual(sut.users.count, 11)
    }

    func test_pagination_ignoresRepeatedTriggersWhileLoading() async {
        let page1 = UsersPage.fixture(users: (0..<10).map { .fixture(name: "U\($0)") },
                                      page: 1, totalPages: 2)
        let page2 = UsersPage.fixture(users: [.fixture(name: "U10")], page: 2, totalPages: 2)
        let repo = FakeUserRepository(pages: [page1, page2])
        let page2Started = AsyncSignal()
        var resumePage2: CheckedContinuation<UsersPage, Error>?
        repo.fetchUsersHandler = { page in
            if page == 2 {
                page2Started.signal()
                return try await withCheckedThrowingContinuation { continuation in
                    resumePage2 = continuation
                }
            }
            return page1
        }

        let sut = UserListViewController(repository: repo)
        _ = sut.view
        await sut.awaitCurrentLoadForTesting()

        sut.tableView(sut.tableView,
                      willDisplay: UITableViewCell(),
                      forRowAt: IndexPath(row: 8, section: 0))
        sut.tableView(sut.tableView,
                      willDisplay: UITableViewCell(),
                      forRowAt: IndexPath(row: 8, section: 0))
        await page2Started.wait()

        XCTAssertEqual(repo.fetchPageCalls, [1, 2])

        resumePage2?.resume(returning: page2)
        await sut.awaitCurrentLoadForTesting()

        XCTAssertEqual(sut.users.count, 11)
        XCTAssertEqual(sut.page, 2)
    }
}

private final class AsyncSignal: @unchecked Sendable {
    private var continuation: CheckedContinuation<Void, Never>?
    private var signaled = false

    func wait() async {
        if signaled { return }
        await withCheckedContinuation { continuation = $0 }
    }

    func signal() {
        signaled = true
        continuation?.resume()
        continuation = nil
    }
}
