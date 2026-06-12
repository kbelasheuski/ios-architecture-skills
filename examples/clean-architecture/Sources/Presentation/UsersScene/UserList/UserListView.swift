import SwiftUI

public struct UserListView: View {
    @State private var viewModel: UserListViewModel

    public init(viewModel: UserListViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    public var body: some View {
        List {
            ForEach(viewModel.users) { user in
                Button {
                    viewModel.didSelectUser(at: user.id)
                } label: {
                    VStack(alignment: .leading) {
                        Text(user.name).font(.headline)
                        Text(user.email).font(.caption).foregroundStyle(.secondary)
                    }
                }
                .buttonStyle(.plain)
                .onAppear { viewModel.didLoadNextPageIfNeeded(currentUser: user) }
            }
            if viewModel.loading == .nextPage {
                HStack { Spacer(); ProgressView(); Spacer() }
            }
        }
        .navigationTitle(viewModel.screenTitle)
        .refreshable { await viewModel.didPullToRefresh() }
        .task { await viewModel.viewDidLoad() }
        .overlay {
            if viewModel.users.isEmpty && viewModel.loading == .fullScreen {
                ProgressView()
            }
        }
        .alert(
            "Error",
            isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorDismissed() } }
            ),
            actions: { Button("OK", role: .cancel) {} },
            message: { Text(viewModel.errorMessage ?? "") }
        )
    }
}
