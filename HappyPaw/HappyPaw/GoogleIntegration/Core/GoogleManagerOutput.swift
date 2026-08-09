import Foundation

nonisolated enum GoogleManagerOutput: Equatable, Sendable {
    case openDocument(GoogleDocumentReference)
    case requestAuthorization
    case presentError(GoogleManagerFailure)
}
