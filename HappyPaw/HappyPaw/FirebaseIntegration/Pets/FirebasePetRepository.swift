import FirebaseFirestore
import Foundation

actor FirebasePetRepository: PetRepository {
    private let database: Firestore

    init(database: Firestore = .firestore()) {
        self.database = database
    }

    func fetchPublishedPets() async throws -> [Pet] {
        do {
            let snapshot = try await database
                .collection(Constants.petsCollection)
                .whereField(Constants.isPublishedField, isEqualTo: true)
                .order(by: Constants.createdAtField, descending: true)
                .getDocuments()
            return try snapshot.documents.map(makePet)
        } catch let error as DataServiceFailure {
            throw error
        } catch {
            throw DataServiceFailure(kind: .database, message: error.localizedDescription)
        }
    }

    func createPet(_ draft: PetDraft) async throws -> Pet {
        let reference = database.collection(Constants.petsCollection).document()
        let now = Date()

        do {
            try await reference.setData([
                Constants.nameField: draft.name,
                Constants.speciesField: draft.species,
                Constants.breedField: draft.breed ?? NSNull(),
                Constants.ageDescriptionField: draft.ageDescription ?? NSNull(),
                Constants.cityField: draft.city,
                Constants.descriptionField: draft.description,
                Constants.photoURLsField: [],
                Constants.statusField: Pet.Status.needsHome.rawValue,
                Constants.isPublishedField: draft.isPublished,
                Constants.createdAtField: Timestamp(date: now),
                Constants.updatedAtField: Timestamp(date: now)
            ])

            return .init(
                id: reference.documentID,
                name: draft.name,
                species: draft.species,
                breed: draft.breed,
                ageDescription: draft.ageDescription,
                city: draft.city,
                description: draft.description,
                photoURLs: [],
                status: .needsHome,
                isPublished: draft.isPublished,
                createdAt: now,
                updatedAt: now
            )
        } catch {
            throw DataServiceFailure(kind: .database, message: error.localizedDescription)
        }
    }

    func updatePet(_ pet: Pet) async throws {
        do {
            try await database.collection(Constants.petsCollection).document(pet.id).setData(
                documentData(for: pet),
                merge: true
            )
        } catch {
            throw DataServiceFailure(kind: .database, message: error.localizedDescription)
        }
    }

    func archivePet(id: String) async throws {
        do {
            try await database.collection(Constants.petsCollection).document(id).updateData([
                Constants.statusField: Pet.Status.archived.rawValue,
                Constants.updatedAtField: FieldValue.serverTimestamp()
            ])
        } catch {
            throw DataServiceFailure(kind: .database, message: error.localizedDescription)
        }
    }

    private func makePet(from document: QueryDocumentSnapshot) throws -> Pet {
        let data = document.data()
        guard let name = data[Constants.nameField] as? String,
              let species = data[Constants.speciesField] as? String,
              let city = data[Constants.cityField] as? String,
              let description = data[Constants.descriptionField] as? String,
              let statusValue = data[Constants.statusField] as? String,
              let status = Pet.Status(rawValue: statusValue),
              let isPublished = data[Constants.isPublishedField] as? Bool else {
            throw DataServiceFailure(kind: .database, message: "A pet document contains invalid data")
        }

        return .init(
            id: document.documentID,
            name: name,
            species: species,
            breed: data[Constants.breedField] as? String,
            ageDescription: data[Constants.ageDescriptionField] as? String,
            city: city,
            description: description,
            photoURLs: (data[Constants.photoURLsField] as? [String] ?? []).compactMap(URL.init(string:)),
            status: status,
            isPublished: isPublished,
            createdAt: (data[Constants.createdAtField] as? Timestamp)?.dateValue() ?? .distantPast,
            updatedAt: (data[Constants.updatedAtField] as? Timestamp)?.dateValue() ?? .distantPast
        )
    }

    private func documentData(for pet: Pet) -> [String: Any] {
        [
            Constants.nameField: pet.name,
            Constants.speciesField: pet.species,
            Constants.breedField: pet.breed ?? NSNull(),
            Constants.ageDescriptionField: pet.ageDescription ?? NSNull(),
            Constants.cityField: pet.city,
            Constants.descriptionField: pet.description,
            Constants.photoURLsField: pet.photoURLs.map(\.absoluteString),
            Constants.statusField: pet.status.rawValue,
            Constants.isPublishedField: pet.isPublished,
            Constants.updatedAtField: FieldValue.serverTimestamp()
        ]
    }

    private enum Constants {
        static let petsCollection = "pets"
        static let nameField = "name"
        static let speciesField = "species"
        static let breedField = "breed"
        static let ageDescriptionField = "ageDescription"
        static let cityField = "city"
        static let descriptionField = "description"
        static let photoURLsField = "photoURLs"
        static let statusField = "status"
        static let isPublishedField = "isPublished"
        static let createdAtField = "createdAt"
        static let updatedAtField = "updatedAt"
    }
}
