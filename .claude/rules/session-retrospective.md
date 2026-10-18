# Session Retrospective —— 經驗回寫協議

> **EZPretty iOS 五個 repo 共用正本，五份內容逐 byte 相同。** 改這份 = 五份一起改，見各 repo `CLAUDE.md` 的「共用規則檔」章節。
>
> 核心原則：**這次踩到的坑若沒回寫進指引，下次會用不同面貌再踩一次。**（`ai-core-rules.md` M6）
> 本專案群**不使用 memory 系統**（全域偏好）：通則只回寫 repo 內的 `CLAUDE.md`／`.claude/rules/`／`.claude/skills/`；進度交接（已完成／進行中／待續／未 push 的分支）只寫在最後一則回覆。

## 執行時機（MUST）

任務完成後（feature／bugfix 皆是），在產出最終報告的同時執行——NEVER 拖到 session 結束才想（那時 context 可能已壓縮）。小修／瑣碎一句話判定「無可回寫」即可，但 MUST 明說，NEVER 靜默跳過。

## Step 1 —— 盤點本次學到什麼

逐題回答（有就記下，沒有就明確說沒有）：

1. 這次的根因，是不是某個「下次還會遇到」的模式？
2. 有沒有走過彎路／一開始判斷錯方向？為什麼？
3. 有沒有發現既有指引（CLAUDE.md／rules／skill）寫錯、過時、或漏了一步？
4. 有沒有「照著文件做卻失敗」的情況？
5. 有沒有某個既有元件／helper 本來就該用但沒人知道它存在？
6. 這次用到的 build／test／工具指令，有沒有跟文件寫的不一樣？

## Step 2 —— 篩選（NEVER 什麼都寫）

**只有「下次遇到同型任務會再用到」的才寫。**

| 該寫 | NEVER 寫 |
|---|---|
| 可複用的判斷準則、陷阱模式 | 這次任務的一次性細節 |
| 文件與現實的落差 | 個別票的流水帳（那是 commit message 的事） |
| 反覆出現第 2 次以上的問題 | 只發生一次且原因明確偶然的事 |
| 「照文件做卻失敗」的所有情況 | 已經寫在指引裡的東西（重複只會稀釋重點） |

文件膨脹本身就是傷害——每輪載入的規則檔塞滿一次性細節，鐵律會被淹沒：

- **MUST** 新增規則時優先**併入既有條目**（改寫、加半句、加一格），NEVER 平行加新條——平行條目是規則檔的「平行實作」。
- **MUST** 案例敘事只留「一行 tell + 處置」；超過 3 行的事故經過寫進 commit message 或 Redmine 票，規則檔不留故事。**單一 bullet > 600 字元 → 砍到只剩 tell**；回寫前後 `wc -c` 比一次，+5% 以上要在 commit message 說明。
- **MUST** 回寫前先問「這條規則若對整個 codebase 套用，會多出多少程式碼？」——答案 >0 且不是原則性的 → 它是補丁不是通則，改寫成「為什麼會走到需要這個補丁」的設計原則再回寫。
- 去重只授權消滅「份數」，不授權消滅「深度」：重複的兩份留資訊最完整的那份；把內容從每輪載入層搬到按需查閱層是可見度降級，MUST 明示徵求同意。

## Step 3 —— 路由：學到什麼 → 寫進哪裡

| 學到的東西 | 寫進 |
|---|---|
| 可重複套用的通則、新的行為鐵律 | `.claude/rules/ai-core-rules.md`（五 repo 同步） |
| 除錯流程的細節／門檻／靜默失敗新形狀 | `.claude/rules/evidence-driven-bugfix.md` |
| UIKit 元件結構規範 | `.claude/rules/ui-view-structure.md` |
| 送後端的欄位來源、驗證方式 | `.claude/rules/api-field-contract.md` |
| 某個 repo 才有的 build／test／工具事實、gotcha、接線注意 | 該 repo 的 `CLAUDE.md`（專案專屬，NEVER 塞進共用 rules） |
| 跨 repo 都適用的 review 判準、修法形狀 | `.claude/skills/code-review/`（SKILL.md 或 references） |
| 某個 skill 少了一步／checklist 有洞 | 該 `.claude/skills/<name>/SKILL.md` |
| 使用者個人偏好 | `~/.claude/CLAUDE.md`（由使用者自己維護，AI 不寫） |

選擇原則：「每次任務都適用」→ `ai-core-rules.md`（只放鐵律）；「特定情境才適用」→ 對應 rules／skill；「只有這個 repo」→ 該 repo `CLAUDE.md`。
改到共用檔 → MUST 五 repo 同步＋checksum（各 repo `CLAUDE.md` 同步鐵律）。

## Step 4 —— 修正文件落差（MUST，不能只記錄）

- 發現指引寫錯／過時 → **當場修正**，並記下修在哪個 repo／branch——未 commit 或未 merge 的修正對其他 checkout 等於不存在；回寫前 `git log --all -S'<該段文字>'` 確認別條 branch 沒改過同一段。
- NEVER 只在報告寫「文件應同步更正」卻不動手。
- 🔴 只要本次動到（或引用到）任何 `CLAUDE.md`／`.claude/rules/*.md`／`SKILL.md`，MUST 把該檔內出現的**工具名、CLI 指令、檔案路徑、scheme／device 名稱**逐一與當前環境核對（路徑用 `ls`、指令用 `--help` 或實跑），NEVER 假設「原本寫在裡面的就是對的」——指引檔沒有編譯器、lint、CI 會驗證它，錯誤可以存活好幾個月。
- 🔴 指令配方 MUST 在同一 session 實跑一次到結果再落地，實跑證據（日期、輸出摘要）寫在配方旁——只核對「存在」抓不到「邏輯錯」。
- 🔴 判斷「指引缺少 X」MUST 在目標 base branch 上 grep 實際檔案，NEVER 以 system prompt 載入的快照為準——快照是開場那條 branch 的版本。
- 🔴 本輪**新寫下的規則，第一個適用對象是催生它的這次改動**：同輪回頭套用到本次改動並把結果寫進交付物再宣告完成。
- 兩條規則對同一動作互相禁止時，讀各自**寫明的原因**判斷哪條真的適用於本案，NEVER 挑「比較強的 NEVER」或發明兩邊都不滿足的變通，並把例外與理由寫進 commit message。
- 修正超出授權範圍（⛔ 級別）→ 明確標示「需負責人確認」並列出具體待改內容。

## Step 5 —— 回報（MUST）

最後一則回覆列出：

```
### Session Retrospective
- **學到的通則**：[條列，或「無新通則」]
- **回寫檔案**：
  - `path/to/file` — [寫了什麼]（已同步五 repo：是／否）
- **發現的文件落差**：[已修正／需確認，或「無」]
- **未回寫的原因**：[若判定無可回寫，說明理由]
```

如實回報，NEVER 為了看起來有做而硬湊條目。
