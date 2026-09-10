import XCTest
@testable import CleanSwiftExample

@MainActor
final class UserListPresenterTests: XCTestCase {

    func test_present_mapsUsersToRows() async {
        let view = MockUserListDisplay()
        let sut = UserListPresenter()
        sut.view = view

        await sut.present(.init(users: [.fixture(name: "Ada")], loading: .none, errorMessage: nil))

        XCTAssertEqual(view.lastViewModel?.rows.first?.title, "Ada")
        XCTAssertNil(view.lastViewModel?.errorMessage)
    }

    func test_present_forwardsError() async {
        let view = MockUserListDisplay()
        let sut = UserListPresenter()
        sut.view = view

        await sut.present(.init(users: [], loading: .none, errorMessage: "Boom"))

        XCTAssertEqual(view.lastViewModel?.errorMessage, "Boom")
    }

    func test_present_doesNotAccumulateAcrossCalls() async {
        let view = MockUserListDisplay()
        let sut = UserListPresenter()
        sut.view = view

        await sut.present(.init(users: [.fixture(name: "Ada")], loading: .none, errorMessage: nil))
        await sut.present(.init(users: [.fixture(name: "Grace")], loading: .none, errorMessage: nil))

        XCTAssertEqual(view.lastViewModel?.rows.map(\.title), ["Grace"])
    }
}

@MainActor
final class MockUserListDisplay: UserListDisplayLogic {
    private(set) var lastViewModel: UserList.FetchUsers.ViewModel?
    func display(_ viewModel: UserList.FetchUsers.ViewModel) {
        lastViewModel = viewModel
    }
}
