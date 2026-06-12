import Foundation

@MainActor
public protocol UserDetailPresentationLogic: AnyObject {
    func presentLoad(_ response: UserDetail.Load.Response) async
    func presentSave(_ response: UserDetail.Save.Response) async
}

@MainActor
public final class UserDetailPresenter: UserDetailPresentationLogic {

    public weak var view: UserDetailDisplayLogic?
    private var emittedSavingForCurrentSave = false

    public init() {}

    public func presentLoad(_ response: UserDetail.Load.Response) async {
        switch response.result {
        case .success(let u):
            view?.displayLoad(.init(name: u.name, email: u.email, errorMessage: nil))
        case .failure(let box):
            view?.displayLoad(.init(name: "", email: "", errorMessage: box.message))
        }
    }

    public func presentSave(_ response: UserDetail.Save.Response) async {
        if !emittedSavingForCurrentSave {
            view?.displaySave(.init(status: .saving))
            emittedSavingForCurrentSave = true
            return
        }
        switch response.result {
        case .success:
            view?.displaySave(.init(status: .saved))
        case .failure(let box):
            view?.displaySave(.init(status: .failed(box.message)))
        }
        emittedSavingForCurrentSave = false
    }
}
