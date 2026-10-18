# Evidence-Driven Bugfix —— 證據驅動除錯流程

> **EZPretty iOS 五個 repo 共用正本，五份內容逐 byte 相同。** 改這份 = 五份一起改，見各 repo `CLAUDE.md` 的「共用規則檔」章節。
>
> 核心原則：**先有證據，才能動手。** 沒有最小重現、沒有根因證據之前，NEVER 直接改程式碼。
> 分工：Bug 修復走本流程（reactive）；新功能走「動手前宣告 → 參照既有 pattern → 最小實作 → 合併前 review」（`ai-core-rules.md`）。

## 除錯鐵律

| # | 禁令 | 原因 |
|---|---|---|
| B1 | **NEVER** 沒有最小重現步驟就開始修 code | 「我大概知道怎麼修」修到的是症狀不是根因。 |
| B2 | **NEVER** 沒有 failing test／可重複的失敗證據就改程式碼 | 沒有驗收標準，你怎麼知道修好了？framework 用單元測試；App repo 測試基礎薄弱，改用可重複的最小重現（操作步驟＋截圖／log／真實 API 回應），根因分析仍 MUST 完成。 |
| B3 | **NEVER** 修超過讓 failing test 通過的最小範圍 | 修復範圍越大，回歸風險越高。 |
| B4 | **NEVER** 跳過 regression protection 就回報完成 | 今天修好的 bug，沒有 guard 三個月後會以不同面貌回來。 |
| B5 | **NEVER** 沒有根因證據就提交修復 | patch 症狀沒釘住根因 = 定時炸彈。 |
| B6 | **NEVER** 憑「可信機制 + 程式碼註解」就定客服／線上 bug 的根因 | 那是假設不是證據。MUST 先撈實際證據（Crashlytics／後端 log／使用者回報的畫面與時間／印表機回報）逐時間對證。 |
| B7 | **NEVER** 動手前不檢查「fix 方向 vs 症狀方向」 | 先把症狀講成方向（太多 X／太少 X），確認 fix 讓它往對的方向變。 |
| B8 | **NEVER** 拿參考實作的**註解／contract 說明**當證據，MUST 讀實際生效的程式與版面 | 參考實作（另一個 App 的同功能、web 端、後端 repo）是要讀的證據，不是照抄的權威：讀完 code 還要把它的 filter／predicate 拿去跑一次**真實 payload**，列出它靜默丟掉的輸入類別；丟掉的類別交票主裁決，NEVER 自行照抄或放寬。 |
| B9 | **NEVER** 只用「純函式測試」當 regression protection 就收工 | 那是**測法官不是測法庭**：policy 全綠、接線沒人守。修復是 guard／一行 hook／新 helper → MUST 加 production 入口驅動的 wiring test（framework）或接線層級的實機驗證（App）。 |
| B10 | **NEVER** 因「實作與註解／命名矛盾」就順手修正既有計數器／旗標／guard | 看起來寫錯的東西可能正在承重（某個未修 bug 的恢復閥）。動手前三查：① `git log --all --grep='#<票號>'`／`-S'<符號>'`；② 修復是否真的已 merge——一律以 `git show <branch>:<path>` 讀內容為準，NEVER 只信 `branch --contains`；③ 連測試目錄一起 grep——設計意圖常只寫在測試的註解或 fixture 名。 |
| B11 | **NEVER** 引用既有 commit message／註解／Redmine 回覆裡的「根因說法」當事實 | 那可能是當初的錯誤推測。票上／前一 session／其他 AI 留下的 RCA 同樣是**待驗假說**——排版再精美都不是證據，先用現行程式重推它那一個承重的機制宣稱。自己重現失敗要當**結果**如實報告，NEVER 用「合理的防禦性修法」蓋掉。 |
| B12 | **NEVER** 用 log／payload 欄位的**值**推論對方端的**行為語意** | 欄位名自我說明但寫入條件常不是你以為的。判定對方行為：讀寫入那個值的程式路徑（後端 repo／另一個 App）。 |

