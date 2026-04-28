import Foundation
import FirebaseFirestore
import CoreLocation

@MainActor
@Observable
final class FirestoreService {

    private(set) var nearbyTags: [GraffiTag] = []
    private(set) var isLoading = false
    private(set) var error: AppError?

    private let db = Firestore.firestore()
    private var tagsListener: ListenerRegistration?

    deinit {
        MainActor.assumeIsolated { tagsListener?.remove() }
    }

    // MARK: - Real-time Nearby Tags

    func startListeningNearbyTags(
        center: CLLocationCoordinate2D,
        radiusKm: Double = 0.5
    ) {
        tagsListener?.remove()

        // Bounding-box approximation (1° lat ≈ 111 km)
        let latDelta = radiusKm / 111.0
        let lngDelta = radiusKm / (111.0 * cos(center.latitude * .pi / 180))

        let minLat = center.latitude  - latDelta
        let maxLat = center.latitude  + latDelta
        let minLng = center.longitude - lngDelta
        let maxLng = center.longitude + lngDelta

        isLoading = true

        tagsListener = db
            .collection(AppConstants.Firebase.tagsCollection)
            .whereField("latitude",  isGreaterThan: minLat)
            .whereField("latitude",  isLessThan:    maxLat)
            .addSnapshotListener { [weak self] snapshot, err in
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    self.isLoading = false
                    if let err {
                        self.error = .firestoreError(err.localizedDescription)
                        return
                    }
                    self.nearbyTags = (snapshot?.documents ?? [])
                        .compactMap { try? $0.data(as: GraffiTag.self) }
                        .filter { $0.longitude >= minLng && $0.longitude <= maxLng }
                }
            }
    }

    func stopListening() {
        tagsListener?.remove()
        tagsListener = nil
    }

    // MARK: - CRUD

    func createTag(_ tag: GraffiTag) async throws {
        do {
            _ = try db.collection(AppConstants.Firebase.tagsCollection).addDocument(from: tag)
        } catch {
            throw AppError.firestoreError(error.localizedDescription)
        }
    }

    func updateTag(_ tag: GraffiTag) async throws {
        guard let id = tag.id else { throw AppError.firestoreError("Missing tag ID") }
        do {
            try db.collection(AppConstants.Firebase.tagsCollection).document(id).setData(from: tag)
        } catch {
            throw AppError.firestoreError(error.localizedDescription)
        }
    }

    func deleteTag(id: String) async throws {
        do {
            try await db.collection(AppConstants.Firebase.tagsCollection).document(id).delete()
        } catch {
            throw AppError.firestoreError(error.localizedDescription)
        }
    }

    func fetchUserTags(userId: String) async throws -> [GraffiTag] {
        do {
            let snap = try await db
                .collection(AppConstants.Firebase.tagsCollection)
                .whereField("authorId", isEqualTo: userId)
                .order(by: "createdAt", descending: true)
                .getDocuments()
            return snap.documents.compactMap { try? $0.data(as: GraffiTag.self) }
        } catch {
            throw AppError.firestoreError(error.localizedDescription)
        }
    }

    func incrementLikes(tagId: String) async throws {
        let ref = db.collection(AppConstants.Firebase.tagsCollection).document(tagId)
        let _ = try await db.runTransaction { tx, _ in
            let count = (try? tx.getDocument(ref).data()?["likesCount"] as? Int) ?? 0
            tx.updateData(["likesCount": count + 1], forDocument: ref)
            return nil
        }
    }
}

