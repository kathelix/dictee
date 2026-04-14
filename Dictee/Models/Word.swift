import Foundation
import SwiftData

@Model
final class Word {
    var id: UUID = UUID()
    var text: String
    var list: WordList?

    init(text: String) {
        self.text = text
    }
}
