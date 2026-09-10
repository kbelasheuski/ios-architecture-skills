import SwiftUI

public struct UserDetailView: View {

    @StateObject private var model: UserDetailModel
    @Environment(\.dismiss) private var dismiss

    public init(model: UserDetailModel) {
        _model = StateObject(wrappedValue: model)
    }

    public var body: some View {
        Form {
            Section("Name") {
                TextField("Name", text: $model.draftName)
                    .textInputAutocapitalization(.words)
                    .disabled(model.state == .saving)
            }
            Section("Email") {
                Text(model.user?.email ?? "—").foregroundStyle(.secondary)
            }
            if case .failed(let msg) = model.state {
                Section { Text(msg).foregroundStyle(.red) }
            }
        }
        .navigationTitle(model.user?.name ?? "Loading…")
        .navigationBarBackButtonHidden(model.isDirty)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                if model.isDirty {
                    Button("Cancel", role: .cancel) { dismiss() }
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button {
                    Task {
                        if await model.save() != nil { dismiss() }
                    }
                } label: {
                    if model.state == .saving {
                        ProgressView()
                    } else {
                        Text("Save")
                    }
                }
                .disabled(!model.canSave)
            }
        }
        .task { await model.onAppear() }
    }
}
