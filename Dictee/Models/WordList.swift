import Foundation
import SwiftData

@Model
final class WordList {
    var id: UUID = UUID()
    var name: String
    var createdAt: Date = Date()
    var photoData: Data?
    var lastPracticedAt: Date?

    @Relationship(deleteRule: .cascade, inverse: \Word.list)
    var words: [Word] = []

    init(name: String, photoData: Data? = nil) {
        self.name = name
        self.photoData = photoData
    }
}
