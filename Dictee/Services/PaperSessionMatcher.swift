import Foundation

/// Aligns OCR chunks from a paper-session photo to the dictated word order.
///
/// Pure function — no Vision, no SwiftUI, no SwiftData. The view layer calls
/// this after `OCRService.recognizeText`, then zips the result with
/// `SessionWord` to build `Answer` records.
///
/// **Recovery**: when OCR returns fewer chunks than expected (the pupil
/// forgot a separator and the recogniser merged multiple answers into one
/// chunk), chunks containing internal whitespace are split so each piece
/// occupies its own position. Spelling correctness is decided downstream by
/// `Answer.correct`; this matcher only restores positional alignment.
enum PaperSessionMatcher {
    struct Result: Equatable {
        let typed: [String]
        /// Number of OCR chunks that were split during recovery. Each
        /// recovered chunk represents one missing separator and warrants a
        /// neatness-score dock from the caller.
        let recoveredChunks: Int
    }

    static func match(ocrChunks: [String], expectedCount: Int) -> Result {
        // TODO: implement recovery — see TODO.md.
        var typed: [String] = []
        for i in 0..<expectedCount {
            typed.append(i < ocrChunks.count ? ocrChunks[i] : "")
        }
        return Result(typed: typed, recoveredChunks: 0)
    }
}
