import Foundation

enum MainAdministratorScreenIntent: Sendable {
    case appeared
    case signInTapped
    case signOutTapped
    case documentTitleChanged(String)
    case documentContentChanged(String)
    case createDocumentTapped
    case errorDismissed
    case documentURLOpened
}
