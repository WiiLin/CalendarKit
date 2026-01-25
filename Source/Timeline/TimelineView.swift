import UIKit

/// TimelineView 的代理協議，用於處理用戶交互事件
public protocol TimelineViewDelegate: AnyObject {
    /// 當用戶點擊時間軸上的某個時間點時調用
    func timelineView(_ timelineView: TimelineView, didTapAt date: Date)
    /// 當用戶長按時間軸上的某個時間點時調用
    func timelineView(_ timelineView: TimelineView, didLongPressAt date: Date)
    /// 當用戶點擊某個事件視圖時調用
    func timelineView(_ timelineView: TimelineView, didTap event: EventView)
    /// 當用戶長按某個事件視圖時調用
    func timelineView(_ timelineView: TimelineView, didLongPress event: EventView)
}

/// 時間軸視圖，用於顯示日曆事件和時間軸
public final class TimelineView: UIView {
    /// 代理對象，用於接收用戶交互事件
    public weak var delegate: TimelineViewDelegate?

    /// 當前顯示的日期，當設置時會觸發重新佈局
    public var date = Date() {
        didSet {
            setNeedsLayout()
        }
    }

    /// 當前時間（實時獲取）
    public var currentTime: Date {
        return Date()
    }

    /// 所有事件視圖的陣列（非全天事件）
    private var eventViews = [EventView]()
    /// 一般事件的佈局屬性陣列（只讀）
    public private(set) var regularLayoutAttributes = [EventLayoutAttributes]()
    /// 全天事件的佈局屬性陣列（只讀）
    public private(set) var allDayLayoutAttributes = [EventLayoutAttributes]()
  
    /// 所有事件的佈局屬性，設置時會自動分離全天事件和一般事件，並重新計算佈局
    public var layoutAttributes: [EventLayoutAttributes] {
        set {
            let totalStartTime = CFAbsoluteTimeGetCurrent()
            print("set layoutAttributes count = \(layoutAttributes.count), date = \(date)")
            // 快速分離 allDay 和 regular 事件，使用 reserveCapacity 預分配容量
            // 單次遍歷分離，避免重複計算
            allDayLayoutAttributes.removeAll(keepingCapacity: true)
            regularLayoutAttributes.removeAll(keepingCapacity: true)
            allDayLayoutAttributes.reserveCapacity(newValue.count)
            regularLayoutAttributes.reserveCapacity(newValue.count)
            
            for anEventLayoutAttribute in newValue {
                if anEventLayoutAttribute.descriptor.isAllDay {
                    allDayLayoutAttributes.append(anEventLayoutAttribute)
                } else {
                    regularLayoutAttributes.append(anEventLayoutAttribute)
                }
            }
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            UIView.performWithoutAnimation {
                print("⏱️===========================================================")
                recalculateEventLayout()
                prepareEventViews()
                layoutEvents()
                if (allDayLayoutAttributes.count == 0 && style.groupCount <= 1) {
                    allDayView.isHidden = true
                } else {
                    allDayView.isHidden = false
                    allDayView.events = allDayLayoutAttributes.map { $0.descriptor }
                    allDayView.scrollToBottom()
                }
            }
            setNeedsLayout()
            CATransaction.commit()
            
            let totalElapsedTime = (CFAbsoluteTimeGetCurrent() - totalStartTime) * 1000 // 轉換為毫秒
            print("⏱️ layoutAttributes setter 總耗時: \(String(format: "%.3f", totalElapsedTime))ms")
            print("⏱️===========================================================")
        }
        get {
            return allDayLayoutAttributes + regularLayoutAttributes
        }
    }

    /// 事件視圖重用池，用於重用 EventView 實例以提升效能
    /// 所有 TimelineView 實例共用同一個 pool，以提升資源利用效率
    private static let sharedPool = ReusePool<EventView>()
    
    /// 當前實例使用的 pool（指向共享的 pool）
    private var pool: ReusePool<EventView> {
        return TimelineView.sharedPool
    }

