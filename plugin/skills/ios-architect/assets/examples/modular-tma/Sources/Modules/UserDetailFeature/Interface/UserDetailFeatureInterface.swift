import SwiftUI
import Domain

public protocol UserDetailFeatureFactory: Sendable {
    @MainActor
    func makeUserDetail(
        userID: User.ID,
        onSaved: @escaping @MainActor (User) -> Void
    ) -> AnyView
}
