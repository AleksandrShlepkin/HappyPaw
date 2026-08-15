import Foundation

/// Public OAuth identifiers read from the Google configuration supplied by Cloud Console.
/// They are identifiers rather than secrets and must not be replaced by a client secret.
nonisolated struct GoogleConfiguration: Sendable, Equatable {
    let clientID: String
    let reversedClientID: String

    static func load(from bundle: Bundle = .main) throws -> GoogleConfiguration {
        guard let url = bundle.url(forResource: "GoogleOAuth-Info", withExtension: "plist") else {
            throw GoogleConfigurationError.fileNotFound
        }

        guard let values = NSDictionary(contentsOf: url) as? [String: Any] else {
            throw GoogleConfigurationError.invalidFile
        }

        guard let clientID = values["CLIENT_ID"] as? String, !clientID.isEmpty,
              let reversedClientID = values["REVERSED_CLIENT_ID"] as? String, !reversedClientID.isEmpty else {
            throw GoogleConfigurationError.missingOAuthIdentifiers
        }

        return .init(clientID: clientID, reversedClientID: reversedClientID)
    }
}

nonisolated enum GoogleConfigurationError: LocalizedError, Equatable, Sendable {
    case fileNotFound
    case invalidFile
    case missingOAuthIdentifiers

    var errorDescription: String? {
        switch self {
        case .fileNotFound:
            return "GoogleOAuth-Info.plist is missing from the app bundle."
        case .invalidFile:
            return "GoogleOAuth-Info.plist cannot be read."
        case .missingOAuthIdentifiers:
            return "GoogleOAuth-Info.plist does not contain CLIENT_ID and REVERSED_CLIENT_ID."
        }
    }
}
