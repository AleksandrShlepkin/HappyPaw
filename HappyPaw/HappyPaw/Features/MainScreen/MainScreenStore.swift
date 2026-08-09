import Foundation
import Observation

@MainActor
@Observable
final class MainScreenStore {
    typealias CardsLoader = @MainActor @Sendable () async throws -> [MainScreenCard]

    private(set) var state = MainScreenState()

    private let loadCards: CardsLoader
    private var loadingTask: Task<Void, Never>?

    init(loadCards: @escaping CardsLoader = { [] }) {
        self.loadCards = loadCards
    }

    func send(_ intent: MainScreenIntent) {
        switch intent {
        case .appeared:
            guard state.phase == .idle else { return }
            startLoading()
        case .refreshTapped:
            startLoading()
        case let .cardTapped(id):
            state.selectedCardID = id
        case .errorDismissed:
            state.errorMessage = nil
        }
    }

    private func startLoading() {
        loadingTask?.cancel()
        state.phase = .loading
        state.errorMessage = nil

        loadingTask = Task { [weak self, loadCards] in
            do {
                let cards = try await loadCards()
                guard !Task.isCancelled else { return }

                self?.state.cards = cards
                self?.state.phase = cards.isEmpty ? .empty : .content
            } catch is CancellationError {
                return
            } catch {
                guard !Task.isCancelled else { return }
                self?.state.phase = .failure
                self?.state.errorMessage = error.localizedDescription
            }
        }
    }
}
