import Foundation

nonisolated enum GoogleManagerIntent: Sendable {
    case restoreSession
    case signIn
    case signOut
    case createDocument(GoogleDocumentDraft)
}
