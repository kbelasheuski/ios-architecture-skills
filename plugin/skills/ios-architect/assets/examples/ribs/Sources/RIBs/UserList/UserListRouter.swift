import RIBs

public protocol UserListInteractable: Interactable, UserDetailListener {
    var router: UserListRouting? { get set }
    var listener: UserListListener? { get set }
}

public protocol UserListViewControllable: ViewControllable {}

public final class UserListRouter:
    ViewableRouter<UserListInteractable, UserListViewControllable>,
    UserListRouting {
    private let userDetailBuilder: UserDetailBuildable
    private var currentDetail: ViewableRouting?

    public init(
        interactor: UserListInteractable,
        viewController: UserListViewControllable,
        userDetailBuilder: UserDetailBuildable
    ) {
        self.userDetailBuilder = userDetailBuilder
        super.init(interactor: interactor, viewController: viewController)
        interactor.router = self
    }

    public func routeToDetail(userID: User.ID) {
        let detail = userDetailBuilder.build(withListener: interactor, userID: userID)
        attachChild(detail)
        currentDetail = detail
        viewController.uiviewController.navigationController?
            .pushViewController(detail.viewControllable.uiviewController, animated: true)
    }

    public func detachDetail() {
        guard let detail = currentDetail else { return }
        detachChild(detail)
        currentDetail = nil
        viewController.uiviewController.navigationController?.popViewController(animated: true)
    }
}
