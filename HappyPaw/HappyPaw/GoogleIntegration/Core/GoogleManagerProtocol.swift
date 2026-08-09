import Foundation

nonisolated protocol GoogleManagerProtocol: Sendable {
    func states() async -> AsyncStream<GoogleManagerState>
    func outputs() async -> AsyncStream<GoogleManagerOutput>
    func send(_ intent: GoogleManagerIntent) async
}
