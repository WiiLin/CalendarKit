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
    /// 日期文字後面加一個下箭頭，提示可點開整月日曆
    public var showsTapIndicator = false
    public init() {}
}

public struct TimelineGroup {
    let name: NSAttributedString
    let width: CGFloat
    public init(name: NSAttributedString, width: CGFloat) {
        self.name = name
        self.width = width
    }
}

public struct TimelineStyle {
    /// 全天事件區塊的樣式
    public var allDayStyle = AllDayViewStyle()
    /// 當前時間指示線的樣式（紅線）
    public var timeIndicator = CurrentTimeIndicatorStyle()
    /// 左側時間文字的顏色（如 10 AM、11 AM）
    public var timeColor = SystemColors.secondaryLabel
    /// 每小時之間水平分隔線的顏色
    public var separatorColor = SystemColors.systemSeparator
    /// Timeline 的背景顏色
    public var backgroundColor = SystemColors.systemBackground
    /// 左側時間文字的字體
    public var font = UIFont.boldSystemFont(ofSize: 11)
    /// 時間顯示格式（12小時制、24小時制、系統設定、或自訂時段）
    public var dateStyle: DateStyle = .system
    /// 每小時的高度（像素），影響 timeline 的垂直縮放比例
    public var verticalDiff: CGFloat = 100
    /// Timeline 頂部的內邊距
    public var verticalInset: CGFloat = 10
    /// 左側時間標籤區域的寬度，事件從這個位置之後開始繪製
    public var leadingInset: CGFloat = 53
    /// 相鄰事件之間的間距（像素）
    public var eventGap: CGFloat = 0
    /// 分組資訊（多人行事曆時，每個人一個 group）
    public var group: [TimelineGroup] = []
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
