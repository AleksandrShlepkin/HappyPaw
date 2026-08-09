import Foundation

enum MainScreenIntent: Sendable {
    case appeared
    case refreshTapped
    case cardTapped(UUID)
    case errorDismissed
}