## 8 步除錯流程

### Step 1 —— 建立最小重現

MUST 產出：環境（App／機型／印表機型號／帳號）、精確操作步驟、預期 vs 實際。重現不明確 NEVER 進下一步。
**證據型態分流**：症狀型（可觀測行為錯誤）→ 重現步驟；**缺席型**（某段程式從未被任何載體呼叫）→ 呼叫點窮舉（列 grep 指令與命中數，含「應該有卻是 0」的目錄），NEVER 為此硬湊較弱的重現。

### Step 2 —— 補 Failing Test／失敗證據

- framework：放 `Tests/EZPrinterKitTests/`，命名描述症狀與預期，修復前穩定 **Red**，Given-When-Then。NEVER 寫「修前也會過」的測試。
- App repo：可重複的最小重現腳本（操作步驟＋截圖／真實 API 回應），或暫時 debug log 逼出狀態（驗完 MUST 移除、NEVER commit）。
- **Red 不可得**（修復形狀是新增尚不存在的參數／欄位 → 修復前編譯不過）→ 改以逐項 sabotage 取代（事前宣告預期紅／綠），報告明記 Red 的取得方式，NEVER 硬造 pass-through stub 湊 Red。

### Step 3 —— 驗證根因假設

- **先驗必經呼叫鏈**：列出每個必須被呼叫的步驟，用 log／斷點證實；沒被呼叫到的步驟回推被什麼擋住——通常就是根因。末端細節（token／網路）最後查。
- 列 **≥2 個**根因假設（排除確認偏誤），各用行號＋邏輯鏈支撐或排除。
- 頻率型症狀（呼叫太多次／事件重複）：先算速率指紋（總次數 ÷ 時長）再讀 code，與 timer／節流常數比對。
- 版本歸因型（「X 版有、Y 版沒有」）：用 tag 直接 diff 相關檔案，NEVER 只從統計推論。
- 「某欄位缺失／某參數沒帶」：先問「這個使用者動作應該產生幾筆實體（訂單／預約／列印工作）」，與對照端比**筆數**——筆數錯誤會偽裝成欄位缺失。
- UI 元素缺席：先在使用者回報的截圖裡找「同機制但正常」的姊妹型別對照——姊妹正常＝分發機制活著，根因收斂到該型別的顯示條件。
- 「差一天／差一小時」：同時列「資料源送錯」與「本端時區轉換」兩個假說，先 `git log -S<關鍵函式> --since=14.days` 看最近誰改過。
- 使用者可見文案先在**所有 client**（兩個 App、web）的資源檔 grep：命中 → client 問題；皆無 → 後端下發，彈窗是 server 對某資料狀態的正確反應。
- 同型入口掃描每一列的 YES MUST 追到缺陷行前**最後一道 gate**（廠牌 switch／紙寬判斷／權限旗標）並附 gate 值；只憑「呼叫了同一個共用上游」判 YES 是 N14 型。

#### 🔴 「靜默失敗」的定位順序（無 crash、無 log，行為就是不對）

MUST 依序排除四層，NEVER 跳著猜：

| 層 | 要問的問題 | 本專案群實例形狀 |
|---|---|---|
| ① 執行到了嗎 | 這段 code 真的被呼叫到嗎？被 `#if` 旗標包住的分支先反查旗標有沒有定義；enum rawValue 未宣告時 `default:`／`?? .unknown` 讓整條分派靜默落空 | web payload 的 eprinter 只帶 id，連線設定要靠 `ensureCached` 回查——沒回查就走不到列印 |
| ② 條件恆不成立嗎 | guard 前提是否永遠假（或真）？`a ?? b` 的 `b` 可達嗎？ | 紙寬 nil 塞預設值讓「未設定」分支永遠不觸發 |
| ③ 錯誤被吞掉了嗎 | 中間層是否把業務錯誤轉掉／丟棄？ | framework 走自己的 `Session`，App 端 401 retry 攔不到它 |
| ④ 資料被靜默改寫了嗎 | 轉換／快取／型別轉換是否無聲改值？ | `dictionary(forKey:) as? [String: 具體型別]` 混型全 nil；後端對不認識的欄位回 200 照常丟掉（`api-field-contract.md`） |

