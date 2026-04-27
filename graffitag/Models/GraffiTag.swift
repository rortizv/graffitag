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

    enum CodingKeys: String, CodingKey {
        case id, authorId, authorName, title, description
        case imageURL, depthMapURL, worldMapURL
        case latitude, longitude, createdAt, likesCount
    }
}
