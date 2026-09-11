import XCTest
@testable import MVVMSwiftUIExample

@MainActor
final class UserDetailModelTests: XCTestCase {

    func test_onAppear_loadsUser() async {
        let user = User.fixture(name: "Ada")
        let repo = FakeUserRepository(pages: [.fixture(users: [user])])
        let sut = UserDetailModel(repository: repo, id: user.id)

        await sut.onAppear()

        XCTAssertEqual(sut.user?.name, "Ada")
        XCTAssertEqual(sut.draftName, "Ada")
        XCTAssertFalse(sut.isDirty)
        XCTAssertFalse(sut.canSave)
    }

    func test_dirtyAndCanSave_whenNameChanges() async {
        let user = User.fixture(name: "Ada")
        let repo = FakeUserRepository(pages: [.fixture(users: [user])])
        let sut = UserDetailModel(repository: repo, id: user.id)
        await sut.onAppear()

        sut.draftName = "Ada Lovelace"

        XCTAssertTrue(sut.isDirty)
        XCTAssertTrue(sut.canSave)
    }

    func test_save_persistsAndReturnsUser() async {
        let id = UUID()
        let original = User(id: id, name: "Ada", email: "ada@example.com")
        let repo = FakeUserRepository(pages: [.fixture(users: [original])])
        let sut = UserDetailModel(repository: repo, id: id)
        await sut.onAppear()
        sut.draftName = "Ada Lovelace"

        let saved = await sut.save()

        XCTAssertEqual(saved?.name, "Ada Lovelace")
        XCTAssertEqual(repo.updateCalls.first?.name, "Ada Lovelace")
        XCTAssertEqual(sut.state, .saved)
        XCTAssertFalse(sut.isDirty)
    }

    func test_save_failure_setsFailedStateAndPreservesDraft() async {
        struct Boom: LocalizedError { var errorDescription: String? { "Boom" } }
        let id = UUID()
        let original = User(id: id, name: "Ada", email: "ada@example.com")
        let repo = FakeUserRepository(pages: [.fixture(users: [original])])
        repo.updateHandler = { _ in throw Boom() }
        let sut = UserDetailModel(repository: repo, id: id)
        await sut.onAppear()
        sut.draftName = "Ada Lovelace"

        let saved = await sut.save()

        XCTAssertNil(saved)
        XCTAssertEqual(sut.state, .failed("Boom"))
        XCTAssertEqual(sut.draftName, "Ada Lovelace")
    }
}
