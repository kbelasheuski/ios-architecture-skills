import Foundation
import Observation
import Domain
import UserDomain

@Observable
@MainActor
final class UserDetailModel {

    enum SaveState: Equatable { case idle, saving, saved, failed(String) }

    private(set) var user: User?
    var draftName: String = ""
    private(set) var state: SaveState = .idle
    let id: User.ID

    var isDirty: Bool { user?.name != draftName }
    var canSave: Bool { isDirty && !draftName.isEmpty && state != .saving }

    private let fetchUser: FetchUserUseCase
    private let updateUser: UpdateUserUseCase
    private let onSaved: @MainActor (User) -> Void

    init(
        fetchUser: FetchUserUseCase,
        updateUser: UpdateUserUseCase,
        id: User.ID,
        onSaved: @escaping @MainActor (User) -> Void
    ) {
        self.fetchUser = fetchUser
        self.updateUser = updateUser
        self.id = id
        self.onSaved = onSaved
    }

    func onAppear() async {
        guard user == nil else { return }
        do {
            let fetchedUser = try await fetchUser(id: id)
            user = fetchedUser
            draftName = fetchedUser.name
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    @discardableResult
    func save() async -> User? {
        guard var updatedUser = user, canSave else { return nil }
        updatedUser.name = draftName
        state = .saving
        do {
            let saved = try await updateUser(updatedUser)
            user = saved
            draftName = saved.name
            state = .saved
            onSaved(saved)
            return saved
        } catch {
            state = .failed(error.localizedDescription)
            return nil
        }
    }
}
