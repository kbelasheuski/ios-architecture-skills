import Combine
import Foundation

@MainActor
public final class UserDetailModel: ObservableObject {

    public enum SaveState: Equatable {
        case idle, saving, saved, failed(String)
    }

    @Published public private(set) var user: User?
    @Published public var draftName: String = ""
    @Published public private(set) var state: SaveState = .idle
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
            return saved
        } catch {
            state = .failed(error.localizedDescription)
            return nil
        }
    }
}
