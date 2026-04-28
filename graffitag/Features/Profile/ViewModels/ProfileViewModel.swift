import Foundation
import FirebaseAuth
internal import UIKit

@MainActor
@Observable
final class ProfileViewModel {

    private(set) var userTags: [GraffiTag] = []
    private(set) var isLoading = false
    private(set) var error: AppError?

    var editingTag: GraffiTag?
    var showEditSheet = false
    var showDeleteAlert = false
    var tagToDelete: GraffiTag?

    private let firestoreService: FirestoreService
    private let authService: AuthService

    var displayName: String { authService.currentUser?.displayName ?? "Artist" }
    var email: String       { authService.currentUser?.email ?? "" }
    var avatarURL: URL?     { authService.currentUser?.photoURL }

    init(firestoreService: FirestoreService, authService: AuthService) {
        self.firestoreService = firestoreService
        self.authService = authService
    }

    func onAppear() async {
        await loadUserTags()
    }

    func loadUserTags() async {
        guard let uid = authService.currentUser?.uid else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            userTags = try await firestoreService.fetchUserTags(userId: uid)
        } catch let e as AppError {
            error = e
        } catch {
            self.error = .unknown(error.localizedDescription)
        }
    }

    func confirmDelete(_ tag: GraffiTag) {
        tagToDelete = tag
        showDeleteAlert = true
        HapticManager.shared.impact(.medium)
    }

    func deleteConfirmed() async {
        guard let tag = tagToDelete, let id = tag.id else { return }
        do {
            try await firestoreService.deleteTag(id: id)
            userTags.removeAll { $0.id == id }
            HapticManager.shared.notification(.success)
        } catch let e as AppError {
            error = e
        } catch {
            self.error = .unknown(error.localizedDescription)
        }
        tagToDelete = nil
    }

    func startEditing(_ tag: GraffiTag) {
        editingTag = tag
        showEditSheet = true
    }

    func saveEdit(title: String, description: String) async {
        guard let tag = editingTag else { return }
        // Create updated copy — Codable structs are value types
        let updated = GraffiTag(
            authorId: tag.authorId,
            authorName: tag.authorName,
            title: title,
            description: description,
            imageURL: tag.imageURL,
            depthMapURL: tag.depthMapURL,
            worldMapURL: tag.worldMapURL,
            latitude: tag.latitude,
            longitude: tag.longitude,
            createdAt: tag.createdAt,
            likesCount: tag.likesCount
        )
        do {
            try await firestoreService.updateTag(updated)
            if let idx = userTags.firstIndex(where: { $0.id == tag.id }) {
                userTags[idx] = updated
            }
            showEditSheet = false
            HapticManager.shared.notification(.success)
        } catch let e as AppError {
            error = e
        } catch {
            self.error = .unknown(error.localizedDescription)
        }
    }

    func signOut() throws {
        try authService.signOut()
    }
}
