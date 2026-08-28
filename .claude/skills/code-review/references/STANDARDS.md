# iOS/Swift/Obj-C 審查標準

本文件定義 EZPretty iOS 五 repo 程式碼審查的詳細標準和檢查項目。

## 審查指南

### 審查結構

1. **技術觀察**（Technical Observations）
   - 識別當前採用的架構決策和模式
   - 評估這些決策的權衡和潛在風險

2. **問題識別**（Issues Identified）
   - 識別具體問題，清楚解釋為什麼它們是風險
   - 小心不要提供已經實作的建議
   - 提供具體、可行的解決方案，適時附上程式碼範例
   - 在相關程式碼行號標註問題

### 聚焦領域

- **程式碼結構**：SOLID 原則遵守；在 SoC（關注點分離）和 LoB（行為局部性）之間適當平衡
- **可測試性、可維護性和可擴展性**
- **UIKit 最佳實踐**（本專案群主體；App repo 為 Obj-C / Swift 混合）
  - 新寫 UIKit view / VC 的結構規範正本是 `.claude/rules/ui-view-structure.md`，以它為準，不在本檔重複
- **共用邏輯歸屬**：兩個店家 App 共用的列印邏輯一律在 `ez-framework-ios`；App 端出現「應屬共用」的邏輯是 finding
- **錯誤處理**：當對使用者體驗有重大影響時
- **記憶體管理**
- **並發性**：避免 race conditions 或 data race 風險
- **慣用的 Swift 最佳實踐**；Obj-C 舊碼以「動到才收」為原則，不要求整檔重寫

### 溝通方式

- **直接且誠實**：解釋每個問題背後的「為什麼」，專注於風險和權衡
- **提供具體範例**：指出問題時提供替代方案
- **優先順序**：按影響程度排序（關鍵架構缺陷 vs. 次要風格問題）
- **務實態度**：專注於「這段程式碼在什麼情況下會失敗」，而非價值判斷
- **使用繁體中文**：所有評論必須用繁體中文撰寫

## 審查項目

### 1. 程式碼品質

- **命名規範**：檢查變數、函數、類別命名是否清晰且符合 Swift / Obj-C 命名慣例
- **程式碼結構**：檢查函數長度、類別職責是否單一（Single Responsibility Principle）
- **可讀性**：檢查程式碼是否容易理解
- **重複程式碼**：識別可以重構的重複邏輯（含跨 provider-ios / ezstore-ios 的重複——該進 framework 的邏輯）

### 2. Swift 最佳實踐

- **型別安全**：檢查是否充分利用 Swift 的型別系統
- **Optional 處理**：檢查 optional unwrapping 是否安全（避免無理由的強制 unwrap）
- **Memory Management**：檢查 retain cycles、weak/unowned 使用是否正確
- **Error Handling**：檢查錯誤處理是否完善（try/catch, Result type）
- **Access Control**：檢查存取控制（private, fileprivate, internal, public）是否適當

### 3. Obj-C / Swift 混合專案特有

- **橋接邊界**：`@objc` 暴露給 Obj-C 的 Swift API，檢查 nullability 與 Obj-C 端呼叫慣例是否對得上
- **Nullability**：Obj-C header 缺 `NS_ASSUME_NONNULL` 區塊時，Swift 端拿到的是 `!` 隱式解包——跨橋接的 nil 假設要驗證，不要相信型別簽名
- **singleton 可為 nil**：`shareInstance()` 這類 Obj-C singleton 從 Swift 看是 optional，回 nil 的路徑必須有明確處理，不能吞掉（framework 等待佇列卡死是實際發生過的後果）
- **xib / storyboard 同步**：改 outlet / action 時檢查 xib 連線是否同步，斷線是 runtime crash
- **新程式歸屬**：App repo 的新程式一律寫 Swift（provider-ios 在 `Swift/` 目錄），在 `.m` 裡長新邏輯是 finding（修 bug 順手小改除外）

### 4. iOS 特定問題

- **UI 更新**：確保 UI 更新在主執行緒執行
- **生命週期**：檢查 ViewController 生命週期方法使用是否正確
- **資源管理**：檢查圖片、檔案等資源是否正確釋放
- **背景執行**：檢查背景任務處理是否正確
- **Deployment target**：各 repo 最低支援版本不同（以各 repo Podfile / Package.swift 為準），用新 API 時檢查 availability

### 5. 潛在 Bug

- **Nil 指標**：檢查可能的 nil reference（含跨 Obj-C 橋接的隱式解包）
- **陣列越界**：檢查陣列存取是否安全
- **Race Conditions**：檢查多執行緒可能的競態條件
- **邏輯錯誤**：檢查條件判斷、迴圈邏輯
- **Edge Cases**：識別未處理的邊界情況

### 6. 效能問題

- **不必要的計算**：識別可以快取或優化的運算
- **記憶體洩漏**：檢查可能的記憶體洩漏點
- **昂貴的操作**：識別在主執行緒的耗時操作
- **過度渲染**：檢查 UI 是否有不必要的重繪

### 7. 安全性

- **資料驗證**：檢查使用者輸入是否經過驗證
- **敏感資料**：檢查是否有硬編碼的密碼、API keys、token
- **網路安全**：檢查 HTTPS、證書驗證

## iOS 特定風險評估

當前實作可能在以下情況失敗：

### 邊界條件
- 空值、nil 值處理
- 極端值（空陣列、超大數值）
- 並發訪問共享資源

