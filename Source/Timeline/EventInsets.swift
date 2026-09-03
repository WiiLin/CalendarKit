import CoreGraphics

/// 事件卡片相對於它的「時段矩形」四邊要內縮多少。
///
/// 抽成純值型別（不碰 UIKit）才驗證得起來 —— 這段算術是總表版面唯一的來源，
/// 出錯的方式又多（下方有沒有卡／貼欄邊界／並排），靠肉眼看模擬器對不出來。
public struct EventInsets: Equatable {
    public let top: CGFloat
    public let bottom: CGFloat
    public let left: CGFloat
    public let right: CGFloat

    public init(top: CGFloat, bottom: CGFloat, left: CGFloat, right: CGFloat) {
        self.top = top
        self.bottom = bottom
        self.left = left
        self.right = right
    }
}

/// 卡片某一邊（上緣或下緣）落在什麼東西上，決定那一邊要內縮多少
public struct VerticalEdge: Equatable {
    /// 這一邊貼著同一欄的另一張卡
    public var touchesCard: Bool
    /// 這一邊落在有畫出來的刻度線上（ezStore 只有整點有線，半點沒有）
    public var onTickLine: Bool

    public init(touchesCard: Bool, onTickLine: Bool) {
        self.touchesCard = touchesCard
        self.onTickLine = onTickLine
    }

    public static let blank = VerticalEdge(touchesCard: false, onTickLine: false)
}

/// 算 `EventInsets` 的規則。
///
/// 「框架」是每一個小時格：上下是**畫出來的刻度線**，左右是群組欄的邊線。
/// event 離框架 `padding`，框架裡面 event 彼此 `gap`。
///
/// - 那一邊**落在刻度線上** → `verticalPadding`（不管有沒有貼著別的卡，線優先）
/// - 那一邊**貼著另一張卡、而且不在刻度線上** → `gap / 2`，兩張湊起來剛好是 `gap`
/// - 那一邊**是空白** → `verticalPadding`
///
/// 30 分模式、padding 12、gap 5 的實際畫面（★ 是整點刻度線）：
///
/// ```
/// ★10:00 ─12─ [10:00-11:30] ─5─ [11:30-12:00] ─12─ ★12:00 ─12─ [12:00-12:30] ─5─ [12:30-13:00] ─12─ ★13:00
/// ```
///
/// 同一個小時格裡的卡只隔 5，跨越刻度線時線的兩側各留 12。
/// 水平：貼群組欄左右邊線用 `horizontalPadding`，同時段並排的那一邊各出一半 `gap`。
/// `gap` 沒設（<= 0）時整個退回 padding。
public struct EventInsetRule: Equatable {
    public let verticalPadding: CGFloat
    public let horizontalPadding: CGFloat
    public let gap: CGFloat

    public init(verticalPadding: CGFloat, horizontalPadding: CGFloat, gap: CGFloat) {
        self.verticalPadding = verticalPadding
        self.horizontalPadding = horizontalPadding
        self.gap = gap
    }

    var halfGapVertical: CGFloat { gap > 0 ? gap / 2 : verticalPadding }
    var halfGapHorizontal: CGFloat { gap > 0 ? gap / 2 : horizontalPadding }

    func inset(for edge: VerticalEdge) -> CGFloat {
        return edge.touchesCard && !edge.onTickLine ? halfGapVertical : verticalPadding
    }

    /// - Parameters:
    ///   - top: 上緣落在什麼上
    ///   - bottom: 下緣落在什麼上
    ///   - columnIndex: 同時段並排時落在第幾欄（0 起算）
    ///   - columnCount: 那一組並排總共幾欄
    ///   - isRightToLeft: RTL 時第一欄在畫面右側，左右要對調
    public func insets(top: VerticalEdge,
                       bottom: VerticalEdge,
                       columnIndex: Int,
                       columnCount: Int,
                       isRightToLeft: Bool = false) -> EventInsets
    {
        let firstColumn = columnIndex == 0 ? horizontalPadding : halfGapHorizontal
        let lastColumn = columnIndex == columnCount - 1 ? horizontalPadding : halfGapHorizontal

        return EventInsets(top: inset(for: top),
                           bottom: inset(for: bottom),
                           left: isRightToLeft ? lastColumn : firstColumn,
                           right: isRightToLeft ? firstColumn : lastColumn)
    }
}
