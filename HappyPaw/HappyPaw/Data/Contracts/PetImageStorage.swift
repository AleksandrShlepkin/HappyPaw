import Foundation

nonisolated protocol PetImageStorage: Sendable {
    func uploadImage(_ data: Data, forPetID petID: String, contentType: String) async throws -> URL
    func deleteImage(at url: URL) async throws
}
