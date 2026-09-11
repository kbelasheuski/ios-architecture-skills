import SwiftUI
import ReSwift

public struct UserDetailView: View {
    let userID: User.ID
    @StateObject private var observer = UserDetailObserver()

    public init(userID: User.ID) {
        self.userID = userID
    }

    public var body: some View {
        Form {
            Section("Name") {
                TextField("Name", text: Binding(
                    get: { observer.state?.draftName ?? "" },
                    set: { AppStore.shared.dispatch(AppAction.userDetail(.nameChanged($0))) }
                ))
                .disabled(observer.state?.isSaving == true)
            }
            Section("Email") {
                Text(observer.state?.user?.email ?? "—").foregroundStyle(.secondary)
            }
        }
        .navigationTitle(observer.state?.user?.name ?? "Loading…")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button {
                    AppStore.shared.dispatch(AppAction.userDetail(.saveTapped))
                } label: {
                    if observer.state?.isSaving == true { ProgressView() } else { Text("Save") }
                }
                .disabled(!(observer.state?.canSave ?? false))
            }
        }
        .task {
            observer.subscribe()
            AppStore.shared.dispatch(AppAction.userDetail(.load(userID)))
        }
        .onDisappear {
            observer.unsubscribe()
            AppStore.shared.dispatch(AppAction.userDetail(.dismissed))
        }
    }
}
