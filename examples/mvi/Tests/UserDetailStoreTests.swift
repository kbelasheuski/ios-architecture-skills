import XCTest
@testable import MVIExample

@MainActor
final class UserDetailStoreTests: XCTestCase {

    func test_onAppear_loadsUser() async {
        let user = User.fixture(name: "Ada")
        let repo = FakeUserRepository(pages: [.fixture(users: [user])])
        let sut = UserDetailStore(repository: repo, id: user.id)

        await sut.dispatch(.onAppear)

        XCTAssertEqual(sut.state.user?.name, "Ada")
        XCTAssertEqual(sut.state.draftName, "Ada")
        XCTAssertFalse(sut.state.isDirty)
        XCTAssertFalse(sut.state.canSave)
    }

    func test_dirtyAndCanSave_whenNameChanges() async {
        let user = User.fixture(name: "Ada")
        let repo = FakeUserRepository(pages: [.fixture(users: [user])])
        let sut = UserDetailStore(repository: repo, id: user.id)
        await sut.dispatch(.onAppear)

        await sut.dispatch(.draftNameChanged("Ada Lovelace"))

        XCTAssertTrue(sut.state.isDirty)
        XCTAssertTrue(sut.state.canSave)
    }

    func test_save_persistsAndReturnsUser() async {
        let id = UUID()
        let original = User(id: id, name: "Ada", email: "ada@example.com")
        let repo = FakeUserRepository(pages: [.fixture(users: [original])])
        let sut = UserDetailStore(repository: repo, id: id)
        await sut.dispatch(.onAppear)
        await sut.dispatch(.draftNameChanged("Ada Lovelace"))

        let saved = await sut.dispatch(.save)

        XCTAssertEqual(saved?.name, "Ada Lovelace")
        XCTAssertEqual(repo.updateCalls.first?.name, "Ada Lovelace")
        XCTAssertEqual(sut.state.saveState, .saved)
        XCTAssertFalse(sut.state.isDirty)
    }

    func test_save_failure_setsFailedStateAndPreservesDraft() async {
        struct Boom: LocalizedError { var errorDescription: String? { "Boom" } }
        let id = UUID()
        let original = User(id: id, name: "Ada", email: "ada@example.com")
        let repo = FakeUserRepository(pages: [.fixture(users: [original])])
        repo.updateHandler = { _ in throw Boom() }
        let sut = UserDetailStore(repository: repo, id: id)
        await sut.dispatch(.onAppear)
        await sut.dispatch(.draftNameChanged("Ada Lovelace"))

        let saved = await sut.dispatch(.save)

        XCTAssertNil(saved)
        XCTAssertEqual(sut.state.saveState, .failed("Boom"))
        XCTAssertEqual(sut.state.draftName, "Ada Lovelace")
    }
}
