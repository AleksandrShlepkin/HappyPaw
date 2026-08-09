import Foundation

struct MainAdministratorScreenState: Equatable {
    enum Phase: Equatable {
        case idle
        case restoringSession
        case authorizing
        case signingOut
        case creatingDocument
    }

    var phase: Phase = .idle
    var accountName: String?
    var accountEmail: String?
    var documentTitle = Constants.defaultDocumentTitle
    var documentContent = ""
    var errorMessage: String?
    var documentURL: URL?

    var isAuthorized: Bool {
        accountEmail != nil
    }

    var isLoading: Bool {
        phase != .idle
    }

    var canCreateDocument: Bool {
        isAuthorized && !documentTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private enum Constants {
        static let defaultDocumentTitle = "HappyPaw — карточка питомца"
    }
}
