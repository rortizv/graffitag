import Foundation
import FirebaseFirestore

struct AppUser: Identifiable, Codable, Sendable {
    @DocumentID var id: String?
    let uid: String
    let displayName: String
    let email: String
    let avatarURL: String?
    let tagCount: Int
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, uid, displayName, email, avatarURL, tagCount, createdAt
    }
}
