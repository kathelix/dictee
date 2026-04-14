import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WordList.createdAt, order: .reverse) private var lists: [WordList]
    @Query private var reviewBank: [ReviewBankEntry]

    @State private var showImport = false
    @State private var practiceList: WordList?
    @State private var showRevisit = false
    @State private var showSettings = false
    @State private var detailList: WordList?

    var body: some View {
        NavigationStack {
            Group {
                if lists.isEmpty {
                    emptyState
                } else {
                    listGrid
                }
            }
            .navigationTitle("Dictée")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showImport = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                if !reviewBank.isEmpty {
                    revisitBanner
                }
            }
        }
        .sheet(isPresented: $showImport) {
            ImportFlowView()
        }
        .sheet(item: $practiceList) { list in
            SessionView(
                words: list.words.map { SessionWord(id: $0.id, text: $0.text) },
                title: list.name,
                listId: list.id,
                isRevisit: false,
                onComplete: { list.lastPracticedAt = Date() }
            )
        }
        .sheet(isPresented: $showRevisit) {
            RevisitSessionView()
        }
        .sheet(item: $detailList) { list in
            WordListDetailView(list: list)
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
    }

    // MARK: - Sub-views

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Word Lists", systemImage: "list.bullet.clipboard")
        } description: {
            Text("Tap + to photograph your first word list")
        } actions: {
            Button("Add Word List") { showImport = true }
                .buttonStyle(.borderedProminent)
        }
    }

    private var listGrid: some View {
        ScrollView {
            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 300), spacing: 12)],
                spacing: 12
            ) {
                ForEach(lists) { list in
                    WordListCard(list: list)
                        .contentShape(RoundedRectangle(cornerRadius: 16))
                        .onTapGesture { practiceList = list }
                        .contextMenu {
                            Button {
                                detailList = list
                            } label: {
                                Label("Details", systemImage: "info.circle")
                            }
                            Button(role: .destructive) {
                                modelContext.delete(list)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
            }
            .padding()
            .padding(.bottom, 80) // room for revisit banner
        }
    }

    private var revisitBanner: some View {
        Button {
            showRevisit = true
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "arrow.clockwise.circle.fill")
                    .font(.title3)
                Text("Revisit · \(reviewBank.count) \(reviewBank.count == 1 ? "word" : "words")")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(.orange)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
        .shadow(color: .orange.opacity(0.35), radius: 8, y: 4)
    }
}
