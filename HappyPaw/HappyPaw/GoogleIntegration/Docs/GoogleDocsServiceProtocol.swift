import Foundation

nonisolated protocol GoogleDocsServiceProtocol: Sendable {
    func createDocument(
        from draft: GoogleDocumentDraft,
        accessToken: String
    ) async throws -> GoogleDocumentReference
}
