import Foundation

/// Application-level routes are deliberately independent of UIKit and SwiftUI.
/// A future deep-link/universal-link parser only has to produce one of these.
enum AppRoute: Equatable, Sendable {
    case cards
    case cardDetails(id: String)
    case editCard(id: String)
    case favorites
    case activity
    case profile
}

@MainActor
protocol AppRouteHandling: AnyObject {
    func handle(_ route: AppRoute)
}
