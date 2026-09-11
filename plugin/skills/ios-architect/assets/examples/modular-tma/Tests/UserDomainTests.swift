import XCTest
import Domain
import UserDomain

final class UserDomainTests: XCTestCase {

    func test_FetchUsersUseCase_clampsPage() async throws {
        let repo = FakeUserRepository(pages: [.fixture(users: [.fixture(name: "Ada")])])
        let sut = FetchUsersUseCaseLive(repository: repo)

        _ = try await sut(page: -3)

        XCTAssertEqual(repo.fetchPageCalls, [1])
    }

    func test_UpdateUserUseCase_rejectsEmptyName() async {
        let repo = FakeUserRepository()
        let sut = UpdateUserUseCaseLive(repository: repo)

        do {
            _ = try await sut(.fixture(name: "   "))
            XCTFail("expected validation error")
        } catch UpdateUserUseCaseLive.ValidationError.emptyName {
            // ok
        } catch {
            XCTFail("unexpected: \(error)")
        }
    }

    func test_UpdateUserUseCase_trimsAndPersists() async throws {
        let repo = FakeUserRepository()
        let sut = UpdateUserUseCaseLive(repository: repo)

        let saved = try await sut(.fixture(name: "  Ada  "))

        XCTAssertEqual(saved.name, "Ada")
        XCTAssertEqual(repo.updateCalls.first?.name, "Ada")
    }
}
