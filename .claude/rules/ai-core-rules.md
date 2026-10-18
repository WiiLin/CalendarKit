# AI 助手核心規則

> **EZPretty iOS 五個 repo 共用正本，五份內容逐 byte 相同。** 改這份 = 五份一起改，見各 repo `CLAUDE.md` 的「共用規則檔」章節。
>
> 來源：Metropia iOS 根指引（v2.4）去專案化後移植；只留通則，案例敘事一律不帶。與全域偏好（`~/.claude/CLAUDE.md`）衝突時，讀各自寫明的原因，以真的適用於本案的那條為準。

## 行為鐵律（每條都有原因）

### NEVER

| # | 禁令 | 原因 |
|---|---|---|
| N1 | **NEVER** 未讀取檔案就編輯它 | 憑記憶或幻覺改，內容對不上。 |
| N2 | **NEVER** 編造不知道的資訊；存在多重解讀時 **NEVER** 默默選一個 | 不知道就說不知道，附上已確認與未確認的部分；多種解讀攤開選項再動手。 |
| N3 | **NEVER** 未跑靜態檢查就回報「完成」 | 寫入磁碟 ≠ 能編譯。本專案群：`swiftformat --lint` 自己改的檔；App 的編譯由使用者驗證（全域偏好），沒驗就明說「未驗證編譯」，NEVER 用「應該可以」帶過。 |
| N4 | **NEVER** 驗證失敗時粉飾結果 | 要的是準確的報告，不是防禦性的報告。 |
| N5 | **NEVER** 加沒被要求的功能 | 畫蛇添足是回歸風險的最大來源。 |
| N6 | **NEVER** 為不可能發生的情況做預防 | 三行重複好過一個過早的抽象。**比例原則**：為 1% 的 edge case 大改程式 → 改成註記／開 Redmine 票，不是接受那份大改。 |
| N7 | **NEVER** 未證明「不承重」就刪除／收攏既有邏輯 —— 證明了就放心刪 | 判準是證據不是感覺。**承重證明三件套**：① 窮舉該行為的其他觸發來源（API 回應／通知／生命週期 hook／web payload）；② 從分派點反查元件實際掛在哪幾條路徑，NEVER 信檔頭註解或函式名宣稱的涵蓋範圍；③ 拆帳：元件內每個公開成員標「本元件職責（隨之刪）」或「別人寄放的通用能力（搬家保留）」——刪除的單位是職責不是檔案。 |
| N8 | **NEVER** 隨意更動既有 API 簽名 | 下游呼叫者不可見。framework 的 public API 尤其：兩個 App 的 call site 不在你眼前。 |
| N9 | **NEVER** 把一次授權擴大為永久授權 | 授權只對當次有效。 |
| N10 | **NEVER** 引入不必要套件（Pod／SPM） | 每個新依賴都是維護負債；要引入須交代原因與替代方案。 |
| N11 | **NEVER** 沒有最小重現／failing test 就直接改 code 修 bug | 「我大概知道怎麼修」修到的是症狀。見 `evidence-driven-bugfix.md`。 |
| N12 | **NEVER** 用 `git stash` 或 `git checkout -- <file>` 暫存／還原修改 | stash 讓變更脫離 branch 追蹤；`checkout --` 清掉該檔全部未提交改動。要暫時還原用 patch（`evidence-driven-bugfix.md` 的 sabotage 鐵律）。 |
| N13 | **NEVER** 自驗證無誤前就 commit；合併前 **MUST** 對自己的 diff 跑過 `code-review` skill | 測試證明「改的東西如預期」，review 證明「沒改到不該改的」，不可互相替代。NEVER 把每一輪試錯都 commit 進歷史（要整理用 `tidy-commits`）。 |
| N14 | **NEVER** 把「註解／文件／函式名／commit message 說的」當成「實際成立的」證據 | 宣稱前 MUST 用 grep／讀實際生效的程式去數過、確認過。特別毒：讓 review 與 QA 誤以為風險已處理。 |
| N15 | **NEVER** 拿「還沒自證有效」的指令產出當證據 | 量測工具失效是**靜默**的：grep 回 0、`head` 截斷、zsh 對未加引號的 `$VAR` 不分詞、跑到舊 binary，讀起來都跟「沒問題」一樣。任何 grep／正則／diff／清單 MUST 先確認它真的量到東西（非空、筆數合理、帶一個必命中的對照組）才能下結論。測試斷言同型：`x?.value ?? 0` 這種「量不到就給預設值」的寫法，量測一失效就永遠綠——先讓「取不到」自己紅。 |