每層都要證據排除；排除完仍找不到 → 懷疑量測本身（N15）。

### Step 4 —— 實作最小修復

MUST：範圍僅限根因確認點；failing test 變 Green；Post-Edit Verification。NEVER 順便重構／加功能／改命名（N5）；NEVER 未檢查 fix 方向（B7）。

- 修法是「改 gate 讓決策改落既有分支」或「把既有入口開放給某個變體」→ MUST 把新落入的分支從決策點讀到終局出口（含 default case），逐步確認語意對這個情境成立——「不再走 A」≠「走到對的 B」，被改落的分支是為別人設計的。
- 複用姊妹 helper 時 MUST 連它呼叫點的前置守門一起複用——helper 的正確性常靠呼叫端的 guard 撐著。
- 設定點↔清除點要成對看的不只「有沒有清」，還有「清除路徑會不會被走到」：清除點掛在「只有 UI 成功顯示才會抵達」的流程裡，任何讓 UI 顯示不出來的前置條件都會讓它變成永久洩漏。
- NEVER 未過三問就加 runtime 自我檢查／探針：① 再發生時既有通道（Crashlytics／後端 log）會不會已經告訴我們？② 探針看得到懷疑的那個失敗模式還是只看得到隔壁的？③ 接受這 pattern 是否等於每個同類寫入點都欠一個？任一不利 → 改寫測試。
- 採用票面／reviewer 點名的「現成狀態 X 可重用」前，在呼叫鏈時間軸上列 X 的「設定點 ↔ 清除點 ↔ 本次讀取點」順序；清除點排在讀取點之前即不可用。
- 🔴 **同一個 bug 兩次修法無效 → 停止疊 patch，revert 回已知良好狀態，重新陳述根因假設後才再動手**（全域偏好）。

### Step 5 —— 補 Regression Protection

- framework：failing test 基礎上補寫得出保護對象的邊界案例（重質不重量）；「參數轉遞漏傳」型 bug 優先評估**移除該預設值**當編譯期 guard——讓省略變成編譯錯誤比寫測試抓省略更強。
- App：接線層級的實機／模擬器驗證證據（截圖／log 節錄）寫進回覆；補單元測試列為範圍外建議即可。

#### B9 —— 測法庭，不是只測法官（wiring test）

修復形狀是「新增 guard／把 helper 掛進流程／新增 helper 並呼叫」→ MUST：

- 只透過 production 入口驅動（真實回呼／狀態變化／action），NEVER 測試裡直接呼叫本次新增的 helper，NEVER 代替 production 設定它該自己設的狀態。
- **自我驗收（sabotage）**：把修復那行暫時註解掉 → wiring test 變紅、純函式測試仍綠 → 還原。事前逐條列預期紅／綠，跑完逐條比對；**預期紅卻仍綠**的當測試缺陷調查。修復含多項變更 → 逐項單獨 sabotage（同時破壞多處可能互相抵銷讓「應紅」變綠）。
- 修復含新增**狀態物件**（旗標／鎖／cache／listener／佇列）→ sabotage 清單加「失敗路徑不清除」情境，斷言失敗／取消／斷線後該物件被釋放，NEVER 只斷言 happy path。
- 需求是「某件事不可以發生」→ 斷言對準「那個動作有沒有被執行」（測試端 spy 子類 override 目標方法），NEVER 只斷言畫面結果——「先做了再蓋掉」也會綠。NEVER 為此在 production 埋 `testOnly_`／`#if DEBUG` hook。

