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
        paragraphStyle.alignment = .right

        let attributes: [NSAttributedString.Key: Any] = [
            .paragraphStyle: paragraphStyle,
            .foregroundColor: style.timeColor,
            .font: style.font,
        ]

        let isRightToLeft = UIView.userInterfaceLayoutDirection(for: semanticContentAttribute) == .rightToLeft
        let x: CGFloat = isRightToLeft ? bounds.width - style.leadingInset : 2

        for (tickIndex, time) in timelineView.times.enumerated() where tickIndex != tickIndexToRemove {
            let timeRect = CGRect(x: x,
                                  y: tickYs[tickIndex] - 7,
                                  width: style.leadingInset - 8,
                                  height: style.font.pointSize + 2)
            NSString(string: time).draw(in: timeRect, withAttributes: attributes)
        }
    }
}
