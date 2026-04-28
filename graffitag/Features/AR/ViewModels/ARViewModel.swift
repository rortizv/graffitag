import Foundation
import ARKit
import RealityKit
internal import UIKit
import CoreLocation
import FirebaseAuth

// MARK: - Draw Stroke

struct DrawStroke: Identifiable {
    let id = UUID()
    var points: [CGPoint]
    var color: UIColor
    var lineWidth: CGFloat
    var world3D: [SIMD3<Float>]   // projected 3D positions
}

// MARK: - ARViewModel

@MainActor
@Observable
final class ARViewModel {

    // MARK: - State

    var mode: Mode = .camera
    var captureResult: ARCaptureResult?
    var strokes: [DrawStroke] = []
    var currentStroke: DrawStroke?
    var selectedColor: UIColor = .orange
    var brushSize: CGFloat = 6
    var isCapturing = false
    var isUploading = false
    var errorMessage: String?
    var uploadSuccess = false

    // Tag metadata
    var tagTitle = ""
    var tagDescription = ""
    var showMetadataForm = false

    enum Mode { case camera, editor }

    // MARK: - Dependencies

    let captureService = ARCaptureService()
    private let firestoreService: FirestoreService
    private let authService: AuthService
    private let locationManager: LocationManager

    init(
        firestoreService: FirestoreService,
        authService: AuthService,
        locationManager: LocationManager
    ) {
        self.firestoreService = firestoreService
        self.authService = authService
        self.locationManager = locationManager
    }

    // MARK: - Drawing

    func beginStroke(at point: CGPoint) {
        currentStroke = DrawStroke(
            points: [point],
            color: selectedColor,
            lineWidth: brushSize,
            world3D: []
        )
    }

    func continueStroke(at point: CGPoint) {
        guard var stroke = currentStroke else { return }
        stroke.points.append(point)
        if let world = captureService.worldPosition(for: point) {
            stroke.world3D.append(world)
        }
        currentStroke = stroke
    }

    func endStroke() {
        guard let stroke = currentStroke, stroke.points.count > 1 else {
            currentStroke = nil
            return
        }
        strokes.append(stroke)
        currentStroke = nil
    }

    func undoLastStroke() {
        guard !strokes.isEmpty else { return }
        strokes.removeLast()
        HapticManager.shared.impact(.light)
    }

    func clearCanvas() {
        strokes.removeAll()
        HapticManager.shared.impact(.medium)
    }

    // MARK: - Capture

    func capture() async {
        guard let coordinate = locationManager.location?.coordinate else {
            errorMessage = "Location unavailable. Move to an open area."
            return
        }
        isCapturing = true
        defer { isCapturing = false }
        do {
            captureResult = try await captureService.capture(at: coordinate)
            mode = .editor
            HapticManager.shared.notification(.success)
        } catch let e as AppError {
            errorMessage = e.errorDescription
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func retake() {
        captureResult = nil
        strokes.removeAll()
        currentStroke = nil
        mode = .camera
    }

    // MARK: - Upload

    func uploadTag() async {
        guard
            let result = captureResult,
            let user = authService.currentUser,
            !tagTitle.isEmpty
        else { return }

        isUploading = true
        defer { isUploading = false }
        errorMessage = nil

        do {
            let tagId = UUID().uuidString

            // Composite: overlay strokes onto snapshot
            let finalImage = rendered(snapshot: result.snapshot)

            // Upload image
            let imageURL = try await StorageService.shared.uploadTagImage(finalImage, tagId: tagId)

            // Upload depth map if available
            var depthURL: URL? = nil
            if let depthData = result.depthData {
                depthURL = try await StorageService.shared.uploadDepthMap(depthData, tagId: tagId)
            }

            // Upload world map if available
            var worldMapURL: URL? = nil
            if let worldMap = result.worldMap,
               let wmData = try? NSKeyedArchiver.archivedData(withRootObject: worldMap, requiringSecureCoding: true) {
                worldMapURL = try await StorageService.shared.uploadWorldMap(wmData, tagId: tagId)
            }

            // Write Firestore doc
            let tag = GraffiTag(
                authorId: user.uid,
                authorName: user.displayName ?? "Artist",
                title: tagTitle,
                description: tagDescription,
                imageURL: imageURL.absoluteString,
                depthMapURL: depthURL?.absoluteString,
                worldMapURL: worldMapURL?.absoluteString,
                latitude: result.coordinate.latitude,
                longitude: result.coordinate.longitude,
                createdAt: Date(),
                likesCount: 0
            )
            try await firestoreService.createTag(tag)

            uploadSuccess = true
            HapticManager.shared.notification(.success)
        } catch let e as AppError {
            errorMessage = e.errorDescription
            HapticManager.shared.notification(.error)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Rendering

    private func rendered(snapshot: UIImage) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: snapshot.size)
        return renderer.image { ctx in
            snapshot.draw(at: .zero)
            for stroke in strokes {
                guard stroke.points.count > 1 else { continue }
                let path = UIBezierPath()
                path.lineWidth = stroke.lineWidth
                path.lineCapStyle = .round
                path.lineJoinStyle = .round
                stroke.color.setStroke()
                path.move(to: stroke.points[0])
                for pt in stroke.points.dropFirst() { path.addLine(to: pt) }
                path.stroke()
            }
        }
    }
}
