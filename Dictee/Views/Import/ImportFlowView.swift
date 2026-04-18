import SwiftUI
import PhotosUI
import SwiftData

struct ImportFlowView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    enum Step { case capture, review, name }

    @State private var step: Step = .capture
    @State private var capturedImage: UIImage?
    @State private var words: [String] = []
    @State private var listName: String = ""
    @State private var isProcessing = false
    @State private var showCamera = false
    @State private var photoItem: PhotosPickerItem?

    var body: some View {
        NavigationStack {
            Group {
                switch step {
                case .capture: captureStep
                case .review:
                    OCRReviewView(words: $words, isProcessing: isProcessing) {
                        listName = Self.defaultName()
                        step = .name
                    }
                case .name: nameStep
                }
            }
            .navigationTitle(stepTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraView {
                showCamera = false
                capturedImage = $0
                runOCR(on: $0)
                step = .review
            } onCancel: {
                showCamera = false
            }
            .ignoresSafeArea()
        }
    }

    // MARK: - Step titles

    private var stepTitle: String {
        switch step {
        case .capture: return "Add Word List"
        case .review:  return "Review Words"
        case .name:    return "Name Your List"
        }
    }

    // MARK: - Capture step

    private var captureStep: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "camera.viewfinder")
                .font(.system(size: 80))
                .foregroundStyle(.blue)

            VStack(spacing: 8) {
                Text("Photograph your word list")
                    .font(.title2.weight(.semibold))
                Text("Hold the camera steady over the paper")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .multilineTextAlignment(.center)

            Spacer()

            VStack(spacing: 12) {
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

                PhotosPicker(selection: $photoItem, matching: .images) {
                    Label("Choose from Library", systemImage: "photo.on.rectangle")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .onChange(of: photoItem) { _, newItem in
                    guard let newItem else { return }
                    Task {
                        guard let data = try? await newItem.loadTransferable(type: Data.self),
                              let image = UIImage(data: data) else { return }
                        capturedImage = image
                        runOCR(on: image)
                        step = .review
                    }
                }
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
        .padding()
    }

    // MARK: - Name step

    private var nameStep: some View {
        VStack(spacing: 24) {
            Spacer()

            VStack(alignment: .leading, spacing: 8) {
                Text("List name")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)

                TextField("Liste du …", text: $listName)
                    .font(.title3)
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal)

            Text("\(words.count) words will be saved")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()

            Button(action: saveList) {
                Text("Save List")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(canSave ? Color.blue : Color.gray)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .disabled(!canSave)
            .padding(.horizontal)
            .padding(.bottom)
        }
    }

    // MARK: - Helpers

    private var canSave: Bool {
        !listName.trimmingCharacters(in: .whitespaces).isEmpty && !words.isEmpty
    }

    private static func defaultName() -> String {
        let f = DateFormatter()
        f.dateStyle = .long
        f.locale = Locale(identifier: "fr_FR")
        return "Liste du \(f.string(from: Date()))"
    }

    private func runOCR(on image: UIImage) {
        isProcessing = true
        Task {
            let result = (try? await OCRService.recognizeText(in: image)) ?? OCRService.OCRResult(words: [], averageConfidence: 0)
            await MainActor.run {
                words = result.words
                isProcessing = false
            }
        }
    }

    private func saveList() {
        let name = listName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }

        let list = WordList(
            name: name,
            photoData: capturedImage?.jpegData(compressionQuality: 0.65)
        )
        modelContext.insert(list)

        for text in words {
            let trimmed = text.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { continue }
            let word = Word(text: trimmed)
            word.list = list
            list.words.append(word)
            modelContext.insert(word)
        }

        dismiss()
    }
}
