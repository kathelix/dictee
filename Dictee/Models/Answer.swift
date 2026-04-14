import Foundation
import SwiftData

@Model
final class Answer {
    var id: UUID = UUID()
    var wordId: UUID
    var wordText: String
    var typed: String
    var correct: Bool
    var session: SessionResult?

    init(wordId: UUID, wordText: String, typed: String) {
        self.wordId = wordId
        self.wordText = wordText
        self.typed = typed
        // Case-insensitive, accent-sensitive comparison
        self.correct = typed.trimmingCharacters(in: .whitespaces).lowercased()
            == wordText.trimmingCharacters(in: .whitespaces).lowercased()
    }
}
