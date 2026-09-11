import UIKit

@MainActor
final class UserDetailRouter: UserDetailRouterProtocol {

    weak var viewController: UIViewController?

    func pop() {
        viewController?.navigationController?.popViewController(animated: true)
    }
}
