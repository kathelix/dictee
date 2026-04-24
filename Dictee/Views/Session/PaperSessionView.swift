import SwiftUI

/// Paper dictation session flow:
/// 1. **Dictation** — app reads each word aloud; pupil writes answers on paper.
/// 2. **Capture**   — pupil photographs their handwritten answer sheet.
/// 3. **Processing** — on-device OCR recognises the handwritten words.
/// 4. **Results**   — recognised words are matched positionally to the dictated
///                    order and compared to the truth list. Neatness score (OCR
///                    confidence) is shown in the results screen.
///
/// Works for both word-list sessions and revisit sessions; callers control
/// persistence via the `onNeatnessSaved` closure.
struct PaperSessionView: View {
    @Environment(\.dismiss) private var dismiss

    let words: [SessionWord]
    let title: String
    let listId: UUID?
    let isRevisit: Bool
    /// Called after OCR completes (before results appear) with the neatness score.
    /// Word-list callers use this to persist `handwritingNeatness` and
    /// `lastPracticedAt`. Revisit callers omit it — neatness is shown but not
    /// saved to any individual list.
    var onNeatnessSaved: ((Double) -> Void)? = nil

    // MARK: - Phase

    enum Phase { case dictation, capture, processing, results }

    // MARK: - State

    @State private var phase: Phase = .dictation
    @State private var speech = SpeechService()
    @State private var shuffled: [SessionWord] = []
    @State private var currentIndex = 0
    @State private var showCamera = false
    @State private var answers: [(word: SessionWord, typed: String)] = []
    @State private var neatnessScore: Double? = nil

    // MARK: - Body

    var body: some View {
        Group {
            switch phase {
            case .dictation:
                dictationContent
            case .capture:
                captureContent
            case .processing:
                processingContent
            case .results:
                ResultsView(
                    sessionAnswers: answers,
                    title: title,
                    listId: listId,
                    isRevisit: isRevisit,
                    isPaperSession: true,
                    handwritingNeatness: neatnessScore,
                    onPracticeAgain: restart,
                    onDismiss: { dismiss() }
                )
            }
        }
        .onAppear(perform: start)
        .onDisappear { speech.stop() }
        .fullScreenCover(isPresented: $showCamera) {
            CameraView(
                onCapture: { image in
                    showCamera = false
                    processPhoto(image)
                },
                onCancel: {
                    showCamera = false
                }
            )
            .ignoresSafeArea()
        }
    }

    // MARK: - Dictation phase

    private var dictationContent: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ProgressView(value: shuffled.isEmpty ? 0 : Double(currentIndex) / Double(shuffled.count))
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
                        speakCurrent()
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

                Button(action: advance) {
                    Text(currentIndex == shuffled.count - 1 ? "Done — Take Photo" : "Next Word")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(.blue)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding()
            }
            .padding(.top, 8)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    // MARK: - Capture phase

    private var captureContent: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Spacer()

                Image(systemName: "camera.viewfinder")
                    .font(.system(size: 80))
                    .foregroundStyle(.blue)

                VStack(spacing: 8) {
                    Text("Photograph your answers")
                        .font(.title2.weight(.semibold))
                    Text("Hold the camera steady over your written word list")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .multilineTextAlignment(.center)

                Spacer()

                Button {
                    showCamera = true
                } label: {
                    Label("Take Photo", systemImage: "camera.fill")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(.blue)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
            .padding()
            .navigationTitle("Your answers")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Processing phase

    private var processingContent: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Recognising your handwriting…")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Actions

    private func start() {
        shuffled = words.shuffled()
        currentIndex = 0
        neatnessScore = nil
        speakCurrent(after: 0.5)
    }

    private func restart() {
        phase = .dictation
        start()
    }

    private func speakCurrent(after delay: TimeInterval = 0) {
        guard let word = shuffled[safe: currentIndex] else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            speech.speak(word.text)
        }
    }

    private func advance() {
        if currentIndex + 1 < shuffled.count {
            currentIndex += 1
            speakCurrent(after: 0.15)
        } else {
            phase = .capture
        }
    }

    private func processPhoto(_ image: UIImage) {
        phase = .processing
        Task {
            let result = (try? await OCRService.recognizeText(in: image, handwriting: true))
                ?? OCRService.OCRResult(words: [], averageConfidence: 0)

            await MainActor.run {
                // Positional match: OCR word[i] ↔ dictated word[i].
                // Words the OCR couldn't read (fewer results than expected) are treated as blank.
                answers = shuffled.enumerated().map { i, word in
                    let typed = i < result.words.count ? result.words[i] : ""
                    return (word: word, typed: typed)
                }
                neatnessScore = result.averageConfidence
                onNeatnessSaved?(result.averageConfidence)
                phase = .results
            }
        }
    }
}

// MARK: - Safe subscript

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
