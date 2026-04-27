import Foundation

enum AppConstants {
    enum Firebase {
        static let tagsCollection = "tags"
        static let usersCollection = "users"
    }

    enum Location {
        static let nearbyRadiusMeters: Double = 500
        static let closeRadiusMeters: Double = 100
        static let warningRadiusMeters: Double = 200
        static let distanceFilterMeters: Double = 5
    }

    enum AR {
        static let maxTagsRendered = 20
        static let worldMapFileName = "worldmap"
    }
}
