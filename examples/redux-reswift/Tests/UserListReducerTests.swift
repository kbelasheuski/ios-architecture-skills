import XCTest
@testable import ReduxReSwiftExample

final class UserListReducerTests: XCTestCase {

    func test_loadFullScreen_resetsAndSetsLoading() {
        let requestID = UUID()
        var s = UserListState(users: [.fixture()], page: 1, totalPages: 1)
        s = userListReducer(action: .loadStarted(.fullScreen, requestID: requestID), state: s)
        XCTAssertEqual(s.loading, .fullScreen)
        XCTAssertTrue(s.users.isEmpty)
        XCTAssertEqual(s.page, 0)
        XCTAssertEqual(s.activeRequestID, requestID)
    }

    func test_loaded_appendsAndUpdatesPaging() {
        let requestID = UUID()
        var s = UserListState(loading: .fullScreen, activeRequestID: requestID)
        s = userListReducer(
            action: .loaded(.fixture(users: [.fixture(name: "Ada")]), requestID: requestID),
            state: s
        )
        XCTAssertEqual(s.users.map(\.name), ["Ada"])
        XCTAssertEqual(s.loading, .none)
        XCTAssertEqual(s.page, 1)
        XCTAssertNil(s.activeRequestID)
    }

    func test_failed_clearsLoadingAndSetsError() {
        let requestID = UUID()
        var s = UserListState(loading: .fullScreen, activeRequestID: requestID)
        s = userListReducer(action: .failed("Boom", requestID: requestID), state: s)
        XCTAssertEqual(s.loading, .none)
        XCTAssertEqual(s.errorMessage, "Boom")
        XCTAssertNil(s.activeRequestID)
    }

    func test_staleLoadedResponse_isIgnored() {
        let activeRequestID = UUID()
        let staleRequestID = UUID()
        var s = UserListState(users: [.fixture(name: "Fresh")], activeRequestID: activeRequestID)
        s = userListReducer(
            action: .loaded(.fixture(users: [.fixture(name: "Stale")], page: 2), requestID: staleRequestID),
            state: s
        )
        XCTAssertEqual(s.users.map(\.name), ["Fresh"])
        XCTAssertEqual(s.activeRequestID, activeRequestID)
    }

    func test_errorDismissed_clearsError() {
        var s = UserListState()
        s.errorMessage = "Boom"
        s = userListReducer(action: .errorDismissed, state: s)
        XCTAssertNil(s.errorMessage)
    }
}
