import Foundation

nonisolated struct GoogleManagerState: Equatable, Sendable {
    nonisolated enum Phase: Equatable, Sendable {
        case idle
        case restoringSession
        case authorizing
        case signingOut
        case creatingDocument
    }

    var phase: Phase = .idle
    var account: GoogleAccount?
    var failure: GoogleManagerFailure?

    var isAuthorized: Bool {
        account != nil
    }
}
