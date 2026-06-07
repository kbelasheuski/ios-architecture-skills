import XCTest
@testable import VIPERExample

@MainActor
final class UserListPresenterTests: XCTestCase {

    func test_viewDidLoad_loadsAndDisplaysRows() async {
        let view = MockUserListView()
        let interactor = StubUserListInteractor(page: .fixture(users: [.fixture(name: "Ada")]))
        let router = SpyUserListRouter()
        let sut = UserListPresenter(view: view, interactor: interactor, router: router)

        await sut.viewDidLoad()

        XCTAssertEqual(view.displayedRows.first?.title, "Ada")
        XCTAssertEqual(view.loadingHistory, [.fullScreen, .none])
        XCTAssertNil(view.lastError)
    }

    func test_didSelectRow_invokesRouter() async {
        let id = UUID()
        let view = MockUserListView()
        let interactor = StubUserListInteractor(page: .fixture(users: [.fixture(id: id)]))
        let router = SpyUserListRouter()
        let sut = UserListPresenter(view: view, interactor: interactor, router: router)
        await sut.viewDidLoad()

        sut.didSelectRow(at: 0)

        XCTAssertEqual(router.pushedIDs, [id])
    }

    func test_failure_propagatesError() async {
        struct Boom: LocalizedError { var errorDescription: String? { "Boom" } }
        let view = MockUserListView()
        let interactor = StubUserListInteractor(error: Boom())
        let router = SpyUserListRouter()
        let sut = UserListPresenter(view: view, interactor: interactor, router: router)

        await sut.viewDidLoad()

        XCTAssertEqual(view.lastError, "Boom")
    }
}

// MARK: - Mocks

@MainActor
final class MockUserListView: UserListViewProtocol {
    private(set) var displayedRows: [UserListRowEntity] = []
    private(set) var loadingHistory: [UserListLoading] = []
    private(set) var lastError: String?
    func display(rows: [UserListRowEntity]) { displayedRows = rows }
    func displayLoading(_ loading: UserListLoading) { loadingHistory.append(loading) }
    func displayError(message: String) { lastError = message }
}

final class StubUserListInteractor: UserListInteractorProtocol {
    let result: Result<UsersPage, Error>
    init(page: UsersPage) { self.result = .success(page) }
    init(error: Error) { self.result = .failure(error) }
    func fetchUsers(page: Int) async throws -> UsersPage { try result.get() }
}

@MainActor
final class SpyUserListRouter: UserListRouterProtocol {
    private(set) var pushedIDs: [User.ID] = []
    func showDetail(for id: User.ID) { pushedIDs.append(id) }
}
