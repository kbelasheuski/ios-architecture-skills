import ComposableArchitecture
import SwiftUI

public struct UserDetailView: View {
    @Bindable var store: StoreOf<UserDetailFeature>

    public init(store: StoreOf<UserDetailFeature>) {
        self.store = store
    }

    public var body: some View {
        Form {
            Section("Name") {
                TextField("Name", text: $store.draftName)
                    .disabled(store.isSaving)
            }
            Section("Email") {
                Text(store.user.email).foregroundStyle(.secondary)
            }
        }
        .navigationTitle(store.user.name)
        .navigationBarBackButtonHidden(store.isDirty)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                if store.isDirty {
                    Button("Cancel", role: .cancel) { store.send(.cancelTapped) }
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button {
                    store.send(.saveTapped)
                } label: {
                    if store.isSaving { ProgressView() } else { Text("Save") }
                }
                .disabled(!store.canSave)
            }
        }
        .alert(
            "Error",
            isPresented: Binding(
                get: { store.errorMessage != nil },
                set: { if !$0 { store.send(.errorDismissed) } }
            ),
            actions: { Button("OK", role: .cancel) {} },
            message: { Text(store.errorMessage ?? "") }
        )
    }
}
