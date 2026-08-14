import UIKit

public final class TimelineContainerController: UIViewController {
    /// Content Offset to be set once the view size has been calculated
    public var pendingContentOffset: CGPoint?
    public lazy var timeline = TimelineView()
    lazy var fakeLeftTimelineView: LockTimelineView = .init(timelineView: timeline)
    lazy var lockContainer: UIScrollView = .init(frame: view.bounds)
    public lazy var container: TimelineContainer = {
        let view = TimelineContainer(timeline, container: self)
        view.addSubview(timeline)
        return view
    }()
    
//    public override func loadView() {
//        view = container
//    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        setupSubviews()
    }

    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override public func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        container.contentSize = timeline.frame.size
        lockContainer.isScrollEnabled = false
        lockContainer.contentSize = .init(width: timeline.style.leadingInset, height: timeline.frame.size.height)
        // timeline 高度會隨刻度設定與營業時段變動，左側時間欄要跟著調整並重繪
        let lockFrame = CGRect(x: 0, y: 0, width: timeline.style.leadingInset, height: timeline.frame.size.height)
        if fakeLeftTimelineView.frame != lockFrame {
            fakeLeftTimelineView.frame = lockFrame
            fakeLeftTimelineView.setNeedsDisplay()
        }
        if let newOffset = pendingContentOffset {
            // Apply new offset only once the size has been determined
            if view.bounds != .zero {
                container.setContentOffset(newOffset, animated: false)
                container.setNeedsLayout()
                pendingContentOffset = nil
            }
        }
    }
}

extension TimelineContainerController {
    func setupSubviews() {
        container.translatesAutoresizingMaskIntoConstraints = false
        container.frame = view.bounds
        view.addSubview(container)
        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: view.topAnchor),
            container.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            container.leftAnchor.constraint(equalTo: view.leftAnchor),
            container.rightAnchor.constraint(equalTo: view.rightAnchor),
        ])
//        lockContainer.backgroundColor = .red.withAlphaComponent(0.5)
        lockContainer.translatesAutoresizingMaskIntoConstraints = false
        lockContainer.frame = .init(x: 0, y: 0, width: 10, height: view.bounds.height)
        view.addSubview(lockContainer)
        NSLayoutConstraint.activate([
            lockContainer.topAnchor.constraint(equalTo: view.topAnchor),
            lockContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            lockContainer.leftAnchor.constraint(equalTo: view.leftAnchor),
            lockContainer.widthAnchor.constraint(equalToConstant: timeline.style.leadingInset),
        ])
        lockContainer.addSubview(fakeLeftTimelineView)
        fakeLeftTimelineView.backgroundColor = .white
        fakeLeftTimelineView.frame = CGRect(x: 0, y: 0, width: timeline.style.leadingInset, height: timeline.fullHeight)
    }
}

class LockTimelineView: UIView {
    let timelineView: TimelineView
    
    init(timelineView: TimelineView) {
        self.timelineView = timelineView
        super.init(frame: .zero)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public func draw(_ rect: CGRect) {
        super.draw(rect)

        // 刻度位置與 TimelineView 共用同一份，兩邊各算會對不上
        let tickYs = timelineView.tickYs
        let tickIndexToRemove = timelineView.tickIndexOverlappingNowLine

        let mutableParagraphStyle = NSParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
        mutableParagraphStyle.lineBreakMode = .byWordWrapping
        mutableParagraphStyle.alignment = .right
        let paragraphStyle = mutableParagraphStyle.copy() as! NSParagraphStyle

        let attributes = [NSAttributedString.Key.paragraphStyle: paragraphStyle,
                          NSAttributedString.Key.foregroundColor: timelineView.style.timeColor,
                          NSAttributedString.Key.font: timelineView.style.font] as [NSAttributedString.Key: Any]

        let scale = UIScreen.main.scale
        let hourLineHeight = 1 / UIScreen.main.scale

        let center: CGFloat
        if Int(scale) % 2 == 0 {
            center = 1 / (scale * 2)
        } else {
            center = 0
        }
      
        let offset = 0.5 - center
        var currentX: CGFloat = 0
        for index in 0 ..< timelineView.style.groupCount {

            let context = UIGraphicsGetCurrentContext()
            context!.interpolationQuality = .none
            context?.saveGState()
            context?.setStrokeColor(timelineView.style.separatorColor.cgColor)
            context?.setLineWidth(hourLineHeight)
          
            context?.beginPath()
            let x = timelineView.style.leadingInset + currentX
            context?.move(to: CGPoint(x: x, y: -30))
            context?.addLine(to: CGPoint(x: x, y: bounds.maxY - timelineView.style.verticalInset))
            context?.strokePath()
            context?.restoreGState()
            currentX += timelineView.style.groupWidth(index: index)
        }
      
        for (tickIndex, time) in timelineView.times.enumerated() {
            let rightToLeft = UIView.userInterfaceLayoutDirection(for: semanticContentAttribute) == .rightToLeft

            if tickIndex == tickIndexToRemove { continue }
            guard tickIndex < tickYs.count else { continue }

            let fontSize = timelineView.style.font.pointSize
            let timeRect: CGRect = {
                var x: CGFloat
                if rightToLeft {
                    x = bounds.width - 53
                } else {
                    x = 2
                }

                return CGRect(x: x,
                              y: tickYs[tickIndex] - 7,
                              width: timelineView.style.leadingInset - 8,
                              height: fontSize + 2)
            }()
      
            let timeString = NSString(string: time)
            timeString.draw(in: timeRect, withAttributes: attributes)
        }
    }
}
