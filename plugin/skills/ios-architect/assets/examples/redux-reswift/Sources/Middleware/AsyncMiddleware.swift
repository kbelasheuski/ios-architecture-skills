import Foundation
import ReSwift

public func asyncMiddleware(repository: UserRepository) -> Middleware<AppState> {
    return { dispatch, getState in
        return { next in
            return { action in
                next(action)
                guard let appAction = action as? AppAction else { return }
                handle(appAction, repository: repository, dispatch: dispatch, getState: getState)
            }
        }
    }
}

private func handle(
    _ action: AppAction,
    repository: UserRepository,
    dispatch: @escaping DispatchFunction,
    getState: @escaping () -> AppState?
) {
    switch action {

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

private func loadUsers(
    kind: UserListAction.Loading,
    repository: UserRepository,
    dispatch: @escaping DispatchFunction,
    getState: @escaping () -> AppState?
) {
    let target = pageToLoad(for: kind, getState: getState)
    let requestID = UUID()
    _ = dispatch(AppAction.userList(.loadStarted(kind, requestID: requestID)))
    Task {
        do {
            let page = try await repository.fetchUsers(page: target)
            await MainActor.run {
                _ = dispatch(AppAction.userList(.loaded(page, requestID: requestID)))
            }
        } catch {
            await failUserList(error, requestID: requestID, dispatch: dispatch)
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
            await failUserDetail(error, dispatch: dispatch)
        }
    }
}

private func saveUser(
    repository: UserRepository,
    dispatch: @escaping DispatchFunction,
    getState: @escaping () -> AppState?
) {
    guard let detail = getState()?.userDetail, let user = detail.user else { return }
    var draft = user
    draft.name = detail.draftName
    Task {
        do {
            let saved = try await repository.update(draft)
            await MainActor.run { _ = dispatch(AppAction.userDetail(.saved(saved))) }
        } catch {
            await failUserDetail(error, dispatch: dispatch)
        }
    }
}

private func pageToLoad(
    for kind: UserListAction.Loading,
    getState: () -> AppState?
) -> Int {
    switch kind {
    case .fullScreen:
        return 1
    case .nextPage:
        return (getState()?.userList.page ?? 0) + 1
    }
}

@MainActor
private func failUserList(
    _ error: Error,
    requestID: UUID,
    dispatch: DispatchFunction
) {
    _ = dispatch(AppAction.userList(.failed(error.localizedDescription, requestID: requestID)))
}

@MainActor
private func failUserDetail(_ error: Error, dispatch: DispatchFunction) {
    _ = dispatch(AppAction.userDetail(.failed(error.localizedDescription)))
}
