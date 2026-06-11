import Foundation
import Observation

@Observable
@MainActor
public final class UserDetailViewModel {

    public private(set) var user: User?
    public var draftName: String = ""
    public private(set) var isSaving: Bool = false
    public var errorMessage: String?

    public var isDirty: Bool { user?.name != draftName }
    public var canSave: Bool { isDirty && !draftName.isEmpty && !isSaving }

    private let id: User.ID
    private let fetchUserUseCase: FetchUserUseCase
    private let updateUserUseCase: UpdateUserUseCase
    private let onSaved: @MainActor (User) -> Void

    public init(
        id: User.ID,
        fetchUserUseCase: FetchUserUseCase,
        updateUserUseCase: UpdateUserUseCase,
        onSaved: @escaping @MainActor (User) -> Void = { _ in }
    ) {
        self.id = id
        self.fetchUserUseCase = fetchUserUseCase
        self.updateUserUseCase = updateUserUseCase
        self.onSaved = onSaved
    }

    public func task() async {
        guard user == nil else { return }
        do {
            let u = try await fetchUserUseCase.execute(id: id)
            user = u
            draftName = u.name
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @discardableResult
    public func save() async -> User? {
        guard var u = user, canSave else { return nil }
        u.name = draftName
        isSaving = true
        defer { isSaving = false }
        do {
            let saved = try await updateUserUseCase.execute(u)
            user = saved
            draftName = saved.name
            onSaved(saved)
            return saved
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }
}
