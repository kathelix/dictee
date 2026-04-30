import SwiftUI

/// Compact, non-interactive total-stars indicator shown in the Home toolbar.
///
/// Renders nothing on its own when `totalStars == 0` — the caller decides
/// whether to show the badge based on its own data.
struct StarBalanceBadge: View {
    let totalStars: Int

    var body: some View {
        HStack(spacing: 4) {
            Text("⭐")
            Text("\(totalStars)")
                .fontWeight(.semibold)
                .monospacedDigit()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(totalStars) star\(totalStars == 1 ? "" : "s") earned")
    }
}

#Preview {
    VStack(spacing: 16) {
        StarBalanceBadge(totalStars: 1)
        StarBalanceBadge(totalStars: 48)
        StarBalanceBadge(totalStars: 1234)
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
