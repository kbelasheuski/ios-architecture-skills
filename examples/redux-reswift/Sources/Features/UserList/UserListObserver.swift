import Foundation
import ReSwift

@MainActor
public final class UserListObserver: ObservableObject, StoreSubscriber {
    @Published public var state: UserListState = .init()

    public init() {}

    public func subscribe() {
        AppStore.shared.subscribe(self) { $0.select { $0.userList } }
    }
    public func unsubscribe() {
        AppStore.shared.unsubscribe(self)
    }

    public nonisolated func newState(state: UserListState) {
        Task { @MainActor in self.state = state }
    }
}
