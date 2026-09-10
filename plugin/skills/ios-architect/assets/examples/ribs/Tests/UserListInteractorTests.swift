import RIBs
import XCTest

final class UserListInteractorTests: XCTestCase {

    func test_didBecomeActive_displaysRows() {
        let presenter = MockUserListPresentable()
        let repo = FakeUserRepository(pages: [.fixture(users: [.fixture(name: "Ada")])])
        let sut = UserListInteractor(presenter: presenter, repository: repo)
        let listener = SpyListener()
        sut.listener = listener

        sut.activate()

        let exp = expectation(description: "rows displayed")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            XCTAssertEqual(presenter.displayedRows.first?.title, "Ada")
            XCTAssertEqual(presenter.loadingHistory.last, .none)
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1)
        sut.deactivate()
    }

    func test_didSelectRow_routesToDetail() {
        let presenter = MockUserListPresentable()
        let user = User.fixture(name: "Ada")
        let repo = FakeUserRepository(pages: [.fixture(users: [user])])
        let router = SpyUserListRouter()
        let sut = UserListInteractor(presenter: presenter, repository: repo)
        sut.router = router

        sut.activate()
        let exp = expectation(description: "load done")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            sut.didSelectRow(at: 0)
            XCTAssertEqual(router.routedIDs, [user.id])
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1)
    }
}

// MARK: - Mocks

final class MockUserListPresentable: UserListPresentable {
    var listener: UserListPresentableListener?
    private(set) var displayedRows: [UserListRow] = []
    private(set) var loadingHistory: [UserListLoading] = []
    private(set) var lastError: String?
    func display(rows: [UserListRow]) { displayedRows = rows }
    func display(loading: UserListLoading) { loadingHistory.append(loading) }
    func displayError(_ message: String) { lastError = message }
}

final class SpyListener: UserListListener {
    private(set) var finishCalls = 0
    func userListDidFinish() { finishCalls += 1 }
}

final class SpyUserListRouter: UserListRouting {
    var interactable: Interactable {
        fatalError("not used in this test")
    }
    var viewControllable: ViewControllable {
        fatalError("not used in this test")
    }
    var children: [Routing] = []
    func attachChild(_ child: Routing) {}
    func detachChild(_ child: Routing) {}
    func load() {}
    private(set) var routedIDs: [User.ID] = []
    func routeToDetail(userID: User.ID) { routedIDs.append(userID) }
    func detachDetail() {}
}
