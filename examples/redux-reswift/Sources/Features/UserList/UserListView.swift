import SwiftUI
import ReSwift

public struct UserListView: View {
    @StateObject private var observer = UserListObserver()
    let onSelect: (User.ID) -> Void

    public init(onSelect: @escaping (User.ID) -> Void) {
        self.onSelect = onSelect
    }

    public var body: some View {
        List {
            ForEach(observer.state.users) { user in
                Button {
                    AppStore.shared.dispatch(AppAction.userList(.selected(user.id)))
                    onSelect(user.id)
                } label: {
                    VStack(alignment: .leading) {
                        Text(user.name).font(.headline)
                        Text(user.email).font(.caption).foregroundStyle(.secondary)
                    }
                }
                .buttonStyle(.plain)
                .onAppear {
                    let s = observer.state
                    if s.hasMore, s.loading == .none,
                       let idx = s.users.firstIndex(of: user),
                       idx >= max(s.users.count - 3, 0) {
                        AppStore.shared.dispatch(AppAction.userList(.load(.nextPage)))
                    }
                }
            }
            if observer.state.loading == .nextPage {
                HStack { Spacer(); ProgressView(); Spacer() }
            }
        }
        .navigationTitle("Users")
        .refreshable { AppStore.shared.dispatch(AppAction.userList(.load(.fullScreen))) }
        .task {
            observer.subscribe()
            AppStore.shared.dispatch(AppAction.userList(.load(.fullScreen)))
        }
        .onDisappear { observer.unsubscribe() }
        .alert(
            "Error",
            isPresented: Binding(
                get: { observer.state.errorMessage != nil },
                set: { if !$0 { AppStore.shared.dispatch(AppAction.userList(.errorDismissed)) } }
            ),
            actions: { Button("OK", role: .cancel) {} },
            message: { Text(observer.state.errorMessage ?? "") }
        )
    }
}
