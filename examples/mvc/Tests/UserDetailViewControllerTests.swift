import UIKit
import XCTest
@testable import MVCExample

@MainActor
final class UserDetailViewControllerTests: XCTestCase {

    func test_load_populatesFields() async {
        let user = User.fixture(name: "Ada", email: "ada@example.com")
        let repo = FakeUserRepository(pages: [.fixture(users: [user])])
        let sut = UserDetailViewController(repository: repo, userID: user.id)
        _ = sut.view
        await sut.awaitCurrentLoadForTesting()
        XCTAssertEqual(sut.user?.name, "Ada")
    }

    func test_save_callsRepositoryUpdate() async throws {
        let user = User.fixture(name: "Ada")
        let started = expectation(description: "repository update started")
        let popped = expectation(description: "detail popped after update")
        let repo = ControlledSaveRepository(user: user, started: started)
        let sut = UserDetailViewController(repository: repo, userID: user.id)
        let root = UIViewController()
        let navigation = SaveNavigationController(rootViewController: root)
        navigation.onPop = { popped.fulfill() }
        navigation.setViewControllers([root, sut], animated: false)
        sut.loadViewIfNeeded()
        await sut.awaitCurrentLoadForTesting()

        let stack = try XCTUnwrap(sut.view.subviews.compactMap { $0 as? UIStackView }.first)
        let field = try XCTUnwrap(stack.arrangedSubviews.compactMap { $0 as? UITextField }.first)
        field.text = "Ada Lovelace"
        let editAction = try XCTUnwrap(field.actions(forTarget: sut, forControlEvent: .editingChanged)?.first)
        sut.perform(NSSelectorFromString(editAction), with: field)
        let save = try XCTUnwrap(sut.navigationItem.rightBarButtonItem)
        XCTAssertTrue(save.isEnabled)
        XCTAssertTrue(save.target === sut)
        let saveAction = try XCTUnwrap(save.action)
        // Invoke the registered selector: SwiftPM unit tests have no UIApplication dispatcher.
        sut.perform(saveAction, with: save)

        await fulfillment(of: [started], timeout: 2)
        guard let completion = repo.completion else { return }
        defer { repo.completion = nil }
        XCTAssertEqual(repo.updates.count, 1)
        XCTAssertEqual(repo.updates.first?.id, user.id)
        XCTAssertEqual(repo.updates.first?.name, "Ada Lovelace")
        XCTAssertEqual(repo.updates.first?.email, user.email)
        XCTAssertTrue(sut.isSaving)
        XCTAssertFalse(save.isEnabled)
        XCTAssertEqual(navigation.popCount, 0)
        completion.resume(returning: repo.updates[0])
        await fulfillment(of: [popped], timeout: 2)
        XCTAssertEqual(navigation.popCount, 1)
        XCTAssertTrue(navigation.topViewController === root)
        XCTAssertFalse(sut.isSaving)
    }
}

@MainActor
private final class ControlledSaveRepository: UserRepository {
    let user: User
    let started: XCTestExpectation
    var updates: [User] = []
    var completion: CheckedContinuation<User, Error>?

    init(user: User, started: XCTestExpectation) {
        self.user = user
        self.started = started
    }
    func fetchUsers(page: Int) async throws -> UsersPage { .fixture(users: [user]) }
    func fetchUser(id: User.ID) async throws -> User { user }
    func update(_ user: User) async throws -> User {
        updates.append(user)
        return try await withCheckedThrowingContinuation {
            completion = $0
            started.fulfill()
        }
    }
}

@MainActor
private final class SaveNavigationController: UINavigationController {
    var popCount = 0
    var onPop: (() -> Void)?
    override func popViewController(animated: Bool) -> UIViewController? {
        popCount += 1
        let popped = super.popViewController(animated: false)
        onPop?()
        return popped
    }
}
