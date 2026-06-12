import Foundation
import Observation

@Observable
@MainActor
public final class AppCoordinator {

    public var path: [AppRoute] = []

    public init() {}

    public func push(_ route: AppRoute) {
        path.append(route)
    }

    @discardableResult
    public func pop() -> AppRoute? {
        path.popLast()
    }

    public func popToRoot() {
        path.removeAll()
    }

    /// Deep-link entry point. Parses a URL into a sequence of routes and assigns.
    /// Real apps validate hosts/paths; kept small here for clarity.
    public func handle(_ url: URL) {
        guard url.host == "users",
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let idItem = components.queryItems?.first(where: { $0.name == "id" })?.value,
              let id = UUID(uuidString: idItem)
        else { return }
        path = [.userDetail(id)]
    }
}
