import Foundation

nonisolated struct GoogleDocsService: GoogleDocsServiceProtocol, Sendable {
    private let client: GoogleAPIClient
    private let builder: any GoogleDocumentBuilding
    private let encoder: JSONEncoder

    init(
        client: GoogleAPIClient = .init(),
        builder: any GoogleDocumentBuilding = GoogleDocumentBuilder(),
        encoder: JSONEncoder = .init()
    ) {
        self.client = client
        self.builder = builder
        self.encoder = encoder
    }

    func createDocument(
        from draft: GoogleDocumentDraft,
        accessToken: String
    ) async throws -> GoogleDocumentReference {
        let createBody = try encode(CreateGoogleDocumentRequest(title: draft.title))
        let response: CreateGoogleDocumentResponse = try await client.send(
            .init(url: try documentsURL(), method: .post, body: createBody),
            accessToken: accessToken
        )

        let requests = builder.buildRequests(for: draft)
        if !requests.isEmpty {
            let updateBody = try encode(BatchUpdateGoogleDocumentRequest(requests: requests))
            _ = try await client.perform(
                .init(url: try batchUpdateURL(documentID: response.documentId), method: .post, body: updateBody),
                accessToken: accessToken
            )
        }

        return .init(id: response.documentId, title: response.title)
    }

    private func encode<Body: Encodable>(_ body: Body) throws -> Data {
        do {
            return try encoder.encode(body)
        } catch {
            throw GoogleServiceError.api("Unable to encode Google request: \(error.localizedDescription)")
        }
    }

    private func documentsURL() throws -> URL {
        guard let url = URL(string: "https://docs.googleapis.com/v1/documents") else {
            throw GoogleServiceError.unknown("Unable to build Google Docs URL")
        }
        return url
    }

    private func batchUpdateURL(documentID: String) throws -> URL {
        guard let encodedID = documentID.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
              let url = URL(string: "https://docs.googleapis.com/v1/documents/\(encodedID):batchUpdate") else {
            throw GoogleServiceError.unknown("Unable to build Google Docs URL")
        }
        return url
    }
}
