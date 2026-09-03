import UIKit

public final class Event: EventDescriptor {
    public var images: [UIImage] = []
    
    public var group: Int = 0
    
    public var startDate = Date()
    public var endDate = Date()
    public var isAllDay = false
    public var text = ""
    public var attributedText: NSAttributedString?
    public var lineBreakMode: NSLineBreakMode?
    public var color = SystemColors.systemBlue {
        didSet {
            updateColors()
        }
    }

    public var backgroundColor = SystemColors.systemBlue.withAlphaComponent(0.3)
    public var textColor = SystemColors.label
    public var font = UIFont.boldSystemFont(ofSize: 12)
    public var userInfo: Any?

    public var borderColor: UIColor = .clear
    public var borderWidth: CGFloat = 0
    /// 事件卡片圓角；沿用原本寫死的 2，要膠囊感的 App 自己調大
    public var cornerRadius: CGFloat = 2
    public var bottomRightText: String?

    public init() {}

    private func updateColors() {
        backgroundColor = color.withAlphaComponent(0.3)
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        color.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        textColor = UIColor(hue: h, saturation: s, brightness: b * 0.4, alpha: a)
    }
}

public extension Event {
    /// 一欄要多寬：同時進行的最大筆數 × 單格寬。單格寬由 App 決定（iPhone 與 iPad 不同）
    static func groupWidth(_ periods: [Event], slotWidth: CGFloat = 110) -> CGFloat {
        let maxOverlap = Self.totalOverlapPeriods(periods)
        return slotWidth * CGFloat(maxOverlap)
    }

    static func updateGroupWidthIfNeed(group: [TimelineGroup], totalWidth: CGFloat) -> [TimelineGroup] {
        var group = group

        let currentTotalWidth = group.reduce(0) { $0 + $1.width }

        if currentTotalWidth < totalWidth {
            let scaleFactor = totalWidth / currentTotalWidth
            group = group.map { group in
                .init(name: group.name, width: group.width * scaleFactor)
            }
        }

        return group
    }

    /// 同一時刻最多幾筆同時進行，決定這一欄要幾格寬。
    ///
    /// 舊版算的是「連通群的大小」：A 與 B 重疊、B 與 C 重疊時，即使 A 與 C 完全錯開
    /// 也會被算成同一群。只要有一筆跨整天的事件，當天所有預約都會被串成一大群，
    /// 欄寬就變成「當天筆數 × 110」而不是實際需要的格數。
    /// 改用掃描線取「同時進行的最大筆數」。
    static func totalOverlapPeriods(_ periods: [Event]) -> Int {
        let ranges = periods.compactMap { $0.range }
        guard ranges.isEmpty == false else { return 1 }

        var points: [(date: Date, delta: Int)] = []
        points.reserveCapacity(ranges.count * 2)
        for range in ranges {
            points.append((range.lowerBound, 1))
            points.append((range.upperBound, -1))
        }
        // 同一時間點先處理離場，讓「前一筆結束、後一筆開始」不算重疊
        points.sort { $0.date == $1.date ? $0.delta < $1.delta : $0.date < $1.date }

        var current = 0
        var maxOverlap = 0
        for point in points {
            current += point.delta
            maxOverlap = max(maxOverlap, current)
        }
        return max(1, maxOverlap)
    }
}

extension Event {
    var range: ClosedRange<Date>? {
        if endDate >= startDate {
            return startDate ... endDate
        } else {
            return nil
        }
    }
}
