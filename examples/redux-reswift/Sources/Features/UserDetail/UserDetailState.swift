import Foundation

public struct UserDetailState: Equatable, Sendable {
    public var user: User?
    public var draftName: String = ""
    public var isSaving: Bool = false
    public var errorMessage: String?

    public var isDirty: Bool { user?.name != draftName }
    public var canSave: Bool { isDirty && !draftName.isEmpty && !isSaving }

    public init(
        user: User? = nil,
        draftName: String = "",
        isSaving: Bool = false,
        errorMessage: String? = nil
    ) {
        self.user = user
        self.draftName = draftName
        self.isSaving = isSaving
        self.errorMessage = errorMessage
    }
}
