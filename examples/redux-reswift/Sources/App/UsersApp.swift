import SwiftUI

@main
struct UsersApp: App {
    @State private var path: [User.ID] = []

    var body: some Scene {
        WindowGroup {
            NavigationStack(path: $path) {
                UserListView(onSelect: { id in path.append(id) })
                    .navigationDestination(for: User.ID.self) { id in
                        UserDetailView(userID: id)
                    }
            }
        }
    }
}
