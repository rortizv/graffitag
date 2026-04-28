import Foundation
import MapKit
import CoreLocation
import SwiftUI

@MainActor
@Observable
final class MapViewModel {

    // MARK: - State

    var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060),
        span: MKCoordinateSpan(latitudeDelta: 0.008, longitudeDelta: 0.008)
    )
    var selectedTag: GraffiTag?
    var showTagDetail = false
    var showNewTagSheet = false

    var nearbyTags: [GraffiTag] { firestoreService.nearbyTags }
    var isLoading: Bool { firestoreService.isLoading }

    // MARK: - Dependencies

    private let firestoreService: FirestoreService
    private let locationManager: LocationManager

    init(firestoreService: FirestoreService, locationManager: LocationManager) {
        self.firestoreService = firestoreService
        self.locationManager = locationManager
    }

    // MARK: - Lifecycle

    func onAppear() {
        locationManager.startUpdating()
        if let coord = locationManager.location?.coordinate {
            center(on: coord)
        }
        observeLocation()
    }

    func onDisappear() {
        firestoreService.stopListening()
    }

    // MARK: - Actions

    func centerOnUser() {
        guard let coord = locationManager.location?.coordinate else { return }
        withAnimation { region.center = coord }
        HapticManager.shared.impact(.light)
    }

    func selectTag(_ tag: GraffiTag) {
        selectedTag = tag
        showTagDetail = true
        HapticManager.shared.impact(.light)
    }

    func proximity(to tag: GraffiTag) -> ProximityLevel {
        locationManager.proximity(to: tag.coordinate)
    }

    func distance(to tag: GraffiTag) -> CLLocationDistance? {
        locationManager.distance(to: tag.coordinate)
    }

    func deleteTag(_ tag: GraffiTag) async {
        guard let id = tag.id else { return }
        try? await firestoreService.deleteTag(id: id)
    }

    func likeTag(_ tag: GraffiTag) async {
        guard let id = tag.id else { return }
        try? await firestoreService.incrementLikes(tagId: id)
        HapticManager.shared.notification(.success)
    }

    // MARK: - Private

    private func center(on coord: CLLocationCoordinate2D) {
        region = MKCoordinateRegion(
            center: coord,
            span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
        )
        firestoreService.startListeningNearbyTags(center: coord)
    }

    private func observeLocation() {
        Task {
            for await location in locationManager.locationStream {
                center(on: location.coordinate)
            }
        }
    }
}

