import RIBs

public protocol UserDetailDependency: Dependency {
    var userRepository: UserRepository { get }
}

public final class UserDetailComponent: Component<UserDetailDependency> {
    public let userID: User.ID
    public init(dependency: UserDetailDependency, userID: User.ID) {
        self.userID = userID
        super.init(dependency: dependency)
    }
    public var userRepository: UserRepository { dependency.userRepository }
}

public protocol UserDetailListener: AnyObject {
    func userDetailDidFinish()
}

public protocol UserDetailBuildable: Buildable {
    func build(withListener listener: UserDetailListener, userID: User.ID) -> ViewableRouting
}

public final class UserDetailBuilder: Builder<UserDetailDependency>, UserDetailBuildable {

    public override init(dependency: UserDetailDependency) {
        super.init(dependency: dependency)
    }

    public func build(withListener listener: UserDetailListener, userID: User.ID) -> ViewableRouting {
        let component = UserDetailComponent(dependency: dependency, userID: userID)
        let viewController = UserDetailViewController()
        let interactor = UserDetailInteractor(
            presenter: viewController,
            repository: component.userRepository,
            userID: userID
        )
        interactor.listener = listener
        return UserDetailRouter(interactor: interactor, viewController: viewController)
    }
}
