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
        try? await Task.sleep(for: .milliseconds(50))
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
        try? await Task.sleep(for: .milliseconds(50))

        // Simulate willDisplay at row near end.
        sut.tableView(sut.tableView,
                      willDisplay: UITableViewCell(),
                      forRowAt: IndexPath(row: 8, section: 0))
        try? await Task.sleep(for: .milliseconds(50))

        XCTAssertEqual(repo.fetchPageCalls, [1, 2])
        XCTAssertEqual(sut.users.count, 11)
    }
}
