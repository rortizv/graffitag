import SwiftUI

// MARK: - HeartbeatModifier
// Animated glow border that pulses based on proximity to a GraffiTag.
// close   (<100m) → red,    fast pulse
// warning (<200m) → orange, slow pulse
// nearby  (≥200m) → green,  no animation

struct HeartbeatModifier: ViewModifier {
    let level: ProximityLevel

    @State private var glowRadius: CGFloat = 4
    @State private var opacity: CGFloat = 0.6

    private var color: Color {
        switch level {
        case .close:   return .red
        case .warning: return .orange
        case .nearby:  return .green
        case .unknown: return Color.white.opacity(0.2)
        }
    }

    private var duration: Double {
        switch level {
        case .close:   return 0.5
        case .warning: return 0.9
        default:       return 0
        }
    }

    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(color.opacity(opacity), lineWidth: 2)
            )
            .shadow(color: color.opacity(opacity * 0.8), radius: glowRadius)
            .onAppear { startAnimation() }
            .onChange(of: level) { _, _ in resetAnimation() }
    }

    private func startAnimation() {
        guard duration > 0 else { return }
        withAnimation(
            .easeInOut(duration: duration)
            .repeatForever(autoreverses: true)
        ) {
            glowRadius = 14
            opacity = 1.0
        }
    }

    private func resetAnimation() {
        glowRadius = 4
        opacity = 0.6
        startAnimation()
    }
}

extension View {
    func heartbeat(level: ProximityLevel) -> some View {
        modifier(HeartbeatModifier(level: level))
    }
}
