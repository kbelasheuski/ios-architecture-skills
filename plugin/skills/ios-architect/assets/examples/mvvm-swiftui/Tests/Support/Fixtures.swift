import Foundation
@testable import MVVMSwiftUIExample

public extension User {
    static func fixture(
        id: UUID = UUID(),
        name: String = "Ada Lovelace",
        email: String = "ada@example.com"
    ) -> User {
        User(id: id, name: name, email: email)
    }
}

public extension UsersPage {
    static func fixture(
        users: [User] = [.fixture()],
        page: Int = 1,
        totalPages: Int = 1
    ) -> UsersPage {
        UsersPage(users: users, page: page, totalPages: totalPages)
    }
}
