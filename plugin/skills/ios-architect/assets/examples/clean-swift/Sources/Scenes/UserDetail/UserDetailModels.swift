import Foundation

public enum UserDetail {

    public enum Load {
        public struct Request: Equatable { public let id: User.ID }
        public struct Response: Equatable {
            public let result: Result<User, ErrorBox>
        }
        public struct ViewModel: Equatable {
            public let name: String
            public let email: String
            public let errorMessage: String?
        }
    }

    public enum Save {
        public struct Request: Equatable { public let name: String }
        public struct Response: Equatable {
            public let result: Result<User, ErrorBox>
        }
        public struct ViewModel: Equatable {
            public enum Status: Equatable { case idle, saving, saved, failed(String) }
            public let status: Status
        }
    }

    public struct ErrorBox: Error, Equatable {
        public let message: String
    }
}
