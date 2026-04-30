import Foundation

/// Reward thresholds and progress calculation for the learner reward system.
///
/// Slice 1 has a single locked threshold; future slices may add tiers
/// (e.g. 50 → small surprise, 150 → secret game) by extending this type
/// without touching call sites.
struct RewardRule {
    /// Stars required to fill the locked Secret reward bar in Slice 1.
    static let secretRewardThreshold: Int = 50

    /// 0…1 progress toward the secret reward threshold, clamped at the upper end.
    /// Returns 0 when the threshold is non-positive (defensive — should not happen).
    static func progressFraction(totalStars: Int) -> Double {
        guard secretRewardThreshold > 0 else { return 0 }
        let raw = Double(totalStars) / Double(secretRewardThreshold)
        return min(1, max(0, raw))
    }
}