    /// 第一個事件的 Y 座標位置，用於自動滾動到第一個事件
    public var firstEventYPosition: CGFloat? {
        let first = regularLayoutAttributes.sorted { $0.frame.origin.y < $1.frame.origin.y }.first
        guard let firstEvent = first else { return nil }
        let firstEventPosition = firstEvent.frame.origin.y
        let beginningOfDayPosition = dateToY(date)
        return max(firstEventPosition, beginningOfDayPosition)
    }

    /// 當前時間指示線（顯示當前時間的紅色線）
    private lazy var nowLine: CurrentTimeIndicator = .init()
  
    /// 全天視圖的頂部約束，用於在滾動時保持固定位置
    private var allDayViewTopConstraint: NSLayoutConstraint?
    
    /// 組名稱視圖（顯示設計師名稱等）
    private lazy var groupNameView: GroupNameView = {
        let groupNameView = GroupNameView(frame: CGRect.zero)
        groupNameView.translatesAutoresizingMaskIntoConstraints = false
        allDayView.addSubview(groupNameView)
        groupNameView.topAnchor.constraint(equalTo: allDayView.topAnchor, constant: 0).isActive = true
        groupNameView.leadingAnchor.constraint(equalTo: allDayView.leadingAnchor, constant: 0).isActive = true
        groupNameView.trailingAnchor.constraint(equalTo: allDayView.trailingAnchor, constant: 0).isActive = true
        groupNameView.bottomAnchor.constraint(equalTo: allDayView.bottomAnchor, constant: 0).isActive = true
        return groupNameView
    }()
    
