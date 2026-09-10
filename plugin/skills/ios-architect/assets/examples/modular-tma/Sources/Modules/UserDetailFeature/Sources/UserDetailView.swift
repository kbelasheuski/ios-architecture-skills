import SwiftUI
import Domain

struct UserDetailView: View {
    @State private var model: UserDetailModel
    @Environment(\.dismiss) private var dismiss

    init(model: UserDetailModel) {
        _model = State(initialValue: model)
    }

    var body: some View {
        Form {
            Section("Name") {
                TextField("Name", text: $model.draftName)
                    .disabled(model.state == .saving)
            }
            Section("Email") {
                Text(model.user?.email ?? "—").foregroundStyle(.secondary)
            }
        }
        .navigationTitle(model.user?.name ?? "Loading…")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button {
                    Task { if await model.save() != nil { dismiss() } }
                } label: {
                    if model.state == .saving { ProgressView() } else { Text("Save") }
                }
                .disabled(!model.canSave)
            }
        }
        .task { await model.onAppear() }
    }
}
