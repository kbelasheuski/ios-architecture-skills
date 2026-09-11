import Foundation

@MainActor
public final class UsersSceneDIContainer {
    private let repository: UserRepository

    public init(repository: UserRepository) {
        self.repository = repository
    }

    // MARK: Use cases
    private func makeFetchUsersUseCase() -> FetchUsersUseCase {
        DefaultFetchUsersUseCase(repository: repository)
    }
    private func makeFetchUserUseCase() -> FetchUserUseCase {
        DefaultFetchUserUseCase(repository: repository)
    }
    private func makeUpdateUserUseCase() -> UpdateUserUseCase {
        DefaultUpdateUserUseCase(repository: repository)
    }

    // MARK: View models
    public func makeUserListViewModel(actions: UserListActions) -> UserListViewModel {
        UserListViewModel(
            fetchUsersUseCase: makeFetchUsersUseCase(),
            actions: actions
        )
    }

    public func makeUserDetailViewModel(
        id: User.ID,
        onSaved: @escaping @MainActor (User) -> Void
    ) -> UserDetailViewModel {
        UserDetailViewModel(
            id: id,
            fetchUserUseCase: makeFetchUserUseCase(),
            updateUserUseCase: makeUpdateUserUseCase(),
            onSaved: onSaved
        )
    }
}
