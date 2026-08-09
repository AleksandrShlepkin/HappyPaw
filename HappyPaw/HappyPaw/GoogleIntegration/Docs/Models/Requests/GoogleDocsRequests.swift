import Foundation

nonisolated struct CreateGoogleDocumentRequest: Encodable, Sendable {
    let title: String
}

nonisolated struct CreateGoogleDocumentResponse: Decodable, Sendable {
    let documentId: String
    let title: String
}

nonisolated struct BatchUpdateGoogleDocumentRequest: Encodable, Sendable {
    let requests: [GoogleDocumentRequest]
}

nonisolated enum GoogleDocumentRequest: Encodable, Sendable {
    case insertText(InsertTextRequest)

    private enum CodingKeys: String, CodingKey {
        case insertText
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case let .insertText(request):
            try container.encode(request, forKey: .insertText)
        }
    }
}

nonisolated struct InsertTextRequest: Encodable, Sendable {
    let location: GoogleDocumentLocation
    let text: String
}

nonisolated struct GoogleDocumentLocation: Encodable, Sendable {
    let index: Int
}
