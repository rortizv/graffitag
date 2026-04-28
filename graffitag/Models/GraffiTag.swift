import Foundation
import FirebaseFirestore
import CoreLocation

struct GraffiTag: Identifiable, Codable, Sendable {
    @DocumentID var id: String?
    let authorId: String
    let authorName: String
    let title: String
    let description: String
    let imageURL: String
    let depthMapURL: String?
    let worldMapURL: String?
    let latitude: Double
    let longitude: Double
    let createdAt: Date
    var likesCount: Int

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    // Memberwise init for creating new tags (id assigned by Firestore)
    init(
        authorId: String,
        authorName: String,
        title: String,
        description: String,
        imageURL: String,
        depthMapURL: String? = nil,
        worldMapURL: String? = nil,
        latitude: Double,
        longitude: Double,
        createdAt: Date,
        likesCount: Int = 0
    ) {
        self.authorId = authorId
        self.authorName = authorName
        self.title = title
        self.description = description
        self.imageURL = imageURL
        self.depthMapURL = depthMapURL
        self.worldMapURL = worldMapURL
        self.latitude = latitude
        self.longitude = longitude
        self.createdAt = createdAt
        self.likesCount = likesCount
    }

    enum CodingKeys: String, CodingKey {
        case id, authorId, authorName, title, description
        case imageURL, depthMapURL, worldMapURL
        case latitude, longitude, createdAt, likesCount
    }
}
