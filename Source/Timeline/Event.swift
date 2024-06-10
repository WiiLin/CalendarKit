import UIKit

public final class Event: EventDescriptor {
    public var image: UIImage?
    
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
    public weak var editedEvent: EventDescriptor? {
        didSet {
            updateColors()
        }
    }

    public var borderColor: UIColor = .clear
    public var borderWidth: CGFloat = 0

    public init() {}

    public func makeEditable() -> Event {
        let cloned = Event()
        cloned.startDate = startDate
        cloned.endDate = endDate
        cloned.isAllDay = isAllDay
        cloned.text = text
        cloned.attributedText = attributedText
        cloned.lineBreakMode = lineBreakMode
        cloned.color = color
        cloned.backgroundColor = backgroundColor
        cloned.textColor = textColor
        cloned.userInfo = userInfo
        cloned.editedEvent = self
        cloned.group = group
        cloned.borderColor = borderColor
        cloned.borderWidth = borderWidth
        return cloned
    }

    public func commitEditing() {
        guard let edited = editedEvent else { return }
        edited.startDate = startDate
        edited.endDate = endDate
    }

    private func updateColors() {
        (editedEvent != nil) ? applyEditingColors() : applyStandardColors()
    }

    private func applyStandardColors() {
        backgroundColor = color.withAlphaComponent(0.3)
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        color.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        textColor = UIColor(hue: h, saturation: s, brightness: b * 0.4, alpha: a)
    }

    private func applyEditingColors() {
        backgroundColor = color
        textColor = .white
    }
}

public extension Event {
    static func groupWidth(_ periods: [Event]) -> CGFloat {
        let array = periods.map {($0.startDate, $0.endDate)}

        let maxOverlap = Self.totalOverlapPeriods(periods)
        let width = 110.0
        return width * Double(maxOverlap)
    }


    static func updateGroupWidthIfNeed(group: [(name: String, width: CGFloat)], totalWidth: CGFloat) -> [(name: String, width: CGFloat)] {
        var group = group

        let currentTotalWidth = group.reduce(0) { $0 + $1.width }

        if currentTotalWidth < totalWidth {
            let scaleFactor = totalWidth / currentTotalWidth
            group = group.map { (name, width) in
                return (name, width * scaleFactor)
            }
        }

        return group
    }


    static func totalOverlapPeriods(_ periods: [Event]) -> Int {
        let validEvents = periods.filter { $0.range != nil }
        let sortedEvents = validEvents.sorted { $0.startDate < $1.startDate }
        var groupsOfEvents = [[Event]]()

        for event in sortedEvents {
            guard let eventRange = event.range else { continue }

            var foundGroup = false

            for i in 0..<groupsOfEvents.count {
                let group = groupsOfEvents[i]
                let longestEvent = group.sorted { (event1, event2) -> Bool in
                    let period1 = event1.endDate.timeIntervalSince(event1.startDate)
                    let period2 = event2.endDate.timeIntervalSince(event2.startDate)
                    return period1 > period2
                }.first!

                if let longestRange = longestEvent.range, longestRange.overlaps(eventRange) {
                    groupsOfEvents[i].append(event)
                    foundGroup = true
                    break
                }
            }

            if !foundGroup {
                groupsOfEvents.append([event])
            }
        }

        let longestGroupCount = groupsOfEvents.map { $0.count }.max() ?? 0
        return longestGroupCount == 0 ? 1 : longestGroupCount
      }


}

extension Event {
    var range: ClosedRange<Date>? {
        if endDate >= startDate {
            return startDate...endDate
        } else {
            return nil
        }
     }
}
