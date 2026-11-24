import SwiftUI

/// Fortschrittsring (z. B. Kalorien gegessen vs. Ziel).
struct RingView: View {
    var progress: Double
    var color: Color
    var lineWidth: CGFloat = 14

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.2), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: min(max(progress, 0), 1))
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeOut(duration: 0.6), value: progress)
        }
    }
}

extension Color {
    static func stressColor(_ level: Double) -> Color {
        switch level {
        case ..<3.5: return .green
        case ..<6.5: return .yellow
        case ..<8.5: return .orange
        default: return .red
        }
    }
}
