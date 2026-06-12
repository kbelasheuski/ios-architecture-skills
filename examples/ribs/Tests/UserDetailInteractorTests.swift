import RIBs
import XCTest

final class UserDetailInteractorTests: XCTestCase {

    func test_didBecomeActive_loadsAndDisplaysUser() {
        let presenter = MockUserDetailPresentable()
        let user = User.fixture(name: "Ada")
        let repo = FakeUserRepository(pages: [.fixture(users: [user])])
        let sut = UserDetailInteractor(presenter: presenter, repository: repo, userID: user.id)

        sut.activate()
        let exp = expectation(description: "load")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            XCTAssertEqual(presenter.lastName, "Ada")
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1)
        sut.deactivate()
    }

    func test_save_notifiesListenerOnSuccess() {
        let presenter = MockUserDetailPresentable()
        let user = User.fixture(name: "Ada")
        let repo = FakeUserRepository(pages: [.fixture(users: [user])])
        let listener = SpyUserDetailListener()
        let sut = UserDetailInteractor(presenter: presenter, repository: repo, userID: user.id)
        sut.listener = listener

        sut.activate()
        let loaded = expectation(description: "loaded")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            sut.didChangeName("Ada Lovelace")
            sut.save()
            loaded.fulfill()
        }
        wait(for: [loaded], timeout: 1)

        let saved = expectation(description: "saved")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            XCTAssertEqual(repo.updateCalls.first?.name, "Ada Lovelace")
            XCTAssertEqual(listener.finishCalls, 1)
            saved.fulfill()
        }
        wait(for: [saved], timeout: 1)
    }
}

final class MockUserDetailPresentable: UserDetailPresentable {
    var listener: UserDetailPresentableListener?
    private(set) var lastName: String?
    private(set) var savingHistory: [Bool] = []
    private(set) var saveEnabledHistory: [Bool] = []
    private(set) var lastError: String?
    func display(name: String, email: String) { lastName = name }
    func display(saving: Bool) { savingHistory.append(saving) }
    func setSaveEnabled(_ enabled: Bool) { saveEnabledHistory.append(enabled) }
    func displayError(_ message: String) { lastError = message }
}

final class SpyUserDetailListener: UserDetailListener {
    private(set) var finishCalls = 0
    func userDetailDidFinish() { finishCalls += 1 }
}
