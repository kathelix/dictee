import Foundation
import SwiftData

/// Grants and tallies stars earned from completed dictations.
///
/// Slice 1 rule: **1 star per correctly written word**, granted exactly once
/// per dictation session (idempotent against `SessionResult.id`).
///
/// The total balance is derived by summing all transactions on demand —
/// no cached counter to drift out of sync.
enum DictationRewardService {

    /// Stars earned for a given correct-answer count. Slice 1: 1 star per correct word.
    static func starsEarned(correctCount: Int) -> Int {
        max(0, correctCount)
    }

    /// Idempotently records a star grant for `sessionId`.
    /// Returns the number of stars granted by *this* call (0 if the session
    /// was already awarded earlier — including if it was awarded with 0 stars).
    ///
    /// A 0-star transaction is still recorded so a later re-render of the same
    /// result screen cannot accidentally inject stars for a session that has
    /// already been processed.
    @MainActor
    @discardableResult
    static func award(sessionId: UUID, correctCount: Int, in context: ModelContext) -> Int {
        // Fetch-all + Swift filter rather than a #Predicate on UUID — the
        // transaction table is bounded by the lifetime number of completed
        // dictations (tens to low hundreds), and it sidesteps SwiftData
        // predicate quirks around UUID equality.
        let all = (try? context.fetch(FetchDescriptor<RewardTransaction>())) ?? []
        if all.contains(where: { $0.dictationSessionId == sessionId }) {
            return 0
        }
        let stars = starsEarned(correctCount: correctCount)
        let txn = RewardTransaction(
            dictationSessionId: sessionId,
            starsEarned: stars,
            reason: "correct_words"
        )
        context.insert(txn)
        return stars
    }

    /// Total lifetime stars across all recorded transactions.
    @MainActor
    static func totalStars(in context: ModelContext) -> Int {
        let all = (try? context.fetch(FetchDescriptor<RewardTransaction>())) ?? []
        return all.reduce(0) { $0 + $1.starsEarned }
    }
}
