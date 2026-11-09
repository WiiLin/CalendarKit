@testable import CalendarKit
import XCTest

/// 營業時段不是全天時，跨日的時間與「24:00」刻度都要落在 timeline 底部，而不是被折回營業時段中間
final class TimelineViewDateToYTests: XCTestCase {
    private let verticalDiff: CGFloat = 90
    private let startHour = 10
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Taipei")!
        return calendar
    }

    private var day: Date {
        return calendar.date(from: DateComponents(year: 2026, month: 9, day: 4))!
    }

    private func makeTimeline(end24Hour: Int, timeStrings: [String]) -> TimelineView {
        let timeline = TimelineView()
        timeline.calendar = calendar
        timeline.date = day
        var style = TimelineStyle()
        style.verticalDiff = verticalDiff
        style.verticalInset = 0
        style.dateStyle = .custom(start24Hour: startHour, end24Hour: end24Hour, timeStrings: timeStrings)
        timeline.updateStyle(style)
        return timeline
    }

    private func time(_ hour: Int, _ minute: Int) -> Date {
        return calendar.date(byAdding: .minute, value: hour * 60 + minute, to: day)!
    }

    func testSameDayTimeIsRelativeToStartHour() {
        let timeline = makeTimeline(end24Hour: 23, timeStrings: [])
        XCTAssertEqual(timeline.dateToY(time(23, 45)), (23.75 - 10) * verticalDiff, accuracy: 0.01)
    }

    /// 23:45 的單服務到隔天 00:15：結束要在 24:00 之後，不能算成營業時段中間
    func testNextDayTimeContinuesPastMidnight() {
        let timeline = makeTimeline(end24Hour: 24, timeStrings: [])
        XCTAssertEqual(timeline.dateToY(time(24, 15)), (24.25 - 10) * verticalDiff, accuracy: 0.01)
    }

    func testFullDayStyleKeepsNextDayOffset() {
        let timeline = TimelineView()
        timeline.calendar = calendar
        timeline.date = day
        var style = TimelineStyle()
        style.verticalDiff = verticalDiff
        style.verticalInset = 0
        style.dateStyle = .twentyFourHour
        timeline.updateStyle(style)
        XCTAssertEqual(timeline.dateToY(time(24, 15)), 24.25 * verticalDiff, accuracy: 0.01)
    }

    /// 「24:00」刻度要畫在 timeline 底部那條線，與 dateToY 同一套換算
    func testMidnightTickSitsAtBottom() {
        let timeline = makeTimeline(end24Hour: 24, timeStrings: ["10:00", "23:00", "24:00"])
        XCTAssertEqual(timeline.tickYs, [0, 13 * verticalDiff, 14 * verticalDiff])
    }
}
