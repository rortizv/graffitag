import SwiftUI

struct TagAnnotationView: View {
    let tag: GraffiTag
    let level: ProximityLevel
    let isSelected: Bool

    @State private var pulse = false

    var body: some View {
        ZStack {
            // Outer pulse ring (only when close/warning)
            if level == .close || level == .warning {
                Circle()
                    .stroke(glowColor.opacity(pulse ? 0 : 0.5), lineWidth: 2)
                    .frame(width: pulse ? 44 : 28)
                    .animation(
                        .easeOut(duration: 1.2).repeatForever(autoreverses: false),
                        value: pulse
                    )
            }

            // Pin body
            ZStack {
                Circle()
                    .fill(glowColor)
                    .frame(width: isSelected ? 36 : 28)
                    .shadow(color: glowColor.opacity(0.7), radius: isSelected ? 8 : 4)

                Text("🎨")
                    .font(.system(size: isSelected ? 18 : 14))
            }
            .scaleEffect(isSelected ? 1.15 : 1.0)
            .animation(.spring(response: 0.3), value: isSelected)
        }
        .onAppear { pulse = true }
    }

    private var glowColor: Color {
        switch level {
        case .close:   return .red
        case .warning: return .orange
        case .nearby:  return .green
        case .unknown: return .gray
        }
    }
}
