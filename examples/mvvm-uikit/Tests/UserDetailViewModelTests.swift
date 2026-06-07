import Combine
@testable import MVVMUIKitExample
import XCTest

@MainActor
final class UserDetailViewModelTests: XCTestCase {

    private var cancellables: Set<AnyCancellable> = []

    func test_onAppear_loadsUser() async {
        let user = User.fixture(name: "Ada")
        let repo = FakeUserRepository(pages: [.fixture(users: [user])])
        let sut = UserDetailViewModel(repository: repo, id: user.id)

        sut.onAppear()
        await waitForUser(sut)

        XCTAssertEqual(sut.user?.name, "Ada")
        XCTAssertEqual(sut.draftName, "Ada")
        XCTAssertFalse(sut.isDirty)
    }

    func test_save_publishesDidSaveAndUpdatesRepository() async {
        let user = User.fixture(name: "Ada")
        let repo = FakeUserRepository(pages: [.fixture(users: [user])])
        let sut = UserDetailViewModel(repository: repo, id: user.id)
        sut.onAppear()
        await waitForUser(sut)

        sut.draftName = "Ada Lovelace"
        XCTAssertTrue(sut.canSave)

        var saved: User?
        sut.didSave.sink { saved = $0 }.store(in: &cancellables)
        sut.save()
        await waitForSavingFinished(sut)

        XCTAssertEqual(repo.updateCalls.first?.name, "Ada Lovelace")
        XCTAssertEqual(saved?.name, "Ada Lovelace")
        XCTAssertEqual(sut.user?.name, "Ada Lovelace")
    }

    private func waitForUser(
        _ vm: UserDetailViewModel,
        timeout: TimeInterval = 1
    ) async {
        let start = Date()
        while vm.user == nil, Date().timeIntervalSince(start) < timeout {
            await Task.yield()
        }
    }

    private func waitForSavingFinished(
        _ vm: UserDetailViewModel,
        timeout: TimeInterval = 1
    ) async {
        let start = Date()
        while vm.isSaving, Date().timeIntervalSince(start) < timeout {
            await Task.yield()
        }
    }
}
