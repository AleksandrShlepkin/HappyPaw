import Foundation

nonisolated protocol GoogleAuthServiceProtocol: Sendable {
    func restoreSession() async throws -> GoogleAccount?
    func signIn() async throws -> GoogleAccount
    func signOut() async throws
    func accessToken() async throws -> String
}
