import SwiftUI

public struct UserListView: View {

    @State private var model: UserListModel

    public init(model: UserListModel) {
        _model = State(initialValue: model)
    }

    public var body: some View {
        List {
            ForEach(model.users) { user in
                Button {
                    model.didSelect(user.id)
                } label: {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(user.name).font(.headline)
                        Text(user.email).font(.caption).foregroundStyle(.secondary)
                    }
                }
                .buttonStyle(.plain)
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
    }
}