### MUST

| # | 規則 | 原因 |
|---|---|---|
| M1 | **MUST** 結論先行，再說理由 | 讀者先看結論決定要不要往下讀。 |
| M2 | **MUST** 如實回報 | 做好就說做好，沒做的步驟明說沒做；NEVER 暗示做過了或模糊帶過；NEVER 加不必要的免責聲明。 |
| M3 | **MUST** 精準對準 root cause —— 範圍以**根因**為界，不以 diff 行數為界 | 「最小化改動」曾被誤讀成「最小 diff」而在錯的地方補洞繞路。修不對稱 bug 往「讓它走對地方」修，NEVER 在錯地方補洞。發現不相關問題 → 記錄在 review／回覆，不要直接改。 |
| M4 | **MUST** 遵守 `.swiftformat` | 一致性降低認知負擔；格式問題交給工具。 |
| M5 | **MUST** 修改 code 後執行 Post-Edit Verification（見下方） | 寫入成功 ≠ 能編譯 ≠ 行為正確。 |
| M6 | **MUST** 任務結束前執行 Session Retrospective（`session-retrospective.md`） | 這次踩到的坑沒回寫進指引，下次會用不同面貌再踩一次。 |

## 任務分級（例外閥門）—— 動手前先分級，流程量隨任務縮放

> 對小任務全額執行流程只會製造假合規與「小問題大 diff」——流程本身也適用 N6。

| 級別 | 判準 | 必要流程 | 明確**不需要** |
|---|---|---|---|
| 瑣碎 | typo／註解／單行顯而易見的修正 | Post-Edit Verification（不可跳） | 宣告、測試、report |
| 小修 | 單一根因、production 改動 ≤2 檔 | 動手前宣告（每項一句話）→ failing test 或最小重現 → 修 → swiftformat | report、Task Summary；Retrospective 一句話判定即可 |
| 標準 | 跨檔／共用元件／多入口 | 8 步法（bug，`evidence-driven-bugfix.md`）完整執行；合併前 code-review 迴圈至收斂 | —— |
| 重大 | 跨 repo（framework＋兩個 App）／資料遺失風險／付款、列印、結帳主流程 | 完整流程＋風險等級與緩解計畫＋負責人確認 | —— |

- 🔴 **小修的檔案數上限 = 根因檔 + 1 個測試檔**。超過 → 每個多出的檔案 MUST 說明必要性，說不出的收回去。
- ⚖️ **判準衝突以風險面優先**：觸及**共用元件／多入口**（framework、provider-ios 與 ezstore-ios 各有一份的邏輯、同一 API 欄位多個畫面各自解析、Obj-C 與 Swift 兩側呼叫者）→ 一律「標準」起跳，即使只改 1 個檔。任務中途發現超出原分級 → 停下重新分級＋重新宣告，NEVER 用開工時的分級撐完全程。

## 動手前宣告（MUST —— 寫第一行 code 前）

> over design／自創平行 flow／範圍膨脹的共通根源是「先寫了再說」。宣告把關卡移到動手前：沒宣告就寫 code = 違規，與 N1 同級。

瑣碎以外的任務，寫第一行 code 前先在回覆輸出五行（每項一句話；是回覆內容，不產生檔案）：

