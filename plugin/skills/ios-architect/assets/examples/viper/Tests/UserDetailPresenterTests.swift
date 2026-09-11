import XCTest
@testable import VIPERExample

@MainActor
final class UserDetailPresenterTests: XCTestCase {

    func test_viewDidLoad_displaysUserAndDisablesSave() async {
        let view = MockUserDetailView()
        let user = User.fixture(name: "Ada")
        let interactor = StubUserDetailInteractor(user: user)
        let router = SpyUserDetailRouter()
        let sut = UserDetailPresenter(view: view, interactor: interactor, router: router, id: user.id)

        await sut.viewDidLoad()

        XCTAssertEqual(view.lastName, "Ada")
        XCTAssertEqual(view.saveEnabledHistory.last, false)
    }

    func test_save_callsInteractorAndPops() async {
        let view = MockUserDetailView()
        let user = User.fixture(name: "Ada")
        let interactor = StubUserDetailInteractor(user: user)
        let router = SpyUserDetailRouter()
        let sut = UserDetailPresenter(view: view, interactor: interactor, router: router, id: user.id)
        await sut.viewDidLoad()
        sut.didChangeName("Ada Lovelace")

        await sut.save()

        XCTAssertEqual(interactor.updateCalls.first?.name, "Ada Lovelace")
        XCTAssertTrue(router.popped)
    }
}

// MARK: - Mocks

@MainActor
final class MockUserDetailView: UserDetailViewProtocol {
    private(set) var lastName: String?
    private(set) var savingHistory: [Bool] = []
    private(set) var saveEnabledHistory: [Bool] = []
    private(set) var lastError: String?
    func display(name: String, email: String) { lastName = name }
    func displaySaving(_ saving: Bool) { savingHistory.append(saving) }
    func displayError(message: String) { lastError = message }
    func setSaveEnabled(_ enabled: Bool) { saveEnabledHistory.append(enabled) }
}

final class StubUserDetailInteractor: UserDetailInteractorProtocol {
    var user: User
    private(set) var updateCalls: [User] = []
    init(user: User) { self.user = user }
    func fetch(id: User.ID) async throws -> User { user }
    func update(_ user: User) async throws -> User {
        updateCalls.append(user)
        self.user = user
        return user
    }
}

@MainActor
final class SpyUserDetailRouter: UserDetailRouterProtocol {
    private(set) var popped = false
    func pop() { popped = true }
}
