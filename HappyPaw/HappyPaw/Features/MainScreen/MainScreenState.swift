import Foundation

struct MainScreenCard: Identifiable, Equatable, Sendable {
    let id: UUID
    let title: String
    let subtitle: String?
}

struct MainScreenState: Equatable {
    enum Phase: Equatable {
        case idle
        case loading
        case content
        case empty
        case failure
    }

    var phase: Phase = .idle
    var cards: [MainScreenCard] = []
    var selectedCardID: UUID?
    var errorMessage: String?

    var isLoading: Bool {
        phase == .loading
    }
}
