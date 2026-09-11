import Foundation

@MainActor
public final class UserDetailPresenter: UserDetailPresenterProtocol {

    public weak var view: UserDetailViewProtocol?
    private let interactor: UserDetailInteractorProtocol
    private let router: UserDetailRouterProtocol
    private let id: User.ID

    private var user: User?
    private var draftName: String = ""
    private var isSaving = false
    private var isDirty: Bool { user?.name != draftName }
    private var canSave: Bool { isDirty && !draftName.isEmpty && !isSaving }

    public init(
        view: UserDetailViewProtocol,
        interactor: UserDetailInteractorProtocol,
        router: UserDetailRouterProtocol,
        id: User.ID
    ) {
        self.view = view
        self.interactor = interactor
        self.router = router
        self.id = id
    }

    public func viewDidLoad() async {
        do {
            let u = try await interactor.fetch(id: id)
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
            user = try await interactor.update(u)
            router.pop()
        } catch {
            view?.displayError(message: error.localizedDescription)
        }
    }
}
