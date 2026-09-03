@testable import CalendarKit
import CoreGraphics
import XCTest

/// `EventInsetRule` 是總表版面唯一的算術來源。
///
/// 「框架」是每一個小時格：上下是畫出來的刻度線（ezStore 只有整點有線），左右是群組欄邊線。
/// event 離框架 padding，框架裡面 event 彼此 gap。
final class EventInsetsTests: XCTestCase {
    private let padding: CGFloat = 12
    private let gap: CGFloat = 5
    /// 30 分模式：每小時 200，所以 30 分的時段矩形高 100
    private let slotHeight: CGFloat = 100

    private var rule: EventInsetRule {
        return EventInsetRule(verticalPadding: padding, horizontalPadding: padding, gap: gap)
    }

    private let onLine = VerticalEdge(touchesCard: false, onTickLine: true)
    private let cardOnLine = VerticalEdge(touchesCard: true, onTickLine: true)
    private let card = VerticalEdge(touchesCard: true, onTickLine: false)
    private let blank = VerticalEdge.blank

    private func insets(top: VerticalEdge = .blank,
                        bottom: VerticalEdge = .blank,
                        columnIndex: Int = 0,
                        columnCount: Int = 1,
                        isRightToLeft: Bool = false) -> EventInsets
    {
        return rule.insets(top: top, bottom: bottom, columnIndex: columnIndex, columnCount: columnCount, isRightToLeft: isRightToLeft)
    }

    // MARK: - 每一邊的三種情況

    func testEdgeOnTickLineUsesPadding() {
        XCTAssertEqual(rule.inset(for: onLine), padding)
    }

    func testEdgeTouchingCardOffTickLineUsesHalfGap() {
        XCTAssertEqual(rule.inset(for: card), gap / 2)
    }

    func testTickLineBeatsCard() {
        XCTAssertEqual(rule.inset(for: cardOnLine), padding, "兩張卡在刻度線上相接，線優先，兩側各留 padding")
    }

    func testBlankEdgeUsesPadding() {
        XCTAssertEqual(rule.inset(for: blank), padding)
    }

    func testInsetsAreNeverNegative() {
        for edge in [onLine, cardOnLine, card, blank] {
            XCTAssertGreaterThanOrEqual(rule.inset(for: edge), 0, "卡片不可凸出時段線")
        }
    }

    // MARK: - 實際畫面（30 分模式，整點有線）

    /// 10:00-10:30 / 10:30-11:00：10:30 沒線 → 12 card 5 card 12
    func testTwoHalfHourCardsInsideOneHour() {
        let upper = insets(top: onLine, bottom: card)
        let lower = insets(top: card, bottom: onLine)
        XCTAssertEqual(upper.top, padding)
        XCTAssertEqual(upper.bottom + lower.top, gap)
        XCTAssertEqual(lower.bottom, padding)
    }

    /// 11:30-12:00 接 12:00-12:30：12:00 有線 → 線的兩側各 12
    func testTwoCardsMeetingOnTickLine() {
        let upper = insets(top: card, bottom: cardOnLine)
        let lower = insets(top: cardOnLine, bottom: card)
        XCTAssertEqual(upper.bottom, padding, "「共$400 離下面那條線」要是 12")
        XCTAssertEqual(lower.top, padding)
        XCTAssertEqual(upper.bottom + lower.top, padding * 2)
    }

    /// 單獨一張 14:00-14:30：上在線、下是空白 → 12 card 12
    func testSingleCard() {
        let result = insets(top: onLine, bottom: blank)
        XCTAssertEqual(result.top, padding)
        XCTAssertEqual(result.bottom, padding)
    }

    func testCardHeights() {
        func height(_ top: VerticalEdge, _ bottom: VerticalEdge) -> CGFloat {
            let result = insets(top: top, bottom: bottom)
            return slotHeight - result.top - result.bottom
        }
        XCTAssertEqual(height(onLine, card), 85.5, "小時格裡的上半張")
        XCTAssertEqual(height(card, onLine), 85.5, "小時格裡的下半張")
        XCTAssertEqual(height(onLine, blank), 76, "單獨一張")
        XCTAssertEqual(height(card, card), 95, "15 分模式下夾在中間的卡")
    }

    // MARK: - 水平

    func testSingleColumnTouchesBothGroupEdges() {
        let result = insets()
        XCTAssertEqual(result.left, padding)
        XCTAssertEqual(result.right, padding)
    }

    func testSideBySideColumns() {
        let first = insets(columnIndex: 0, columnCount: 3)
        let middle = insets(columnIndex: 1, columnCount: 3)
        let last = insets(columnIndex: 2, columnCount: 3)
        XCTAssertEqual(first.left, padding)
        XCTAssertEqual(first.right, gap / 2)
        XCTAssertEqual(middle.left, gap / 2)
        XCTAssertEqual(middle.right, gap / 2)
        XCTAssertEqual(last.left, gap / 2)
        XCTAssertEqual(last.right, padding)
        XCTAssertEqual(first.right + middle.left, gap, "並排兩張卡之間也是 gap")
    }

    func testSideBySideDoesNotAffectVertical() {
        let middle = insets(top: onLine, bottom: onLine, columnIndex: 1, columnCount: 3)
        XCTAssertEqual(middle.top, padding)
        XCTAssertEqual(middle.bottom, padding)
    }

    func testRightToLeftSwapsHorizontalInsets() {
        let first = insets(columnIndex: 0, columnCount: 3, isRightToLeft: true)
        XCTAssertEqual(first.right, padding, "RTL 時第一欄在畫面右側")
        XCTAssertEqual(first.left, gap / 2)
    }

    // MARK: - gap 未設定（provider-ios）

    func testZeroGapFallsBackToPadding() {
        let noGap = EventInsetRule(verticalPadding: 2, horizontalPadding: 2, gap: 0)
        let result = noGap.insets(top: card, bottom: card, columnIndex: 1, columnCount: 3)
        XCTAssertEqual(result.top, 2)
        XCTAssertEqual(result.bottom, 2)
        XCTAssertEqual(result.left, 2)
        XCTAssertEqual(result.right, 2)
    }
}
