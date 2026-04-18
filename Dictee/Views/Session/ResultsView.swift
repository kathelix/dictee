import SwiftUI
import SwiftData

struct ResultsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var reviewBank: [ReviewBankEntry]

    let answers: [(word: SessionWord, typed: String)]
    let title: String
    let listId: UUID?
    let isRevisit: Bool
    /// True when answers came from a paper dictation session (written + photographed).
    var isPaperSession: Bool = false
    /// OCR-confidence-based neatness score from the paper photo (nil for typed sessions).
    var handwritingNeatness: Double? = nil
    let onPracticeAgain: () -> Void
    let onDismiss: () -> Void

    private var correct: [(word: SessionWord, typed: String)] {
        answers.filter { isCorrect($0.typed, expected: $0.word.text) }
    }
    private var incorrect: [(word: SessionWord, typed: String)] {
        answers.filter { !isCorrect($0.typed, expected: $0.word.text) }
    }

    var body: some View {
        NavigationStack {
            List {
                scoreHeader

                if !correct.isEmpty {
                    Section("Correct ✓") {
                        ForEach(correct, id: \.word.id) { item in
                            Text(item.word.text)
                                .foregroundStyle(.green)
                        }
                    }
                }

                if !incorrect.isEmpty {
                    Section("Needs work ✗") {
                        ForEach(incorrect, id: \.word.id) { item in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.word.text)
                                        .fontWeight(.semibold)
                                    Text("You wrote: \(item.typed.isEmpty ? "—" : item.typed)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.red)
                            }
                        }
                    }
                }

                Section {
                    Button(action: onPracticeAgain) {
                        Label("Practice Again", systemImage: "arrow.clockwise")
                            .frame(maxWidth: .infinity)
                    }
                    Button(role: .cancel, action: onDismiss) {
                        Label("Back to Home", systemImage: "house")
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .navigationTitle("Results")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear(perform: persistResults)
        }
    }

    // MARK: - Score header

    private var scoreHeader: some View {
        Section {
            VStack(spacing: 8) {
                Text("\(correct.count) / \(answers.count)")
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .foregroundStyle(scoreColor)

                Text(scoreLabel)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                // Neatness indicator — paper sessions only
                if isPaperSession, let neatness = handwritingNeatness {
                    HStack(spacing: 10) {
                        NeatnessRing(percentage: neatness)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Handwriting neatness")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("\(Int((neatness * 100).rounded()))%")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(neatnessColor(neatness))
                        }
                    }
                    .padding(.top, 4)
                }

                if isRevisit {
                    let removed = correct.filter { $0.word.reviewEntryId != nil }.count
                    if removed > 0 {
                        Text("\(removed) word\(removed == 1 ? "" : "s") removed from your review list")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .listRowBackground(Color.clear)
        }
    }

    private var scoreColor: Color {
        let ratio = answers.isEmpty ? 0.0 : Double(correct.count) / Double(answers.count)
        if ratio >= 0.9 { return .green }
        if ratio >= 0.6 { return .orange }
        return .red
    }

    private var scoreLabel: String {
        let ratio = answers.isEmpty ? 0.0 : Double(correct.count) / Double(answers.count)
        if ratio == 1.0 { return "Perfect!" }
        if ratio >= 0.9 { return "Excellent" }
        if ratio >= 0.7 { return "Good job" }
        if ratio >= 0.5 { return "Keep practising" }
        return "Don't give up!"
    }

    private func neatnessColor(_ p: Double) -> Color {
        if p > 0.80 { return .green }
        if p >= 0.50 { return .orange }
        return .red
    }

    // MARK: - Persistence

    private func persistResults() {
        let result = SessionResult(
            listId: listId,
            listName: title,
            isRevisit: isRevisit,
            isPaperSession: isPaperSession
        )
        modelContext.insert(result)

        for item in answers {
            let answer = Answer(wordId: item.word.id, wordText: item.word.text, typed: item.typed)
            answer.session = result
            result.answers.append(answer)
            modelContext.insert(answer)
        }

        if isRevisit {
            // Remove correctly answered words from the Review Bank
            let toRemove = correct.compactMap(\.word.reviewEntryId)
            for entryId in toRemove {
                if let entry = reviewBank.first(where: { $0.id == entryId }) {
                    modelContext.delete(entry)
                }
            }
        } else {
            // Add incorrectly answered words to the Review Bank (or increment miss count)
            for item in incorrect {
                if let existing = reviewBank.first(where: { $0.wordId == item.word.id }) {
                    existing.missCount += 1
                } else {
                    let entry = ReviewBankEntry(wordId: item.word.id, wordText: item.word.text)
                    modelContext.insert(entry)
                }
            }
        }
    }

    // MARK: - Helpers

    private func isCorrect(_ typed: String, expected: String) -> Bool {
        typed.normalizedForDictation == expected.normalizedForDictation
    }
}
