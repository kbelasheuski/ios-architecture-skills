import Combine
import Foundation

@MainActor
public final class UserDetailViewModel {

    @Published public private(set) var user: User?
    @Published public var draftName: String = ""
    @Published public private(set) var isSaving = false
    @Published public var errorMessage: String?

    public let didSave = PassthroughSubject<User, Never>()

    public var isDirty: Bool { user?.name != draftName }
    public var canSave: Bool { isDirty && !draftName.isEmpty && !isSaving }

    private let repository: UserRepository
    private let id: User.ID

    public init(repository: UserRepository, id: User.ID) {
        self.repository = repository
        self.id = id
    }

    public func onAppear() {
        guard user == nil else { return }
        Task { [weak self] in
            guard let self else { return }
            do {
                let fetchedUser = try await repository.fetchUser(id: id)
                user = fetchedUser
                draftName = fetchedUser.name
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    public func save() {
        guard var updatedUser = user, canSave else { return }
        updatedUser.name = draftName
        isSaving = true
        Task { [weak self] in
            guard let self else { return }
            do {
                let saved = try await repository.update(updatedUser)
                user = saved
                draftName = saved.name
                didSave.send(saved)
            } catch {
                errorMessage = error.localizedDescription
            }
            isSaving = false
        }
    }
}
