import Foundation
import SwiftData

/// One reward grant produced by a completed dictation session.
///
/// The total star balance is *derived* by summing `starsEarned` across all
/// transactions — there is no separate balance row to keep in sync.
///
/// `dictationSessionId` is the `SessionResult.id` of the dictation that
/// produced this grant; awarding logic is idempotent against this field so
/// a re-rendered result screen cannot grant stars twice for the same session.
@Model
final class RewardTransaction {
    var id: UUID = UUID()
    var dictationSessionId: UUID
    var starsEarned: Int
    /// Free-form reason tag — Slice 1 only uses `"correct_words"`.
    /// Future slices may add streak / surprise / unlock reasons.
    var reason: String
    var createdAt: Date = Date()

    init(dictationSessionId: UUID, starsEarned: Int, reason: String) {
        self.dictationSessionId = dictationSessionId
        self.starsEarned = starsEarned
        self.reason = reason
    }
}
