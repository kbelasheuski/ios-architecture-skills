import SwiftUI

public struct UserListView<Detail: View>: View {

    @State private var store: UserListStore
    private let detail: (User) -> Detail

    public init(
        store: UserListStore,
        @ViewBuilder detail: @escaping (User) -> Detail
    ) {
        _store = State(initialValue: store)
        self.detail = detail
    }

    public var body: some View {
        List {
            ForEach(store.state.users) { user in
                NavigationLink {
                    detail(user)
                } label: {
                    UserRow(user: user)
                }
                .onAppear { Task { await store.dispatch(.loadNextPageIfNeeded(user)) } }
            }
            if store.state.loadState == .loading && !store.state.users.isEmpty {
                HStack { Spacer(); ProgressView(); Spacer() }
            }
        }
        .listStyle(.plain)
        .navigationTitle("Users")
        .refreshable { await store.dispatch(.refresh) }
        .task { await store.dispatch(.onAppear) }
        .overlay { emptyOverlay }
    }

    @ViewBuilder
    private var emptyOverlay: some View {
        if store.state.users.isEmpty {
            switch store.state.loadState {
            case .loading:
                ProgressView()
            case .loaded:
                ContentUnavailableView("No users", systemImage: "person.slash")
            case .failed(let msg):
                ContentUnavailableView {
                    Label("Failed to load", systemImage: "exclamationmark.triangle")
                } description: {
                    Text(msg)
                } actions: {
                    Button("Retry") { Task { await store.dispatch(.refresh) } }
                }
            case .idle:
                EmptyView()
            }
        }
    }
}

private struct UserRow: View {
    let user: User
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(user.name).font(.headline)
            Text(user.email).font(.caption).foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }
}
