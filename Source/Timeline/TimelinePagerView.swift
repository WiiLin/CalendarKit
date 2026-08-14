import UIKit

public protocol TimelinePagerViewDelegate: AnyObject {
    func timelinePagerDidSelectEventView(_ eventView: EventView)
    func timelinePagerDidLongPressEventView(_ eventView: EventView)
    func timelinePager(timelinePager: TimelinePagerView, didTapTimelineAt date: Date)
    func timelinePagerDidBeginDragging(timelinePager: TimelinePagerView)
    func timelinePagerDidTransitionCancel(timelinePager: TimelinePagerView)
    func timelinePager(timelinePager: TimelinePagerView, willMoveTo date: Date)
    func timelinePager(timelinePager: TimelinePagerView, didMoveTo date: Date)
    func timelinePager(timelinePager: TimelinePagerView, didLongPressTimelineAt date: Date)
}

public final class TimelinePagerView: UIView, UIScrollViewDelegate, DayViewStateUpdating, UIPageViewControllerDataSource, UIPageViewControllerDelegate, TimelineViewDelegate {
    public weak var dataSource: EventDataSource?
    public weak var delegate: TimelinePagerViewDelegate?

    public private(set) var calendar: Calendar = .autoupdatingCurrent

    public var timelineScrollOffset: CGPoint {
        // Any view is fine as they are all synchronized
        let offset = currentTimeline?.container.contentOffset
        return offset ?? CGPoint()
    }

    private var currentTimeline: TimelineContainerController? {
        return pagingViewController.viewControllers?.first as? TimelineContainerController
    }

    public var autoScrollToFirstEvent = false

    private var pagingViewController = UIPageViewController(transitionStyle: .scroll,
                                                            navigationOrientation: .horizontal,
                                                            options: nil)
    public private(set) var style = TimelineStyle()

    public weak var state: DayViewState? {
        willSet(newValue) {
            state?.unsubscribe(client: self)
        }
        didSet {
            state?.subscribe(client: self)
        }
    }

    public init(calendar: Calendar) {
        self.calendar = calendar
        super.init(frame: .zero)
        configure()
    }

