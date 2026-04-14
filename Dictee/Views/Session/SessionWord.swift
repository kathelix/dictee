import Foundation

/// A lightweight value type used to drive both Practice and Revisit sessions.
struct SessionWord: Identifiable {
    let id: UUID
    let text: String
    /// Non-nil only in Revisit sessions; points to the ReviewBankEntry to remove on correct answer.
    let reviewEntryId: UUID?

    init(id: UUID, text: String, reviewEntryId: UUID? = nil) {
        self.id = id
        self.text = text
        self.reviewEntryId = reviewEntryId
    }
}
