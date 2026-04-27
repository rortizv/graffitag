import Foundation
import CoreLocation
import Observation

// MARK: - Authorization State

enum LocationAuthState: Equatable {
    case notDetermined
    case denied
    case authorized
}

// MARK: - LocationManager

@MainActor
@Observable
final class LocationManager: NSObject {

    // MARK: - Public State

    private(set) var location: CLLocation?
    private(set) var authState: LocationAuthState = .notDetermined
    private(set) var isUpdating = false

    // Yields every filtered location update — consumers iterate with `for await`
    let locationStream: AsyncStream<CLLocation>

    // MARK: - Private

    private let clManager: CLLocationManager
    private let streamContinuation: AsyncStream<CLLocation>.Continuation

    // MARK: - Init

    override init() {
        clManager = CLLocationManager()
        (locationStream, streamContinuation) = AsyncStream.makeStream()

        super.init()

        clManager.delegate = self
        clManager.desiredAccuracy = kCLLocationAccuracyBest
        clManager.distanceFilter = AppConstants.Location.distanceFilterMeters
        authState = Self.mapAuth(clManager.authorizationStatus)
    }

    deinit {
        streamContinuation.finish()
    }

    // MARK: - Public API

    func requestPermission() {
        guard authState == .notDetermined else { return }
        clManager.requestWhenInUseAuthorization()
    }

    func startUpdating() {
        guard authState == .authorized else {
            requestPermission()
            return
        }
        clManager.startUpdatingLocation()
        isUpdating = true
    }

    func stopUpdating() {
        clManager.stopUpdatingLocation()
        isUpdating = false
    }

    /// Distance in meters from current location to a map coordinate.
    func distance(to coordinate: CLLocationCoordinate2D) -> CLLocationDistance? {
        guard let location else { return nil }
        return location.distance(from: CLLocation(
            latitude: coordinate.latitude,
            longitude: coordinate.longitude
        ))
    }

    /// Proximity category based on AppConstants thresholds.
    func proximity(to coordinate: CLLocationCoordinate2D) -> ProximityLevel {
        guard let d = distance(to: coordinate) else { return .unknown }
        switch d {
        case ..<AppConstants.Location.closeRadiusMeters:   return .close
        case ..<AppConstants.Location.warningRadiusMeters: return .warning
        default:                                            return .nearby
        }
    }

    // MARK: - Private helpers

    private static func mapAuth(_ status: CLAuthorizationStatus) -> LocationAuthState {
        switch status {
        case .notDetermined:                      return .notDetermined
        case .denied, .restricted:                return .denied
        case .authorizedWhenInUse, .authorizedAlways: return .authorized
        @unknown default:                         return .notDetermined
        }
    }
}

// MARK: - Proximity Level

enum ProximityLevel {
    case close    // < 100 m  → red
    case warning  // < 200 m  → orange
    case nearby   // ≥ 200 m  → green
    case unknown  // no location yet
}

// MARK: - CLLocationManagerDelegate

extension LocationManager: CLLocationManagerDelegate {

    // Called on main thread since clManager was created on @MainActor
    nonisolated func locationManager(
        _ manager: CLLocationManager,
        didUpdateLocations locations: [CLLocation]
    ) {
        guard let latest = locations.last else { return }
        MainActor.assumeIsolated {
            location = latest
            streamContinuation.yield(latest)
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        MainActor.assumeIsolated {
            authState = Self.mapAuth(status)
            if authState == .authorized { startUpdating() }
        }
    }

    nonisolated func locationManager(
        _ manager: CLLocationManager,
        didFailWithError error: Error
    ) {
        // CLError.locationUnknown (code 0) is transient — ignore silently.
        // Other errors surface through authState going to .denied.
        guard (error as? CLError)?.code != .locationUnknown else { return }
        print("[LocationManager] \(error.localizedDescription)")
    }
}
