import SwiftUI
import ARKit
import RealityKit

// MARK: - ARViewContainer (UIViewRepresentable)

struct ARViewContainer: UIViewRepresentable {
    let captureService: ARCaptureService

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        arView.environment.background = .cameraFeed()
        captureService.attach(to: arView)
        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {}
}

// MARK: - AR Camera Screen

struct ARCameraView: View {
    @Bindable var viewModel: ARViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            // AR live feed
            ARViewContainer(captureService: viewModel.captureService)
                .ignoresSafeArea()

            // HUD overlay
            VStack {
                // Top bar
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.white)
                            .padding(10)
                            .background(Circle().fill(.black.opacity(0.5)))
                    }

                    Spacer()

                    // Tracking status pill
                    Text(viewModel.captureService.trackingState)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(.black.opacity(0.5)))
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)

                Spacer()

                // Bottom — shutter
                VStack(spacing: 16) {
                    Text("Point at a wall or surface")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))

                    Button {
                        Task { await viewModel.capture() }
                    } label: {
                        ZStack {
                            Circle()
                                .strokeBorder(.white, lineWidth: 3)
                                .frame(width: 72, height: 72)
                            if viewModel.isCapturing {
                                ProgressView().tint(.white)
                            } else {
                                Circle()
                                    .fill(.white)
                                    .frame(width: 58, height: 58)
                            }
                        }
                    }
                    .disabled(viewModel.isCapturing)
                }
                .padding(.bottom, 48)
            }
        }
        .statusBarHidden()
    }
}
