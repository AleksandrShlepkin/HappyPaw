import Foundation

struct LaunchState: Equatable {
    enum Phase: Equatable {
        case idle
        case resolvingDestination
        case finished
    }

    enum Destination: Equatable {
        case onboarding
        case mainAdministrator
    }

    var phase: Phase = .idle
    var destination: Destination?
}
