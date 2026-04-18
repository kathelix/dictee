import Foundation
import SwiftData

@Model
final class SessionResult {
    var id: UUID = UUID()
    var listId: UUID?
    var listName: String
    var date: Date = Date()
    var isRevisit: Bool
    /// True when the session was completed via the paper dictation flow
    /// (pupil wrote answers on paper and photographed them).
    var isPaperSession: Bool = false

    @Relationship(deleteRule: .cascade, inverse: \Answer.session)
    var answers: [Answer] = []

    var correctCount: Int { answers.filter(\.correct).count }
    var total: Int { answers.count }

    init(listId: UUID?, listName: String, isRevisit: Bool, isPaperSession: Bool = false) {
        self.listId = listId
        self.listName = listName
        self.isRevisit = isRevisit
        self.isPaperSession = isPaperSession
    }
}
