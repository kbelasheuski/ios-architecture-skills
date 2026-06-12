import SwiftUI
import Domain
import UserDomain
import UserDetailFeatureInterface

public struct UserDetailFeatureFactoryLive: UserDetailFeatureFactory {
    private let fetchUser: FetchUserUseCase
    private let updateUser: UpdateUserUseCase

    public init(fetchUser: FetchUserUseCase, updateUser: UpdateUserUseCase) {
        self.fetchUser = fetchUser
        self.updateUser = updateUser
    }

    @MainActor
    public func makeUserDetail(
        userID: User.ID,
        onSaved: @escaping @MainActor (User) -> Void
    ) -> AnyView {
        AnyView(
            UserDetailView(
                model: UserDetailModel(
                    fetchUser: fetchUser,
                    updateUser: updateUser,
                    id: userID,
                    onSaved: onSaved
                )
            )
        )
    }
}
