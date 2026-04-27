import XCTest
@testable import Dictee

final class PaperSessionMatcherTests: XCTestCase {

    // MARK: - Recovery: forgotten separator

    func test_recoverForgottenComma_allCorrect() {
        // Expected: chat, voiture
        // Written:  chat voiture (one chunk, missing comma)
        let result = PaperSessionMatcher.match(
            ocrChunks: ["chat voiture"],
            expectedCount: 2
        )
        XCTAssertEqual(result.typed, ["chat", "voiture"])
        XCTAssertEqual(result.recoveredChunks, 1)
    }

    func test_recoverForgottenComma_oneMisspelt() {
        // Expected: chat, voiture
        // Written:  chat vouture (one chunk, second piece misspelt)
        // Algorithm should still split — downstream comparison marks "vouture" wrong.
        let result = PaperSessionMatcher.match(
            ocrChunks: ["chat vouture"],
            expectedCount: 2
        )
        XCTAssertEqual(result.typed, ["chat", "vouture"])
        XCTAssertEqual(result.recoveredChunks, 1)
    }

    func test_recoverForgottenComma_bothMisspelt() {
        // Expected: chat, voiture
        // Written:  chate vouture (one chunk, both pieces misspelt)
        // Critical: must NOT treat "chate vouture" as the answer for "chat" —
        // that would shift voiture out of alignment. Split anyway so each
        // expected word is diagnosed against its own piece.
        let result = PaperSessionMatcher.match(
            ocrChunks: ["chate vouture"],
            expectedCount: 2
        )
        XCTAssertEqual(result.typed, ["chate", "vouture"])
        XCTAssertEqual(result.recoveredChunks, 1)
    }

    // MARK: - No-op cases (no recovery needed or possible)

    func test_noDeficit_passesThrough() {
        let result = PaperSessionMatcher.match(
            ocrChunks: ["chat", "voiture"],
            expectedCount: 2
        )
        XCTAssertEqual(result.typed, ["chat", "voiture"])
        XCTAssertEqual(result.recoveredChunks, 0)
    }

    func test_noDeficit_keepsMultiWordChunkIntact() {
        // No deficit, so a multi-word chunk is left as-is (downstream marks it wrong).
        // Don't split "le chat" speculatively — the pupil may have legitimately
        // written two words for one expected answer.
        let result = PaperSessionMatcher.match(
            ocrChunks: ["le chat", "voiture"],
            expectedCount: 2
        )
        XCTAssertEqual(result.typed, ["le chat", "voiture"])
        XCTAssertEqual(result.recoveredChunks, 0)
    }

    func test_deficitButNoWhitespace_blanksTail() {
        // Can't recover without whitespace — just blank-fill the tail.
        let result = PaperSessionMatcher.match(
            ocrChunks: ["chat"],
            expectedCount: 2
        )
        XCTAssertEqual(result.typed, ["chat", ""])
        XCTAssertEqual(result.recoveredChunks, 0)
    }

    func test_emptyChunks_allBlanks() {
        let result = PaperSessionMatcher.match(
            ocrChunks: [],
            expectedCount: 2
        )
        XCTAssertEqual(result.typed, ["", ""])
        XCTAssertEqual(result.recoveredChunks, 0)
    }

    // MARK: - Multi-recovery and mid-list

    func test_twoChunksEachMissingOneSeparator() {
        let result = PaperSessionMatcher.match(
            ocrChunks: ["a b", "c d"],
            expectedCount: 4
        )
        XCTAssertEqual(result.typed, ["a", "b", "c", "d"])
        XCTAssertEqual(result.recoveredChunks, 2)
    }

    func test_recoveryInMiddle() {
        let result = PaperSessionMatcher.match(
            ocrChunks: ["a", "b c"],
            expectedCount: 3
        )
        XCTAssertEqual(result.typed, ["a", "b", "c"])
        XCTAssertEqual(result.recoveredChunks, 1)
    }

    func test_singleChunkAbsorbsLargeDeficit() {
        // Deficit of 2 absorbed by one chunk that splits into 3 pieces.
        let result = PaperSessionMatcher.match(
            ocrChunks: ["a b c"],
            expectedCount: 3
        )
        XCTAssertEqual(result.typed, ["a", "b", "c"])
        XCTAssertEqual(result.recoveredChunks, 1)
    }

    // MARK: - Composition with tail blanks and overflow guard

    func test_recoveryComposesWithTailBlanks() {
        let result = PaperSessionMatcher.match(
            ocrChunks: ["a b"],
            expectedCount: 3
        )
        XCTAssertEqual(result.typed, ["a", "b", ""])
        XCTAssertEqual(result.recoveredChunks, 1)
    }

    func test_excessPiecesAreDroppedNotOverflowed() {
        // Chunk has more pieces than expected — clamp to expectedCount.
        let result = PaperSessionMatcher.match(
            ocrChunks: ["a b c d"],
            expectedCount: 2
        )
        XCTAssertEqual(result.typed, ["a", "b"])
        XCTAssertEqual(result.recoveredChunks, 1)
    }
}
