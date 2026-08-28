import UIKit

public final class TimelineContainerController: UIViewController {
    /// Content Offset to be set once the view size has been calculated
    public var pendingContentOffset: CGPoint?
    public lazy var timeline = TimelineView()
    public lazy var container: TimelineContainer = {
        let view = TimelineContainer(timeline, container: self)
        view.addSubview(timeline)
        return view
    }()

    override public func viewDidLoad() {
        super.viewDidLoad()
        setupSubviews()
    }

    override public func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        container.contentSize = timeline.frame.size
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
    }
}
