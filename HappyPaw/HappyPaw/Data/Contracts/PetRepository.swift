import Foundation

nonisolated protocol PetRepository: Sendable {
    func fetchPublishedPets() async throws -> [Pet]
    func createPet(_ draft: PetDraft) async throws -> Pet
    func updatePet(_ pet: Pet) async throws
    func archivePet(id: String) async throws
}
