import Foundation

@MainActor
public final class UserDetailPresenter: UserDetailPresenting {

    private weak var view: UserDetailView?
    private let repository: UserRepository
    private let id: User.ID
    private let onSaved: (User) -> Void

    private var user: User?
    private var draftName: String = ""
    private var isSaving = false
    private var isDirty: Bool { user?.name != draftName }
    private var canSave: Bool { isDirty && !draftName.isEmpty && !isSaving }

    public init(view: UserDetailView,
                repository: UserRepository,
                id: User.ID,
                onSaved: @escaping (User) -> Void) {
        self.view = view
        self.repository = repository
        self.id = id
        self.onSaved = onSaved
    }

    public func viewDidLoad() async {
        do {
            let u = try await repository.fetchUser(id: id)
            user = u
            draftName = u.name
            view?.display(name: u.name, email: u.email)
            view?.setSaveEnabled(false)
        } catch {
            view?.displayError(message: error.localizedDescription)
        }
    }

    public func didChangeName(_ name: String) {
        draftName = name
        view?.setSaveEnabled(canSave)
    }

    public func save() async {
        guard var u = user, canSave else { return }
        u.name = draftName
        isSaving = true
        view?.displaySaving(true)
        view?.setSaveEnabled(false)
        defer {
            isSaving = false
            view?.displaySaving(false)
            view?.setSaveEnabled(canSave)
        }
        do {
            let saved = try await repository.update(u)
            user = saved
            onSaved(saved)
            view?.dismiss()
        } catch {
            view?.displayError(message: error.localizedDescription)
        }
    }
}
