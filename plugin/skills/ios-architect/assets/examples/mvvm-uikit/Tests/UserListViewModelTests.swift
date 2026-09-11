import Combine
@testable import MVVMUIKitExample
import XCTest

@MainActor
final class UserListViewModelTests: XCTestCase {

    private var cancellables: Set<AnyCancellable> = []

    func test_onAppear_publishesUsers() async {
        let repo = FakeUserRepository(pages: [
            .fixture(users: [.fixture(name: "Ada"), .fixture(name: "Grace")])
        ])
        let sut = UserListViewModel(repository: repo)

        sut.onAppear()
        await waitForUsersCount(sut, count: 2)

        XCTAssertEqual(sut.users.map(\.name), ["Ada", "Grace"])
        XCTAssertEqual(sut.loading, .none)
        XCTAssertEqual(repo.fetchPageCalls, [1])
    }

    func test_didSelectRow_emitsUserSelected() async {
        let id = UUID()
        let repo = FakeUserRepository(pages: [.fixture(users: [.fixture(id: id)])])
        let sut = UserListViewModel(repository: repo)
        sut.onAppear()
        await waitForUsersCount(sut, count: 1)

        var received: User.ID?
        sut.userSelected.sink { received = $0 }.store(in: &cancellables)
        sut.didSelectRow(at: 0)

        XCTAssertEqual(received, id)
    }

    func test_failure_setsErrorMessage() async {
        let repo = FakeUserRepository(pages: [])    // notFound
        let sut = UserListViewModel(repository: repo)

        sut.onAppear()
        await waitForError(sut)

        XCTAssertNotNil(sut.errorMessage)
        XCTAssertEqual(sut.loading, .none)
    }

    // MARK: - helpers

    private func waitForUsersCount(
        _ vm: UserListViewModel,
        count: Int,
        timeout: TimeInterval = 1
    ) async {
        let start = Date()
        while vm.users.count < count, Date().timeIntervalSince(start) < timeout {
            await Task.yield()
        }
    }

    private func waitForError(
        _ vm: UserListViewModel,
        timeout: TimeInterval = 1
    ) async {
        let start = Date()
        while vm.errorMessage == nil, Date().timeIntervalSince(start) < timeout {
            await Task.yield()
        }
    }
}