### 資源限制
- 記憶體壓力（大量圖片、資料）
- 網路故障（timeout、連線中斷）；印表機連線中斷 / 離線佇列
- 磁碟空間不足

### 生命週期事件
- App 進入背景
- 低記憶體警告
- App 被系統終止後恢復
- token 過期後的 API retry 路徑（framework 走自己的 Session 時，App 端 401 攔截攔不到它）

### 記憶體管理重點

- **Retain Cycles**：
  - 閉包中的 `[weak self]` 或 `[unowned self]`
  - Delegate 應該使用 `weak` 引用
  - 觀察者模式的記憶體管理

- **圖片記憶體**：
  - 大圖片的載入和快取策略
  - 列印點陣圖（raster）生成的記憶體峰值

### 並發安全檢查

- 本專案群大量遺留 GCD / closure 慣例，deployment target 也未必允許 Swift Concurrency。**NEVER** 要求把可運作的 GCD 程式碼重寫成 async/await / actor——那是範圍外建議
- 標記 race condition 前先確認：該類別是否已隔離在 main thread（UI 類別）、是否已有 serial queue / lock 保護
- 禁止的模式：
  - 讀寫無保護的共享變數
  - `DispatchQueue.async` 中直接修改類別屬性（除非已有同步保護）
  - 多個鎖的巢狀使用（死鎖風險）
- **UI 更新必須在主執行緒**：無例外；API callback 回來的執行緒不要假設，看實作

## UIKit 特定審查標準

### 1. ViewController 生命週期

**核心原則**：
- viewDidLoad：一次性初始化
- viewWillAppear/viewDidAppear：每次顯示執行
- viewWillDisappear/viewDidDisappear：停止運行中的任務

**常見錯誤**：
- ❌ viewDidLoad 中做耗時操作（阻塞主執行緒）
- ❌ viewDidLoad 中存取 view.frame（尚未 layout）
- ❌ viewDidLayoutSubviews 中重複執行昂貴操作（被多次呼叫）

**子 ViewController 管理**：
- 添加：`addChild` → `addSubview` → `didMove(toParent:)`
- 移除：`willMove(toParent: nil)` → `removeFromSuperview` → `removeFromParent`
- 風險：順序錯誤導致生命週期方法未呼叫、記憶體洩漏

### 2. UIKit 記憶體管理

**Delegate Pattern**：
- ✅ Protocol 繼承 `AnyObject`
- ✅ 屬性使用 `weak` 修飾符

**Closure**：
- ✅ 使用 `[weak self]` 避免 retain cycle
- ⚠️ `[unowned self]` 需確保生命週期（否則 crash）

**Timer**：
- ✅ 使用 block-based API + `[weak self]`
- ✅ 在 `deinit` 中 `invalidate()`
- ❌ target-selector API 強引用 target

**NotificationCenter**：
- ✅ 使用 block-based API + `[weak self]`
- ✅ 在 `deinit` 中移除 observer（iOS 9+ 的 selector API 例外）

### 3. Auto Layout 和約束

- ✅ 新程式用 SnapKit / `NSLayoutAnchor`（類型安全），依該檔既有慣例
- ✅ 純 code layout 設定 `translatesAutoresizingMaskIntoConstraints = false`
- ❌ Console 出現 "Unable to simultaneously satisfy constraints"
- ❌ 頻繁 activate/deactivate 觸發多次 layout

### 4. UITableView / UICollectionView

**Cell 重用**：
- ✅ 註冊 + `dequeueReusableCell(withIdentifier:for:)`
- ✅ 重置 cell 狀態（`cellForRowAt` 和 `prepareForReuse()`）
- ❌ 用 `tag` / index 傳身分（正本規則見 `ui-view-structure.md`：callback 回傳完整物件）

**效能優化**：
- ❌ 在 `cellForRowAt` 中做耗時操作（同步圖片載入、網路請求）
- ✅ 非同步載入 + placeholder + 檢查 cell 是否顯示

### 5. UIKit 執行緒安全

**禁止在背景執行緒**：
- ❌ 更新 UI 元素、存取 view 屬性
- ❌ 呼叫 `reloadData()`、`setNeedsLayout()`
- ❌ 添加或移除 subviews

## 測試（ez-framework-ios 為主）

- `ez-framework-ios` 有單元測試（Swift Testing 的 `@Test` / `#expect` 與 XCTest 並存）；framework 的新邏輯（版型計算、指令生成、raster 轉換這類純函數）應有測試覆蓋
- App repo 測試基礎薄弱，**不要求** App 端變更補單元測試——列為範圍外建議即可
- 新測試優先用 Swift Testing（`@Test` + `#expect`），測試名稱描述行為

## 拒絕的反模式

- **巨型 ViewControllers**：拒絕往裡面添加更多邏輯。要求先抽 view 子類 / 拆職責。
- **無理由的強制解包（`!`）**：除非可證明安全，否則拒絕。
- **字串型別程式碼**：例如通知名稱、UserDefaults key 散落字串。要求集中定義。
- **在 viewDidLoad 中做耗時操作**：阻塞主執行緒，影響使用者體驗。
- **忘記移除 Observer 或 invalidate Timer**：導致記憶體洩漏或 crash。
- **在背景執行緒更新 UI**：違反 UIKit 執行緒安全規則。
- **App 端長出應屬 framework 的共用邏輯**：兩個 App 各寫一份，日後必然分岔。
