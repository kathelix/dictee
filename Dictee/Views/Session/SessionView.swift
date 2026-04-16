import SwiftUI

/// Drives both Practice and Revisit sessions.
/// - Practice: words come from a WordList; incorrect answers feed the Review Bank.
/// - Revisit:  words come from the Review Bank; correct answers clear them.
struct SessionView: View {
    @Environment(\.dismiss) private var dismiss

    let words: [SessionWord]
    let title: String
    let listId: UUID?
    let isRevisit: Bool
    var onComplete: (() -> Void)? = nil

    @State private var speech = SpeechService()

    @State private var shuffled: [SessionWord] = []
    @State private var currentIndex = 0
    @State private var typedAnswer = ""
    @State private var collectedAnswers: [(word: SessionWord, typed: String)] = []
    @State private var showResults = false

    private var current: SessionWord? { shuffled[safe: currentIndex] }
    private var progress: Double {
        shuffled.isEmpty ? 0 : Double(currentIndex) / Double(shuffled.count)
    }

    var body: some View {
        Group {
            if showResults {
                ResultsView(
                    answers: collectedAnswers,
                    title: title,
                    listId: listId,
                    isRevisit: isRevisit,
                    onPracticeAgain: restart,
                    onDismiss: { dismiss() }
                )
            } else {
                sessionContent
            }
        }
        .onAppear(perform: start)
        .onDisappear { speech.stop() }
    }

    // MARK: - Session content

    private var sessionContent: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Progress bar
                ProgressView(value: progress)
                    .tint(.blue)
                    .padding(.horizontal)

                Text("\(currentIndex + 1) of \(shuffled.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)

                Spacer()

                // Speaker button
                VStack(spacing: 12) {
                    Button {
                        current.map { speech.speak($0.text) }
                    } label: {
                        Image(
                            systemName: speech.isSpeaking
                                ? "speaker.wave.3.fill"
                                : "speaker.wave.2.circle.fill"
                        )
                        .font(.system(size: 80))
                        .foregroundStyle(speech.isSpeaking ? .blue : .primary)
                        .contentTransition(.symbolEffect(.replace))
                        .symbolEffect(.pulse, isActive: speech.isSpeaking)
                    }
                    .buttonStyle(.plain)

                    Text("Tap to hear the word again")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }

                Spacer()

                // Input area
                VStack(spacing: 14) {
                    DictationTextField(
                        placeholder: "Type the word…",
                        text: $typedAnswer,
                        onSubmit: submitAnswer
                    )
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .frame(height: 56)

                    Button(action: submitAnswer) {
                        Text(currentIndex == shuffled.count - 1 ? "Finish" : "Next")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(.blue)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }
                .padding()
            }
            .padding(.top, 8)
            .navigationTitle(isRevisit ? "Revisit" : title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    // MARK: - Actions

    private func start() {
        shuffled = words.shuffled()
        currentIndex = 0
        typedAnswer = ""
        collectedAnswers = []
        showResults = false
        speakCurrent(after: 0.5)
    }

    private func restart() {
        start()
    }

    private func submitAnswer() {
        guard let word = current else { return }
        let trimmed = typedAnswer.trimmingCharacters(in: .whitespaces)
        collectedAnswers.append((word: word, typed: trimmed))

        if currentIndex + 1 < shuffled.count {
            currentIndex += 1
            typedAnswer = ""
            speakCurrent(after: 0.15)
        } else {
            onComplete?()
            showResults = true
        }
    }

    private func speakCurrent(after delay: TimeInterval) {
        guard let word = current else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            speech.speak(word.text)
        }
    }
}

// MARK: - Safe subscript

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
