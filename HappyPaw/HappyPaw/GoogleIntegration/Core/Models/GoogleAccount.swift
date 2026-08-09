import Foundation

nonisolated struct GoogleAccount: Equatable, Sendable {
    let id: String
    let email: String
    let displayName: String?
}
