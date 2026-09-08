@testable import CalendarKit
import CoreGraphics
import XCTest

/// 總表版面的算術只有兩層：`VerticalEdge.resolve` 判定每一邊落在什麼上、`EventInsetRule` 把它換成內縮。
/// 這裡先釘查表，再用整串 pattern 釘判定 —— 會出錯的是判定那層，不是查表。
///
/// 「框架」是每一個小時格：上下是畫出來的刻度線（ezStore 只有整點有線），左右是群組欄邊線。
/// event 離框架 padding，框架裡面 event 彼此 gap。
final class EventInsetsTests: XCTestCase {
    private let padding: CGFloat = 12
    private let gap: CGFloat = 5
    /// 30 分模式：每小時 200，營業 08:00–21:00，刻度線只在整點
    private let verticalDiff: CGFloat = 200
    private let startHour = 8
    private var tickYs: [CGFloat] { (0 ... 13).map { CGFloat($0) * verticalDiff } }

    private var rule: EventInsetRule {
        return EventInsetRule(verticalPadding: padding, horizontalPadding: padding, gap: gap)
    }

    private let onLine = VerticalEdge(touchesCard: false, onTickLine: true)
    private let cardOnLine = VerticalEdge(touchesCard: true, onTickLine: true)
    private let card = VerticalEdge(touchesCard: true, onTickLine: false)
    private let blank = VerticalEdge.blank

    // MARK: - 查表：每一邊的四種情況

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

    // MARK: - 整串 pattern：VerticalEdge.resolve + EventInsetRule

    /// 你截圖的畫面：10:00-11:30 預約卡接 11:30、12:00 預約卡，再接連續時段格
    func testRealScreen() {
        let frames = [slot((10, 0), (11, 30)), slot((11, 30), (12, 0)), slot((12, 0), (12, 30)), slot((12, 30), (13, 0))]
        XCTAssertEqual(pattern(frames), "★12 card 5 card ★24 card 5 card 12★")
    }

    /// 10:30 沒線 → 12 card 5 card 12
    func testTwoHalfHourCardsInsideOneHour() {
        XCTAssertEqual(pattern([slot((10, 0), (10, 30)), slot((10, 30), (11, 0))]), "★12 card 5 card 12★")
    }

    /// 11:00 有線 → 線的兩側各 12
    func testTwoFullHourCardsMeetingOnTickLine() {
        XCTAssertEqual(pattern([slot((10, 0), (11, 0)), slot((11, 0), (12, 0))]), "★12 card ★24 card 12★")
    }

    /// 上在線、下是空白
    func testSingleCard() {
        XCTAssertEqual(pattern([slot((14, 0), (14, 30))]), "★12 card 12")
    }

    /// 四張 30 分跨過 ★10:00
    func testFourHalfHourCardsAcrossTickLine() {
        let frames = [slot((9, 0), (9, 30)), slot((9, 30), (10, 0)), slot((10, 0), (10, 30)), slot((10, 30), (11, 0))]
        XCTAssertEqual(pattern(frames), "★12 card 5 card ★24 card 5 card 12★")
    }

    /// 15 分模式一小時內四張：中間三條縫都沒線
    func testFourQuarterHourCardsInsideOneHour() {
        let frames = [slot((10, 0), (10, 15)), slot((10, 15), (10, 30)), slot((10, 30), (10, 45)), slot((10, 45), (11, 0))]
        XCTAssertEqual(pattern(frames), "★12 card 5 card 5 card 5 card 12★")
    }

    /// 中間隔了 30 分空檔的兩張，各自四邊都是 padding
    func testCardsSeparatedByBlankAreNotNeighbours() {
        let edges = VerticalEdge.resolve(frames: [slot((10, 0), (10, 30)), slot((11, 0), (11, 30))], tickYs: tickYs)
        XCTAssertFalse(edges[0].bottom.touchesCard)
        XCTAssertFalse(edges[1].top.touchesCard)
        XCTAssertEqual(edges[0].bottom, .blank, "10:30 沒線也沒卡")
    }

    /// 不在格線上的時間（10:07-10:52）：兩邊都不是線、也沒貼卡
    func testOffGridCardGetsPaddingOnBothSides() {
        let edges = VerticalEdge.resolve(frames: [slot((10, 7), (10, 52))], tickYs: tickYs)
        XCTAssertEqual(edges[0].top, .blank)
        XCTAssertEqual(edges[0].bottom, .blank)
    }

    // MARK: - 判定：並排、容差

    func testSideBySideColumnsAreNotVerticalNeighbours() {
        let columnWidth: CGFloat = 200
        let frames = (0 ..< 3).map { slot((10, 0), (11, 0), x: CGFloat($0) * columnWidth, width: columnWidth) }
        for edge in VerticalEdge.resolve(frames: frames, tickYs: tickYs) {
            XCTAssertFalse(edge.top.touchesCard, "並排的欄 x 不重疊，不可互相當成上下鄰居")
            XCTAssertFalse(edge.bottom.touchesCard)
        }
    }

