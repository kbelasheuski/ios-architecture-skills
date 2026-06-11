import XCTest
@testable import ReduxReSwiftExample

final class UserListReducerTests: XCTestCase {

    func test_loadFullScreen_resetsAndSetsLoading() {
        var s = UserListState(users: [.fixture()], page: 1, totalPages: 1)
        s = userListReducer(action: .load(.fullScreen), state: s)
        XCTAssertEqual(s.loading, .fullScreen)
        XCTAssertTrue(s.users.isEmpty)
        XCTAssertEqual(s.page, 0)
    }

    func test_loaded_appendsAndUpdatesPaging() {
        var s = UserListState(loading: .fullScreen)
        s = userListReducer(action: .loaded(.fixture(users: [.fixture(name: "Ada")])), state: s)
        XCTAssertEqual(s.users.map(\.name), ["Ada"])
        XCTAssertEqual(s.loading, .none)
        XCTAssertEqual(s.page, 1)
    }

    func test_failed_clearsLoadingAndSetsError() {
        var s = UserListState(loading: .fullScreen)
        s = userListReducer(action: .failed("Boom"), state: s)
        XCTAssertEqual(s.loading, .none)
        XCTAssertEqual(s.errorMessage, "Boom")
    }

    func test_errorDismissed_clearsError() {
        var s = UserListState()
        s.errorMessage = "Boom"
        s = userListReducer(action: .errorDismissed, state: s)
        XCTAssertNil(s.errorMessage)
    }
}
