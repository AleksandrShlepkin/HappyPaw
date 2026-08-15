import Foundation

nonisolated struct AppDataManagerState: Equatable, Sendable {
    enum Phase: Equatable, Sendable { case idle, restoringSession, authorizing, signingOut, loadingPets, creatingPet }
    var phase: Phase = .idle
    var user: AppUser?
    var pets: [Pet] = []
    var failure: DataServiceFailure?
    var isAuthorized: Bool { user != nil }
    var canManagePets: Bool { user?.canManagePets == true }
}

nonisolated enum AppDataManagerIntent: Sendable { case restoreSession, signInWithGoogle, signOut, loadPets, createPet(PetDraft) }

nonisolated enum AppDataManagerOutput: Equatable, Sendable { case requestAuthorization, presentError(DataServiceFailure), petCreated(Pet) }

nonisolated protocol AppDataManagerProtocol: Sendable {
    func states() async -> AsyncStream<AppDataManagerState>
    func outputs() async -> AsyncStream<AppDataManagerOutput>
    func send(_ intent: AppDataManagerIntent) async
}

nonisolated struct DataServiceFailure: Error, Equatable, Sendable {
    enum Kind: Equatable, Sendable { case authorization, permission, network, storage, database, unknown }
    let kind: Kind
    let message: String
}

nonisolated struct AppUser: Equatable, Sendable {
    enum Role: String, Equatable, Sendable { case volunteer, administrator }
    let id: String
    let email: String?
    let displayName: String?
    let role: Role
    var canManagePets: Bool { role == .administrator }
}

nonisolated struct Pet: Identifiable, Equatable, Sendable {
    enum Status: String, Equatable, Sendable { case needsHome, adopted, archived }
    let id: String
    let name: String
    let species: String
    let breed: String?
    let ageDescription: String?
    let city: String
    let description: String
    let photoURLs: [URL]
    let status: Status
    let isPublished: Bool
    let createdAt: Date
    let updatedAt: Date
}

nonisolated struct PetDraft: Equatable, Sendable {
    let name: String
    let species: String
    let breed: String?
    let ageDescription: String?
    let city: String
    let description: String
    let isPublished: Bool

    init(name: String, species: String, breed: String? = nil, ageDescription: String? = nil, city: String, description: String, isPublished: Bool = false) {
        self.name = name
        self.species = species
        self.breed = breed
        self.ageDescription = ageDescription
        self.city = city
        self.description = description
        self.isPublished = isPublished
    }
}
