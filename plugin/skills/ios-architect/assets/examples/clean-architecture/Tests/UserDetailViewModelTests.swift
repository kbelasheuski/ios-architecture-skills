import XCTest
@testable import CleanArchitectureExample

@MainActor
final class UserDetailViewModelTests: XCTestCase {

    func test_save_propagatesToOnSaved() async {
        let id = UUID()
        let user = User(id: id, name: "Ada", email: "ada@example.com")
        let repo = FakeUserRepository(pages: [.fixture(users: [user])])
        var captured: User?
        let sut = UserDetailViewModel(
            id: id,
            fetchUserUseCase: DefaultFetchUserUseCase(repository: repo),
            updateUserUseCase: DefaultUpdateUserUseCase(repository: repo),
            onSaved: { captured = $0 }
        )

        await sut.task()
        sut.draftName = "Ada Lovelace"
        let saved = await sut.save()

        XCTAssertEqual(saved?.name, "Ada Lovelace")
        XCTAssertEqual(captured?.name, "Ada Lovelace")
    }
}
