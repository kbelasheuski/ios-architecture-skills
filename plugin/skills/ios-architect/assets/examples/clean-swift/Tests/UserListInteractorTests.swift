import XCTest
@testable import CleanSwiftExample

@MainActor
final class UserListInteractorTests: XCTestCase {

    func test_fetchUsers_emitsLoadingThenLoadedUsers() async throws {
        let presenter = SpyUserListPresenter()
        let worker = UserListWorker(repository: FakeUserRepository(pages: [
            .fixture(users: [.fixture(name: "Ada")])
        ]))
        let sut = UserListInteractor(worker: worker)
        sut.presenter = presenter

        await sut.fetchUsers(.init(reset: true))

        XCTAssertEqual(presenter.received.count, 2)
        let first = try XCTUnwrap(presenter.received.first)
        let last = try XCTUnwrap(presenter.received.last)
        XCTAssertEqual(first.loading, .fullScreen)
        XCTAssertEqual(last.loading, .none)
        XCTAssertEqual(last.users.first?.name, "Ada")
        XCTAssertNil(last.errorMessage)
        XCTAssertEqual(sut.users.count, 1)
    }

    func test_refresh_doesNotDuplicateRows() async {
        let presenter = SpyUserListPresenter()
        let worker = UserListWorker(repository: FakeUserRepository(pages: [
            .fixture(users: [.fixture(name: "Ada"), .fixture(name: "Grace")])
        ]))
        let sut = UserListInteractor(worker: worker)
        sut.presenter = presenter

        await sut.fetchUsers(.init(reset: true))
        await sut.fetchUsers(.init(reset: true))

        XCTAssertEqual(sut.users.count, 2)
        XCTAssertEqual(presenter.received.last?.users.count, 2)
    }

    func test_fetchUsers_failure_emitsError() async {
        let presenter = SpyUserListPresenter()
        let worker = UserListWorker(repository: FakeUserRepository(pages: []))
        let sut = UserListInteractor(worker: worker)
        sut.presenter = presenter

        await sut.fetchUsers(.init(reset: true))

        XCTAssertNotNil(presenter.received.last?.errorMessage)
    }

    func test_selectRow_setsSelectedID() async {
        let presenter = SpyUserListPresenter()
        let user = User.fixture(name: "Ada")
        let worker = UserListWorker(repository: FakeUserRepository(pages: [.fixture(users: [user])]))
        let sut = UserListInteractor(worker: worker)
        sut.presenter = presenter
        await sut.fetchUsers(.init(reset: true))

        sut.selectRow(.init(index: 0))

        XCTAssertEqual(sut.selectedUserID, user.id)
    }
}

@MainActor
final class SpyUserListPresenter: UserListPresentationLogic {
    private(set) var received: [UserList.FetchUsers.Response] = []
    func present(_ response: UserList.FetchUsers.Response) async {
        received.append(response)
    }
}