    /// 全天事件視圖容器
    private lazy var allDayView: AllDayView = {
        let allDayView = AllDayView(frame: CGRect.zero)
    
        allDayView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(allDayView)

        self.allDayViewTopConstraint = allDayView.topAnchor.constraint(equalTo: topAnchor, constant: 0)
        self.allDayViewTopConstraint?.isActive = true

        allDayView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 0).isActive = true
        allDayView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 0).isActive = true
        allDayView.heightAnchor.constraint(equalToConstant: 30).isActive = true
        return allDayView
    }()
    
    /// 組名稱視圖的高度
    var groupNameViewHeight: CGFloat = 30
  
    /// 全天視圖的實際高度
    var allDayViewHeight: CGFloat {
        return allDayView.bounds.height
    }

    /// 時間軸的樣式配置
    public var style = TimelineStyle()
    /// 事件視圖的水平內邊距
    private var horizontalEventInset: CGFloat = 3

    /// 時間軸的完整高度（包含所有小時）
    public var fullHeight: CGFloat {
        return style.verticalInset * 2 + style.verticalDiff * CGFloat(style.dateStyle.count)
    }

    /// 日曆區域的寬度（總寬度減去左側時間標籤寬度）
    public var calendarWidth: CGFloat {
        return bounds.width - style.leadingInset
    }
    
    /// 是否使用 24 小時制顯示時間
    public private(set) var is24hClock = true {
        didSet {
            setNeedsDisplay()
        }
    }

    /// 使用的日曆系統，設置時會更新相關行為
    public var calendar: Calendar = .autoupdatingCurrent {
        didSet {
            snappingBehavior = snappingBehaviorType.init(calendar)
            nowLine.calendar = calendar
            regenerateTimeStrings()
            setNeedsLayout()
        }
    }
  
    /// 事件編輯時的對齊行為類型（例如：對齊到 15 分鐘間隔）
    // TODO: Make a public API
    public var snappingBehaviorType: EventEditingSnappingBehavior.Type = SnapTo15MinuteIntervals.self
    /// 事件編輯時的對齊行為實例
    lazy var snappingBehavior: EventEditingSnappingBehavior = snappingBehaviorType.init(calendar)

    /// 時間標籤字串陣列（用於顯示在左側）
    public var times: [String] {
        switch style.dateStyle {
        case let .custom(_, _, timeStrings):
            return timeStrings
        default: return
            is24hClock ? _24hTimes : _12hTimes
        }
    }

    /// 12 小時制的時間字串陣列
    private lazy var _12hTimes: [String] = TimeStringsFactory(calendar).make12hStrings()
    /// 24 小時制的時間字串陣列
    private lazy var _24hTimes: [String] = TimeStringsFactory(calendar).make24hStrings()
  
    /// 重新生成時間字串（當日曆改變時調用）
    private func regenerateTimeStrings() {
        let factory = TimeStringsFactory(calendar)
        _12hTimes = factory.make12hStrings()
        _24hTimes = factory.make24hStrings()
    }
  
    /// 長按手勢識別器
    public lazy var longPressGestureRecognizer = UILongPressGestureRecognizer(target: self,
                                                                              action: #selector(longPress(_:)))

    /// 點擊手勢識別器
    public lazy var tapGestureRecognizer = UITapGestureRecognizer(target: self,
                                                                  action: #selector(tap(_:)))

    /// 判斷當前顯示的日期是否為今天
    public var isToday: Bool {
        return calendar.isDateInToday(date)
    }
  
    // MARK: - Initialization
  
    /// 初始化時間軸視圖（使用默認 frame）
    public init() {
        super.init(frame: .zero)
        frame.size.height = fullHeight
        configure()
    }

    /// 使用指定的 frame 初始化時間軸視圖
    override public init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }

    /// 從 Storyboard/XIB 初始化時間軸視圖
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configure()
    }

    /// 配置視圖的基本設置
    private func configure() {
        contentScaleFactor = 1
        layer.contentsScale = 1
        contentMode = .redraw
        backgroundColor = .white
        addSubview(nowLine)
    
        // 添加長按和點擊手勢識別器
        addGestureRecognizer(longPressGestureRecognizer)
        addGestureRecognizer(tapGestureRecognizer)
        groupNameView.backgroundColor = .white
    }
  
    // MARK: - Event Handling
  
    /// 處理長按手勢
    /// - Parameter gestureRecognizer: 長按手勢識別器
    @objc private func longPress(_ gestureRecognizer: UILongPressGestureRecognizer) {
        if gestureRecognizer.state == .began {
            // 獲取手勢位置對應的時間點
            let pressedLocation = gestureRecognizer.location(in: self)
            if let eventView = findEventView(at: pressedLocation) {
                // 如果點擊的是事件視圖，通知代理
                delegate?.timelineView(self, didLongPress: eventView)
            } else {
                // 如果點擊的是空白區域，通知代理對應的時間點
                delegate?.timelineView(self, didLongPressAt: yToDate(pressedLocation.y))
            }
        }
    }
  
    /// 處理點擊手勢
    /// - Parameter sender: 點擊手勢識別器
    @objc private func tap(_ sender: UITapGestureRecognizer) {
        let pressedLocation = sender.location(in: self)
        if let eventView = findEventView(at: pressedLocation) {
            // 如果點擊的是事件視圖，通知代理
            delegate?.timelineView(self, didTap: eventView)
        } else {
            // 如果點擊的是空白區域，通知代理對應的時間點
            delegate?.timelineView(self, didTapAt: yToDate(pressedLocation.y))
        }
    }
  
    /// 在指定位置查找事件視圖
    /// - Parameter point: 要查找的座標點
    /// - Returns: 找到的事件視圖，如果沒有則返回 nil
    private func findEventView(at point: CGPoint) -> EventView? {
        // 先檢查全天事件視圖
        for eventView in allDayView.eventViews {
            let frame = eventView.convert(eventView.bounds, to: self)
            if frame.contains(point) {
                return eventView
            }
        }

        // 再檢查一般事件視圖
        for eventView in eventViews {
            let frame = eventView.frame
            if frame.contains(point) {
                return eventView
            }
        }
        return nil
    }
  
    /**
     Custom implementation of the hitTest method is needed for the tap gesture recognizers
     located in the AllDayView to work.
     Since the AllDayView could be outside of the Timeline's bounds, the touches to the EventViews
     are ignored.
     In the custom implementation the method is recursively invoked for all of the subviews,
     regardless of their position in relation to the Timeline's bounds.
     */
    override public func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        for subview in allDayView.subviews {
            if let subSubView = subview.hitTest(convert(point, to: subview), with: event) {
                return subSubView
            }
        }
        return super.hitTest(point, with: event)
    }
  
    // MARK: - Style

    /// 更新時間軸的樣式
    /// - Parameter newStyle: 新的樣式配置
    public func updateStyle(_ newStyle: TimelineStyle) {
        style = newStyle
        allDayView.updateStyle(style.allDayStyle)
        nowLine.updateStyle(style.timeIndicator)
        groupNameView.updateStyle(newStyle)
        allDayView.isHidden = (allDayLayoutAttributes.count == 0 && style.groupCount <= 1)
        switch style.dateStyle {
        case .twelveHour:
            is24hClock = false
        case .twentyFourHour:
            is24hClock = true
        default:
            is24hClock = calendar.locale?.uses24hClock() ?? Locale.autoupdatingCurrent.uses24hClock()
        }
    
        backgroundColor = style.backgroundColor
        setNeedsDisplay()
    }
  
    // MARK: - Background Pattern

    /// 需要強調顯示的日期（用於繪製特殊標記）
    public var accentedDate: Date?

    override public func draw(_ rect: CGRect) {
        super.draw(rect)

        var hourToRemoveIndex = -1

        var accentedHour = -1
        var accentedMinute = -1

        if let accentedDate = accentedDate {
            accentedHour = snappingBehavior.accentedHour(for: accentedDate)
            accentedMinute = snappingBehavior.accentedMinute(for: accentedDate)
        }

        if isToday {
            let minute = component(component: .minute, from: currentTime)
            let hour = component(component: .hour, from: currentTime)
            if minute > 39 {
                hourToRemoveIndex = hour + 1
            } else if minute < 21 {
                hourToRemoveIndex = hour
            }
        }

        let mutableParagraphStyle = NSParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
        mutableParagraphStyle.lineBreakMode = .byWordWrapping
        mutableParagraphStyle.alignment = .right
        let paragraphStyle = mutableParagraphStyle.copy() as! NSParagraphStyle

        let attributes = [NSAttributedString.Key.paragraphStyle: paragraphStyle,
                          NSAttributedString.Key.foregroundColor: style.timeColor,
                          NSAttributedString.Key.font: style.font] as [NSAttributedString.Key: Any]

        let scale = UIScreen.main.scale
        let hourLineHeight = 1 / UIScreen.main.scale

        let center: CGFloat
        if Int(scale) % 2 == 0 {
            center = 1 / (scale * 2)
        } else {
            center = 0
        }
    
        let offset = 0.5 - center
        var currentX: CGFloat = style.leadingInset
        for index in 0 ..< style.groupCount {

            let context = UIGraphicsGetCurrentContext()
            context!.interpolationQuality = .none
            context?.saveGState()
            context?.setStrokeColor(style.separatorColor.cgColor)
            context?.setLineWidth(hourLineHeight)
        
            context?.beginPath()

            context?.move(to: CGPoint(x: currentX, y: -30))
            context?.addLine(to: CGPoint(x: currentX, y: bounds.maxY - style.verticalInset))
            context?.strokePath()
            context?.restoreGState()
            currentX += style.groupWidth(index: index)
        }
    
        for (hour, time) in times.enumerated() {
            let rightToLeft = UIView.userInterfaceLayoutDirection(for: semanticContentAttribute) == .rightToLeft
        
            let hourFloat = CGFloat(hour)
            let context = UIGraphicsGetCurrentContext()
            context!.interpolationQuality = .none
            context?.saveGState()
            context?.setStrokeColor(style.separatorColor.cgColor)
            context?.setLineWidth(hourLineHeight)
            let xStart: CGFloat = {
                if rightToLeft {
                    return bounds.width - 53
                } else {
                    return 53
                }
            }()
            let xEnd: CGFloat = {
                if rightToLeft {
                    return 0
                } else {
                    return bounds.width
                }
            }()
            let y = style.verticalInset + hourFloat * style.verticalDiff + offset
            context?.beginPath()
            context?.move(to: CGPoint(x: xStart, y: y))
            context?.addLine(to: CGPoint(x: xEnd, y: y))
            context?.strokePath()
            context?.restoreGState()
    
            if hour == hourToRemoveIndex { continue }
    
            let fontSize = style.font.pointSize
            let timeRect: CGRect = {
                var x: CGFloat
                if rightToLeft {
                    x = bounds.width - 53
                } else {
                    x = 2
                }
            
                return CGRect(x: x,
                              y: hourFloat * style.verticalDiff + style.verticalInset - 7,
                              width: style.leadingInset - 8,
                              height: fontSize + 2)
            }()
    
            let timeString = NSString(string: time)
            timeString.draw(in: timeRect, withAttributes: attributes)
    
            if accentedMinute == 0 {
                continue
            }
    
            if hour == accentedHour {
                var x: CGFloat
                if UIView.userInterfaceLayoutDirection(for: semanticContentAttribute) == .rightToLeft {
                    x = bounds.width - (style.leadingInset + 7)
                } else {
                    x = 2
                }
            
                let timeRect = CGRect(x: x, y: hourFloat * style.verticalDiff + style.verticalInset - 7 + style.verticalDiff * (CGFloat(accentedMinute) / 60),
                                      width: style.leadingInset - 8, height: fontSize + 2)
            
                let timeString = NSString(string: ":\(accentedMinute)")
            
                timeString.draw(in: timeRect, withAttributes: attributes)
            }
        }
    }
  
    // MARK: - Layout

    /// 當視圖需要重新佈局時調用
    override public func layoutSubviews() {
        super.layoutSubviews()
        // 如果正在拖動，不重新計算佈局
        if (superview as? TimelineContainer)?.isDragging ?? false { return }
        // 注意：recalculateEventLayout() 和 prepareEventViews() 已在 layoutAttributes setter 中調用
        // 這裡只需要根據已計算好的 frame 來佈局視圖
//        layoutEvents()
        layoutNowLine()
        layoutAllDayEvents()
    }

    /// 佈局當前時間指示線
    private func layoutNowLine() {
        if !isToday {
            // 如果不是今天，隱藏時間線
            nowLine.alpha = 0
        } else {
            // 如果是今天，顯示並定位時間線
            bringSubviewToFront(nowLine)
            nowLine.alpha = 1
            let size = CGSize(width: bounds.size.width, height: 20)
            let rect = CGRect(origin: CGPoint.zero, size: size)
            nowLine.date = currentTime
            nowLine.frame = rect
            nowLine.center.y = dateToY(currentTime)
        }
    }

    /// 佈局所有事件視圖
    private func layoutEvents() {
        if eventViews.isEmpty { return }
        
        let startTime = CFAbsoluteTimeGetCurrent()
        for (idx, attributes) in regularLayoutAttributes.enumerated() {
            let descriptor = attributes.descriptor
            let eventView = eventViews[idx]
            eventView.frame = attributes.frame
        
            // 處理 RTL（從右到左）佈局
            var x: CGFloat
            if UIView.userInterfaceLayoutDirection(for: semanticContentAttribute) == .rightToLeft {
                x = bounds.width - attributes.frame.minX - attributes.frame.width
            } else {
                x = attributes.frame.minX
            }
            // 添加內邊距
            let widthPadding: CGFloat = 2.0
            let heightPadding: CGFloat = 2.0
            eventView.frame = CGRect(x: x + widthPadding,
                                     y: attributes.frame.minY + heightPadding,
                                     width: attributes.frame.width - style.eventGap - (widthPadding * 2),
                                     height: attributes.frame.height - style.eventGap - (heightPadding * 2))
            eventView.updateWithDescriptor(event: descriptor)
        }
        let elapsedTime = (CFAbsoluteTimeGetCurrent() - startTime) * 1000 // 轉換為毫秒
        print("⏱️ layoutEvents 耗時: \(String(format: "%.3f", elapsedTime))ms, eventViews count = \(eventViews.count)")
    }
  
    /// 佈局全天事件視圖（確保在最前面）
    private func layoutAllDayEvents() {
        // 全天視圖需要顯示在當前時間線前面
        bringSubviewToFront(allDayView)
    }
  
    /**
     調整全天視圖的位置，使其在滾動時保持固定
     當父視圖是 ScrollView 時，此方法用於保持全天視圖在頂部可見
   
     - Parameter yValue: 滾動偏移量，通常是 ScrollView 的 contentOffset.y
     */
    public func offsetAllDayView(by yValue: CGFloat) {
        if let topConstraint = allDayViewTopConstraint {
            topConstraint.constant = yValue
            layoutIfNeeded()
        }
//    if let topConstraint = self.allDayViewTopConstraint {
//      topConstraint.constant = yValue
//      layoutIfNeeded()
//    }
    }

    /// 檢查日期範圍是否與其他日期範圍重疊
    /// - Parameters:
    ///   - date: 要檢查的日期範圍
    ///   - dates: 其他日期範圍陣列
    ///   - eventGap: 事件之間的間隔（未使用，保留用於未來擴展）
    /// - Returns: 如果重疊則返回 true，否則返回 false
    public class func overlap(date: ClosedRange<Date>, dates: [ClosedRange<Date>], eventGap: CGFloat) -> Bool {
        for element in dates {
            let overlap = date.overlaps(element)
            if overlap == true {
                return true
            }
        }
        return false
    }

    /// 重新計算事件的佈局（只處理非全天事件）
    /// 將重疊的事件分組，並計算每個事件的 frame
    private func recalculateEventLayout() {
        let startTime = CFAbsoluteTimeGetCurrent()
        // 過濾並排序事件，只處理非全天事件
        let sortedEvents = regularLayoutAttributes.filter { !$0.descriptor.isAllDay }
            .sorted { $0.descriptor.startDate < $1.descriptor.startDate }

        guard !sortedEvents.isEmpty else {
            let elapsedTime = (CFAbsoluteTimeGetCurrent() - startTime) * 1000
            print("⏱️ recalculateEventLayout 耗時: \(String(format: "%.3f", elapsedTime))ms, layoutAttributes count = \(layoutAttributes.count)")
            return
        }
        
        // 使用字典按 group 分組，減少需要檢查的事件數量
        var eventsByGroup: [Int: [EventLayoutAttributes]] = [:]
        for event in sortedEvents {
            let eventGroup = event.descriptor.group
            if eventsByGroup[eventGroup] == nil {
                eventsByGroup[eventGroup] = []
            }
            eventsByGroup[eventGroup]?.append(event)
        }
        
        // 為每個 group 計算重疊組
        var groupsOfEvents: [[EventLayoutAttributes]] = []
        
        for (_, groupEvents) in eventsByGroup {
            // 為當前 group 內的事件分組
            var groupOverlappingEvents: [[EventLayoutAttributes]] = []
            // 緩存每個組的最長事件，避免重複計算
            var longestEventCache: [Int: EventLayoutAttributes] = [:]
            
            for event in groupEvents {
                var foundGroup = false
                let eventPeriod = event.descriptor.datePeriod
                
                // 尋找重疊的組
                for groupIndex in 0..<groupOverlappingEvents.count {
                    let group = groupOverlappingEvents[groupIndex]
                    
                    // 使用緩存的最長事件，避免重複計算
                    let longestEvent: EventLayoutAttributes = {
                        if let cached = longestEventCache[groupIndex] {
                            return cached
                        }
                        // 計算最長事件並緩存
                        let longest = group.max(by: { attr1, attr2 in
                            let period1 = calendar.dateComponents([.second], from: attr1.descriptor.datePeriod.lowerBound, to: attr1.descriptor.datePeriod.upperBound).second ?? 0
                            let period2 = calendar.dateComponents([.second], from: attr2.descriptor.datePeriod.lowerBound, to: attr2.descriptor.datePeriod.upperBound).second ?? 0
                            return period1 < period2
                        }) ?? group[0]
                        longestEventCache[groupIndex] = longest
                        return longest
                    }()
                    
                    if TimelineView.overlap(date: longestEvent.descriptor.datePeriod, dates: [eventPeriod], eventGap: style.eventGap) {
                        groupOverlappingEvents[groupIndex].append(event)
                        // 如果新事件比最長事件還長，更新緩存
                        let newEventPeriod = calendar.dateComponents([.second], from: eventPeriod.lowerBound, to: eventPeriod.upperBound).second ?? 0
                        let longestEventPeriod = calendar.dateComponents([.second], from: longestEvent.descriptor.datePeriod.lowerBound, to: longestEvent.descriptor.datePeriod.upperBound).second ?? 0
                        if newEventPeriod > longestEventPeriod {
                            longestEventCache[groupIndex] = event
                        }
                        foundGroup = true
                        break
                    }
                }
                
                if !foundGroup {
                    let newGroupIndex = groupOverlappingEvents.count
                    groupOverlappingEvents.append([event])
                    longestEventCache[newGroupIndex] = event
                }
            }
            
            groupsOfEvents.append(contentsOf: groupOverlappingEvents)
        }

        // 計算並設置 frame
        for overlappingEvents in groupsOfEvents {
            guard let firstEvent = overlappingEvents.first else { continue }
            let totalCount = CGFloat(overlappingEvents.count)
            let groupWidth = style.groupWidth(index: firstEvent.descriptor.group)
            let groupX = style.groupX(index: firstEvent.descriptor.group)
            let equalWidth = groupWidth / totalCount
            
            for (index, event) in overlappingEvents.enumerated() {
                let floatIndex = CGFloat(index)
                let startY = dateToY(event.descriptor.datePeriod.lowerBound)
                var endY = dateToY(event.descriptor.datePeriod.upperBound)
                
                // 跨日 event 的 endY 會小於 startY，clamp 到 timeline 底部
                //https://redmine.ezpretty.com.tw/issues/24342
                if endY < startY {
                    endY = CGFloat(style.dateStyle.count) * style.verticalDiff + style.verticalInset
                }
                
                let x = groupX + style.leadingInset + floatIndex / totalCount * groupWidth

                event.frame = CGRect(x: x, y: startY, width: equalWidth, height: endY - startY)
            }
        }
        
        let elapsedTime = (CFAbsoluteTimeGetCurrent() - startTime) * 1000 // 轉換為毫秒
        print("⏱️ recalculateEventLayout 耗時: \(String(format: "%.3f", elapsedTime))ms, layoutAttributes count = \(layoutAttributes.count)")
    }

    /// 準備事件視圖（重用池機制）
    /// 將舊視圖回收到池中，然後從池中取出或創建新視圖
    private func prepareEventViews() {

        let startTime = CFAbsoluteTimeGetCurrent()
            enqueueEventViews()

            var reusableViews: [EventView] = []
            var newViews: [EventView] = []
            let neededCount = regularLayoutAttributes.count

            // 批量從池中取出
            for _ in 0..<neededCount {
                let tuple = pool.dequeue()
                if tuple.isNew {
                    newViews.append(tuple.object)
                } else {
                    reusableViews.append(tuple.object)
                }
            }

            // 關鍵：一次性添加所有 view
            let allViews = reusableViews + newViews
            allViews.forEach { $0.frame = .zero } // 可選：預設 frame
            self.addSubviews(allViews) // 使用批量添加擴展

            eventViews = allViews

            let elapsedTime = (CFAbsoluteTimeGetCurrent() - startTime) * 1000
            print("⏱️ prepareEventViews 耗時: \(String(format: "%.3f", elapsedTime))ms, new: \(newViews.count), reuse: \(reusableViews.count)")

    }

    /// 準備重用視圖（清理當前視圖並回收到池中）
    public func prepareForReuse() {
        // 先移除視圖的 superview，然後回收到重用池
        enqueueEventViews()
        setNeedsDisplay()
    }
    
    func enqueueEventViews() {
        eventViews.forEach { $0.removeFromSuperview() }
        pool.enqueue(views: eventViews)
        eventViews.removeAll()
    }

    // MARK: - Helpers

    /// 將日期轉換為 Y 座標
    /// - Parameter date: 要轉換的日期
    /// - Returns: 對應的 Y 座標位置
    public func dateToY(_ date: Date) -> CGFloat {
        let provisionedDate = date.dateOnly(calendar: calendar)
        let timelineDate = self.date.dateOnly(calendar: calendar)
        var dayOffset: CGFloat = 0
        if provisionedDate > timelineDate {
            // 事件結束於下一天
            dayOffset += 1
        } else if provisionedDate < timelineDate {
            // 事件開始於前一天
            dayOffset -= 1
        }
        let fullTimelineHeight = CGFloat(style.dateStyle.count) * style.verticalDiff
        let hour = component(component: .hour, from: date)
        let minute = component(component: .minute, from: date)
        let hourY = CGFloat(style.dateStyle.real24Hour(original24Hour: hour)) * style.verticalDiff + style.verticalInset
        let minuteY = CGFloat(minute) * style.verticalDiff / 60
        return hourY + minuteY + fullTimelineHeight * dayOffset
    }

    /// 將 Y 座標轉換為日期
    /// - Parameter y: Y 座標位置
    /// - Returns: 對應的日期
    public func yToDate(_ y: CGFloat) -> Date {
        let timeValue = y - style.verticalInset
        var hour = Int(timeValue / style.verticalDiff)
        let fullHourPoints = CGFloat(hour) * style.verticalDiff
        let minuteDiff = timeValue - fullHourPoints
        let minute = Int(minuteDiff / style.verticalDiff * 60)
        var dayOffset = 0
        if hour > 23 {
            dayOffset += 1
            hour -= 24
        } else if hour < 0 {
            dayOffset -= 1
            hour += 24
        }
        let offsetDate = calendar.date(byAdding: DateComponents(day: dayOffset),
                                       to: date)!
        let newDate = calendar.date(bySettingHour: hour,
                                    minute: minute.clamped(to: 0 ... 59),
                                    second: 0,
                                    of: offsetDate)
        return newDate!
    }

    /// 從日期中提取指定的日曆組件
    /// - Parameters:
    ///   - component: 要提取的組件類型（如 .hour, .minute）
    ///   - date: 日期
    /// - Returns: 組件的值
    public func component(component: Calendar.Component, from date: Date) -> Int {
        return calendar.component(component, from: date)
    }
  
    /// 獲取日期的時間區間（用於事件對齊）
    /// - Parameter date: 日期
    /// - Returns: 對齊後的時間區間
    private func getDateInterval(date: Date) -> ClosedRange<Date> {
        let earliestEventMintues = component(component: .minute, from: date)
        let splitMinuteInterval = style.splitMinuteInterval
        let minute = component(component: .minute, from: date)
        let minuteRange = (minute / splitMinuteInterval) * splitMinuteInterval
        let beginningRange = calendar.date(byAdding: .minute, value: -(earliestEventMintues - minuteRange), to: date)!
        let endRange = calendar.date(byAdding: .minute, value: splitMinuteInterval, to: beginningRange)!
        return beginningRange ... endRange
    }
}

extension UIView {
    func addSubviews(_ views: [UIView]) {
        views.forEach { addSubview($0) }
    }
}
