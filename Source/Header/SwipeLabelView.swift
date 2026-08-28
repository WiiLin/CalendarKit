import UIKit

public final class SwipeLabelView: UIView, DayViewStateUpdating {
    public enum AnimationDirection {
        case Forward
        case Backward
    
        mutating func flip() {
            switch self {
            case .Forward:
                self = .Backward
            case .Backward:
                self = .Forward
            }
        }
    }

    public private(set) var calendar = Calendar.autoupdatingCurrent
    public weak var state: DayViewState? {
        willSet(newValue) {
            state?.unsubscribe(client: self)
        }
        didSet {
            state?.subscribe(client: self)
            updateLabelText()
        }
    }

    /// 點日期文字的回呼，供上層開啟整月快速選日
    public var onTap: (() -> Void)?

    private func updateLabelText() {
        labels.first!.attributedText = decorated(formattedDate(date: state!.selectedDate))
    }

    private var firstLabel: UILabel {
        return labels.first!
    }

    private var secondLabel: UILabel {
        return labels.last!
    }

    private var labels = [UILabel]()

    private var style = SwipeLabelStyle()

    public init(calendar: Calendar = Calendar.autoupdatingCurrent) {
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
        for _ in 0 ... 1 {
            let label = UILabel()
            label.textAlignment = .center
            labels.append(label)
            addSubview(label)
        }
        // 只吃點擊，左右滑動切換日期的手勢不受影響
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTap)))
        updateStyle(style)
    }

    @objc private func handleTap() {
        onTap?()
    }

    /// 需要提示可點時，在日期文字後面附一個下箭頭
    private func decorated(_ text: String) -> NSAttributedString {
        let attributes: [NSAttributedString.Key: Any] = [.foregroundColor: style.textColor,
                                                         .font: style.font]
        let attributed = NSMutableAttributedString(string: text, attributes: attributes)
        // chevron.down 原生是扁的，bounds 給正方形會被水平壓窄；尺寸交給 SymbolConfiguration 決定
        let config = UIImage.SymbolConfiguration(pointSize: style.font.pointSize * 0.7, weight: .semibold)
        guard style.showsTapIndicator,
              let image = UIImage(systemName: "chevron.down", withConfiguration: config)?
              .withTintColor(style.textColor, renderingMode: .alwaysOriginal)
        else {
            return attributed
        }
        let attachment = NSTextAttachment()
        attachment.image = image
        attachment.bounds = CGRect(x: 0,
                                   y: (style.font.capHeight - image.size.height) / 2,
                                   width: image.size.width,
                                   height: image.size.height)
        attributed.append(NSAttributedString(string: " "))
        attributed.append(NSAttributedString(attachment: attachment))
        return attributed
    }

    public func updateStyle(_ newStyle: SwipeLabelStyle) {
        style = newStyle
        labels.forEach { label in
            label.textColor = style.textColor
            label.font = style.font
        }
        if state != nil {
            updateLabelText()
        }
    }

    private func animate(_ direction: AnimationDirection) {
        let multiplier: CGFloat = direction == .Forward ? -1 : 1
        let shiftRatio: CGFloat = 30 / 375
        let screenWidth = bounds.width

        secondLabel.alpha = 0
        secondLabel.frame = bounds
        secondLabel.frame.origin.x -= CGFloat(shiftRatio * screenWidth * 3) * multiplier

        UIView.animate(withDuration: 0.3, animations: {
            self.secondLabel.frame = self.bounds
            self.firstLabel.frame.origin.x += CGFloat(shiftRatio * screenWidth) * multiplier
            self.secondLabel.alpha = 1
            self.firstLabel.alpha = 0
        }, completion: { _ in
            self.labels = self.labels.reversed()
        })
    }

    override public func layoutSubviews() {
        for subview in subviews {
            subview.frame = bounds
        }
    }

    // MARK: DayViewStateUpdating

    public func move(from oldDate: Date, to newDate: Date) {
        guard newDate != oldDate
        else { return }
        labels.last!.attributedText = decorated(formattedDate(date: newDate))
    
        var direction: AnimationDirection = newDate > oldDate ? .Forward : .Backward
    
        let rightToLeft = UIView.userInterfaceLayoutDirection(for: semanticContentAttribute) == .rightToLeft
        if rightToLeft { direction.flip() }
    
        animate(direction)
    }

    private func formattedDate(date: Date) -> String {
        let timezone = calendar.timeZone
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .none
        formatter.timeZone = timezone
        formatter.locale = Locale(identifier: Locale.preferredLanguages[0])
        return formatter.string(from: date)
    }
}
