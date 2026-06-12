import UIKit

@MainActor
public protocol UserDetailRoutingLogic { func pop() }

@MainActor
final class UserDetailRouter: UserDetailRoutingLogic {
    weak var viewController: UIViewController?
    func pop() { viewController?.navigationController?.popViewController(animated: true) }
}
