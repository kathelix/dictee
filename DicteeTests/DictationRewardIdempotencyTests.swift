import XCTest
import SwiftData
@testable import Dictee

/// Verifies the SwiftData-backed parts of the reward system:
/// transaction insertion, idempotency per session, and total accumulation.
@MainActor
final class DictationRewardIdempotencyTests: XCTestCase {

    private func makeContext() throws -> ModelContext {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: RewardTransaction.self,
            configurations: config
        )
        return ModelContext(container)
    }

    func test_award_recordsStarsForFirstCall() throws {
        let context = try makeContext()
        let sessionId = UUID()

        let granted = DictationRewardService.award(
            sessionId: sessionId,
            correctCount: 7,
            in: context
        )

        XCTAssertEqual(granted, 7)
        XCTAssertEqual(DictationRewardService.totalStars(in: context), 7)
    }

    func test_award_isIdempotentForSameSessionId() throws {
        // Re-rendering the result screen for the same dictation must not
        // grant stars a second time.
        let context = try makeContext()
        let sessionId = UUID()

        _ = DictationRewardService.award(sessionId: sessionId, correctCount: 7, in: context)
        let secondCall = DictationRewardService.award(
            sessionId: sessionId,
            correctCount: 7,
            in: context
        )

        XCTAssertEqual(secondCall, 0, "Re-awarding the same session should grant no extra stars")
        XCTAssertEqual(DictationRewardService.totalStars(in: context), 7)
    }

    func test_award_accumulatesAcrossDifferentSessions() throws {
        let context = try makeContext()

        _ = DictationRewardService.award(sessionId: UUID(), correctCount: 7, in: context)
        _ = DictationRewardService.award(sessionId: UUID(), correctCount: 5, in: context)

        XCTAssertEqual(DictationRewardService.totalStars(in: context), 12)
    }

    func test_award_zeroCorrect_stillIdempotent() throws {
        // A 0-correct session must still be tagged as "awarded" so a re-render
        // cannot later accidentally insert a non-zero grant for it.
        let context = try makeContext()
        let sessionId = UUID()

        let first = DictationRewardService.award(sessionId: sessionId, correctCount: 0, in: context)
        let second = DictationRewardService.award(sessionId: sessionId, correctCount: 12, in: context)

        XCTAssertEqual(first, 0)
        XCTAssertEqual(second, 0, "Second call must not inject stars even with a different correct count")
        XCTAssertEqual(DictationRewardService.totalStars(in: context), 0)
    }
}
