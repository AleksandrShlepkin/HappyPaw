import Foundation
import Observation

@MainActor
@Observable
final class MainAdministratorScreenStore {
    private(set) var state = MainAdministratorScreenState()

    private let googleManager: (any GoogleManagerProtocol)?
    private var stateTask: Task<Void, Never>?
    private var outputTask: Task<Void, Never>?

    init(googleManager: (any GoogleManagerProtocol)? = nil) {
        self.googleManager = googleManager
    }

    func send(_ intent: MainAdministratorScreenIntent) {
        switch intent {
        case .appeared:
            startObservingGoogleManager()
            sendToGoogle(.restoreSession)
        case .signInTapped:
            sendToGoogle(.signIn)
        case .signOutTapped:
            sendToGoogle(.signOut)
        case let .documentTitleChanged(title):
            state.documentTitle = title
        case let .documentContentChanged(content):
            state.documentContent = content
        case .createDocumentTapped:
            let draft = GoogleDocumentDraft(
                title: state.documentTitle.trimmingCharacters(in: .whitespacesAndNewlines),
                content: state.documentContent
            )
            sendToGoogle(.createDocument(draft))
        case .errorDismissed:
            state.errorMessage = nil
        case .documentURLOpened:
            state.documentURL = nil
        }
    }

    private func startObservingGoogleManager() {
        guard let googleManager, stateTask == nil, outputTask == nil else { return }

        stateTask = Task { [weak self, googleManager] in
            let states = await googleManager.states()
            for await googleState in states where !Task.isCancelled {
                self?.apply(googleState)
            }
        }

        outputTask = Task { [weak self, googleManager] in
            let outputs = await googleManager.outputs()
            for await output in outputs where !Task.isCancelled {
                self?.apply(output)
            }
        }
    }

    private func sendToGoogle(_ intent: GoogleManagerIntent) {
        guard let googleManager else { return }

        Task {
            await googleManager.send(intent)
        }
    }

    private func apply(_ googleState: GoogleManagerState) {
        state.phase = switch googleState.phase {
        case .idle: .idle
        case .restoringSession: .restoringSession
        case .authorizing: .authorizing
        case .signingOut: .signingOut
        case .creatingDocument: .creatingDocument
        }
        state.accountName = googleState.account?.displayName
        state.accountEmail = googleState.account?.email
        state.errorMessage = googleState.failure?.message
    }

    private func apply(_ output: GoogleManagerOutput) {
        switch output {
        case let .openDocument(document):
            state.documentURL = document.webURL
        case .requestAuthorization:
            state.errorMessage = Constants.authorizationRequiredMessage
        case let .presentError(failure):
            state.errorMessage = failure.message
        }
    }

    private enum Constants {
        static let authorizationRequiredMessage = "Чтобы создать документ, войдите в Google."
    }
}
