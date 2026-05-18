import UIKit

open class EventView: UIView {
    static let imageSize = CGSize(width: 20, height: 20)
    public var descriptor: EventDescriptor?
    public var color = SystemColors.label

    public var contentHeight: CGFloat {
        return textView.frame.height
    }

    public lazy var textView: UITextView = {
        let view = UITextView()
        view.isUserInteractionEnabled = false
        view.backgroundColor = .clear
        view.isScrollEnabled = false
        view.textContainerInset.top = 1
        view.textContainerInset.left = 0
        return view
    }()
    
    lazy var imagesStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 3
        return stackView
    }()

    public lazy var bottomRightLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .right
        return label
    }()
    

    override public init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configure()
    }

    private func configure() {
        clipsToBounds = false
        color = tintColor
        addSubview(textView)
        addSubview(imagesStackView)
        addSubview(bottomRightLabel)


        imagesStackView.translatesAutoresizingMaskIntoConstraints = false
        bottomRightLabel.translatesAutoresizingMaskIntoConstraints = false
        let padding: CGFloat = 3
        NSLayoutConstraint.activate([
            imagesStackView.topAnchor.constraint(equalTo: topAnchor, constant: padding),
            imagesStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -padding),
            bottomRightLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -padding),
            bottomRightLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -padding)
        ])
        layer.cornerRadius = 2
        clipsToBounds = true
  
    }

    public func updateWithDescriptor(event: EventDescriptor) {
        if let attributedText = event.attributedText {
            textView.attributedText = attributedText
        } else {
            textView.text = event.text
            textView.textColor = event.textColor
            textView.font = event.font
        }
        if let lineBreakMode = event.lineBreakMode {
            textView.textContainer.lineBreakMode = lineBreakMode
        }
        bottomRightLabel.text = event.bottomRightText
        bottomRightLabel.font = event.font
        bottomRightLabel.textColor = event.textColor
        descriptor = event
        backgroundColor = event.backgroundColor
        layer.borderColor = event.borderColor.cgColor
        layer.borderWidth = event.borderWidth
        color = event.color
        imagesStackView.removeAllArrangedSubviews()
        let imageViews = event.images.map {
            let imageView = UIImageView(image: $0)
            imageView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                  imageView.widthAnchor.constraint(equalToConstant: EventView.imageSize.width),
                  imageView.heightAnchor.constraint(equalToConstant: EventView.imageSize.height)
              ])
            return imageView
        }
        imagesStackView.addArrangedSubviews(imageViews)
        setNeedsDisplay()
        setNeedsLayout()
    }

    override open func draw(_ rect: CGRect) {
        super.draw(rect)
        guard let context = UIGraphicsGetCurrentContext() else {
            return
        }
        context.interpolationQuality = .none
        context.saveGState()
        context.setStrokeColor(color.cgColor)
        context.setLineWidth(1)
        context.translateBy(x: 0, y: 0.5)
        let leftToRight = UIView.userInterfaceLayoutDirection(for: semanticContentAttribute) == .leftToRight
        let x: CGFloat = leftToRight ? 0 : frame.width - 1 // 1 is the line width
        let y: CGFloat = 0
        context.beginPath()
        context.move(to: CGPoint(x: x, y: y))
        context.addLine(to: CGPoint(x: x, y: bounds.height))
        context.strokePath()
        context.restoreGState()
    }

    override open func layoutSubviews() {
        super.layoutSubviews()
        let imageWidth = Self.imageSize.width
        let padding = 3.0
        let hasBottomText = !(bottomRightLabel.text?.isEmpty ?? true)
        let bottomReserved = hasBottomText ? bottomRightLabel.intrinsicContentSize.height + padding : 0
        textView.frame = CGRect(x: bounds.minX + padding,
                                y: bounds.minY,
                                width: bounds.width - padding - imageWidth - padding,
                                height: bounds.height - bottomReserved)

        if frame.minY < 0 {
            var textFrame = textView.frame
            textFrame.origin.y = frame.minY * -1
            textFrame.size.height += frame.minY
            textView.frame = textFrame
        }
    }
}


extension UIStackView {
    func addArrangedSubviews(_ views: [UIView]) {
        views.forEach { addArrangedSubview($0) }
    }

    func removeFully(view: UIView) {
        removeArrangedSubview(view)
        view.removeFromSuperview()
    }

    /// 移除所有子視圖
    func removeFullyAllArrangedSubviews() {
        for view in arrangedSubviews {
            removeFully(view: view)
        }
    }
}
