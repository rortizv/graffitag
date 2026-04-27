import Foundation

enum AppError: LocalizedError {
    case authFailed(String)
    case locationDenied
    case locationUnavailable
    case firestoreError(String)
    case storageError(String)
    case arSessionFailed(String)
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .authFailed(let msg):       return "Authentication failed: \(msg)"
        case .locationDenied:            return "Location access denied. Please enable it in Settings."
        case .locationUnavailable:       return "Location unavailable. Please try again."
        case .firestoreError(let msg):   return "Database error: \(msg)"
        case .storageError(let msg):     return "Storage error: \(msg)"
        case .arSessionFailed(let msg):  return "AR session error: \(msg)"
        case .unknown(let msg):          return "Unexpected error: \(msg)"
        }
    }
}
