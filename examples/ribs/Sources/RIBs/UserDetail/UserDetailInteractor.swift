import RIBs
import RxSwift

public protocol UserDetailPresentable: Presentable {
    var listener: UserDetailPresentableListener? { get set }
    func display(name: String, email: String)
    func display(saving: Bool)
    func setSaveEnabled(_ enabled: Bool)
    func displayError(_ message: String)
}

public protocol UserDetailPresentableListener: AnyObject {
    func didChangeName(_ name: String)
    func save()
}

public final class UserDetailInteractor:
    PresentableInteractor<UserDetailPresentable>,
    UserDetailInteractable,
    UserDetailPresentableListener {
    public weak var router: UserDetailRouting?
    public weak var listener: UserDetailListener?

    private let repository: UserRepository
    private let userID: User.ID
    private var user: User?
    private var draftName: String = ""
    private var isSaving = false
    private let disposeBag = DisposeBag()

    public init(
        presenter: UserDetailPresentable,
        repository: UserRepository,
        userID: User.ID
    ) {
        self.repository = repository
        self.userID = userID
        super.init(presenter: presenter)
        presenter.listener = self
    }

    public override func didBecomeActive() {
        super.didBecomeActive()
        load()
    }

    private func load() {
        Single.fromAsync { [repository, userID] in
            try await repository.fetchUser(id: userID)
        }
        .observe(on: MainScheduler.instance)
        .subscribe(
            onSuccess: { [weak self] u in
                guard let self else { return }
                self.user = u
                self.draftName = u.name
                self.presenter.display(name: u.name, email: u.email)
                self.presenter.setSaveEnabled(false)
            },
            onFailure: { [weak self] error in
                self?.presenter.displayError(error.localizedDescription)
            }
        )
        .disposed(by: disposeBag)
    }

    public func didChangeName(_ name: String) {
        draftName = name
        let dirty = user?.name != draftName
        let nonEmpty = !draftName.isEmpty
        presenter.setSaveEnabled(dirty && nonEmpty && !isSaving)
    }

    public func save() {
        guard var u = user, u.name != draftName, !draftName.isEmpty, !isSaving else { return }
        u.name = draftName
        isSaving = true
        presenter.display(saving: true)
        presenter.setSaveEnabled(false)
        Single.fromAsync { [repository] in
            try await repository.update(u)
        }
        .observe(on: MainScheduler.instance)
        .subscribe(
            onSuccess: { [weak self] saved in
                guard let self else { return }
                self.user = saved
                self.isSaving = false
                self.presenter.display(saving: false)
                self.listener?.userDetailDidFinish()
            },
            onFailure: { [weak self] error in
                guard let self else { return }
                self.isSaving = false
                self.presenter.display(saving: false)
                self.presenter.displayError(error.localizedDescription)
                self.presenter.setSaveEnabled(true)
            }
        )
        .disposed(by: disposeBag)
    }
}
