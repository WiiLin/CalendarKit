import UIKit

public final class TimelineContainerController: UIViewController {
    /// Content Offset to be set once the view size has been calculated
    public var pendingContentOffset: CGPoint?

    public private(set) lazy var timeline = TimelineView()
    public private(set) lazy var container: TimelineContainer = {
        let view = TimelineContainer(timeline)
        view.addSubview(timeline)
        return view
    }()

    override public func loadView() {
        view = container
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