**sabotage 的存檔／還原鐵律**：

- 存 patch MUST 用 `git --no-pager diff > <scratchpad>/mine.patch`（pager 會靜默產出 0 byte），路徑直接寫在指令上，存完 `wc -l` 確認非空。
- 還原用 `git apply -R <patch>`（先 `--check`），驗完 `git apply` 套回；untracked 新檔另外 `mv`。**NEVER `git checkout -- <file>`**（清掉該檔全部未提交修改）、**NEVER `git stash`**（N12）。
- 被 sabotage 的檔案另有未 commit 改動時，先 `git diff -- file > pre.patch` 拍快照，還原後與快照 `cmp`；或用暫時檔 sabotage 不碰既有檔。
- 還原 MUST 掛 `trap … EXIT INT TERM`，NEVER 寫在指令尾端（超時中斷會把 `// SABOTAGE` 留在 production）；commit 前 gate `grep -rc SABOTAGE == 0`。
- 施作與判讀都接到控制流：錨點先 `grep -c` 證明唯一 → 施作 `|| exit` → `grep -c SABOTAGE` >0 才起測試。判讀三分：全綠／真紅（有 failed 測試）／**0 筆 failed＝建置失敗或沒跑到**，NEVER 讀成「破壞了卻沒紅」。
- 還原後重跑測試回全綠，用 grep 關鍵符號／`git diff --stat` 確認狀態真的變了，NEVER 只看 exit code。
- sabotage 後測試仍全綠 ⇒ NEVER 推論「修復多餘」，依序懷疑：① 斷言量錯**對象**（量的是呼叫前存下的值複本、或容器 frame 而非使用者看得到的量）；② 量錯**時機**（觀察窗沒涵蓋缺陷發作時刻；tell：前後測試耗時完全相同）；③ 破壞本身沒落地；④ 被拆／被清的東西在 Given 裡從未存在（先寫正向 probe）；⑤ 分支根本不可達（讀產生該值的上游一層，`?? []` 兜底讓 nil 分支永不成立 → 整包撤回，NEVER 留一段測不紅的防禦碼）。

### Step 6 —— 票面驗收逐條確認

對照 Redmine 票的需求逐條打勾（無明文 → 標註＋判斷依據）；確認沒改壞其他行為。清單寫進回覆或 commit message，NEVER 另開文件。

### Step 7 —— Code Quality Review

以 `code-review` skill 跑 local review 迴圈（`ai-core-rules.md` 送審前自檢）。發現不相關問題 → 記錄，NEVER 在此步修改。

### Step 8 —— Final Report

- 機制宣稱進任何耐久產物（回覆／票面留言／commit message）前先分類：**observed**（量測在手）／**derived**（由量測算得）／**asserted**（信念）——asserted 要嘛先測（一次 curl／grep 的成本），要嘛明標「未驗證」。
- 動到 request 欄位 → 真實 API 前後 GET 對照（`api-field-contract.md`），只看 200 不算驗證。
- 寫下「同型未驗風險／待確認」時 MUST 當場用最便宜手段定案（一次 curl／grep）或寫回 Redmine 票，NEVER 只留在回覆文字裡——沒有人會回頭確認它。
- 回覆含：根因、修法、風險等級（Low／Medium／High）、受影響範圍、驗證證據、未驗證項目。

## 例外情況

| 狀況 | 處置 |
|---|---|
| 無法用單元測試重現（UI 動畫／手勢／實體印表機） | Step 2 改手動重現腳本＋截圖／印出結果，Step 3 根因分析仍 MUST 完成 |
| 緊急 hotfix（release branch） | 允許先 Step 4 → 24 小時內補齊其餘步驟 |
| 根因跨 repo（framework＋App） | 🔴 先取得負責人確認，三個 repo 各自開分支，拆成多個最小修復；兩個 App 都要驗編譯 |
