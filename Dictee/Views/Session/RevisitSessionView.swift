import SwiftUI
import SwiftData

struct RevisitSessionView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \ReviewBankEntry.addedAt) private var reviewBank: [ReviewBankEntry]
    @AppStorage("revisitSessionCap") private var sessionCap: Int = 20

    var body: some View {
        let capped = Array(reviewBank.prefix(sessionCap))
        let sessionWords = capped.map {
            SessionWord(id: $0.id, text: $0.wordText, reviewEntryId: $0.id)
        }

        if sessionWords.isEmpty {
            // Shouldn't normally appear (button is hidden when bank is empty)
            ContentUnavailableView(
                "Review Bank Empty",
                systemImage: "checkmark.circle",
                description: Text("All caught up! Keep practising your word lists.")
            )
        } else {
            SessionView(
                words: sessionWords,
                title: "Revisit",
                listId: nil,
                isRevisit: true,
                onComplete: { dismiss() }
            )
        }
    }
}
