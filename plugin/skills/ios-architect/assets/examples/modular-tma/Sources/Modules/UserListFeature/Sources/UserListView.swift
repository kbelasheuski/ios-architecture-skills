import SwiftUI
import Domain

struct UserListView: View {
    @State private var model: UserListModel
    let detail: @MainActor (User) -> AnyView

    init(
        model: UserListModel,
        detail: @escaping @MainActor (User) -> AnyView
    ) {
        _model = State(initialValue: model)
        self.detail = detail
    }

    var body: some View {
        List {
            ForEach(model.users) { user in
                NavigationLink { detail(user) } label: {
                    VStack(alignment: .leading) {
                        Text(user.name).font(.headline)
                        Text(user.email).font(.caption).foregroundStyle(.secondary)
                    }
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
    }
}
