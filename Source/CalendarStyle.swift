import Foundation
import UIKit

public enum DateStyle {
    /// Times should be shown in the 12 hour format
    case twelveHour
    
    /// Times should be shown in the 24 hour format
    case twentyFourHour
    
    /// Times should be shown according to the user's system preference.
    case system
    
    case custom(start24Hour: Int, end24Hour: Int, timeStrings: [String])
    
    public var count: Int {
        switch self {
        case let .custom(_, _, timeStrings):
            return timeStrings.count
        default:
            return 24
        }
    }
    
    func real24Hour(original24Hour: Int) -> Int {
        switch self {
        case let .custom(start24Hour, _, _):
            return original24Hour - start24Hour
        default:
            return original24Hour
        }
    }
    
    public func inHourRange(startDate: Date, endDate: Date, calendar: Calendar) -> Bool {
        switch self {
        case let .custom(start24Hour, end24Hour, _):
            let date = Date() // 取得目前時間
            let startDateHour = calendar.component(.hour, from: startDate)
            let endDateHour = calendar.component(.hour, from: endDate)
            return startDateHour >= start24Hour && endDateHour <= end24Hour
        default:
            return true
        }
    }
}

public struct CalendarStyle {
    public var header = DayHeaderStyle()
    public var timeline = TimelineStyle()
    public init() {}
}

public struct DayHeaderStyle {
    public var daySymbols = DaySymbolsStyle()
    public var daySelector = DaySelectorStyle()
    public var swipeLabel = SwipeLabelStyle()
    public var backgroundColor = SystemColors.secondarySystemBackground
    public init() {}
}

public struct DaySelectorStyle {
    public var activeTextColor = SystemColors.systemBackground
    public var selectedBackgroundColor = SystemColors.label

    public var weekendTextColor = SystemColors.secondaryLabel
    public var inactiveTextColor = SystemColors.label
    public var inactiveBackgroundColor = UIColor.clear

    public var todayInactiveTextColor = SystemColors.systemRed
    public var todayActiveTextColor = UIColor.white
    public var todayActiveBackgroundColor = SystemColors.systemRed
    
    public var font = UIFont.systemFont(ofSize: 18)
    public var todayFont = UIFont.boldSystemFont(ofSize: 18)
  
    public init() {}
}

public struct DaySymbolsStyle {
    public var weekendColor = SystemColors.secondaryLabel
    public var weekDayColor = SystemColors.label
    public var font = UIFont.systemFont(ofSize: 10)
    public init() {}
}

public struct SwipeLabelStyle {
    public var textColor = SystemColors.label
    public var font = UIFont.systemFont(ofSize: 15)
    public init() {}
}

public struct TimelineStyle {
    public var allDayStyle = AllDayViewStyle()
    public var timeIndicator = CurrentTimeIndicatorStyle()
    public var timeColor = SystemColors.secondaryLabel
    public var separatorColor = SystemColors.systemSeparator
    public var backgroundColor = SystemColors.systemBackground
    public var font = UIFont.boldSystemFont(ofSize: 11)
    public var dateStyle: DateStyle = .system
    public var minimumEventDurationInMinutesWhileEditing: Int = 30
    public var splitMinuteInterval: Int = 15
    public var verticalDiff: CGFloat = 100
    public var verticalInset: CGFloat = 10
    public var leadingInset: CGFloat = 53
    public var eventGap: CGFloat = 0
    public var group: [(name: String, width: CGFloat)] = []
    var groupCount: Int {
        return group.count
    }

    var totalGroupWidth: CGFloat {
        return group.map { $0.width }.reduce(0, {$0 + $1})
    }

    public var fixWidthGroupCount: Int = 7
    
//    func contentWidth() -> CGFloat {
//        if groupCount <= fixWidthGroupCount {
//            return UIScreen.main.bounds.width
//        } else {
//            return leadingInset + (110.0 * CGFloat(groupCount))
//        }
//    }
//
//    func groupWidth(index: Int) -> CGFloat {
//        if groupCount <= fixWidthGroupCount {
//            return (UIScreen.main.bounds.width - leadingInset) / CGFloat(groupCount)
//        } else {
//            return 110
//        }
//    }


    func contentWidth() -> CGFloat {
        return leadingInset + totalGroupWidth
    }
    
    func groupWidth(index: Int) -> CGFloat {
        return group[safe: index]?.width ?? 0
    }

    func groupX(index: Int) -> CGFloat {
        return group.prefix(index).map { $0.width }.reduce(0, {$0 + $1})
    }

    public init() {}
}

public struct CurrentTimeIndicatorStyle {
    public var color = SystemColors.systemRed
    public var font = UIFont.systemFont(ofSize: 11)
    public var dateStyle: DateStyle = .system
    public init() {}
}

public struct AllDayViewStyle {
    public var backgroundColor: UIColor = SystemColors.systemGray4
    public var allDayFont = UIFont.systemFont(ofSize: 12.0)
    public var allDayColor: UIColor = SystemColors.label
    public init() {}
}




private extension Collection {
    /// Returns the element at the specified index if it is within bounds, otherwise nil.
    subscript (safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
