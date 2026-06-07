import RIBs

public protocol UserListDependency: Dependency {
    var userRepository: UserRepository { get }
}

public final class UserListComponent: Component<UserListDependency>, UserDetailDependency {
    public var userRepository: UserRepository { dependency.userRepository }
}

public protocol UserListBuildable: Buildable {
    func build(withListener listener: UserListListener) -> UserListRouting
}

public final class UserListBuilder: Builder<UserListDependency>, UserListBuildable {

    public override init(dependency: UserListDependency) {
        super.init(dependency: dependency)
    }

    public func build(withListener listener: UserListListener) -> UserListRouting {
        let component = UserListComponent(dependency: dependency)
        let viewController = UserListViewController()
        let interactor = UserListInteractor(presenter: viewController, repository: component.userRepository)
        interactor.listener = listener
        let userDetailBuilder = UserDetailBuilder(dependency: component)
        return UserListRouter(
            interactor: interactor,
            viewController: viewController,
            userDetailBuilder: userDetailBuilder
        )
    }
}
