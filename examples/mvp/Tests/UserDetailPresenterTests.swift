import XCTest
@testable import MVPExample

@MainActor
final class UserDetailPresenterTests: XCTestCase {

    func test_viewDidLoad_displaysUserAndDisablesSave() async {
        let view = MockUserDetailView()
        let user = User.fixture(name: "Ada")
        let repo = FakeUserRepository(pages: [.fixture(users: [user])])
        let sut = UserDetailPresenter(view: view, repository: repo, id: user.id, onSaved: { _ in })

        await sut.viewDidLoad()

        XCTAssertEqual(view.lastName, "Ada")
        XCTAssertEqual(view.saveEnabledHistory.last, false)
    }

    func test_changingName_enablesSave_thenSave_invokesRepository() async {
        let view = MockUserDetailView()
        let user = User.fixture(name: "Ada")
        let repo = FakeUserRepository(pages: [.fixture(users: [user])])
        var savedCallback: User?
        let sut = UserDetailPresenter(view: view, repository: repo, id: user.id) { savedCallback = $0 }

        await sut.viewDidLoad()
        sut.didChangeName("Ada Lovelace")
        XCTAssertTrue(view.saveEnabledHistory.contains(true))

        await sut.save()

        XCTAssertEqual(repo.updateCalls.first?.name, "Ada Lovelace")
        XCTAssertEqual(savedCallback?.name, "Ada Lovelace")
        XCTAssertTrue(view.dismissed)
    }
}

@MainActor
final class MockUserDetailView: UserDetailView {
    private(set) var lastName: String?
    private(set) var savingHistory: [Bool] = []
    private(set) var saveEnabledHistory: [Bool] = []
    private(set) var lastError: String?
    private(set) var dismissed = false
    func display(name: String, email: String) { lastName = name }
    func displaySaving(_ saving: Bool) { savingHistory.append(saving) }
    func displayError(message: String) { lastError = message }
    func setSaveEnabled(_ enabled: Bool) { saveEnabledHistory.append(enabled) }
    func dismiss() { dismissed = true }
}
