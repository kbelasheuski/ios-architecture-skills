import Foundation

@MainActor
public protocol UserDetailBusinessLogic: AnyObject {
    func load(_ request: UserDetail.Load.Request) async
    func save(_ request: UserDetail.Save.Request) async
}

@MainActor
public final class UserDetailInteractor: UserDetailBusinessLogic {

    public var presenter: UserDetailPresentationLogic!
    private let worker: UserDetailWorker
    private var user: User?

    public init(worker: UserDetailWorker) { self.worker = worker }

    public func load(_ request: UserDetail.Load.Request) async {
        do {
            let u = try await worker.fetch(id: request.id)
            self.user = u
            await presenter.presentLoad(.init(result: .success(u)))
        } catch {
            await presenter.presentLoad(.init(result: .failure(.init(message: error.localizedDescription))))
        }
    }

    public func save(_ request: UserDetail.Save.Request) async {
        guard var u = user else { return }
        u.name = request.name
        await presenter.presentSave(.init(result: .success(u)))   // saving status
        do {
            let saved = try await worker.update(u)
            self.user = saved
            await presenter.presentSave(.init(result: .success(saved)))
        } catch {
            await presenter.presentSave(.init(result: .failure(.init(message: error.localizedDescription))))
        }
    }
}
