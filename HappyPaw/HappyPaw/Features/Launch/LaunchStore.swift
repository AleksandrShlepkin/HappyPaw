import Foundation
import Observation

@MainActor
@Observable
final class LaunchStore {
    private(set) var state = LaunchState()

    private let hasCompletedOnboarding: @MainActor () -> Bool

    init(
        hasCompletedOnboarding: @escaping @MainActor () -> Bool = {
            UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
        }
    ) {
        self.hasCompletedOnboarding = hasCompletedOnboarding
    }

    func send(_ intent: LaunchIntent) {
        switch intent {
        case .appeared:
            resolveDestination()
        }
    }

    private func resolveDestination() {
        guard state.phase == .idle else { return }

        state.phase = .resolvingDestination
        state.destination = hasCompletedOnboarding()
            ? .mainAdministrator
            : .onboarding
        state.phase = .finished
    }
}
