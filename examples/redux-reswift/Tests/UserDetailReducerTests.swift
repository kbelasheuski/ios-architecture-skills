import XCTest
@testable import ReduxReSwiftExample

final class UserDetailReducerTests: XCTestCase {

    func test_loaded_setsUserAndDraftName() {
        var s: UserDetailState? = .init()
        let user = User.fixture(name: "Ada")
        s = userDetailReducer(action: .loaded(user), state: s)
        XCTAssertEqual(s?.user?.name, "Ada")
        XCTAssertEqual(s?.draftName, "Ada")
    }

    func test_saveTapped_setsIsSaving() {
        var s = UserDetailState(user: .fixture(name: "Ada"))
        s.draftName = "Ada Lovelace"
        let next = userDetailReducer(action: .saveTapped, state: s)
        XCTAssertEqual(next?.isSaving, true)
    }

    func test_saved_updatesUserAndClearsSaving() {
        var s = UserDetailState(user: .fixture(name: "Ada"))
        s.isSaving = true
        let next = userDetailReducer(action: .saved(.fixture(name: "Ada Lovelace")), state: s)
        XCTAssertEqual(next?.user?.name, "Ada Lovelace")
        XCTAssertEqual(next?.isSaving, false)
    }

    func test_dismissed_clearsState() {
        let next = userDetailReducer(action: .dismissed, state: .init(user: .fixture()))
        XCTAssertNil(next)
    }
}
