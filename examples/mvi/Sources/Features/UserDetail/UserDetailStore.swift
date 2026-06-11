import Foundation
import Observation

@Observable
@MainActor
public final class UserDetailStore {

    public enum SaveState: Equatable {
        case idle, saving, saved, failed(String)
    }

    public struct State: Equatable {
        public var user: User?
        public var draftName = ""
        public var saveState: SaveState = .idle

        public var isDirty: Bool { user?.name != draftName }
        public var canSave: Bool { isDirty && !draftName.isEmpty && saveState != .saving }
    }

    public enum Intent: Equatable {
        case onAppear
        case draftNameChanged(String)
        case save
    }

    public private(set) var state: State
    public let id: User.ID

    private let repository: UserRepository

    public init(repository: UserRepository, id: User.ID) {
        self.repository = repository
        self.id = id
        self.state = State()
    }

    @discardableResult
    public func dispatch(_ intent: Intent) async -> User? {
        switch intent {
        case .onAppear:
            guard state.user == nil else { return nil }
            do {
                let fetchedUser = try await repository.fetchUser(id: id)
                state.user = fetchedUser
                state.draftName = fetchedUser.name
            } catch {
                state.saveState = .failed(error.localizedDescription)
            }
            return nil
        case .draftNameChanged(let value):
            state.draftName = value
            return nil
        case .save:
            return await save()
        }
    }

    private func save() async -> User? {
        guard var updatedUser = state.user, state.canSave else { return nil }
        updatedUser.name = state.draftName
        state.saveState = .saving
        do {
            let saved = try await repository.update(updatedUser)
            state.user = saved
            state.draftName = saved.name
            state.saveState = .saved
            return saved
        } catch {
            state.saveState = .failed(error.localizedDescription)
            return nil
        }
    }
}
