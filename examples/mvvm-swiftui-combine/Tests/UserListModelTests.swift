import XCTest
@testable import MVVMSwiftUICombineExample

@MainActor
final class UserListModelTests: XCTestCase {

    func test_onAppear_loadsFirstPage() async {
        let repo = FakeUserRepository(pages: [
            .fixture(users: [.fixture(name: "Ada"), .fixture(name: "Grace")],
                     page: 1, totalPages: 2)
        ])
        let sut = UserListModel(repository: repo)

        await sut.onAppear()

        XCTAssertEqual(sut.users.map(\.name), ["Ada", "Grace"])
        XCTAssertEqual(sut.state, .loaded)
        XCTAssertTrue(sut.hasMore)
        XCTAssertEqual(repo.fetchPageCalls, [1])
    }

    func test_onAppear_isIdempotent_whenAlreadyLoaded() async {
        let repo = FakeUserRepository(pages: [.fixture(users: [.fixture()])])
        let sut = UserListModel(repository: repo)
        await sut.onAppear()
        await sut.onAppear()
        XCTAssertEqual(repo.fetchPageCalls, [1])
    }

    func test_loadNextPageIfNeeded_appendsBelowThreshold() async {
        let page1Users = (0..<10).map { User.fixture(name: "U\($0)") }
        let page2Users = [User.fixture(name: "U10")]
        let repo = FakeUserRepository(pages: [
            .fixture(users: page1Users, page: 1, totalPages: 2),
            .fixture(users: page2Users, page: 2, totalPages: 2)
        ])
        let sut = UserListModel(repository: repo)
        await sut.onAppear()

        sut.loadNextPageIfNeeded(currentItem: page1Users[7])
        await Task.yield()
        try? await Task.sleep(for: .milliseconds(50))

        XCTAssertEqual(repo.fetchPageCalls, [1, 2])
        XCTAssertEqual(sut.users.count, 11)
        XCTAssertFalse(sut.hasMore)
    }

    func test_refresh_failure_setsFailedState() async {
        let repo = FakeUserRepository(pages: [])
        let sut = UserListModel(repository: repo)

        await sut.refresh()

        if case .failed = sut.state { } else {
            XCTFail("expected .failed, got \(sut.state)")
        }
    }
}
