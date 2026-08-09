import Foundation

struct OnboardingState: Equatable {
    static let pageCount = 3

    var currentPage = 0
    var isCompleted = false

    var canGoBack: Bool {
        currentPage > 0
    }

    var isLastPage: Bool {
        currentPage == Self.pageCount - 1
    }
}
