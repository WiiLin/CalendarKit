import UIKit

/// 左側固定的時間刻度欄。整個 TimelinePagerView 只有一份，換頁時改指向當前的
/// TimelineView；刻度位置與文字都直接取自它，不自己算，兩邊才不會不同步。
final class TimeRulerView: UIView {
    /// 背景色由 TimelinePagerView 在 syncTimeRuler 一併設定，
    /// 那裡才拿得到最新的 style（換 style 時這個參考不會變）
    weak var timelineView: TimelineView? {
        didSet {
            setNeedsDisplay()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        // 事件與長按都由下層的 TimelineView 處理，這層只是視覺
        isUserInteractionEnabled = false
        backgroundColor = .white
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ rect: CGRect) {
        super.draw(rect)
        guard let timelineView = timelineView else { return }

        let style = timelineView.style
        let tickYs = timelineView.tickYs
        let tickIndexToRemove = timelineView.tickIndexOverlappingNowLine

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = .byWordWrapping
        paragraphStyle.alignment = .center

        let attributes: [NSAttributedString.Key: Any] = [
            .paragraphStyle: paragraphStyle,
            .foregroundColor: style.timeColor,
            .font: style.font,
        ]

        let isRightToLeft = UIView.userInterfaceLayoutDirection(for: semanticContentAttribute) == .rightToLeft
        // 文字置中，繪製區域就要吃滿整個時間欄，不再為右對齊留邊距
        let x: CGFloat = isRightToLeft ? bounds.width - style.leadingInset : 0

        for (tickIndex, time) in timelineView.times.enumerated() where tickIndex != tickIndexToRemove {
            // 文字垂直居中在刻度線上，但不能超出上緣 —— verticalInset 為 0 時第一個刻度會被裁掉
            let timeRect = CGRect(x: x,
                                  y: max(0, tickYs[tickIndex] - 7),
                                  width: style.leadingInset,
                                  height: style.font.pointSize + 2)
            NSString(string: time).draw(in: timeRect, withAttributes: attributes)
        }
    }
}
