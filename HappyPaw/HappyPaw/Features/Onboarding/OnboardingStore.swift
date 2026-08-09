import Foundation
import Observation

@MainActor
@Observable
final class OnboardingStore {
    private(set) var state = OnboardingState()
    private let persistCompletion: @MainActor () -> Void

    init(persistCompletion: @escaping @MainActor () -> Void = {}) {
        self.persistCompletion = persistCompletion
    }

    func send(_ intent: OnboardingIntent) {
        switch intent {
        case .nextTapped:
            if state.isLastPage {
                completeOnboarding()
            } else {
                state.currentPage += 1
            }
        case .backTapped:
            guard state.canGoBack else { return }
            state.currentPage -= 1
        case .skipTapped:
            completeOnboarding()
        }
    }

    private func completeOnboarding() {
        guard !state.isCompleted else { return }
        state.isCompleted = true
        persistCompletion()
    }
}
