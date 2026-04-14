import Foundation
import SwiftData

/// A denormalized record of a word the pupil has misspelled.
/// Stores the word text directly so entries survive list deletion.
@Model
final class ReviewBankEntry {
    var id: UUID = UUID()
    var wordId: UUID
    var wordText: String
    var addedAt: Date = Date()
    var missCount: Int = 1

    init(wordId: UUID, wordText: String) {
        self.wordId = wordId
        self.wordText = wordText
    }
}
