---
name: <skill_name>
description: <一句話描述此 skill 解決什麼問題、何時使用、常見觸發詞或指令>
user-invocable: true
---

# <Skill Title>

> 使用方式：複製本模板到 `.claude/skills/<skill-name>/SKILL.md`，將所有 `<...>` 佔位符替換為實際內容。
>
> 原則：先說清楚「角色 / 目標 / 邊界 / 輸出 / 何時停止」，再補 workflow 細節。
>
> **五 repo 共用的 skill**（code-review / tidy-commits / commit-message）規則本體 MUST 逐 byte 相同，專案專屬段落（gate 指令、路徑）各自保留；見各 repo `CLAUDE.md`「共用規則檔」。

## 7 段式提示契約

1. **角色（Role）**：你是 <此 skill 扮演的角色>。
2. **人設（Personality）**：<語氣、協作方式、回覆風格、是否結論先行、使用語言（繁體中文）>。
3. **目標（Goal）**：<這個 skill 最終要達成的成果>。
4. **成功標準（Success）**：<怎樣算完成得好；可驗證、可檢查、可交付>。
5. **約束（Constraints）**：<不能做什麼、只能做什麼、邊界在哪裡>。
6. **輸出（Output）**：<最後要產出什麼格式、什麼檔案、什麼摘要>。
7. **停止規則（Stop Rules）**：<遇到哪些情況必須停止、升級、標註不確定或等待確認>。

## 目的

說明此 skill 的任務範圍、主要價值，以及它和其他 skill / rule 的關係。

範例：
- 將 <某工作流程> 轉成可直接執行的技能指引
- 僅適用於 <repo / language / domain>
- 若屬於 <另一類任務>，應改用 <其他 skill>

## 啟用時機

- 使用者要求 <任務類型 1>
- 使用者要求 <任務類型 2>
- 使用者提到 <關鍵字 / 票號 / 指令>
- 使用者輸入 `/<skill-command>`

## 強制規則（MUST / NEVER）

- **MUST** <開始前必讀哪些規範 / 文件>
- **MUST** <遵守哪些流程或驗證>
- **MUST** <語言、路徑、目錄、命名規則>
- **NEVER** <不能跳過的步驟>
- **NEVER** <不能擴大範圍的情況>
- **NEVER** <不能碰的目錄 / 設定 / 類型>

> 若此 skill 牽涉 iOS production code，請對齊：各 repo `CLAUDE.md`、`.claude/rules/ai-core-rules.md`、`.claude/rules/*.md`。

## 必讀檔案（依序）

1. `<核心規範檔 1>` — <用途>
2. `<核心規範檔 2>` — <用途>
3. `<相關實作 / 既有輸出 / 測試>` — <用途>

> 只列真正必要的檔案，避免 skill 一開始就過度讀取。

## 輸出位置與命名

- **目錄**：`<output-directory>`（不產檔的 skill 刪掉本節）
- **檔名格式**：`<filename-pattern>`
- **內容語言**：繁體中文

## 參數 / 觸發 metadata（選填）

**觸發方式：**
1. 關鍵字：`<keyword-1>`、`<keyword-2>`
2. 手動指令：`/<skill-command> <args>`

**參數：**
- `<param_1>`（必要 / 選填）：<說明>

## 工作流程

依任務類型拆成可執行步驟。若是多分支流程，請明確分支條件。

### Step 0 — Init / Intake
- <讀取必要上下文>
- <確認輸入是否完整>

### Step 1 — Analysis
- <如何定位檔案 / 比對規格 / 搜集證據>

### Step 2 — Main Execution
- <核心工作流程>

### Step 3 — Verification
- <format / 針對性單測 / 影響範圍掃描 / checklist>
- <何時視為可交付；沒驗證的要明說>

### Step 4 — Final Report / Handoff
- <完成摘要要包含哪些內容>
- <是否要回寫 rules / skill / CLAUDE.md（Session Retrospective）>

## 檢查重點 / 領域規則（依 skill 類型增補；不適用就整段刪）

### 1. 功能 / 規格面
### 2. 技術面
### 3. 測試面

## 輸出格式規範

- 結論先行
- checklist 呈現
- 每個 `❌` 必須附原因 + 建議 + 影響範圍

### 完成摘要範例

```md
✅ <任務狀態>

- 範圍：<scope>
- 主要產出：<artifact>
- 驗證結果：<verification result；未驗證的明說>
- 風險 / 待確認：<risk or blockers>
```

## 失敗處理 / 升級條件

- `<錯誤類型 1>` → <最多重試幾次 / 如何回報>
- `<需要人工確認的情況>` → <如何標記>
- 同一假設連續兩次失敗 → 停下，輸出假設清單與已排除項

## 完成前檢查清單

- [ ] 已替換所有 `<...>` 佔位符
- [ ] `name` 與 `description` 已對應實際 skill
- [ ] 已填寫 7 段式提示契約
- [ ] 已寫清楚啟用時機與停止規則
- [ ] 已列出真正必要的必讀檔案
- [ ] 已補上 workflow 與驗證方式
- [ ] 已納入 repo / domain 專屬限制
- [ ] 已移除不適用的空章節
- [ ] 檔內寫死的工具名 / 指令 / 路徑已在當前環境核對過（`session-retrospective.md` Step 4）
