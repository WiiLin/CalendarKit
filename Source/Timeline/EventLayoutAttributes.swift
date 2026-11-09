import Foundation
import UIKit

public final class EventLayoutAttributes {
    public let descriptor: EventDescriptor
    public var frame = CGRect.zero
    /// 同時段並排時這一筆落在第幾欄、整組共幾欄。
    /// layout 靠它分辨某一邊是貼著群組欄邊界（用 padding）還是貼著另一筆事件（用 eventGap）
    public var columnIndex = 0
    public var columnCount = 1
    /// 上／下緣落在什麼東西上（刻度線／另一張卡／空白），由 TimelineView 算完 frame 後填入，
    /// 決定那一邊用 eventVerticalPadding 還是 eventGap 的一半
    public var topEdge = VerticalEdge.blank
    public var bottomEdge = VerticalEdge.blank

    public init(_ descriptor: EventDescriptor) {
        self.descriptor = descriptor
    }
}
