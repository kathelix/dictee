import Foundation
import SwiftData

@Model
final class Answer {
    var id: UUID = UUID()
    var wordId: UUID
    var wordText: String
    var typed: String
    var session: SessionResult?

    /// Derived from stored fields — single source of truth for correctness.
    var correct: Bool {
        typed.normalizedForDictation == wordText.normalizedForDictation
    }

    init(wordId: UUID, wordText: String, typed: String) {
        self.wordId = wordId
        self.wordText = wordText
        self.typed = typed
    }
}