    func testTouchToleranceIsOnePoint() {
        let upper = CGRect(x: 0, y: 0, width: 200, height: 100)
        let almost = CGRect(x: 0, y: 100.9, width: 200, height: 100)
        let apart = CGRect(x: 0, y: 101.1, width: 200, height: 100)
        XCTAssertTrue(VerticalEdge.resolve(frames: [upper, almost], tickYs: [])[0].bottom.touchesCard)
        XCTAssertFalse(VerticalEdge.resolve(frames: [upper, apart], tickYs: [])[0].bottom.touchesCard)
    }

    func testTickToleranceIsHalfPoint() {
        let frame = CGRect(x: 0, y: 0, width: 200, height: 100)
        XCTAssertTrue(VerticalEdge.resolve(frames: [frame], tickYs: [100.4])[0].bottom.onTickLine)
        XCTAssertFalse(VerticalEdge.resolve(frames: [frame], tickYs: [100.6])[0].bottom.onTickLine)
    }

    /// 跨日 event 的 endY 被 clamp 到 timeline 底，那不是刻度線位置
    func testClampedBottomIsBlank() {
        let bottomOfTimeline = CGFloat(14) * verticalDiff
        let frame = CGRect(x: 0, y: slot((20, 0), (21, 0)).minY, width: 200, height: bottomOfTimeline - slot((20, 0), (21, 0)).minY)
        XCTAssertEqual(VerticalEdge.resolve(frames: [frame], tickYs: tickYs)[0].bottom, .blank)
    }

    // MARK: - 水平

    func testSingleColumnTouchesBothGroupEdges() {
        let result = rule.insets(top: .blank, bottom: .blank, columnIndex: 0, columnCount: 1)
        XCTAssertEqual(result.left, padding)
        XCTAssertEqual(result.right, padding)
    }

    func testSideBySideColumns() {
        let first = rule.insets(top: .blank, bottom: .blank, columnIndex: 0, columnCount: 3)
        let middle = rule.insets(top: .blank, bottom: .blank, columnIndex: 1, columnCount: 3)
        let last = rule.insets(top: .blank, bottom: .blank, columnIndex: 2, columnCount: 3)
        XCTAssertEqual(first.left, padding)
        XCTAssertEqual(first.right, gap / 2)
        XCTAssertEqual(middle.left, gap / 2)
        XCTAssertEqual(middle.right, gap / 2)
        XCTAssertEqual(last.left, gap / 2)
        XCTAssertEqual(last.right, padding)
        XCTAssertEqual(first.right + middle.left, gap, "並排兩張卡之間也是 gap")
    }

    func testRightToLeftSwapsHorizontalInsets() {
        let first = rule.insets(top: .blank, bottom: .blank, columnIndex: 0, columnCount: 3, isRightToLeft: true)
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

    // MARK: - Helpers

    private func slot(_ from: (Int, Int), _ to: (Int, Int), x: CGFloat = 0, width: CGFloat = 200) -> CGRect {
        func y(_ time: (Int, Int)) -> CGFloat {
            return CGFloat(time.0 - startHour) * verticalDiff + CGFloat(time.1) * verticalDiff / 60
        }
        return CGRect(x: x, y: y(from), width: width, height: y(to) - y(from))
    }

    /// 印成「★12 card 5 card ★24 card 12★」：數字是留白／縫，★ 標在刻度線那一側
    private func pattern(_ frames: [CGRect]) -> String {
        let edges = VerticalEdge.resolve(frames: frames, tickYs: tickYs)
        let cards = zip(frames, edges).map { frame, edge -> CGRect in
            let insets = rule.insets(top: edge.top, bottom: edge.bottom, columnIndex: 0, columnCount: 1)
            return CGRect(x: frame.minX + insets.left,
                          y: frame.minY + insets.top,
                          width: frame.width - insets.left - insets.right,
                          height: frame.height - insets.top - insets.bottom)
        }
        func number(_ value: CGFloat) -> String {
            return value == value.rounded() ? String(Int(value)) : String(describing: value)
        }
        var parts: [String] = [(edges[0].top.onTickLine ? "★" : "") + number(cards[0].minY - frames[0].minY)]
        for index in frames.indices {
            parts.append("card")
            if index < frames.count - 1 {
                let star = edges[index].bottom.onTickLine ? "★" : ""
                parts.append(star + number(cards[index + 1].minY - cards[index].maxY))
            } else {
                parts.append(number(frames[index].maxY - cards[index].maxY) + (edges[index].bottom.onTickLine ? "★" : ""))
            }
        }
        return parts.joined(separator: " ")
    }
}
