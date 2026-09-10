import ComposableArchitecture
import XCTest
@testable import TCAExample

@MainActor
final class UserDetailFeatureTests: XCTestCase {

    func test_save_emitsDelegateAndDismisses() async {
        let user = User.fixture(name: "Ada")
        let store = TestStore(initialState: UserDetailFeature.State(user: user)) {
            UserDetailFeature()
        } withDependencies: {
            $0.userClient.update = { user in user }
            $0.dismiss = DismissEffect { /* no-op for test */ }
        }

        await store.send(\.binding.draftName, "Ada Lovelace") { $0.draftName = "Ada Lovelace" }
        await store.send(.saveTapped) { $0.isSaving = true }
        await store.receive(\.saveResponse) {
            $0.isSaving = false
            $0.user.name = "Ada Lovelace"
            $0.draftName = "Ada Lovelace"
        }
        await store.receive(\.delegate.didSave)
    }

    func test_save_failure_setsErrorMessage() async {
        struct Boom: LocalizedError { var errorDescription: String? { "Boom" } }
        let user = User.fixture(name: "Ada")
        let store = TestStore(initialState: UserDetailFeature.State(user: user)) {
            UserDetailFeature()
        } withDependencies: {
            $0.userClient.update = { _ in throw Boom() }
        }

        await store.send(\.binding.draftName, "Ada Lovelace") { $0.draftName = "Ada Lovelace" }
        await store.send(.saveTapped) { $0.isSaving = true }
        await store.receive(\.saveResponse) {
            $0.isSaving = false
            $0.errorMessage = "Boom"
        }
    }
}
