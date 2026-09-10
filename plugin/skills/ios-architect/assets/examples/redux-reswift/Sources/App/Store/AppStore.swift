import Foundation
import ReSwift

@MainActor
public enum AppStore {
    public static let shared: Store<AppState> = {
        let repo: UserRepository = LiveUserRepository(baseURL: URL(string: "https://api.example.com")!)
        return Store(reducer: appReducer, state: nil, middleware: [asyncMiddleware(repository: repo)])
    }()
}
