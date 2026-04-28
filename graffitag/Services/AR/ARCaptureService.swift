import Foundation
import ARKit
import RealityKit
internal import UIKit
import CoreLocation

// MARK: - Capture Result

struct ARCaptureResult {
    let snapshot: UIImage
    let worldMap: ARWorldMap?
    let depthData: Data?          // nil on non-LiDAR devices
    let coordinate: CLLocationCoordinate2D
}

// MARK: - ARCaptureService

@MainActor
final class ARCaptureService: NSObject {

    // MARK: - State

    enum SessionState: Equatable {
        case idle
        case running
        case paused
        case failed(String)
    }

    private(set) var sessionState: SessionState = .idle
    private(set) var trackingState: String = "Initializing…"
    private(set) var isLiDARAvailable: Bool = false

    // MARK: - Private

    private var arView: ARView?
    private var session: ARSession { arView?.session ?? ARSession() }

    // MARK: - Setup

    func attach(to arView: ARView) {
        self.arView = arView
        isLiDARAvailable = ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh)

        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal, .vertical]
        config.environmentTexturing = .automatic
        if isLiDARAvailable {
            config.sceneReconstruction = .mesh
            config.frameSemantics = .sceneDepth
        }

        arView.session.delegate = self
        arView.session.run(config, options: [.resetTracking, .removeExistingAnchors])
        sessionState = .running
    }

    func pause() {
        arView?.session.pause()
        sessionState = .paused
    }

    func resume() {
        guard let arView else { return }
        attach(to: arView)
    }

    // MARK: - Capture

    func capture(at coordinate: CLLocationCoordinate2D) async throws -> ARCaptureResult {
        guard let arView else {
            throw AppError.arSessionFailed("ARView not attached")
        }

        // 1. Snapshot
        let snapshot = try await withCheckedThrowingContinuation { (cont: CheckedContinuation<UIImage, Error>) in
            arView.snapshot(saveToHDR: false) { image in
                if let image { cont.resume(returning: image) }
                else { cont.resume(throwing: AppError.arSessionFailed("Snapshot failed")) }
            }
        }

        // 2. WorldMap
        let worldMap = try? await withCheckedThrowingContinuation { (cont: CheckedContinuation<ARWorldMap, Error>) in
            arView.session.getCurrentWorldMap { map, error in
                if let map { cont.resume(returning: map) }
                else { cont.resume(throwing: error ?? AppError.arSessionFailed("WorldMap unavailable")) }
            }
        }

        // 3. Depth (LiDAR only)
        var depthData: Data? = nil
        if isLiDARAvailable,
           let frame = arView.session.currentFrame,
           let sceneDepth = frame.sceneDepth {
            depthData = try? encodeDepth(sceneDepth.depthMap)
        }

        return ARCaptureResult(
            snapshot: snapshot,
            worldMap: worldMap,
            depthData: depthData,
            coordinate: coordinate
        )
    }

    // MARK: - Raycast (2D → 3D projection)

    /// Projects a screen-space point into world space using plane hit-testing.
    func worldPosition(for screenPoint: CGPoint) -> SIMD3<Float>? {
        guard let arView else { return nil }
        let results = arView.raycast(
            from: screenPoint,
            allowing: .estimatedPlane,
            alignment: .any
        )
        return results.first.map {
            SIMD3<Float>(
                $0.worldTransform.columns.3.x,
                $0.worldTransform.columns.3.y,
                $0.worldTransform.columns.3.z
            )
        }
    }

    // MARK: - Private helpers

    private func encodeDepth(_ depthMap: CVPixelBuffer) throws -> Data {
        CVPixelBufferLockBaseAddress(depthMap, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(depthMap, .readOnly) }
        guard let base = CVPixelBufferGetBaseAddress(depthMap) else {
            throw AppError.arSessionFailed("Cannot read depth buffer")
        }
        let byteCount = CVPixelBufferGetDataSize(depthMap)
        return Data(bytes: base, count: byteCount)
    }
}

// MARK: - ARSessionDelegate

extension ARCaptureService: ARSessionDelegate {
    nonisolated func session(_ session: ARSession, didUpdate frame: ARFrame) {
        let desc: String
        switch frame.camera.trackingState {
        case .normal:                         desc = "Tracking"
        case .notAvailable:                   desc = "Not available"
        case .limited(.initializing):         desc = "Initializing…"
        case .limited(.excessiveMotion):      desc = "Slow down"
        case .limited(.insufficientFeatures): desc = "More texture needed"
        case .limited(.relocalizing):         desc = "Relocalizing…"
        @unknown default:                     desc = "Unknown"
        }
        Task { @MainActor in self.trackingState = desc }
    }

    nonisolated func session(_ session: ARSession, didFailWithError error: Error) {
        Task { @MainActor in
            self.sessionState = .failed(error.localizedDescription)
        }
    }

    nonisolated func sessionWasInterrupted(_ session: ARSession) {
        Task { @MainActor in self.sessionState = .paused }
    }

    nonisolated func sessionInterruptionEnded(_ session: ARSession) {
        Task { @MainActor in self.resume() }
    }
}
