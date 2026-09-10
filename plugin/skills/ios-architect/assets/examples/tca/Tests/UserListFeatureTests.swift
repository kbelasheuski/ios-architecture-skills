import ComposableArchitecture
import XCTest
@testable import TCAExample

@MainActor
final class UserListFeatureTests: XCTestCase {

    func test_onAppear_loadsFirstPage() async {
        let ada = User.fixture(name: "Ada")
        let store = TestStore(initialState: UserListFeature.State()) {
            UserListFeature()
        } withDependencies: {
            $0.userClient.fetchUsers = { _ in .fixture(users: [ada]) }
        }

        await store.send(.onAppear) { $0.isLoading = true }
        await store.receive(\.pageResponse) {
            $0.isLoading = false
            $0.users = [ada]
            $0.page = 1
            $0.totalPages = 1
        }
    }

    func test_loadNextPage_appendsBelowThreshold() async {
        let page1Users = (0..<10).map { User.fixture(name: "U\($0)") }
        let page2Users = [User.fixture(name: "U10")]
        let store = TestStore(
            initialState: UserListFeature.State(
                users: IdentifiedArray(uniqueElements: page1Users),
                page: 1,
                totalPages: 2
            )
        ) { UserListFeature() } withDependencies: {
            $0.userClient.fetchUsers = { _ in
                .init(users: page2Users, page: 2, totalPages: 2)
            }
        }

        let triggerID = page1Users[7].id
        await store.send(.loadNextPageIfNeeded(triggerID)) { $0.isLoading = true }
        await store.receive(\.pageResponse) {
            $0.isLoading = false
            $0.users.append(contentsOf: page2Users)
            $0.page = 2
        }
    }
}
