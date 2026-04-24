import SwiftUI

/// Circular progress ring showing the percentage score from the last
/// practice session for a word list.
///
/// - `percentage` nil  → never practised: gray empty ring, no label
/// - `percentage` 0.0…1.0 → filled arc + centred percentage label
struct ScoreRing: View {
    let percentage: Double?

    // MARK: - Derived

    private var fill: Double { percentage ?? 0 }

    private var ringColor: Color {
        guard let p = percentage else { return Color(.systemGray4) }
        if p >= 0.90 { return .green }
        if p >= 0.75 { return .orange }
        return .red
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            // Background track
            Circle()
                .stroke(Color(.systemGray5), lineWidth: 4)

            // Filled arc
            Circle()
                .trim(from: 0, to: fill)
                .stroke(ringColor,
                        style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeOut(duration: 0.5), value: fill)

            // Percentage label (only when practised)
            if let p = percentage {
                Text("\(Int((p * 100).rounded()))%")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(ringColor)
            }
        }
        .frame(width: 44, height: 44)
    }
}

// MARK: - Preview

#Preview {
    HStack(spacing: 20) {
        ScoreRing(percentage: nil)          // never practised
        ScoreRing(percentage: 0.40)         // red
        ScoreRing(percentage: 0.80)         // amber
        ScoreRing(percentage: 0.92)         // green
        ScoreRing(percentage: 1.00)         // perfect
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
