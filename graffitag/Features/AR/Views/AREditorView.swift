import SwiftUI

// MARK: - Drawing Canvas

private struct DrawingCanvas: UIViewRepresentable {
    @Binding var strokes: [DrawStroke]
    @Binding var currentStroke: DrawStroke?
    let selectedColor: UIColor
    let brushSize: CGFloat
    let onBegin: (CGPoint) -> Void
    let onMove: (CGPoint) -> Void
    let onEnd: () -> Void

    func makeUIView(context: Context) -> CanvasUIView {
        let view = CanvasUIView()
        view.backgroundColor = .clear
        view.delegate = context.coordinator
        let pan = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePan))
        pan.maximumNumberOfTouches = 1
        view.addGestureRecognizer(pan)
        return view
    }

    func updateUIView(_ uiView: CanvasUIView, context: Context) {
        uiView.strokes = strokes
        uiView.currentStroke = currentStroke
        uiView.setNeedsDisplay()
    }

    func makeCoordinator() -> Coordinator { Coordinator(parent: self) }

    final class Coordinator: NSObject {
        var parent: DrawingCanvas
        init(parent: DrawingCanvas) { self.parent = parent }

        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            guard let view = gesture.view else { return }
            let pt = gesture.location(in: view)
            switch gesture.state {
            case .began:   parent.onBegin(pt)
            case .changed: parent.onMove(pt)
            case .ended, .cancelled: parent.onEnd()
            default: break
            }
        }
    }
}

final class CanvasUIView: UIView {
    var strokes: [DrawStroke] = []
    var currentStroke: DrawStroke?
    weak var delegate: AnyObject?

    override func draw(_ rect: CGRect) {
        guard let ctx = UIGraphicsGetCurrentContext() else { return }
        ctx.setLineCap(.round)
        ctx.setLineJoin(.round)

        func drawStroke(_ stroke: DrawStroke) {
            guard stroke.points.count > 1 else { return }
            ctx.setStrokeColor(stroke.color.cgColor)
            ctx.setLineWidth(stroke.lineWidth)
            ctx.beginPath()
            ctx.move(to: stroke.points[0])
            for pt in stroke.points.dropFirst() { ctx.addLine(to: pt) }
            ctx.strokePath()
        }

        strokes.forEach(drawStroke)
        if let current = currentStroke { drawStroke(current) }
    }
}

// MARK: - Color Palette

private let paletteColors: [UIColor] = [
    .orange, .red, .yellow, .green, .cyan, .purple, .white, .black
]

// MARK: - AR Editor View

struct AREditorView: View {
    @Bindable var viewModel: ARViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let result = viewModel.captureResult {
                // Background snapshot
                Image(uiImage: result.snapshot)
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()

                // Drawing canvas over snapshot
                DrawingCanvas(
                    strokes: $viewModel.strokes,
                    currentStroke: $viewModel.currentStroke,
                    selectedColor: viewModel.selectedColor,
                    brushSize: viewModel.brushSize,
                    onBegin: { viewModel.beginStroke(at: $0) },
                    onMove:  { viewModel.continueStroke(at: $0) },
                    onEnd:   { viewModel.endStroke() }
                )
                .ignoresSafeArea()

                // Tool overlay
                VStack {
                    // Top bar
                    HStack {
                        Button { viewModel.retake() } label: {
                            Image(systemName: "arrow.uturn.backward")
                                .toolbarIcon()
                        }
                        Spacer()
                        Button { viewModel.undoLastStroke() } label: {
                            Image(systemName: "arrow.uturn.left")
                                .toolbarIcon()
                        }
                        Button { viewModel.clearCanvas() } label: {
                            Image(systemName: "trash")
                                .toolbarIcon()
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)

                    Spacer()

                    // Bottom toolbar
                    VStack(spacing: 12) {
                        // Brush size
                        HStack {
                            Image(systemName: "circle.fill")
                                .font(.system(size: 8))
                                .foregroundStyle(.white)
                            Slider(value: $viewModel.brushSize, in: 2...24)
                                .tint(.orange)
                            Image(systemName: "circle.fill")
                                .font(.system(size: 20))
                                .foregroundStyle(.white)
                        }
                        .padding(.horizontal, 20)

                        // Color palette
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(paletteColors, id: \.self) { color in
                                    let isSelected = viewModel.selectedColor == color
                                    Circle()
                                        .fill(Color(color))
                                        .frame(width: isSelected ? 36 : 28, height: isSelected ? 36 : 28)
                                        .overlay(
                                            Circle().strokeBorder(.white,
                                                lineWidth: isSelected ? 2 : 0)
                                        )
                                        .shadow(color: Color(color), radius: isSelected ? 6 : 0)
                                        .onTapGesture { viewModel.selectedColor = color }
                                        .animation(.spring(response: 0.2), value: isSelected)
                                }
                            }
                            .padding(.horizontal, 20)
                        }

                        // Post button
                        Button {
                            viewModel.showMetadataForm = true
                        } label: {
                            Label("Post Tag", systemImage: "paperplane.fill")
                                .font(.headline)
                                .foregroundStyle(.black)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(RoundedRectangle(cornerRadius: 12).fill(Color.orange))
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 40)
                    .background(
                        LinearGradient(
                            colors: [.clear, .black.opacity(0.85)],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                }
            }

            // Upload overlay
            if viewModel.isUploading {
                Color.black.opacity(0.7).ignoresSafeArea()
                VStack(spacing: 16) {
                    ProgressView().tint(.orange).scaleEffect(1.5)
                    Text("Posting your tag…")
                        .font(.subheadline).foregroundStyle(.white)
                }
            }
        }
        .sheet(isPresented: $viewModel.showMetadataForm) {
            TagMetadataSheet(viewModel: viewModel, onDismiss: { dismiss() })
                .presentationDetents([.medium])
        }
        .statusBarHidden()
    }
}

// MARK: - Tag Metadata Sheet

private struct TagMetadataSheet: View {
    @Bindable var viewModel: ARViewModel
    let onDismiss: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 20) {
                Text("Tag Details")
                    .font(.headline).foregroundStyle(.white)
                    .padding(.top, 20)

                GraffiTextField(placeholder: "Title (required)", text: $viewModel.tagTitle)
                GraffiTextField(placeholder: "Description (optional)", text: $viewModel.tagDescription)

                if let error = viewModel.errorMessage {
                    Text(error).font(.caption).foregroundStyle(.red)
                }

                if viewModel.uploadSuccess {
                    Label("Tag posted!", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                dismiss(); onDismiss()
                            }
                        }
                } else {
                    Button {
                        Task { await viewModel.uploadTag() }
                    } label: {
                        Group {
                            if viewModel.isUploading {
                                ProgressView().tint(.black)
                            } else {
                                Text("Post Tag")
                                    .font(.headline).foregroundStyle(.black)
                            }
                        }
                        .frame(maxWidth: .infinity).padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(viewModel.tagTitle.isEmpty ? Color.gray.opacity(0.4) : Color.orange)
                        )
                    }
                    .disabled(viewModel.tagTitle.isEmpty || viewModel.isUploading)

                    Button("Cancel") { dismiss() }.foregroundStyle(.gray)
                }
            }
            .padding(24)
        }
    }
}

// MARK: - Helpers

private extension Image {
    func toolbarIcon() -> some View {
        self
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(.white)
            .padding(10)
            .background(Circle().fill(.black.opacity(0.55)))
    }
}
