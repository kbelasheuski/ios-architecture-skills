import XCTest
@testable import CoordinatorExample

@MainActor
final class UserListModelTests: XCTestCase {

    func test_onAppear_loadsFirstPage() async {
        let repo = FakeUserRepository(pages: [
            .fixture(users: [.fixture(name: "Ada")], page: 1, totalPages: 1)
        ])
        var selectedID: User.ID?
        let sut = UserListModel(
            repository: repo,
            onSelect: { selectedID = $0 }
        )

        await sut.onAppear()

        XCTAssertEqual(sut.users.map(\.name), ["Ada"])
        XCTAssertEqual(sut.state, .loaded)
        XCTAssertNil(selectedID)
    }

    func test_didSelect_invokesOnSelectCallback() async {
        let id = UUID()
        let repo = FakeUserRepository(pages: [.fixture(users: [.fixture(id: id)])])
        var captured: User.ID?
        let sut = UserListModel(
            repository: repo,
            onSelect: { captured = $0 }
        )
        await sut.onAppear()

        sut.didSelect(id)

        XCTAssertEqual(captured, id)
    }
}
