import XCTest
@testable import CleanArchitectureExample

final class FetchUsersUseCaseTests: XCTestCase {

    func test_clampsPageToOne_andReturnsRepositoryPage() async throws {
        let repo = FakeUserRepository(pages: [.fixture(users: [.fixture(name: "Ada")])])
        let sut = DefaultFetchUsersUseCase(repository: repo)

        let page = try await sut.execute(page: -5)

        XCTAssertEqual(repo.fetchPageCalls, [1])
        XCTAssertEqual(page.users.first?.name, "Ada")
    }

    func test_passesPageThroughWhenPositive() async throws {
        let repo = FakeUserRepository(pages: [
            .fixture(users: [.fixture(name: "A")], page: 1, totalPages: 2),
            .fixture(users: [.fixture(name: "B")], page: 2, totalPages: 2)
        ])
        let sut = DefaultFetchUsersUseCase(repository: repo)

        _ = try await sut.execute(page: 2)

        XCTAssertEqual(repo.fetchPageCalls, [2])
    }
}

final class UpdateUserUseCaseTests: XCTestCase {

    func test_rejectsEmptyName() async {
        let repo = FakeUserRepository()
        let sut = DefaultUpdateUserUseCase(repository: repo)
        let user = User.fixture(name: "   ")
        do {
            _ = try await sut.execute(user)
            XCTFail("expected validation error")
        } catch DefaultUpdateUserUseCase.ValidationError.emptyName {
            // ok
        } catch {
            XCTFail("unexpected: \(error)")
        }
        XCTAssertTrue(repo.updateCalls.isEmpty)
    }

    func test_trimsWhitespace_andPersists() async throws {
        let repo = FakeUserRepository()
        let sut = DefaultUpdateUserUseCase(repository: repo)
        let user = User.fixture(name: "  Ada  ")

        let saved = try await sut.execute(user)

        XCTAssertEqual(saved.name, "Ada")
        XCTAssertEqual(repo.updateCalls.first?.name, "Ada")
    }
}
