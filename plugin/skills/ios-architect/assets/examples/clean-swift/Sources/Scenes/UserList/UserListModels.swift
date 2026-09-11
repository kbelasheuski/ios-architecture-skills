import Foundation

public enum UserList {

    public enum FetchUsers {
        public struct Request: Equatable {
            public let reset: Bool

            public init(reset: Bool) {
                self.reset = reset
            }
        }
        public struct Response: Equatable {
            public let users: [User]
            public let loading: ViewModel.Loading
            public let errorMessage: String?

            public init(users: [User], loading: ViewModel.Loading, errorMessage: String?) {
                self.users = users
                self.loading = loading
                self.errorMessage = errorMessage
            }
        }
        public struct ViewModel: Equatable {
            public struct Row: Equatable {
                public let id: User.ID
                public let title: String
                public let subtitle: String
            }
            public enum Loading: Equatable { case none, fullScreen, nextPage }
            public let rows: [Row]
            public let loading: Loading
            public let errorMessage: String?
        }
    }

    public enum SelectRow {
        public struct Request: Equatable {
            public let index: Int
        }
    }
}
