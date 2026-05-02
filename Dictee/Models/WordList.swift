import Foundation
import SwiftData

@Model
final class WordList {
    var id: UUID = UUID()
    var name: String
    var createdAt: Date = Date()
    var photoData: Data?
    var lastPracticedAt: Date?
    /// Mean OCR confidence from a handwriting import (0–1).
    /// `nil` for lists imported as printed text.
    var handwritingNeatness: Double? = nil

    @Relationship(deleteRule: .cascade, inverse: \Word.list)
    var words: [Word] = []

    init(name: String, photoData: Data? = nil) {
        self.name = name
        self.photoData = photoData
    }
}
