import SwiftUI

struct WordListCard: View {
    let list: WordList
    /// Score from the most recent practice session (nil = never practised).
    let lastScore: Double?

    var body: some View {
        HStack(spacing: 14) {
            thumbnail

            VStack(alignment: .leading, spacing: 4) {
                Text(list.name)
                    .font(.headline)
                    .lineLimit(1)

                Text(list.words.count == 1 ? "1 word" : "\(list.words.count) words")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if let lastPracticed = list.lastPracticedAt {
                    Text(lastPracticed, format: .relative(presentation: .named))
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer(minLength: 0)

            HStack(spacing: 8) {
                if let neatness = list.handwritingNeatness {
                    NeatnessRing(percentage: neatness)
                }
                ScoreRing(percentage: lastScore)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    @ViewBuilder
    private var thumbnail: some View {
        if let data = list.photoData, let uiImage = UIImage(data: data) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(width: 60, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: 10))
        } else {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.systemFill))
                .frame(width: 60, height: 60)
                .overlay {
                    Image(systemName: "doc.text.image")
                        .foregroundStyle(.secondary)
                }
        }
    }
}
