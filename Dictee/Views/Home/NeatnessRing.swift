import SwiftUI

/// Circular progress ring showing a handwriting neatness score derived from
/// the OCR confidence of a handwriting import.
///
/// The ring fill represents the neatness percentage (0–1). A pencil icon
/// inside distinguishes it from the practice score ring.
///
/// | Score      | Ring colour |
/// |------------|-------------|
/// | ≥ 90%      | Green       |
/// | ≥ 75%      | Amber       |
/// | < 75%      | Red         |
struct NeatnessRing: View {
    let percentage: Double  // 0–1

    private var ringColor: Color {
        if percentage >= 0.90 { return .green }
        if percentage >= 0.75 { return .orange }
        return .red
    }

    var body: some View {
        ZStack {
            // Background track
            Circle()
                .stroke(Color(.systemGray5), lineWidth: 4)

            // Filled arc
            Circle()
                .trim(from: 0, to: percentage)
                .stroke(ringColor, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeOut(duration: 0.5), value: percentage)

            // Pencil icon — distinguishes this from the score ring
            Image(systemName: "pencil")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(ringColor)
        }
        .frame(width: 44, height: 44)
    }
}

// MARK: - Preview

#Preview {
    HStack(spacing: 20) {
        NeatnessRing(percentage: 0.92)  // green
        NeatnessRing(percentage: 0.80)  // amber
        NeatnessRing(percentage: 0.50)  // red
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