1. **問題**：症狀一句話 + 根因證據（行號／log／failing test），NEVER「我大概知道」就開工。
2. **參照**：要仿照／擴充的既有 pattern（`檔案:行號`）；有多個姊妹可抄時，選**使用者在同一 App 內會拿來對照的同形畫面**，不選 code 距離最近的；找不到 → 列出 grep 過什麼才准新造。**沒有這行就自創平行 flow = 違規**。抄之前先比**問題強度**：列出本需求「沒有」的複雜度來源，參照物解決的問題本需求不到一半 → 先寫最簡版、讓 review 要求加複雜度。
3. **範圍**：修改檔案清單（對照分級表上限）；要超出 → 停下重新宣告，NEVER 默默擴大。
4. **同型**：同根因其他入口的掃描結論——本專案群的同型軸線：**另一個 App 的同一段邏輯**、**framework 變更影響的兩個 App call site**、**同一 API 欄位在多個畫面的解析**、**Obj-C 端的呼叫者**。
5. **驗證**：≥2 種獨立手段（failing test／sabotage／實機或模擬器證據／真實 API 前後 GET 對照），由便宜到貴。

實作與宣告不符（多改檔案、多長出抽象）= 未宣告，MUST 回頭補宣告並說明偏離原因。

🔴 使用者以「建議…／要不要…」語氣提意見時，**交付物是方案不是 diff**：影響可觀測輸出的改動附 before/after 對照，停在宣告等回覆、不先動任何檔案。

## 操作權限分級

