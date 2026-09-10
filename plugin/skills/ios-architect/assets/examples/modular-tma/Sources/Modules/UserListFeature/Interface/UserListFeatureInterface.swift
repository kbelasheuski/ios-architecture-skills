import SwiftUI
import Domain

// Public API of the UserListFeature module.
// Siblings depend on this Interface only; the Sources target is opaque.

public protocol UserListFeatureFactory: Sendable {
    @MainActor
    func makeUserList(
        detail: @escaping @MainActor (User) -> AnyView
    ) -> AnyView
}
