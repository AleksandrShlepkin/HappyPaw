import FirebaseStorage
import Foundation

actor FirebasePetImageStorage: PetImageStorage {
    private let storage: Storage

    init(storage: Storage = .storage()) {
        self.storage = storage
    }

    func uploadImage(
        _ data: Data,
        forPetID petID: String,
        contentType: String
    ) async throws -> URL {
        let reference = storage.reference()
            .child(Constants.petsDirectory)
            .child(petID)
            .child(UUID().uuidString)
        let metadata = StorageMetadata()
        metadata.contentType = contentType

        do {
            _ = try await reference.putDataAsync(data, metadata: metadata)
            return try await reference.downloadURL()
        } catch {
            throw DataServiceFailure(kind: .storage, message: error.localizedDescription)
        }
    }

    func deleteImage(at url: URL) async throws {
        do {
            try await storage.reference(forURL: url.absoluteString).delete()
        } catch {
            throw DataServiceFailure(kind: .storage, message: error.localizedDescription)
        }
    }

    private enum Constants {
        static let petsDirectory = "pets"
    }
}
