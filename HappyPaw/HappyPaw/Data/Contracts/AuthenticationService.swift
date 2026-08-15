import Foundation

@MainActor
protocol AuthenticationService: Sendable {
    func restoreSession() async throws -> AppUser?
    func signInWithGoogle() async throws -> AppUser
    func signOut() async throws
}
