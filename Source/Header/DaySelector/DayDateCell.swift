import UIKit

public final class DayDateCell: UIView, DaySelectorItemProtocol {
    private let dateLabel = DateLabel()
    private let dayLabel = UILabel()
    private let stackView = UIStackView()

    public var date = Date() {
        didSet {
            dateLabel.date = date
            updateState()
        }
    }

    public var calendar = Calendar.autoupdatingCurrent {
        didSet {
            dateLabel.calendar = calendar
            updateState()
        }
    }

    public var selected: Bool {
        get {
            return dateLabel.selected
        }
        set(value) {
            dateLabel.selected = value
            stackView.spacing = value ? 5 : 3
        }
    }

    var style = DaySelectorStyle()

    override public var intrinsicContentSize: CGSize {
        return CGSize(width: 75, height: 35)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configure()
    }

    private func configure() {
        clipsToBounds = true
        
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = 3
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        stackView.addArrangedSubview(dayLabel)
        stackView.addArrangedSubview(dateLabel)
        addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: centerYAnchor),
            
            dateLabel.widthAnchor.constraint(equalToConstant: 30),
            dateLabel.heightAnchor.constraint(equalToConstant: 30)
        ])
    }

    public func updateStyle(_ newStyle: DaySelectorStyle) {
        style = newStyle
        dateLabel.updateStyle(newStyle)
        updateState()
    }

    private func updateState() {
        let isWeekend = isAWeekend(date: date)
        dayLabel.font = style.weekdayFont
        dayLabel.textColor = isWeekend ? style.weekendTextColor : style.inactiveTextColor
        dateLabel.updateState()
        updateDayLabel()
        setNeedsLayout()
    }

    private func updateDayLabel() {
        let daySymbols = calendar.shortWeekdaySymbols
        let weekendMask = [true] + [Bool](repeating: false, count: 5) + [true]
        var weekDays = Array(zip(daySymbols, weekendMask))
        weekDays.shift(calendar.firstWeekday - 1)
        let weekDay = component(component: .weekday, from: date)
        dayLabel.text = daySymbols[weekDay - 1]
    }

    private func component(component: Calendar.Component, from date: Date) -> Int {
        return calendar.component(component, from: date)
    }

    private func isAWeekend(date: Date) -> Bool {
        let weekday = component(component: .weekday, from: date)
        if weekday == 7 || weekday == 1 {
            return true
        }
        return false
    }

    override public func layoutSubviews() {
        super.layoutSubviews()
        // Auto Layout handles positioning now
    }

    override public func tintColorDidChange() {
        updateState()
    }
}
