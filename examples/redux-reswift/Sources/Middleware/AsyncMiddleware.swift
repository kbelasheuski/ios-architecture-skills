import Foundation
import ReSwift

public func asyncMiddleware(repository: UserRepository) -> Middleware<AppState> {
    return { dispatch, getState in
        return { next in
            return { action in
                next(action)
                guard let app = action as? AppAction else { return }
                switch app {
                case .userList(.load(let kind)):
                    loadUsers(kind: kind, repository: repository, dispatch: dispatch, getState: getState)
                case .userDetail(.load(let id)):
                    loadUser(id: id, repository: repository, dispatch: dispatch)
                case .userDetail(.saveTapped):
                    saveUser(repository: repository, dispatch: dispatch, getState: getState)
                default:
                    break
                }
            }
        }
    }
}

private func loadUsers(
    kind: UserListAction.Loading,
    repository: UserRepository,
    dispatch: @escaping DispatchFunction,
    getState: @escaping () -> AppState?
) {
    let target: Int = {
        switch kind {
        case .fullScreen: return 1
        case .nextPage: return (getState()?.userList.page ?? 0) + 1
        }
    }()
    Task {
        do {
            let page = try await repository.fetchUsers(page: target)
            await MainActor.run { _ = dispatch(AppAction.userList(.loaded(page))) }
        } catch {
            await MainActor.run {
                _ = dispatch(AppAction.userList(.failed(error.localizedDescription)))
            }
        }
    }
}

private func loadUser(
    id: User.ID,
    repository: UserRepository,
    dispatch: @escaping DispatchFunction
) {
    Task {
        do {
            let user = try await repository.fetchUser(id: id)
            await MainActor.run { _ = dispatch(AppAction.userDetail(.loaded(user))) }
        } catch {
            await MainActor.run {
                _ = dispatch(AppAction.userDetail(.failed(error.localizedDescription)))
            }
        }
    }
}

private func saveUser(
    repository: UserRepository,
    dispatch: @escaping DispatchFunction,
    getState: @escaping () -> AppState?
) {
    guard let detail = getState()?.userDetail, let currentUser = detail.user else { return }
    var draft = currentUser
    draft.name = detail.draftName
    let userToSave = draft
    Task {
        do {
            let saved = try await repository.update(userToSave)
            await MainActor.run { _ = dispatch(AppAction.userDetail(.saved(saved))) }
        } catch {
            await MainActor.run {
                _ = dispatch(AppAction.userDetail(.failed(error.localizedDescription)))
            }
        }
    }
}
