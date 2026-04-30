import XCTest
@testable import Dictee

/// Pure-helper tests for the reward system: no SwiftData involved.
final class DictationRewardServiceTests: XCTestCase {

    // MARK: - starsEarned

    func test_starsEarned_zeroCorrect_yieldsZero() {
        XCTAssertEqual(DictationRewardService.starsEarned(correctCount: 0), 0)
    }

    func test_starsEarned_oneStarPerCorrect() {
        XCTAssertEqual(DictationRewardService.starsEarned(correctCount: 1), 1)
        XCTAssertEqual(DictationRewardService.starsEarned(correctCount: 12), 12)
    }

    // MARK: - RewardRule.secretRewardThreshold

    func test_secretRewardThreshold_isFifty() {
        // Slice 1 default — confirmed in the design discussion.
        XCTAssertEqual(RewardRule.secretRewardThreshold, 50)
    }

    // MARK: - RewardRule.progressFraction

    func test_progressFraction_zeroStars_isZero() {
        XCTAssertEqual(RewardRule.progressFraction(totalStars: 0), 0.0, accuracy: 1e-9)
    }

    func test_progressFraction_partialProgress() {
        // 25 / 50 = 0.5
        XCTAssertEqual(RewardRule.progressFraction(totalStars: 25), 0.5, accuracy: 1e-9)
    }

    func test_progressFraction_atThreshold_isOne() {
        XCTAssertEqual(
            RewardRule.progressFraction(totalStars: RewardRule.secretRewardThreshold),
            1.0,
            accuracy: 1e-9
        )
    }

    func test_progressFraction_aboveThreshold_isClampedToOne() {
        // The locked bar must never overflow; future slices will introduce
        // additional tiers, but Slice 1 only has one threshold.
        XCTAssertEqual(
            RewardRule.progressFraction(totalStars: RewardRule.secretRewardThreshold * 3),
            1.0,
            accuracy: 1e-9
        )
    }
}
