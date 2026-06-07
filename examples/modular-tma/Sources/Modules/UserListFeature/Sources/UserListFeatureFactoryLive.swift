import SwiftUI
import Domain
import UserDomain
import UserListFeatureInterface

public struct UserListFeatureFactoryLive: UserListFeatureFactory {
    private let fetchUsers: FetchUsersUseCase

    public init(fetchUsers: FetchUsersUseCase) {
        self.fetchUsers = fetchUsers
    }

    @MainActor
    public func makeUserList(
        detail: @escaping @MainActor (User) -> AnyView
    ) -> AnyView {
        AnyView(
            UserListView(
                model: UserListModel(fetchUsers: fetchUsers),
                detail: detail
            )
        )
    }
}
