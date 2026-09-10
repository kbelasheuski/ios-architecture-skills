import Foundation
import Observation

@Observable
@MainActor
public final class UserDetailModel {

    public enum SaveState: Equatable {
        case idle, saving, saved, failed(String)
    }

    public private(set) var user: User?
    public var draftName: String = ""
    public private(set) var state: SaveState = .idle
    public let id: User.ID

    public var isDirty: Bool { user?.name != draftName }
    public var canSave: Bool { isDirty && !draftName.isEmpty && state != .saving }

    private let repository: UserRepository
    private let onSaved: @MainActor (User) -> Void

    public init(
        repository: UserRepository,
        id: User.ID,
        onSaved: @escaping @MainActor (User) -> Void = { _ in }
    ) {
        self.repository = repository
        self.id = id
        self.onSaved = onSaved
    }

    public func onAppear() async {
        guard user == nil else { return }
        do {
            let fetchedUser = try await repository.fetchUser(id: id)
            user = fetchedUser
            draftName = fetchedUser.name
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    @discardableResult
    public func save() async -> User? {
        guard var updatedUser = user, canSave else { return nil }
        updatedUser.name = draftName
        state = .saving
        do {
            let saved = try await repository.update(updatedUser)
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
