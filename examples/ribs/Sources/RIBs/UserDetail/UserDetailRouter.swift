import RIBs

public protocol UserDetailInteractable: Interactable {
    var router: UserDetailRouting? { get set }
    var listener: UserDetailListener? { get set }
}

public protocol UserDetailViewControllable: ViewControllable {}

public protocol UserDetailRouting: ViewableRouting {}

public final class UserDetailRouter:
    ViewableRouter<UserDetailInteractable, UserDetailViewControllable>,
    UserDetailRouting {
    public override init(
        interactor: UserDetailInteractable,
        viewController: UserDetailViewControllable
    ) {
        super.init(interactor: interactor, viewController: viewController)
        interactor.router = self
    }
}
