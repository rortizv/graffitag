import SwiftUI

struct ProximityBadge: View {
    let level: ProximityLevel
    let distance: Double?

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
                .shadow(color: color, radius: 4)

            if let distance {
                Text(formatted(distance))
                    .font(.system(.caption2, design: .monospaced).weight(.semibold))
                    .foregroundStyle(.white)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            Capsule().fill(color.opacity(0.18))
                .overlay(Capsule().strokeBorder(color.opacity(0.4), lineWidth: 1))
        )
    }

    private var color: Color {
        switch level {
        case .close:   return .red
        case .warning: return .orange
        case .nearby:  return .green
        case .unknown: return .gray
        }
    }

    private func formatted(_ meters: Double) -> String {
        meters < 1000 ? "\(Int(meters))m" : String(format: "%.1fkm", meters / 1000)
    }
}
