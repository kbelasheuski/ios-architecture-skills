import Foundation
import ReSwift

@MainActor
public final class UserDetailObserver: ObservableObject, StoreSubscriber {
    @Published public var state: UserDetailState?

    public init() {}

    public func subscribe() {
        AppStore.shared.subscribe(self) { $0.select { $0.userDetail } }
    }
    public func unsubscribe() {
        AppStore.shared.unsubscribe(self)
    }

    public nonisolated func newState(state: UserDetailState?) {
        Task { @MainActor in self.state = state }
    }
}
