import UIKit

final class ReusePool<T: UIView> {
    private(set) var storage: [T]

    init() {
        storage = [T]()
    }

    func enqueue(views: [T]) {
        views.forEach { $0.frame = .zero }
        storage.append(contentsOf: views)
    }

    func dequeue() -> (object:T, isNew: Bool) {
        guard !storage.isEmpty else { return (T(), true) }
        return (storage.removeLast(), false)
    }
}
