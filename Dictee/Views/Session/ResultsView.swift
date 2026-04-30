import SwiftUI
import SwiftData

struct ResultsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var reviewBank: [ReviewBankEntry]

    // Input from the session
    let sessionAnswers: [(word: SessionWord, typed: String)]
    let title: String
    let listId: UUID?
    let isRevisit: Bool
    var isPaperSession: Bool = false
    var handwritingNeatness: Double? = nil
    let onPracticeAgain: () -> Void
    let onDismiss: () -> Void

    // Populated once on first appear; drives all display
    @State private var savedSession: SessionResult? = nil
    @State private var removedFromBank: Int = 0
    @State private var starsEarnedThisSession: Int = 0
    @State private var totalStars: Int = 0
    /// Ordered snapshot of answers in dictation order. SwiftData `@Relationship`
    /// arrays are unordered and may reshuffle when the context autosaves and
    /// reloads the relationship — capturing the order locally keeps the display
    /// stable across re-renders.
    @State private var orderedAnswers: [Answer] = []

    private var correctAnswers: [Answer] { orderedAnswers.filter(\.correct) }
    private var incorrectAnswers: [Answer] { orderedAnswers.filter { !$0.correct } }
    private var totalCount: Int { orderedAnswers.count }

    var body: some View {
        NavigationStack {
            List {
                scoreHeader

                rewardSection

                if !correctAnswers.isEmpty {
                    Section("Correct ✓") {
                        ForEach(correctAnswers, id: \.id) { answer in
                            Text(answer.wordText)
                                .foregroundStyle(.green)
                        }
                    }
                }

                if !incorrectAnswers.isEmpty {
                    Section("Needs work ✗") {
                        ForEach(incorrectAnswers, id: \.id) { answer in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(answer.wordText)
                                        .fontWeight(.semibold)
                                    Text("You wrote: \(answer.typed.isEmpty ? "—" : answer.typed)")
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
            .onAppear {
                guard savedSession == nil else { return }
                savedSession = persistResults()
            }
        }
    }

    // MARK: - Score header

    private var scoreHeader: some View {
        Section {
            VStack(spacing: 8) {
                Text("\(correctAnswers.count) / \(totalCount)")
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .foregroundStyle(scoreColor)

                Text(scoreLabel)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

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

                if isRevisit && removedFromBank > 0 {
                    Text("\(removedFromBank) word\(removedFromBank == 1 ? "" : "s") removed from your review list")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .listRowBackground(Color.clear)
        }
    }

    private var scoreColor: Color {
        let ratio = totalCount == 0 ? 0.0 : Double(correctAnswers.count) / Double(totalCount)
        if ratio >= 0.90 { return .green }
        if ratio >= 0.75 { return .orange }
        return .red
    }

    private var scoreLabel: String {
        let ratio = totalCount == 0 ? 0.0 : Double(correctAnswers.count) / Double(totalCount)
        if ratio == 1.0 { return "Perfect!" }
        if ratio >= 0.90 { return "Excellent" }
        if ratio >= 0.70 { return "Good job" }
        if ratio >= 0.50 { return "Keep practising" }
        return "Don't give up!"
    }

    private func neatnessColor(_ p: Double) -> Color {
        if p >= 0.90 { return .green }
        if p >= 0.75 { return .orange }
        return .red
    }

    // MARK: - Reward block

    private var rewardSection: some View {
        Section("Stars") {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Text("⭐")
                        .font(.title3)
                    Text("+\(starsEarnedThisSession) star\(starsEarnedThisSession == 1 ? "" : "s") earned")
                        .fontWeight(.semibold)
                }
                .accessibilityElement(children: .combine)

                HStack {
                    Text("Total stars")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(totalStars)")
                        .fontWeight(.semibold)
                        .monospacedDigit()
                }

                Divider()

                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Text("🎁")
                        Text("Secret reward")
                            .fontWeight(.semibold)
                        Image(systemName: "lock.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .accessibilityLabel("locked")
                    }

                    Text("\(min(totalStars, RewardRule.secretRewardThreshold)) / \(RewardRule.secretRewardThreshold) stars")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    ProgressView(
                        value: RewardRule.progressFraction(totalStars: totalStars)
                    )
                    .tint(.yellow)
                    .accessibilityLabel(
                        "Reward progress: \(totalStars) of \(RewardRule.secretRewardThreshold) stars"
                    )
                }
            }
            .padding(.vertical, 4)
        }
    }

    // MARK: - Persistence

    @discardableResult
    private func persistResults() -> SessionResult {
        let result = SessionResult(
            listId: listId,
            listName: title,
            isRevisit: isRevisit,
            isPaperSession: isPaperSession
        )
        modelContext.insert(result)

        // Build answers in sessionAnswers order so the zip below is safe
        var builtAnswers: [Answer] = []
        for item in sessionAnswers {
            let answer = Answer(wordId: item.word.id, wordText: item.word.text, typed: item.typed)
            answer.session = result
            result.answers.append(answer)
            modelContext.insert(answer)
            builtAnswers.append(answer)
        }

        if isRevisit {
            var removed = 0
            for (item, answer) in zip(sessionAnswers, builtAnswers) where answer.correct {
                if let reviewId = item.word.reviewEntryId,
                   let entry = reviewBank.first(where: { $0.id == reviewId }) {
                    modelContext.delete(entry)
                    removed += 1
                }
            }
            removedFromBank = removed
        } else {
            for answer in builtAnswers where !answer.correct {
                if let existing = reviewBank.first(where: { $0.wordId == answer.wordId }) {
                    existing.missCount += 1
                } else {
                    let entry = ReviewBankEntry(wordId: answer.wordId, wordText: answer.wordText)
                    modelContext.insert(entry)
                }
            }
        }

        // Award stars for this dictation. Idempotent against result.id so a
        // re-render of the same SessionResult cannot grant stars twice.
        let correctCount = builtAnswers.filter(\.correct).count
        starsEarnedThisSession = DictationRewardService.award(
            sessionId: result.id,
            correctCount: correctCount,
            in: modelContext
        )
        totalStars = DictationRewardService.totalStars(in: modelContext)

        orderedAnswers = builtAnswers
        return result
    }
}
