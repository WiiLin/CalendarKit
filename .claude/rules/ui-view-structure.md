# UI 元件結構規範

> **EZPretty iOS 五個 repo 共用正本，五份內容逐 byte 相同。** 改這份 = 五份一起改，見各 repo `CLAUDE.md` 的「共用規則檔」章節。
>
> 適用範圍：所有**新寫**的 UIKit view / view controller。既有 code 不強制回頭重寫，但**動到的檔案**要順手往這個方向收。

## 元件結構

- **可複用 UI 區塊 MUST 抽成獨立 `UIView` 子類**（self-contained）：view 自理**內部版面與外觀**，擺放位置（貼哪、滿不滿版）由持有它的 VC 決定，對外只暴露 callback（如 `var onXxxTapped: (() -> Void)?`）。**NEVER** 把整段版面 inline 在 VC 裡。

- **View 基礎宣告 MUST 用 closure `private let` 屬性**（`private let label: UILabel = { ... }()`），**NEVER** 在 `setupViews()` 裡 `let x = UILabel()` inline new 一堆；`setup` 只負責組裝（addSubview / stack / 注入需要實例值的內容）與約束。

- **背景色塊 MUST 用獨立 view**，**NEVER** 塞成某個 label 的 `backgroundColor`（如標題淺藍底 = 獨立 header view，標題 label 垂直置中放裡面）。

- **相關欄位群組 MUST 用 `UIStackView` + `setCustomSpacing(_:after:)`**，**NEVER** 一條條手 pin top 間距；固定高度區塊用 `heightAnchor`（或 SnapKit `make.height.equalTo(_:)`）+ 內容置中。

- **Stack view MUST 在宣告處直接把 views 填進 `UIStackView.vstack([...])` / `.hstack([...])`**；views 需引用同類別其他 view 屬性時，宣告改用 `lazy var`。**NEVER** 先建空 stack 再在 `setupViews()` / `buildLayout()` 裡逐條 `addArrangedSubview` 塞。
  > 例外：**執行期才知道數量**的清單（依 API 回傳筆數展開的列），MUST 用 `removeFullyAllArrangedSubviews()` 清空後再逐筆 `addArrangedSubview`；這種 stack 宣告時填空陣列。

- **Callback 回傳完整物件，NEVER 用 `button.tag` / index 傳身分**：多列 / 多條 UI 的每列 action 用 closure 捕獲該列的資料物件（或帶穩定 id 的 display model）回傳給持有者；tag / index 在列增刪、重排、cell 重用時會錯位，且讀碼時看不出指向誰。

- **NEVER 硬套不合語意的既有元件**（如「垂直選單浮層」不可拿來當水平 Cancel/Submit 雙鍵列）；要消除重複就另抽專用共用元件，而非扭曲現有元件職責。

## 顏色

- **NEVER 在 view 裡寫 inline 色彩字面值**（`UIColor(hexString: "#2CC69E")`、`UIColor(rgba:)`）。一律集中到該 repo 的色票檔（見下表），呼叫端只引用 token。
- 能對應既有 brand token（`mainGreen` / `black1` / `gray1`…）就**重用**，無對應才新建；同主題的 token 用 `// MARK:` 分區歸納。

## `UIStackView.vstack` / `.hstack` helper

| repo | helper 位置 | 色票檔 |
|---|---|---|
| `provider-ios` | `ezDesigner/ezDesigner/Swift/Extension/UIStackView+Extension.swift` | `Swift/Utils/AppColor.swift` |
| `ezhair-ios` | `ezHair/ezHair/Swift/Extension/UIStackView+Extensions.swift` | 專案色票 extension |
| `ezstore-ios` | 尚未建立 —— 首次要用時依下方 canonical 版本新增於 `ezStore/Extensions/` | 專案色票 extension |
| `ez-framework-ios` | 尚未建立 —— 首次要用時依下方 canonical 版本新增於 `Sources/EZCore/` | `EZCore` 色票 |
| `CalendarKit` | 尚未建立 —— 首次要用時依下方 canonical 版本新增於 `Source/` | `CalendarStyle` |

Canonical 版本（新增時逐字照抄，**NEVER** 各自發明簽名）：

```swift
extension UIStackView {
    static func vstack(
        _ views: [UIView] = [],
        spacing: CGFloat = 0,
        alignment: UIStackView.Alignment = .fill,
        distribution: UIStackView.Distribution = .fill
    ) -> UIStackView {
        let stackView = UIStackView(arrangedSubviews: views)
        stackView.axis = .vertical
        stackView.spacing = spacing
        stackView.alignment = alignment
        stackView.distribution = distribution
        return stackView
    }

    static func hstack(
        _ views: [UIView] = [],
        spacing: CGFloat = 0,
        alignment: UIStackView.Alignment = .fill,
        distribution: UIStackView.Distribution = .fill
    ) -> UIStackView {
        let stackView = UIStackView(arrangedSubviews: views)
        stackView.axis = .horizontal
        stackView.spacing = spacing
        stackView.alignment = alignment
        stackView.distribution = distribution
        return stackView
    }

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
```

## 範本

```swift
/// 一句話說明這個 view 是什麼、被誰持有
final class SomeBlockView: UIView {
    // MARK: - Subviews（一律 closure private let；需引用其他屬性才用 lazy var）

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textColor = .black1
        return label
    }()

    private let valueLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .gray1
        return label
    }()

    /// 背景色塊自成一個 view，不塞進 label 的 backgroundColor
    private let headerBackgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = .menuHighlightBackground
        view.layer.cornerRadius = 8
        return view
    }()

    private lazy var contentStackView = UIStackView.vstack([titleLabel, valueLabel], spacing: 4)

    // MARK: - Output

    /// 回傳完整物件，不用 tag / index
    var onTapped: ((SomeItem) -> Void)?

    private var item: SomeItem?

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Interface

    func configure(item: SomeItem) {
        self.item = item
        titleLabel.text = item.title
        valueLabel.text = item.value
    }
}

private extension SomeBlockView {
    /// 只負責組裝與約束，NEVER 在這裡 new view
    func setupViews() {
        addSubview(headerBackgroundView)
        addSubview(contentStackView)

        headerBackgroundView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        contentStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(12)
        }

        addGestureRecognizer(EZTapGestureRecognizer { [weak self] in
            guard let self, let item else { return }
            onTapped?(item)
        })
    }
}
```

## 自我檢查（改完 MUST 掃一遍）

- [ ] VC 裡沒有超過幾行的版面組裝 —— 有的話該抽成 view 子類
- [ ] view 檔案裡沒有 `let x = UI...()` 出現在 `setupViews()` / `setupUI()` 內
- [ ] 沒有先建空 stack 再 `addArrangedSubview`（執行期動態清單除外）
- [ ] 沒有 `sender.tag` / `indexPath.row` 當身分傳出去
- [ ] 沒有 inline 色彩字面值
