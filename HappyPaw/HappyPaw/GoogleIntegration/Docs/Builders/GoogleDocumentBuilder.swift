import Foundation

nonisolated protocol GoogleDocumentBuilding: Sendable {
    func buildRequests(for draft: GoogleDocumentDraft) -> [GoogleDocumentRequest]
}

/// Translates app content into Google Docs API operations, keeping API indices out of the UI.
nonisolated struct GoogleDocumentBuilder: GoogleDocumentBuilding {
    func buildRequests(for draft: GoogleDocumentDraft) -> [GoogleDocumentRequest] {
        guard !draft.content.isEmpty else { return [] }

        return [
            .insertText(
                .init(
                    location: .init(index: 1),
                    text: normalizedContent(draft.content)
                )
            )
        ]
    }

    private func normalizedContent(_ content: String) -> String {
        content.hasSuffix("\n") ? content : content + "\n"
    }
}
