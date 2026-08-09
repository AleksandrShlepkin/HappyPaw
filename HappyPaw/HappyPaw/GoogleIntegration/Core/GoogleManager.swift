import Foundation

actor GoogleManager: GoogleManagerProtocol {
    private let authService: any GoogleAuthServiceProtocol
    private let docsService: any GoogleDocsServiceProtocol

    private var state = GoogleManagerState()
    private var activeOperationID: UUID?
    private var stateContinuations: [UUID: AsyncStream<GoogleManagerState>.Continuation] = [:]
    private var outputContinuations: [UUID: AsyncStream<GoogleManagerOutput>.Continuation] = [:]

    init(
        authService: any GoogleAuthServiceProtocol,
        docsService: any GoogleDocsServiceProtocol
    ) {
        self.authService = authService
        self.docsService = docsService
    }

    func states() async -> AsyncStream<GoogleManagerState> {
        let id = UUID()

        return AsyncStream(bufferingPolicy: .bufferingNewest(1)) { continuation in
            stateContinuations[id] = continuation
            continuation.yield(state)
            continuation.onTermination = { [weak self] _ in
                Task { await self?.removeStateContinuation(id) }
            }
        }
    }

    func outputs() async -> AsyncStream<GoogleManagerOutput> {
        let id = UUID()

        return AsyncStream(bufferingPolicy: .bufferingNewest(10)) { continuation in
            outputContinuations[id] = continuation
            continuation.onTermination = { [weak self] _ in
                Task { await self?.removeOutputContinuation(id) }
            }
        }
    }

    func send(_ intent: GoogleManagerIntent) async {
        switch intent {
        case .restoreSession:
            await restoreSession()
        case .signIn:
            await signIn()
        case .signOut:
            await signOut()
        case let .createDocument(draft):
            await createDocument(from: draft)
        }
    }

    private func restoreSession() async {
        let operationID = beginOperation(phase: .restoringSession)

        do {
            let account = try await authService.restoreSession()
            guard isActive(operationID) else { return }
            updateState {
                $0.phase = .idle
                $0.account = account
            }
            completeOperation(operationID)
        } catch {
            handle(error, operationID: operationID, fallbackKind: .authorization)
        }
    }

    private func signIn() async {
        let operationID = beginOperation(phase: .authorizing)

        do {
            let account = try await authService.signIn()
            guard isActive(operationID) else { return }
            updateState {
                $0.phase = .idle
                $0.account = account
            }
            completeOperation(operationID)
        } catch {
            handle(error, operationID: operationID, fallbackKind: .authorization)
        }
    }

    private func signOut() async {
        let operationID = beginOperation(phase: .signingOut)

        do {
            try await authService.signOut()
            guard isActive(operationID) else { return }
            updateState {
                $0.phase = .idle
                $0.account = nil
            }
            completeOperation(operationID)
        } catch {
            handle(error, operationID: operationID, fallbackKind: .authorization)
        }
    }

    private func createDocument(from draft: GoogleDocumentDraft) async {
        guard state.isAuthorized else {
            emit(.requestAuthorization)
            return
        }

        let operationID = beginOperation(phase: .creatingDocument)

        do {
            let token = try await authService.accessToken()
            guard isActive(operationID) else { return }
            let document = try await docsService.createDocument(
                from: draft,
                accessToken: token
            )
            guard isActive(operationID) else { return }
            updateState { $0.phase = .idle }
            completeOperation(operationID)
            emit(.openDocument(document))
        } catch {
            handle(error, operationID: operationID, fallbackKind: .api)
        }
    }

    private func beginOperation(phase: GoogleManagerState.Phase) -> UUID {
        let operationID = UUID()
        activeOperationID = operationID
        updateState {
            $0.phase = phase
            $0.failure = nil
        }
        return operationID
    }

    private func isActive(_ operationID: UUID) -> Bool {
        activeOperationID == operationID
    }

    private func completeOperation(_ operationID: UUID) {
        guard isActive(operationID) else { return }
        activeOperationID = nil
    }

    private func updateState(_ mutation: (inout GoogleManagerState) -> Void) {
        mutation(&state)
        stateContinuations.values.forEach { $0.yield(state) }
    }

    private func emit(_ output: GoogleManagerOutput) {
        outputContinuations.values.forEach { $0.yield(output) }
    }

    private func handle(
        _ error: any Error,
        operationID: UUID,
        fallbackKind: GoogleManagerFailure.Kind
    ) {
        guard isActive(operationID) else { return }

        let failure = classify(error, fallbackKind: fallbackKind)
        updateState {
            $0.phase = .idle
            $0.failure = failure

            if case GoogleServiceError.authorizationExpired = error {
                $0.account = nil
            }
        }
        completeOperation(operationID)
        emit(.presentError(failure))
    }

    private func classify(
        _ error: any Error,
        fallbackKind: GoogleManagerFailure.Kind
    ) -> GoogleManagerFailure {
        if let failure = error as? GoogleManagerFailure {
            return failure
        }

        if let serviceError = error as? GoogleServiceError {
            switch serviceError {
            case .authorizationExpired:
                return .init(kind: .authorization, message: "Google authorization expired")
            case let .authorization(message):
                return .init(kind: .authorization, message: message)
            case let .network(message):
                return .init(kind: .network, message: message)
            case let .api(message):
                return .init(kind: .api, message: message)
            case let .unknown(message):
                return .init(kind: .unknown, message: message)
            }
        }

        if error is URLError {
            return .init(kind: .network, message: error.localizedDescription)
        }

        return .init(kind: fallbackKind, message: error.localizedDescription)
    }

    private func removeStateContinuation(_ id: UUID) {
        stateContinuations[id] = nil
    }

    private func removeOutputContinuation(_ id: UUID) {
        outputContinuations[id] = nil
    }
}
