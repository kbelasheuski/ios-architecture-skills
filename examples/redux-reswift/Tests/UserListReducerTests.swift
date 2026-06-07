import XCTest
@testable import ReduxReSwiftExample

final class UserListReducerTests: XCTestCase {

    func test_loadFullScreen_resetsAndSetsLoading() {
        var state = UserListState(users: [.fixture()], page: 1, totalPages: 1)
        state = userListReducer(action: .load(.fullScreen), state: state)
        XCTAssertEqual(state.loading, .fullScreen)
        XCTAssertTrue(state.users.isEmpty)
        XCTAssertEqual(state.page, 0)
    }

    func test_loaded_appendsAndUpdatesPaging() {
        var state = UserListState(loading: .fullScreen)
        state = userListReducer(action: .loaded(.fixture(users: [.fixture(name: "Ada")])), state: state)
        XCTAssertEqual(state.users.map(\.name), ["Ada"])
        XCTAssertEqual(state.loading, .none)
        XCTAssertEqual(state.page, 1)
    }

    func test_failed_clearsLoadingAndSetsError() {
        var state = UserListState(loading: .fullScreen)
        state = userListReducer(action: .failed("Boom"), state: state)
        XCTAssertEqual(state.loading, .none)
        XCTAssertEqual(state.errorMessage, "Boom")
    }

    func test_errorDismissed_clearsError() {
        var state = UserListState()
        state.errorMessage = "Boom"
        state = userListReducer(action: .errorDismissed, state: state)
        XCTAssertNil(state.errorMessage)
    }
}
