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

    public init(repository: UserRepository, id: User.ID) {
        self.repository = repository
        self.id = id
    }

    public func onAppear() async {
        guard user == nil else { return }
        do {
            let u = try await repository.fetchUser(id: id)
            user = u
            draftName = u.name
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    @discardableResult
    public func save() async -> User? {
        guard var u = user, canSave else { return nil }
        u.name = draftName
        state = .saving
        do {
            let saved = try await repository.update(u)
            user = saved
            draftName = saved.name
            state = .saved
            return saved
        } catch {
            state = .failed(error.localizedDescription)
            return nil
        }
    }
}
