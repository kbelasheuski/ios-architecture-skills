import XCTest
@testable import ReduxReSwiftExample

final class UserDetailReducerTests: XCTestCase {

    func test_loaded_setsUserAndDraftName() {
        var state: UserDetailState? = .init()
        let user = User.fixture(name: "Ada")
        state = userDetailReducer(action: .loaded(user), state: state)
        XCTAssertEqual(state?.user?.name, "Ada")
        XCTAssertEqual(state?.draftName, "Ada")
    }

    func test_saveTapped_setsIsSaving() {
        var state = UserDetailState(user: .fixture(name: "Ada"))
        state.draftName = "Ada Lovelace"
        let next = userDetailReducer(action: .saveTapped, state: state)
        XCTAssertEqual(next?.isSaving, true)
    }

    func test_saved_updatesUserAndClearsSaving() {
        var state = UserDetailState(user: .fixture(name: "Ada"))
        state.isSaving = true
        let next = userDetailReducer(action: .saved(.fixture(name: "Ada Lovelace")), state: state)
        XCTAssertEqual(next?.user?.name, "Ada Lovelace")
        XCTAssertEqual(next?.isSaving, false)
    }

    func test_dismissed_clearsState() {
        let next = userDetailReducer(action: .dismissed, state: .init(user: .fixture()))
        XCTAssertNil(next)
    }
}
