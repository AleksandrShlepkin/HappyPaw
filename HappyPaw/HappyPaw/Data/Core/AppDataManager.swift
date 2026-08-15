import Foundation

actor AppDataManager: AppDataManagerProtocol {
    private let authenticationService: any AuthenticationService
    private let petRepository: any PetRepository

    private var state = AppDataManagerState()
    private var activeOperationID: UUID?
    private var stateContinuations: [UUID: AsyncStream<AppDataManagerState>.Continuation] = [:]
    private var outputContinuations: [UUID: AsyncStream<AppDataManagerOutput>.Continuation] = [:]

    init(authenticationService: any AuthenticationService, petRepository: any PetRepository) {
        self.authenticationService = authenticationService
        self.petRepository = petRepository
    }

    func states() async -> AsyncStream<AppDataManagerState> {
        let id = UUID()
        return AsyncStream(bufferingPolicy: .bufferingNewest(1)) { continuation in
            stateContinuations[id] = continuation
            continuation.yield(state)
            continuation.onTermination = { [weak self] _ in
                Task { await self?.removeStateContinuation(id) }
            }
        }
    }

    func outputs() async -> AsyncStream<AppDataManagerOutput> {
        let id = UUID()
        return AsyncStream(bufferingPolicy: .bufferingNewest(10)) { continuation in
            outputContinuations[id] = continuation
            continuation.onTermination = { [weak self] _ in
                Task { await self?.removeOutputContinuation(id) }
            }
        }
    }

    func send(_ intent: AppDataManagerIntent) async {
        switch intent {
        case .restoreSession: await restoreSession()
        case .signInWithGoogle: await signInWithGoogle()
        case .signOut: await signOut()
        case .loadPets: await loadPets()
        case let .createPet(draft): await createPet(draft)
        }
    }

    private func restoreSession() async {
        let operationID = beginOperation(phase: .restoringSession)
        do {
            let user = try await authenticationService.restoreSession()
            guard isActive(operationID) else { return }
            updateState { $0.phase = .idle; $0.user = user }
            completeOperation(operationID)
        } catch { handle(error, operationID: operationID, fallbackKind: .authorization) }
    }

    private func signInWithGoogle() async {
        let operationID = beginOperation(phase: .authorizing)
        do {
            let user = try await authenticationService.signInWithGoogle()
            guard isActive(operationID) else { return }
            updateState { $0.phase = .idle; $0.user = user }
            completeOperation(operationID)
        } catch { handle(error, operationID: operationID, fallbackKind: .authorization) }
    }

    private func signOut() async {
        let operationID = beginOperation(phase: .signingOut)
        do {
            try await authenticationService.signOut()
            guard isActive(operationID) else { return }
            updateState { $0.phase = .idle; $0.user = nil; $0.pets = [] }
            completeOperation(operationID)
        } catch { handle(error, operationID: operationID, fallbackKind: .authorization) }
    }

    private func loadPets() async {
        let operationID = beginOperation(phase: .loadingPets)
        do {
            let pets = try await petRepository.fetchPublishedPets()
            guard isActive(operationID) else { return }
            updateState { $0.phase = .idle; $0.pets = pets }
            completeOperation(operationID)
        } catch { handle(error, operationID: operationID, fallbackKind: .database) }
    }

    private func createPet(_ draft: PetDraft) async {
        guard state.canManagePets else { emit(.requestAuthorization); return }
        let operationID = beginOperation(phase: .creatingPet)
        do {
            let pet = try await petRepository.createPet(draft)
            guard isActive(operationID) else { return }
            updateState { $0.phase = .idle; $0.pets.insert(pet, at: 0) }
            completeOperation(operationID)
            emit(.petCreated(pet))
        } catch { handle(error, operationID: operationID, fallbackKind: .database) }
    }

    private func beginOperation(phase: AppDataManagerState.Phase) -> UUID {
        let operationID = UUID()
        activeOperationID = operationID
        updateState { $0.phase = phase; $0.failure = nil }
        return operationID
    }

    private func isActive(_ operationID: UUID) -> Bool { activeOperationID == operationID }

    private func completeOperation(_ operationID: UUID) {
        guard isActive(operationID) else { return }
        activeOperationID = nil
    }

    private func updateState(_ mutation: (inout AppDataManagerState) -> Void) {
        mutation(&state)
        stateContinuations.values.forEach { $0.yield(state) }
    }

    private func emit(_ output: AppDataManagerOutput) {
        outputContinuations.values.forEach { $0.yield(output) }
    }

    private func handle(_ error: any Error, operationID: UUID, fallbackKind: DataServiceFailure.Kind) {
        guard isActive(operationID) else { return }
        let failure = classify(error, fallbackKind: fallbackKind)
        updateState { $0.phase = .idle; $0.failure = failure }
        completeOperation(operationID)
        emit(.presentError(failure))
    }

    private func classify(_ error: any Error, fallbackKind: DataServiceFailure.Kind) -> DataServiceFailure {
        if let failure = error as? DataServiceFailure { return failure }
        if error is URLError { return .init(kind: .network, message: error.localizedDescription) }
        return .init(kind: fallbackKind, message: error.localizedDescription)
    }

    private func removeStateContinuation(_ id: UUID) { stateContinuations[id] = nil }
    private func removeOutputContinuation(_ id: UUID) { outputContinuations[id] = nil }
}
