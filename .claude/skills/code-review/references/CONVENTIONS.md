# 專案特定編碼慣例

本文件定義 EZPretty iOS 五 repo 接受的編碼慣例和權衡決策。審查時需要尊重這些慣例。

## 正本規則檔

以下規範已有正本，審查以正本為準、本檔不重複內容：

- **UI 元件結構**：`.claude/rules/ui-view-structure.md`（可複用區塊抽 `UIView` 子類、closure `private let` 宣告、`UIStackView.vstack/.hstack` 宣告處填滿、callback 回傳完整物件、顏色集中色票檔）
- **repo 專屬事實**（build 指令、目錄結構、gotcha）：各 repo 的 `CLAUDE.md`

## 編碼風格

### 註解
- ✅ 預設不寫註解；只在「為什麼」非顯而易見時補一行
- ❌ 「這行在做什麼」的翻譯型註解、對 reviewer 說話的註解（「修正 X」「新增 Y」）是 finding

### 抽象層級
- ✅ 不過度抽象、不為假想需求預留設計（YAGNI）
- ❌ 為了 testability 硬加 Protocol / 抽象層是 over design
- ✅ 只在需要時才遵從 protocol（Equatable、Identifiable、Hashable）

### 內部信任邊界
- ✅ 不為「不可能發生」的情境寫防呆 / fallback / null check
- ⚠️ 例外：跨 Obj-C 橋接、跨 process（web payload）、跨網路的輸入**不是**內部信任邊界，該驗的要驗
- ❌ 缺值時塞預設值矇混（如紙寬未設定塞預設寬度）——該擋下就明確丟錯誤

### 既有 code 的處理
- ✅ 既有 code 不強制回頭重寫；**動到的檔案**順手清理同檔顯而易見的規範違規
- ✅ 修 bug 時在 `.m` 順手小改可接受；在 `.m` 長全新邏輯不可接受（新程式寫 Swift）

### 錯誤處理
- ✅ 對使用者無影響的錯誤：靜默處理 + debug log
- ⚠️ 影響使用者體驗的錯誤：必須處理並顯示訊息

### TODO 標記
- ✅ 可留下 TODO 供後續實作；審查時尊重 TODO，不強制當下完成
- ⚠️ 審查時：確認 TODO 是否合理、是否有追蹤票號（Redmine `#id`）

## 版本控制慣例

- commit message prefix：`[feat][#<Redmine id>]` / `[fix][#<id>]` / `[v47.3(7)]`（release 合併）
- feature 分支以 `git merge --no-ff` 合進 `release/vX.Y`，commit 歷史完整保留——commit 拆分品質是審查項目（一個 commit 一個關注點）
- 有 `.swiftformat` / pre-commit 的 repo，格式問題交給工具，審查不糾纏純格式

## 接受的模式清單

審查時，以下模式是**明確接受**的，不應該標記為問題：

- ✅ **適度重複優先於過早抽象**（可讀性 > DRY）
- ✅ **短函數的行為局部性**（<= 20 行不強制關注點分離）
- ✅ **靜默錯誤 + debug log**（對使用者無影響）
- ✅ **TODO 標記**（明確標記的未來工作）
- ✅ **YAGNI 的型別設計**
- ✅ **遺留 GCD / closure 慣例**（不要求重寫成 Swift Concurrency）
- ✅ **Obj-C 舊碼維持原樣**（未動到的檔案）

## 權衡決策

### 可讀性 vs. 抽象
**選擇：優先可讀性**——接受適度重複，而非過早抽象；偏好行為局部性

### 完整性 vs. 實用性
**選擇：優先實用性**——接受靜默錯誤（非關鍵路徑）；使用 TODO 延後次要功能；專注主要使用者流程

### 類型安全 vs. 靈活性
**選擇：平衡**——需要時才遵從 protocol；核心資料模型要求類型安全；不濫用 force unwrap

### 測試覆蓋 vs. 開發速度
**選擇：分層**——framework（ez-framework-ios）的純邏輯要求測試覆蓋；App repo 不強制

## 總結

專案的實用主義態度：
- **KISS**：保持簡單
- **YAGNI**：避免過度設計
- **DRY**：但不要為了 DRY 而過早抽象；跨 App 的重複例外——那該進 framework
- **實用優先**：專注於真正重要的事情
