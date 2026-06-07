import SwiftUI

public struct UserListView<Detail: View>: View {

    @State private var model: UserListModel
    private let detail: (User) -> Detail

    public init(
        model: UserListModel,
        @ViewBuilder detail: @escaping (User) -> Detail
    ) {
        _model = State(initialValue: model)
        self.detail = detail
    }

    public var body: some View {
        List {
            ForEach(model.users) { user in
                NavigationLink {
                    detail(user)
                } label: {
                    UserRow(user: user)
                }
                .onAppear { model.loadNextPageIfNeeded(currentItem: user) }
            }
            if model.state == .loading && !model.users.isEmpty {
                HStack { Spacer(); ProgressView(); Spacer() }
            }
        }
        .listStyle(.plain)
        .navigationTitle("Users")
        .refreshable { await model.refresh() }
        .task { await model.onAppear() }
        .overlay { emptyOverlay }
    }

    @ViewBuilder
    private var emptyOverlay: some View {
        if model.users.isEmpty {
            switch model.state {
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
                    Button("Retry") { Task { await model.refresh() } }
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
