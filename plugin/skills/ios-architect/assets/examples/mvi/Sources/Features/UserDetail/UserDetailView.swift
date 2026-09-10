import SwiftUI

public struct UserDetailView: View {

    @State private var store: UserDetailStore
    @Environment(\.dismiss) private var dismiss

    public init(store: UserDetailStore) {
        _store = State(initialValue: store)
    }

    public var body: some View {
        Form {
            Section("Name") {
                TextField("Name", text: Binding(
                    get: { store.state.draftName },
                    set: { value in Task { await store.dispatch(.draftNameChanged(value)) } }
                ))
                    .textInputAutocapitalization(.words)
                    .disabled(store.state.saveState == .saving)
            }
            Section("Email") {
                Text(store.state.user?.email ?? "—").foregroundStyle(.secondary)
            }
            if case .failed(let msg) = store.state.saveState {
                Section { Text(msg).foregroundStyle(.red) }
            }
        }
        .navigationTitle(store.state.user?.name ?? "Loading…")
        .navigationBarBackButtonHidden(store.state.isDirty)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                if store.state.isDirty {
                    Button("Cancel", role: .cancel) { dismiss() }
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button {
                    Task {
                        await store.dispatch(.save)
                        if store.state.saveState == .saved { dismiss() }
                    }
                } label: {
                    if store.state.saveState == .saving {
                        ProgressView()
                    } else {
                        Text("Save")
                    }
                }
                .disabled(!store.state.canSave)
            }
        }
        .task { await store.dispatch(.onAppear) }
    }
}