    override public init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configure()
    }

    private func configure() {
        // 初始頁面需要立即更新 layoutAttributes
        let vc = configureTimelineController(date: Date(), shouldUpdateLayout: true)
        pagingViewController.setViewControllers([vc], direction: .forward, animated: false, completion: nil)
        pagingViewController.dataSource = self
        pagingViewController.delegate = self
        addSubview(pagingViewController.view!)
    }

    public func updateStyle(_ newStyle: TimelineStyle) {
        style = newStyle
        pagingViewController.viewControllers?.forEach { timelineContainer in
            if let controller = timelineContainer as? TimelineContainerController {
                self.updateStyleOfTimelineContainer(controller: controller)
            }
        }
        pagingViewController.view.backgroundColor = style.backgroundColor
    }

    private func updateStyleOfTimelineContainer(controller: TimelineContainerController) {
        let container = controller.container
        let timeline = controller.timeline
        timeline.updateStyle(style)
        container.backgroundColor = style.backgroundColor
        // style 會改變 fullHeight（刻度密度、營業時段），frame 沒跟著調整的話
        // 舊的繪製內容會被縮放後殘留在 layer 上，看起來像兩套刻度疊在一起
        container.updateTimelineFrame()
        container.setNeedsLayout()
        // 左側固定時間欄畫的是同一批刻度，style 換了也要重繪
        controller.fakeLeftTimelineView.setNeedsDisplay()
    }

    public func scrollTo(hour24: Float, animated: Bool = true) {
        // Any view is fine as they are all synchronized
        if let controller = currentTimeline {
            controller.container.scrollTo(hour24: hour24, animated: animated)
        }
    }

    /// 配置 TimelineController
    /// - Parameters:
    ///   - date: 要顯示的日期
    ///   - shouldUpdateLayout: 是否立即更新 layoutAttributes（只有當前頁才需要）
    /// - Returns: 配置好的 TimelineContainerController
    private func configureTimelineController(date: Date, shouldUpdateLayout: Bool = false) -> TimelineContainerController {
        let controller = TimelineContainerController()
        updateStyleOfTimelineContainer(controller: controller)
        let timeline = controller.timeline
        timeline.delegate = self
        timeline.calendar = calendar
        timeline.date = date.dateOnly(calendar: calendar)
        controller.container.delegate = self
        // 只有當前頁才立即更新 layoutAttributes，預加載頁稍後在 didMoveTo 時更新
        if shouldUpdateLayout {
            updateTimeline(timeline)
        }
        return controller
    }

    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offset = scrollView.contentOffset
        currentTimeline?.lockContainer.contentOffset = .init(x: 0, y: offset.y)
    }

    /// 重新載入數據，只更新當前可見的 TimelineView
    public func reloadData() {
        // 只更新當前可見的 TimelineView，避免更新預加載頁
        if let currentTimeline = currentTimeline {
            updateTimeline(currentTimeline.timeline)
        }
    }

    override public func layoutSubviews() {
        super.layoutSubviews()
        pagingViewController.view.frame = bounds
    }

    private func updateTimeline(_ timeline: TimelineView) {
        guard let dataSource = dataSource else { return }
        let date = timeline.date.dateOnly(calendar: calendar)
        let events = dataSource.eventsForDate(date)

        let end = calendar.date(byAdding: .day, value: 1, to: date)!
        let day = date ... end
        let validEvents = events.filter { $0.datePeriod.overlaps(day) }
        timeline.layoutAttributes = validEvents.map(EventLayoutAttributes.init)
    }

    public func updateTimelineFrame() {
        if let controller = currentTimeline {
            controller.container.updateTimelineFrame()
        }
    }

    public func scrollToFirstEventIfNeeded(animated: Bool) {
        if autoScrollToFirstEvent {
            if let controller = currentTimeline {
                controller.container.scrollToFirstEvent(animated: animated)
            }
        }
    }

    // MARK: DayViewStateUpdating

    public func move(from oldDate: Date, to newDate: Date) {
        let oldDate = oldDate.dateOnly(calendar: calendar)
        let newDate = newDate.dateOnly(calendar: calendar)
        // 創建新控制器時不立即更新 layoutAttributes，稍後在 completionHandler 中更新
        let newController = configureTimelineController(date: newDate, shouldUpdateLayout: false)

        delegate?.timelinePager(timelinePager: self, willMoveTo: newDate)

        func completionHandler(_ completion: Bool) {
            DispatchQueue.main.async { [self] in
                // Fix for the UIPageViewController issue: https://stackoverflow.com/questions/12939280/uipageviewcontroller-navigates-to-wrong-page-with-scroll-transition-style
        
                let leftToRight = UIView.userInterfaceLayoutDirection(for: semanticContentAttribute) == .leftToRight
                let direction: UIPageViewController.NavigationDirection = leftToRight ? .reverse : .forward
        
                self.pagingViewController.setViewControllers([newController],
                                                             direction: direction,
                                                             animated: false,
                                                             completion: nil)
              
                // 在 didMoveTo 時才更新當前頁的 layoutAttributes
                if let currentTimeline = self.currentTimeline {
                    self.updateTimeline(currentTimeline.timeline)
                }
              
                self.pagingViewController.viewControllers?.first?.view.setNeedsLayout()
                self.scrollToFirstEventIfNeeded(animated: true)
                self.delegate?.timelinePager(timelinePager: self, didMoveTo: newDate)
            }
        }

        if newDate < oldDate {
            currentTimeline?.timeline.enqueueEventViews()
            
            let leftToRight = UIView.userInterfaceLayoutDirection(for: semanticContentAttribute) == .leftToRight
            let direction: UIPageViewController.NavigationDirection = leftToRight ? .reverse : .forward
            pagingViewController.setViewControllers([newController],
                                                    direction: direction,
                                                    animated: true,
                                                    completion: completionHandler(_:))
        } else if newDate > oldDate {
            currentTimeline?.timeline.enqueueEventViews()
            let leftToRight = UIView.userInterfaceLayoutDirection(for: semanticContentAttribute) == .leftToRight
            let direction: UIPageViewController.NavigationDirection = leftToRight ? .forward : .reverse
            pagingViewController.setViewControllers([newController],
                                                    direction: direction,
                                                    animated: true,
                                                    completion: completionHandler(_:))
        }
    }

    // MARK: UIPageViewControllerDataSource

    public func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let containerController = viewController as? TimelineContainerController else { return nil }
        let previousDate = calendar.date(byAdding: .day, value: -1, to: containerController.timeline.date)!
        // 預加載頁不立即更新 layoutAttributes，稍後在 didMoveTo 時更新
        let vc = configureTimelineController(date: previousDate, shouldUpdateLayout: false)
        let offset = (pageViewController.viewControllers?.first as? TimelineContainerController)?.container.contentOffset
        vc.pendingContentOffset = offset
        return vc
    }

    public func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let containerController = viewController as? TimelineContainerController else { return nil }
        let nextDate = calendar.date(byAdding: .day, value: 1, to: containerController.timeline.date)!
        // 預加載頁不立即更新 layoutAttributes，稍後在 didMoveTo 時更新
        let vc = configureTimelineController(date: nextDate, shouldUpdateLayout: false)
        let offset = (pageViewController.viewControllers?.first as? TimelineContainerController)?.container.contentOffset
        vc.pendingContentOffset = offset
        return vc
    }

    // MARK: UIPageViewControllerDelegate

    public func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        guard completed else {
            delegate?.timelinePagerDidTransitionCancel(timelinePager: self)
            return
        }
        if let timelineContainerController = pageViewController.viewControllers?.first as? TimelineContainerController {
            (previousViewControllers as? [TimelineContainerController])?.forEach { vc in
                vc.timeline.enqueueEventViews()
            }
            let selectedDate = timelineContainerController.timeline.date
            delegate?.timelinePager(timelinePager: self, willMoveTo: selectedDate)
            // 在 didMoveTo 時才更新當前頁的 layoutAttributes
            updateTimeline(timelineContainerController.timeline)
            state?.client(client: self, didMoveTo: selectedDate)
            scrollToFirstEventIfNeeded(animated: true)
            delegate?.timelinePager(timelinePager: self, didMoveTo: selectedDate)
        }
    }
  
    public func pageViewController(_ pageViewController: UIPageViewController, willTransitionTo pendingViewControllers: [UIViewController]) {
        delegate?.timelinePagerDidBeginDragging(timelinePager: self)
    }

    // MARK: TimelineViewDelegate
  
    public func timelineView(_ timelineView: TimelineView, didTapAt date: Date) {
        delegate?.timelinePager(timelinePager: self, didTapTimelineAt: date)
    }
  
    public func timelineView(_ timelineView: TimelineView, didLongPressAt date: Date) {
        delegate?.timelinePager(timelinePager: self, didLongPressTimelineAt: date)
    }
  
    public func timelineView(_ timelineView: TimelineView, didTap event: EventView) {
        delegate?.timelinePagerDidSelectEventView(event)
    }
  
    public func timelineView(_ timelineView: TimelineView, didLongPress event: EventView) {
        delegate?.timelinePagerDidLongPressEventView(event)
    }
}
