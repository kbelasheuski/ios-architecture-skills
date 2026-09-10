import XCTest
@testable import CoordinatorExample

@MainActor
final class AppCoordinatorTests: XCTestCase {

    func test_push_appendsRoute() {
        let sut = AppCoordinator()
        let id = UUID()
        sut.push(.userDetail(id))
        XCTAssertEqual(sut.path, [.userDetail(id)])
    }

    func test_pop_removesLastRoute() {
        let sut = AppCoordinator()
        let id1 = UUID(), id2 = UUID()
        sut.push(.userDetail(id1))
        sut.push(.userDetail(id2))
        let popped = sut.pop()
        XCTAssertEqual(popped, .userDetail(id2))
        XCTAssertEqual(sut.path, [.userDetail(id1)])
    }

    func test_popToRoot_clearsAllRoutes() {
        let sut = AppCoordinator()
        sut.push(.userDetail(UUID()))
        sut.push(.userDetail(UUID()))
        sut.popToRoot()
        XCTAssertTrue(sut.path.isEmpty)
    }

    func test_handle_validDeepLink_setsPathToDetail() {
        let id = UUID()
        let url = URL(string: "myapp://users?id=\(id.uuidString)")!
        let sut = AppCoordinator()
        sut.handle(url)
        XCTAssertEqual(sut.path, [.userDetail(id)])
    }

    func test_handle_invalidDeepLink_doesNothing() {
        let url = URL(string: "myapp://users?id=not-a-uuid")!
        let sut = AppCoordinator()
        sut.handle(url)
        XCTAssertTrue(sut.path.isEmpty)
    }
}
