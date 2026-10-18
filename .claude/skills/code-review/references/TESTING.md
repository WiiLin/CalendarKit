# 測試審查慣例

> 本專案群實況：單元測試只在 **`ez-framework-ios`**（XCTest，`Tests/EZPrinterKitTests/`，`import` 或 `@testable import` 各 library module：`EZCore` / `EZThermalPrinter` / `EZLabelPrinter` / `EZPrinterSettings`）。App repo（provider / ezstore / ezhair）測試基礎薄弱，**不要求**補單測；CalendarKit 無測試套件。本檔只列**審查時**要問的問題。
>
> 2026-10-18 核對：`Tests/EZPrinterKitTests/` 25 檔全部 `import XCTest`，0 檔 `import Testing`——審查時 NEVER 要求改寫成 Swift Testing，新測試沿用鄰檔框架。

## 測試品質三問（重質不重量）

- **這條測試保護誰？** 每條測試 MUST 能說出「未來哪一種改動會讓它紅」；說不出來 → 建議刪除，不是建議補更多。
- **拿掉 production 那行會紅嗎？** 修復／新增邏輯至少一條測試從 production 入口驅動（wiring），純函式測試不算（`evidence-driven-bugfix.md` B9）。
- **斷言量對對象了嗎？** 量測失效時預設值會不會讓斷言恆綠（`ai-core-rules.md` N15）；版型／raster 的斷言要量到輸出 bytes 或 image，不是量中間 model。

## 審查測試程式碼的檢查項目

### 1. 位置與框架
- [ ] 檔案在 `Tests/EZPrinterKitTests/`
- [ ] `import XCTest` + 鄰檔同款的 module import（NEVER 新引入 Swift Testing 或第三方斷言庫）

### 2. 命名與結構
- [ ] 測試名描述行為與預期（既有慣例：`testMissingFieldsFallBackToDefaults` 這種「情境＋預期」命名）；bugfix 測試名能對到症狀
- [ ] 檔頭註解寫明這組測試守的是哪個票號／哪條規則
- [ ] Given / When / Then 三段結構

### 3. 隔離與可重複
- [ ] 不依賴網路、系統時間、真實印表機、真實後端
- [ ] `tearDown` 還原 UserDefaults / 全域單例 / 快取（如 eprinter 快取）；除錯開關在 `setUp` 明確釘死期望值
- [ ] 不驅動會離開本程序的動作（開外部 URL、真實連線）

### 4. 依賴與觀測點
- [ ] 外部依賴（印表機 SDK / 網路 Session / 儲存 / 時間）的 stub 透過依賴邊界 protocol 或既有可指派屬性注入（`ai-core-rules.md` POP 判準）
- [ ] 沒有為了測試在 production 新增 `testOnly_` / `#if DEBUG` hook / mockData → must-fix；觀測用測試端 spy 子類 override
- [ ] 非同步結果用 expectation / run-loop 輪詢等到，不直接斷言

### 5. 測試覆蓋（質 > 量）
- [ ] 每條測試是否寫得出它保護的那一種未來改動？寫不出的是否建議刪除？
- [ ] 核心行為是否有從 production 入口驅動的 wiring test？
- [ ] 會真的發生的失敗 / 邊界 / 錯誤處理是否有測？（不是「每個分支都要有」）
- [ ] 是否有為了湊數而存在、拿掉 production 也不會紅的測試？

### 6. 真實資料對照
- [ ] 配對型邏輯（API 清單 ↔ 本地清單、依筆數展開）的 fixture 是否來自一份**真實 API response**，而不是作者手寫的理想形狀？
- [ ] ESC/POS / TSPL / EZPL 指令輸出的 golden bytes 是否標明在哪台**真實機型**驗過？

## 常見錯誤

- ❌ 測試直接呼叫本次新增的 helper（測法官）→ ✅ 從 production 入口驅動（測法庭）
- ❌ `XCTAssertLessThanOrEqual(x?.height ?? 0, limit)`（量不到就恆綠）→ ✅ 先 `XCTUnwrap` 讓「取不到」自己紅
- ❌ 順序斷言單獨存在（被歷史事件假綠）→ ✅ 加 count delta 雙保險
- ❌ sabotage 後仍綠就推論「修復多餘」→ ✅ 先懷疑量錯對象 / 量錯時機 / 破壞沒落地（`evidence-driven-bugfix.md` Step 5）
- ❌ 把 App 端「沒有測試」列成 Blocker → ✅ 列為範圍外建議；App 端的證據是實機／模擬器驗證
