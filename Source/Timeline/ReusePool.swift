import UIKit

final class ReusePool {

    static let shared = ReusePool()

    private var storage: [EventView]

    init() {
        storage = [EventView]()
    }

    func enqueue(views: [EventView]) {
        views.forEach { $0.frame = .zero }
        storage.append(contentsOf: views)
    }

    func dequeue() -> EventView {
        guard !storage.isEmpty else { return EventView() }
        return storage.removeLast()
    }
}
