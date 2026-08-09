import Foundation

nonisolated struct GoogleDocumentReference: Equatable, Sendable {
    let id: String
    let title: String

    var webURL: URL? {
        URL(string: "https://docs.google.com/document/d/\(id)/edit")
    }
}