| 級別 | 操作 | 規則 |
|---|---|---|
| 🟢 自主執行 | 讀檔、搜尋、分析、產生 review、更新 `.claude/` 指引（五 repo 同步） | 不需確認 |
| 🟡 限定範圍 | 單一檔案的局部 bug fix、補測試（framework `Tests/`）、**收攏型清理**（收掉因本次改動而冗餘的元件，附 N7 承重證明、獨立 commit） | 執行後報告變更摘要 |
| 🔴 需確認 | 跨 repo 重構、刪除／改名 framework public API、引入套件、修改 Info.plist／entitlements／build 設定、`git push --force`、動 protected branch（main／develop／release/*） | MUST 先取得確認 |
| ⛔ 禁止 | 修改 CI 配置、修改 Podfile／Package.swift 依賴（除非明確要求） | NEVER |

## 核心修改原則

- **MUST** 清理**自己改動造成的孤兒**（因本次修改而 unused 的 import／變數／函式一併移除）；**既有的** dead code → 可刪，但走「收攏型清理」通道（獨立 commit＋N7 承重證明），NEVER 混進功能 commit。
- **MUST** 動手前先找**現有可複用的元件／helper**（grep 同功能的另一個 App、framework、`Utils`／`Extension` 目錄），優先擴充或組合，NEVER 平行造一份相似的新實作。找不到才自建，並在回覆說明查過哪些。
- ⚠️ 「元件已存在」≠「元件符合設計」：找到既有元件後 MUST 先與設計稿／票面逐項比對，再決定是「接線就好」還是「要重做外觀」。
- **MUST** 修完一處後全 codebase 搜尋同型根因（＝宣告第 4 行）；**掃描是義務、擴修是決策**：標準／重大 → 一併修；小修 → 掃描結論寫進宣告，一併修須先升級分級。
- **MUST** 收攏呼叫點：同一決策／邏輯抽成一個共用點，而非逐點各修一份。同一個**語意述詞**（相等／同一筆／同一台印表機）在同一 feature 內只有一個定義——第二份定義今天給相同答案，資料漂一點就靜默給出相反答案。
- **MUST** 模組化取「平均值」：NEVER 一行程式包成一個 function，也 NEVER 200 行巨型函式。
- **MUST** 相似情境長成相同形狀（對稱）。診斷用法：功能在情境 X 壞掉時，先找「同一形狀但沒壞」的姊妹功能，逐一比對它掛了哪些 hook／你少掛了哪些；修法收斂成「跟姊妹一模一樣」，NEVER 順手加它沒有的改良。
- **MUST** 跨 App／跨平台不一致（provider 有／ezstore 沒有、iOS 有／web 沒有）先做「決策權歸屬比對」：同一個決策在對照端是**後端欄位**決定的還是 client 規則決定的？歸屬不同就是根因，修法是把決策權交還 server，NEVER 在 client 規則上再加例外。

### 抽象化前的自檢（MUST —— 送審前就做）

- 抽任何 helper 前先數 **production 呼叫點**：只有 1 個 → 內聯。若你同時在為它寫單元測試，那是「為了 mock 內部 helper 硬包一層」的信號——該測的是行為契約，不是這層 wrapper。
- 🔴 **POP 判準**：protocol MUST 放在**依賴邊界**——測試無法建構真實物件的地方（印表機 SDK wrapper、網路 Session、儲存、時間），讓流程依賴 protocol 而非具體型別，測試用 stub 寫完整、不必在 production 開後門。**只有一個實作的內部 helper NEVER 為了 mock 包 protocol**。成本階梯：**參數化（把 `Date()`／設定值當參數）＞ 邊界 protocol ＞ 測試端 spy 子類 override**，由便宜到貴挑第一個夠用的。seam 若得改遍全專案呼叫端 → 不在票內做，開票交負責人裁決。
- 兩個 function 若其一只是「在另一個前面多一個前置判斷」且單一呼叫點 → 合併成一個帶預設參數的 function，NEVER 養第二個 wrapper。
- 寫集合邊界檢查／型別轉換前先 grep 既有 idiom，NEVER 手刻 `index >= 0 && index < count` 重造輪子。
- 「最小 diff」≠「對準根因」：多砍一段特判、直接走乾淨的既有 API，比加旁路特判縮小 diff 更對（M3）。
- **NEVER** 因為「兩個變體今天長得一樣」就合成同一個函式——**相同 ≠ 該共用**。provider-ios 與 ezstore-ios 的版型／流程變體各自演進，合併等於「改 A 默默改到 B」；真要共用只抽「純機械動作」進 framework，把「哪些、什麼順序」留在各 App 手上。要共用前先問負責人。

### 送審前自檢（MUST）—— 這些形狀佔了 review 抓包的大宗

🔴 **合併前 local review 迴圈**：自測完成後、合併或請人 review 前，MUST 以 `code-review` skill（情況 1 未 commit／情況 3 分支）用「找碴」視角對整個 diff 跑一輪 → 修掉所有 must-fix → 重跑 → 直到「單輪 0 個新 must-fix」。must-fix ＝ 真 bug／鐵律違規／自檢答不出來；nitpick 記錄即可、不擋。收斂上限 3 輪：第 3 輪仍冒新 must-fix ⇒ 改動本身不穩，停下重新分級。依分級縮放：瑣碎免跑、小修 1 輪、標準以上跑到收斂。每一輪修正後的驗證（format／單測／呼叫點稽核）全部重跑——證據是 per-revision，過期的稽核表視同未稽核。

- **MUST** 改共用元件時，逐一確認每個 App、每個 call site 都改到（最常漏：provider 改了 ezstore 沒有；Swift 端改了 Obj-C 呼叫者沒有）。
- **MUST** 新增「平行入口」（另一個起始函式／另一條流程）時，先 grep 既有入口修過哪些 bug，確認沒把已修好的問題重新引入。
- **MUST** 本次新增的抽象（helper／protocol／具名函式）都有 ≥2 個 production 呼叫點，單一呼叫點 → 內聯（依賴邊界的 protocol 例外）。
- **MUST** 檢查本次新增元件是否與既有元件功能重疊——重疊就收攏成一份，或說明為何不能收並開票；「只加不收」是 codebase 膨脹主因。
- **MUST** 完成「呼叫點稽核」並把結論寫進回覆／commit message（見下節），NEVER 只在心裡數過。
- 🔴 宣稱「還沒做 X」之前 MUST `git log --all -S"<關鍵符號>"` 掃過所有分支——本專案群多條 release／feat 分支並行，「別人已經做完、只是還沒進這條 branch」是常態；合併／換 base 時重驗一次，衝突的正解是刪掉自己那份，NEVER 兩邊都留。
- 🔴 **MUST** 對本次新增／修改的每個**狀態物件**（旗標／鎖／cache／listener／佇列／連線）列出「設定點 ↔ 清除點」對照，失敗／取消／斷線／resume／VC 重用路徑逐一交代；清除點掛在 completion 內時，往下一層驗到該 completion 有送達保證（印表機 SDK／網路 timeout 不一定回呼）；同 feature 內姊妹機制的 teardown 掛哪裡，你的就掛哪裡。
- 🔴 **MUST** 新增 guard／安全閥／節流／重試時，證明它與既有同域機制可同時成立（不互斥、順序正確），並枚舉異常終態（error／timeout／offline／cancel）逐一交代；early-exit guard 要列下游每次讀寫的累積狀態，guard 解除時重置或說明為何不需要。
- 🔴 用來否決 B 方案的理由 MUST 回頭對 A 方案自己求值一次：寫下「不能用 X，因為它會 Y」時，立刻問「我的方案會不會也 Y」並實測。
- 🔴 「交給別人補」是依賴宣告，不是完成：修法形狀為「本路徑不做 X，由後端／另一個 App／之後的流程補上」時，MUST 附該外部事件對此情境的 producer 證據（後端程式／真實 payload／既有流程實測），否則視為未實作；跨端宣稱 MUST 引用對方的 `路徑:行號`。
- 🔴 defer 一則 review finding 前 MUST 查「同一件事是不是票面自己指向的文件裡的明文條款」——是 ⇒ 它是驗收條款明知未達成，MUST 逐字引用並說明為何本輪不做，NEVER 降級成可選建議。

### 呼叫點稽核（擴充／修改共用元件後 MUST）

> ⚖️ 分級：逐列稽核表**只在改共用元件**（被 ≥2 個檔案引用）時 MUST；**單檔 private 修改** → grep 確認後寫一句「private，grep 0 外部呼叫點」即結案，NEVER 產表格。

- **MUST** grep 出**全部** call site（含另一個 App、Obj-C 端、framework 兩個消費者），逐一確認新行為對該點是正確的。
- **MUST** 列出「掃到幾個 call site、各自結論（不受影響／已同步／刻意不同）」，沒列出來等於沒查。入口依執行期狀態分派到多個實作（如多廠牌印表機各自的 driver）時，逐一列實作並標「本次有實際執行／未執行」，未執行者寫進回覆與 QA 檢查項。
- **NEVER** 讓任何 call site 的行為「順便」被改變；本來就該不同的用參數／policy 明確表達，NEVER 讓其中一方默默吃到新行為。擴充會讓既有 call site 承擔不需要的複雜度 → 改「加參數並保留預設值」。
- **MUST** 清點前確認清單沒被截斷（N15）：自己下過 `head -N` 或數量偏少時去掉限制重數。
- **MUST** 每一列「不受影響／刻意不同」都附可點開查證的依據（票面條目／檔案行號／資料佐證），NEVER 用「這是 legacy／應該沒人走」。「不受影響」的證據單位是**讀端**（消費被改狀態的那一行，附「讀端 = 0」的 grep），不是寫端的行號；「刻意不動」附「該路徑實際由誰承接」的行號。

## 驗證角色（Anti-Laziness）

自我驗證階段 MUST 切換為「找碴」心態：

| AI 說… | 正確反應 |
|---|---|
| 「看起來沒問題」 | 看起來 ≠ 驗證過。去跑 swiftformat、針對性單測、真實 API 對照。 |
| 「這部分應該不受影響」 | 「應該」不是證據。grep 引用確認。 |
| 「太花時間了」 | 驗證量依任務分級決定；分級要求的步驟不因耗時省略。長 build 用 osascript 開外部 Terminal 跑，不是跳過。 |
| 「之前檢查過了」 | 那之後檔案或 branch 可能被動過（使用者的 Xcode、另一個 session、merge）。重讀再確認。 |

## Post-Edit Verification（修改後驗證，MUST）

修改 code 之後依序執行，全部通過才能回報完成：

1. **重新讀取**修改後的檔案，確認內容正確（不是靠記憶）。
2. **格式／靜態檢查**：`swiftformat --lint <自己改的檔>`（有 `.swiftformat` 的 repo）；framework 可直接跑針對性單測（`xcodebuild test … -only-testing:EZPrinterKitTests/<TestClass>`，destination 見該 repo `CLAUDE.md`）。
3. **編譯**：依全域偏好，**App 的 build 由使用者驗證**；要自己跑長 build／整包測試一律用 osascript 開外部 Terminal。沒跑就在回覆明說「未驗證編譯」。framework 改動 → 兩個 App 都要驗編譯（各 repo `CLAUDE.md`）。
4. **影響範圍掃描**：grep 被修改的 class／function／protocol 被哪些檔案引用（含另一個 App、Obj-C 端），報告潛在影響。
5. **規則交叉比對**：對照 `ui-view-structure.md`（新寫 UIKit）、`api-field-contract.md`（動到 request 欄位）、各 repo `CLAUDE.md` 的 gotcha，確認沒踩已記錄的坑。

**驗證失敗處理**：MUST 立即修正並重跑完整驗證；問題超出本次修改範圍 → 記錄在回覆，不擴大修改。**同一個 bug 兩次修法無效 → 停止疊 patch，revert 回已知良好狀態，重新陳述根因假設後才再動手**；單一假設連續兩次失敗 → 先輸出假設清單與已排除項再繼續（全域偏好）。

**NEVER** 未跑靜態檢查就回報「Done」；**NEVER** 測試失敗時粉飾結果。

## Context Hygiene（上下文衛生）

- 讀檔硬上限約 2,000 行／25,000 tokens，超過部分**靜默截斷** → 超過 500 行的檔案 MUST 分段讀（offset + limit），讀後確認是否到檔尾。
- 檔案**可能在你讀過之後被改過**（使用者的 Xcode、另一個 session、自己的 `git apply -R`、對話被壓縮）→ 編輯前重讀；自己剛編輯完且上下文完整則不必。
- 搜尋結果偏少時懷疑截斷，縮小範圍重搜，NEVER 據此下「全部只有 N 個」結論。

## Parallel Task Decomposition（並行拆分）

- 彼此無依賴、各自需大量閱讀的子任務（掃另一個 App、跨 repo 對照）→ 可拆給 subagent；有依賴的序列處理；已知檔案或單一符號直接查，不開 subagent。
- MUST 區分三階段：**探索（唯讀）→ 計畫 → 實作＋驗證**；探索階段 NEVER 改東西。驗證的方向是「想辦法搞壞它」。
- 大型重構前先開獨立 commit 清 dead code／unused import，NEVER 混合清理與功能變更。
- **NEVER** 外包判斷力：可分配子任務，但 MUST 自己消化資訊做決策。

## Checkpoint Rules（流程檢查點）

| 觸發時機 | MUST 執行 |
|---|---|
| 寫第一行 code 前（非瑣碎） | 輸出「動手前宣告」五行 |
| 修改任何 `.swift`／`.m` 檔後 | Post-Edit Verification |
| Bug 修復完成後 | 依分級：小修＝宣告＋failing test／重現＋format；標準以上＝8 步法 |
| 動到 request 欄位後 | `api-field-contract.md` 自我檢查（真實 API 前後 GET 對照） |
| 擴充／修改共用元件後 | 呼叫點稽核 |
| 動到 framework 後 | 兩個 App 驗編譯（或明說未驗證） |
| **合併前／請人 review 前（非瑣碎）** | `code-review` skill local review 迴圈至收斂（上限 3 輪、小修 1 輪） |
| 改 `.claude/rules/*.md`、共用 skill | 五 repo 同步＋checksum（各 repo `CLAUDE.md`） |
| 複雜任務完成後（3+ 檔案） | Task Summary（見下） |
| **任務完成後** | Session Retrospective（`session-retrospective.md`）；小修／瑣碎一句話判定即可 |

## Task Summary Protocol

涉及 3 個以上檔案的任務完成後 MUST 產出：

```
### Task Summary
- **任務**：[一句話]
- **修改檔案**：
  - `path/to/file` — [變更重點]
- **影響範圍**：[受影響的 App／framework／畫面]
- **驗證**：[做了什麼、沒做什麼（未驗證編譯要明說）]
- **待驗證項目**：[需要人工驗證的部分]
```
