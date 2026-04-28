import Foundation
import FirebaseStorage
internal import UIKit

final class StorageService {
    static let shared = StorageService()
    private init() {}

    private let storage = Storage.storage()

    // MARK: - Upload

    func uploadTagImage(_ image: UIImage, tagId: String) async throws -> URL {
        guard let data = image.jpegData(compressionQuality: 0.8) else {
            throw AppError.storageError("Failed to compress image")
        }
        return try await upload(data: data, path: "tags/\(tagId)/image.jpg", contentType: "image/jpeg")
    }

    func uploadDepthMap(_ data: Data, tagId: String) async throws -> URL {
        try await upload(data: data, path: "tags/\(tagId)/depth.bin", contentType: "application/octet-stream")
    }

    func uploadWorldMap(_ data: Data, tagId: String) async throws -> URL {
        try await upload(data: data, path: "tags/\(tagId)/worldmap.bin", contentType: "application/octet-stream")
    }

    // MARK: - Private

    private func upload(data: Data, path: String, contentType: String) async throws -> URL {
        let ref = storage.reference().child(path)
        let meta = StorageMetadata()
        meta.contentType = contentType

        return try await withCheckedThrowingContinuation { continuation in
            ref.putData(data, metadata: meta) { _, error in
                if let error {
                    continuation.resume(throwing: AppError.storageError(error.localizedDescription))
                    return
                }
                ref.downloadURL { url, error in
                    if let url {
                        continuation.resume(returning: url)
                    } else {
                        continuation.resume(throwing: AppError.storageError(
                            error?.localizedDescription ?? "Unknown download URL error"
                        ))
                    }
                }
            }
        }
    }
}
