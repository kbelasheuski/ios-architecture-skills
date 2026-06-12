import XCTest
import Domain
import UserDomain
@testable import UserListFeature

@MainActor
final class UserListModelTests: XCTestCase {

    func test_onAppear_loadsFirstPage() async {
        let repo = FakeUserRepository(pages: [
            .fixture(users: [.fixture(name: "Ada")], page: 1, totalPages: 1)
        ])
        let sut = UserListModel(fetchUsers: FetchUsersUseCaseLive(repository: repo))

        await sut.onAppear()

        XCTAssertEqual(sut.users.map(\.name), ["Ada"])
        XCTAssertEqual(sut.state, .loaded)
    }
}
