import XCTest
@testable import MVIExample

@MainActor
final class UserListStoreTests: XCTestCase {

    func test_onAppear_loadsFirstPage() async {
        let repo = FakeUserRepository(pages: [
            .fixture(users: [.fixture(name: "Ada"), .fixture(name: "Grace")],
                     page: 1, totalPages: 2)
        ])
        let sut = UserListStore(repository: repo)

        await sut.dispatch(.onAppear)

        XCTAssertEqual(sut.state.users.map(\.name), ["Ada", "Grace"])
        XCTAssertEqual(sut.state.loadState, .loaded)
        XCTAssertTrue(sut.state.hasMore)
        XCTAssertEqual(repo.fetchPageCalls, [1])
    }

    func test_onAppear_isIdempotent_whenAlreadyLoaded() async {
        let repo = FakeUserRepository(pages: [.fixture(users: [.fixture()])])
        let sut = UserListStore(repository: repo)
        await sut.dispatch(.onAppear)
        await sut.dispatch(.onAppear)
        XCTAssertEqual(repo.fetchPageCalls, [1])
    }

    func test_loadNextPageIfNeeded_appendsBelowThreshold() async {
        let page1Users = (0..<10).map { User.fixture(name: "U\($0)") }
        let page2Users = [User.fixture(name: "U10")]
        let repo = FakeUserRepository(pages: [
            .fixture(users: page1Users, page: 1, totalPages: 2),
            .fixture(users: page2Users, page: 2, totalPages: 2)
        ])
        let sut = UserListStore(repository: repo)
        await sut.dispatch(.onAppear)

        await sut.dispatch(.loadNextPageIfNeeded(page1Users[7]))

        XCTAssertEqual(repo.fetchPageCalls, [1, 2])
        XCTAssertEqual(sut.state.users.count, 11)
        XCTAssertFalse(sut.state.hasMore)
    }

    func test_refresh_ignoresStaleOnAppearResult() async {
        let stalePage = UsersPage.fixture(users: [.fixture(name: "Stale")], page: 1, totalPages: 1)
        let freshPage = UsersPage.fixture(users: [.fixture(name: "Fresh")], page: 1, totalPages: 1)
        let repo = FakeUserRepository(pages: [stalePage, freshPage])
        let firstRequestStarted = AsyncSignal()
        var resumeFirstRequest: CheckedContinuation<UsersPage, Error>?
        repo.fetchUsersHandler = { _ in
            if repo.fetchPageCalls.count == 1 {
                firstRequestStarted.signal()
                return try await withCheckedThrowingContinuation { continuation in
                    resumeFirstRequest = continuation
                }
            }
            return freshPage
        }
        let sut = UserListStore(repository: repo)

        let firstLoad = Task { await sut.dispatch(.onAppear) }
        await firstRequestStarted.wait()
        await sut.dispatch(.refresh)

        XCTAssertEqual(sut.state.users.map(\.name), ["Fresh"])

        resumeFirstRequest?.resume(returning: stalePage)
        await firstLoad.value

        XCTAssertEqual(repo.fetchPageCalls, [1, 1])
        XCTAssertEqual(sut.state.users.map(\.name), ["Fresh"])
    }

    func test_refresh_failure_setsFailedState() async {
        let repo = FakeUserRepository(pages: [])
        let sut = UserListStore(repository: repo)

        await sut.dispatch(.refresh)

        if case .failed = sut.state.loadState { } else {
            XCTFail("expected .failed, got \(sut.state)")
        }
    }
}

private final class AsyncSignal: @unchecked Sendable {
    private var continuation: CheckedContinuation<Void, Never>?
    private var signaled = false

    func wait() async {
        if signaled { return }
        await withCheckedContinuation { continuation = $0 }
    }

    func signal() {
        signaled = true
        continuation?.resume()
        continuation = nil
    }
}
