import UIKit

open class EventView: UIView {
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
    
    public lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        return imageView
    }()

    /// Resize Handle views showing up when editing the event.
    /// The top handle has a tag of `0` and the bottom has a tag of `1`
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
        addSubview(textView)
        addSubview(imageView)
    
        for (idx, handle) in eventResizeHandles.enumerated() {
            handle.tag = idx
            addSubview(handle)
        }
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
        imageView.image = event.image
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

    /**
     Custom implementation of the hitTest method is needed for the tap gesture recognizers
     located in the ResizeHandleView to work.
     Since the ResizeHandleView could be outside of the EventView's bounds, the touches to the ResizeHandleView
     are ignored.
     In the custom implementation the method is recursively invoked for all of the subviews,
     regardless of their position in relation to the Timeline's bounds.
     */
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
        let x: CGFloat = leftToRight ? 0 : frame.width - 1 // 1 is the line width
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
        textView.frame = CGRect(x: bounds.minX + padding,
                                y: bounds.minY,
                                width: bounds.width - padding - imageWidth - padding,
                                height: bounds.height)
        imageView.frame = CGRect(x: bounds.maxX - imageWidth - padding,
                                 y: bounds.minY + padding,
                                 width: imageWidth,
                                 height: imageWidth)
        
        if frame.minY < 0 {
            var textFrame = textView.frame
            textFrame.origin.y = frame.minY * -1
            textFrame.size.height += frame.minY
            textView.frame = textFrame
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
