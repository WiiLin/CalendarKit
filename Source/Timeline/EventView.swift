import UIKit

open class EventView: UIView {
    public var descriptor: EventDescriptor?
    public var color = SystemColors.label

    public lazy var label: UILabel = {
        let label = UILabel()
        label.numberOfLines = 2
        label.backgroundColor = .clear
        label.isUserInteractionEnabled = false
        return label
    }()

    // Replace UIImageView with a CALayer
    public lazy var imageLayer: CALayer = {
        let layer = CALayer()
        return layer
    }()

    public lazy var eventResizeHandles = [EventResizeHandleView(), EventResizeHandleView()]

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
        addSubview(label)
        layer.addSublayer(imageLayer)

        for (idx, handle) in eventResizeHandles.enumerated() {
            handle.tag = idx
            addSubview(handle)
        }
        layer.cornerRadius = 2
        clipsToBounds = true
    }

    public func updateWithDescriptor(event: EventDescriptor) {
        if let attributedText = event.attributedText {
            label.attributedText = attributedText
        } else {
            label.text = event.text
            label.textColor = event.textColor
            label.font = event.font
        }
        descriptor = event
        backgroundColor = event.backgroundColor
        layer.borderColor = event.borderColor.cgColor
        layer.borderWidth = event.borderWidth
        color = event.color
        eventResizeHandles.forEach {
            $0.borderColor = event.color
            $0.isHidden = event.editedEvent == nil
        }
        drawsShadow = event.editedEvent != nil

        // Set image to the layer's contents
        if let image = event.image {
            imageLayer.contents = image.cgImage
        } else {
            imageLayer.contents = nil
        }

        setNeedsDisplay()
        setNeedsLayout()
    }

    public func animateCreation() {
        transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        func scaleAnimation() {
            transform = .identity
        }
        UIView.animate(withDuration: 0.2,
                       delay: 0,
                       usingSpringWithDamping: 0.2,
                       initialSpringVelocity: 10,
                       options: [],
                       animations: scaleAnimation,
                       completion: nil)
    }

    override public func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        for resizeHandle in eventResizeHandles {
            if let subSubView = resizeHandle.hitTest(convert(point, to: resizeHandle), with: event) {
                return subSubView
            }
        }
        return super.hitTest(point, with: event)
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
        let x: CGFloat = leftToRight ? 0 : frame.width - 1
        let y: CGFloat = 0
        context.beginPath()
        context.move(to: CGPoint(x: x, y: y))
        context.addLine(to: CGPoint(x: x, y: bounds.height))
        context.strokePath()
        context.restoreGState()
    }

    private var drawsShadow = false

    override open func layoutSubviews() {
        super.layoutSubviews()
        let imageWidth = 20.0
        let padding = 3.0
        label.frame = CGRect(x: bounds.minX + padding,
                             y: bounds.minY,
                             width: bounds.width - padding - imageWidth - padding,
                             height: bounds.height)

        imageLayer.frame = CGRect(x: bounds.maxX - imageWidth - padding,
                                  y: bounds.minY + padding,
                                  width: imageWidth,
                                  height: imageWidth)

        if frame.minY < 0 {
            var textFrame = label.frame
            textFrame.origin.y = frame.minY * -1
            textFrame.size.height += frame.minY
            label.frame = textFrame
        }

        let first = eventResizeHandles.first
        let last = eventResizeHandles.last
        let radius: CGFloat = 40
        let yPad: CGFloat = -radius / 2
        let width = bounds.width
        let height = bounds.height
        let size = CGSize(width: radius, height: radius)
        first?.frame = CGRect(origin: CGPoint(x: width - radius - layoutMargins.right, y: yPad),
                              size: size)
        last?.frame = CGRect(origin: CGPoint(x: layoutMargins.left, y: height - yPad - radius),
                             size: size)

        if drawsShadow {
            applySketchShadow(alpha: 0.13,
                              blur: 10)
        }
    }

    private func applySketchShadow(
        color: UIColor = .black,
        alpha: Float = 0.5,
        x: CGFloat = 0,
        y: CGFloat = 2,
        blur: CGFloat = 4,
        spread: CGFloat = 0
    ) {
        layer.shadowColor = UIColor.red.cgColor
        layer.shadowOpacity = alpha
        layer.shadowOffset = CGSize(width: x, height: y)
        layer.shadowRadius = blur / 2.0
        if spread == 0 {
            layer.shadowPath = nil
        } else {
            let dx = -spread
            let rect = bounds.insetBy(dx: dx, dy: dx)
            layer.shadowPath = UIBezierPath(rect: rect).cgPath
        }
    }
}
