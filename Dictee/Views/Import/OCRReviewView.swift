import SwiftUI

struct OCRReviewView: View {
    @Binding var words: [String]
    let isProcessing: Bool
    let onContinue: () -> Void

    @State private var newWordText = ""

    var body: some View {
        Group {
            if isProcessing {
                VStack(spacing: 16) {
                    ProgressView()
                    Text("Recognising words…")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                wordList
            }
        }
    }

    private var wordList: some View {
        List {
            Section {
                ForEach($words.indices, id: \.self) { index in
                    TextField("Word", text: $words[index])
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                }
                .onDelete { words.remove(atOffsets: $0) }
                .onMove { words.move(fromOffsets: $0, toOffset: $1) }
            } header: {
                Text(words.count == 1 ? "1 word found" : "\(words.count) words found")
            } footer: {
                Text("Edit or delete any OCR errors. Swipe to delete, drag to reorder.")
                    .font(.caption)
            }

            Section("Add a word") {
                HStack {
                    TextField("Type a word", text: $newWordText)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .onSubmit(addWord)
                    Button("Add", action: addWord)
                        .disabled(newWordText.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }

            Section {
                Button {
                    onContinue()
                } label: {
                    Text("Continue")
                        .frame(maxWidth: .infinity)
                        .fontWeight(.semibold)
                }
                .disabled(words.isEmpty)
            }
        }
        .environment(\.editMode, .constant(.active))
    }

    private func addWord() {
        let trimmed = newWordText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        words.append(trimmed)
        newWordText = ""
    }
}
