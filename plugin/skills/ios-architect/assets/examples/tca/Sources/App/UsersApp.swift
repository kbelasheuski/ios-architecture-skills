import ComposableArchitecture
import SwiftUI

@main
struct UsersApp: App {
    static let store = Store(initialState: UserListFeature.State()) {
        UserListFeature()
    }

    var body: some Scene {
        WindowGroup {
            UserListView(store: Self.store)
        }
    }
}
