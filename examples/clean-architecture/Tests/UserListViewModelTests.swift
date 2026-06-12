import XCTest
@testable import CleanArchitectureExample

@MainActor
final class UserListViewModelTests: XCTestCase {

    func test_viewDidLoad_loadsAndExposesUsers() async {
        let repo = FakeUserRepository(pages: [.fixture(users: [.fixture(name: "Ada")])])
        var navigated: User?
        let sut = UserListViewModel(
            fetchUsersUseCase: DefaultFetchUsersUseCase(repository: repo),
            actions: .init(showUserDetail: { navigated = $0 })
        )

        await sut.viewDidLoad()

        XCTAssertEqual(sut.users.map(\.name), ["Ada"])
        XCTAssertEqual(sut.loading, .none)
        XCTAssertNil(navigated)
    }

    func test_didSelectUser_routesToCoordinator() async {
        let user = User.fixture(name: "Ada")
        let repo = FakeUserRepository(pages: [.fixture(users: [user])])
        var navigated: User?
        let sut = UserListViewModel(
            fetchUsersUseCase: DefaultFetchUsersUseCase(repository: repo),
            actions: .init(showUserDetail: { navigated = $0 })
        )
        await sut.viewDidLoad()

        sut.didSelectUser(at: user.id)

        XCTAssertEqual(navigated?.id, user.id)
    }
}
