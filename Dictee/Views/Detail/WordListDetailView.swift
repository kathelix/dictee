import SwiftUI
import SwiftData

struct WordListDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var reviewBank: [ReviewBankEntry]

    @Bindable var list: WordList

    @State private var isRenaming = false
    @State private var renameText = ""
    @State private var showPhoto = false
    @State private var confirmDelete = false

    var body: some View {
        NavigationStack {
            List {
                if let photoData = list.photoData, let uiImage = UIImage(data: photoData) {
                    Section {
                        Button {
                            showPhoto = true
                        } label: {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: .infinity)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .buttonStyle(.plain)
                    } header: {
                        Text("Original Photo")
                    }
                }

                Section {
                    ForEach(list.words.sorted(by: { $0.text < $1.text })) { word in
                        HStack {
                            Text(word.text)
                            Spacer()
                            if reviewBank.contains(where: { $0.wordId == word.id }) {
                                Image(systemName: "bookmark.fill")
                                    .foregroundStyle(.orange)
                                    .font(.caption)
                            }
                        }
                    }
                } header: {
                    Text("\(list.words.count) \(list.words.count == 1 ? "word" : "words")")
                } footer: {
                    Text("Bookmarked words are in your Review Bank.")
                        .font(.caption)
                }

                Section {
                    Button {
                        renameText = list.name
                        isRenaming = true
                    } label: {
                        Label("Rename", systemImage: "pencil")
                    }

                    Button(role: .destructive) {
                        confirmDelete = true
                    } label: {
                        Label("Delete List", systemImage: "trash")
                    }
                }
            }
            .navigationTitle(list.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .alert("Rename List", isPresented: $isRenaming) {
                TextField("List name", text: $renameText)
                Button("Save") {
                    let trimmed = renameText.trimmingCharacters(in: .whitespaces)
                    if !trimmed.isEmpty { list.name = trimmed }
                }
                Button("Cancel", role: .cancel) {}
            }
            .confirmationDialog("Delete \"\(list.name)\"?", isPresented: $confirmDelete, titleVisibility: .visible) {
                Button("Delete", role: .destructive) {
                    modelContext.delete(list)
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This cannot be undone.")
            }
            .sheet(isPresented: $showPhoto) {
                if let data = list.photoData, let uiImage = UIImage(data: data) {
                    PhotoFullscreenView(image: uiImage)
                }
            }
        }
    }
}

private struct PhotoFullscreenView: View {
    @Environment(\.dismiss) private var dismiss
    let image: UIImage

    var body: some View {
        NavigationStack {
            ScrollView([.horizontal, .vertical]) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
            }
            .navigationTitle("Original Photo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
