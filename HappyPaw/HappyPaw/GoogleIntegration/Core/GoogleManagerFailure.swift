import Foundation

nonisolated struct GoogleManagerFailure: Error, Equatable, Sendable {
    nonisolated enum Kind: Equatable, Sendable {
        case authorization
        case network
        case api
        case unknown
    }

    let kind: Kind
    let message: String
}

nonisolated enum GoogleServiceError: Error, Equatable, Sendable {
    case authorizationExpired
    case authorization(String)
    case network(String)
    case api(String)
    case unknown(String)
}
