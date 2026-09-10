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

    public func dispatch(_ intent: Intent) async {
        switch intent {
        case .onAppear:
            guard state.user == nil else { return }
            do {
                let fetchedUser = try await repository.fetchUser(id: id)
                state.user = fetchedUser
                state.draftName = fetchedUser.name
            } catch {
                state.saveState = .failed(error.localizedDescription)
            }
        case .draftNameChanged(let value):
            state.draftName = value
        case .save:
            await save()
        }
    }

    private func save() async {
        guard var updatedUser = state.user, state.canSave else { return }
        updatedUser.name = state.draftName
        state.saveState = .saving
        do {
            let saved = try await repository.update(updatedUser)
            state.user = saved
            state.draftName = saved.name
            state.saveState = .saved
        } catch {
            state.saveState = .failed(error.localizedDescription)
        }
    }
}
