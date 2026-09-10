import XCTest
@testable import MVPExample

@MainActor
final class UserListPresenterTests: XCTestCase {

    func test_viewDidLoad_displaysRows_andStopsLoading() async {
        let view = MockUserListView()
        let repo = FakeUserRepository(pages: [.fixture(users: [.fixture(name: "Ada")])])
        let navigator = SpyNavigator()
        let sut = UserListPresenter(view: view, repository: repo, navigator: navigator)

        await sut.viewDidLoad()

        XCTAssertEqual(view.displayed.first?.title, "Ada")
        XCTAssertEqual(view.loadingHistory, [.fullScreen, .none])
        XCTAssertNil(view.lastError)
    }

    func test_didSelectRow_callsNavigator() async {
        let id = UUID()
        let view = MockUserListView()
        let repo = FakeUserRepository(pages: [.fixture(users: [.fixture(id: id)])])
        let navigator = SpyNavigator()
        let sut = UserListPresenter(view: view, repository: repo, navigator: navigator)
        await sut.viewDidLoad()

        sut.didSelectRow(at: 0)

        XCTAssertEqual(navigator.pushedIDs, [id])
    }

    func test_failure_displaysError() async {
        let view = MockUserListView()
        let repo = FakeUserRepository(pages: [])     // no page → notFound
        let navigator = SpyNavigator()
        let sut = UserListPresenter(view: view, repository: repo, navigator: navigator)

        await sut.viewDidLoad()

        XCTAssertNotNil(view.lastError)
    }
}

@MainActor
final class MockUserListView: UserListView {
    private(set) var displayed: [UserListRowViewModel] = []
    private(set) var loadingHistory: [UserListLoading] = []
    private(set) var lastError: String?
    func display(rows: [UserListRowViewModel]) { displayed = rows }
    func displayLoading(_ loading: UserListLoading) { loadingHistory.append(loading) }
    func displayError(message: String) { lastError = message }
}

@MainActor
final class SpyNavigator: UserNavigating {
    private(set) var pushedIDs: [User.ID] = []
    func showDetail(for id: User.ID) { pushedIDs.append(id) }
}
