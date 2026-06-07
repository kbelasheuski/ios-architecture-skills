import SwiftUI

public struct UserDetailView: View {
    @State private var viewModel: UserDetailViewModel
    @Environment(\.dismiss) private var dismiss

    public init(viewModel: UserDetailViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    public var body: some View {
        Form {
            Section("Name") {
                TextField("Name", text: $viewModel.draftName)
                    .disabled(viewModel.isSaving)
            }
            Section("Email") {
                Text(viewModel.user?.email ?? "—").foregroundStyle(.secondary)
            }
            if let msg = viewModel.errorMessage {
                Section { Text(msg).foregroundStyle(.red) }
            }
        }
        .navigationTitle(viewModel.user?.name ?? "Loading…")
        .navigationBarBackButtonHidden(viewModel.isDirty)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                if viewModel.isDirty {
                    Button("Cancel", role: .cancel) { dismiss() }
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button {
                    Task {
                        if await viewModel.save() != nil { dismiss() }
                    }
                } label: {
                    if viewModel.isSaving { ProgressView() } else { Text("Save") }
                }
                .disabled(!viewModel.canSave)
            }
        }
        .task { await viewModel.task() }
    }
}
