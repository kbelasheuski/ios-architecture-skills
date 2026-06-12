import ComposableArchitecture
import SwiftUI

public struct UserListView: View {
    @Bindable var store: StoreOf<UserListFeature>

    public init(store: StoreOf<UserListFeature>) {
        self.store = store
    }

    public var body: some View {
        NavigationStack(path: $store.scope(state: \.path, action: \.path)) {
            List {
                ForEach(store.users) { user in
                    Button {
                        store.send(.rowTapped(user.id))
                    } label: {
                        VStack(alignment: .leading) {
                            Text(user.name).font(.headline)
                            Text(user.email).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    .buttonStyle(.plain)
                    .onAppear { store.send(.loadNextPageIfNeeded(user.id)) }
                }
                if store.isLoading && !store.users.isEmpty {
                    HStack { Spacer(); ProgressView(); Spacer() }
                }
            }
            .navigationTitle("Users")
            .refreshable { await store.send(.refresh).finish() }
            .task { store.send(.onAppear) }
            .alert(
                "Error",
                isPresented: Binding(
                    get: { store.errorMessage != nil },
                    set: { if !$0 { store.send(.errorDismissed) } }
                ),
                actions: { Button("OK", role: .cancel) {} },
                message: { Text(store.errorMessage ?? "") }
            )
        } destination: { store in
            UserDetailView(store: store)
        }
    }
}
