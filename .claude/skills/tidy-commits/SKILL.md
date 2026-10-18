---
name: tidy-commits
description: 合併前整理分支的 commit 歷史，依「修復脈絡」重新拆分與排序，讓主管 / reviewer 照 commit 順序由淺入深就讀懂修復方向。處理 fixup 折疊、commit 拆分、message 重寫，並強制備份與前後內容比對。觸發詞：「整理 commit」「整理一下 commit」「commit 整理」「合併前先整理」。
user-invocable: true
---

# 整理 Commit —— 讓主管由淺入深讀懂修復方向

> **EZPretty iOS 五個 repo 共用正本，五份內容逐 byte 相同。** 改這份 = 五份一起改，見各 repo `CLAUDE.md` 的「共用規則檔」章節。本檔不含任何 repo 專屬指令：**gate 指令、目錄名、保護分支一律讀該 repo 的 `CLAUDE.md`**。

> 目標讀者是**主管 / reviewer**，不是作者自己。他們要能**照著 commit 順序一路讀下去，就看懂「問題是什麼 → 怎麼修 → 為什麼這樣修 → 留下什麼」**，而不是被迫在 diff 裡自己拼湊。

**整理 commit 只准動歷史，NEVER 動內容。** 這是本 skill 的定義，也是驗收標準。

---

## 什麼時候值得整理

本專案群三類 repo 各有理由：

- **Obj-C / Swift 混合的 App**（provider / ezstore / ezhair）：一個功能常同時動到 `.m` 舊 API 層、Swift 新程式、xib 與 assets——拆清楚才分得出「哪一刀改了行為」與「哪一刀只是搬家」。
- **共用 SPM package**（ez-framework-ios）：一次改動同時影響兩個 App——哪個 App 出事時才追得出是哪一刀。
- **上游 fork**（CalendarKit）：客製 commit 長期疊在主線上，日後 rebase 上游新版要逐個重放——commit 越小越聚焦，衝突越好解。

**合併方式決定整理的成果留不留得住** —— 本專案群走 `git merge --no-ff <feature>` 進 `release/vX.Y` 或 develop 系分支（見 `git log`），每個 commit 完整留在目標分支上；squash 則全部壓平（見下方例外）。**動手前 MUST 先確認這次要怎麼合**，NEVER 憑猜測。

它同時幫上：

- **code review** —— 一個 commit 一個關注點，review 意見能精準對位，不會混在一大坨 diff 裡
- **主管 / 同事看分支** —— 照順序讀就懂修復方向，不必問「這段是幹嘛的」
- **日後 bisect / 追責** —— 每個 commit 都是可獨立編譯的狀態，二分法才有意義

### 例外：整理的是會被 squash 合併的分支時

若該分支合進目標分支時會被 **squash**（歷史屆時被壓平），**MUST 額外產出 squash commit 的 body 草稿**（每個階梯一段），否則整理出來的資訊會在 squash 當下蒸發。**合併方式若不確定，MUST 先問**，不要憑猜測決定要不要出草稿。

---

## 核心原則（MUST）

- **依修復脈絡拆分，NEVER 依檔案類型或時間順序拆。** commit 順序 = 閱讀順序 = 由淺入深：

  | # | 階梯 | 對應 `type` | 內容 |
  |---|------|------------|------|
  | 1 | 前置整理 / 重構 | `refactor` / `style` | 不改行為的鋪路，先獨立出來，讓後面的行為變更 diff 乾淨 |
  | 2 | 根因修復 | `fix` / `feat` | 真正改行為的那一刀，最小、最聚焦。**主管只看這個 commit 就懂改了什麼** |
  | 3 | 測試 | `test` | 只有在測試**不是**跟著第 2 步一起進去時才獨立（見下方硬條款） |
  | 4 | 契約 / 文件 | `docs` | API 契約、文案、`CLAUDE.md` |
  | 5 | 版控周邊 | `chore` | 版號、依賴、tooling |

  > type 以 [`commit-message` skill](../commit-message/SKILL.md) 為準；舊歷史的 `R` 等同 `refactor`，整理時一律改寫成現行 type，NEVER 自創新 type。

- **MUST 整理掉「前後反覆修改」的痕跡。** 同一段 code 在本次開發改了又改、review 後又修一次 → **一律折回它該屬於的那個 commit**。**NEVER** 讓 `Fix typo`、`Apply review feedback`、`Correct previous commit`、`WIP` 這種 commit 留在歷史上 —— 那是作者的試錯過程，不是修復脈絡。
- **每個 commit MUST 能單獨讀懂**：subject 說做了什麼，body 說**為什麼**。主管不必回頭看前一個 commit 才知道這個在幹嘛。
- **拆不開就別硬拆。** 為了拆而拆出中間壞掉的狀態，比不拆更糟。

### 🔴 硬條款：每個 commit MUST 自己過 gate

gate ＝ **該 repo `CLAUDE.md` 的 Build／驗證章節指令**（`swiftformat <目錄>` ＋ 編譯；有測試的 repo 加測試）。動手前 MUST 先把它讀出來，NEVER 憑記憶寫 xcodebuild 參數——各 repo 的 workspace、scheme、sdk 都不同，provider 甚至**只能 device build**（simulator link 必失敗是既有狀況，不是整理壞了，誤判會白白拆掉正確的歷史）。

整理後的**每一個** commit 都 MUST 能單獨通過它 —— 任何一個紅的，都會變成別人 bisect 時踩到的地雷。

- **regression test 與修復它的 code MUST 放同一個 commit。** 先寫 Red test 是**開發順序，不是 commit 順序** —— 把 Red test 單獨切一個 commit，等於在歷史上留一個測試是紅的狀態。
- **生成物 / 鎖定檔 MUST 跟著它的來源檔同一個 commit**：`Podfile.lock` 跟著 `Podfile`、`Package.resolved` 跟著 `Package.swift` 的依賴變更、`Binaries/` 的 xcframework 跟著它的 target 設定、`Localizations/*.lproj` 跟著它翻譯的那段 code。分開切會讓中間的 commit 編不過。
- **xib / storyboard 的 outlet 變更 MUST 跟著用到它的 Swift / ObjC 檔同一個 commit** —— 分開切會讓中間的 commit 在執行期炸 `setValue:forUndefinedKey:`，而**編譯是過的**，gate 抓不到。
- **`project.pbxproj` 的變更跟著它的來源檔走**：用 `PBXFileSystemSynchronizedRootGroup` 的目錄新增檔案不會動到 pbxproj，但手動加進 target 的資源 / ObjC 檔會。
- **沒有測試套件的 repo**（如 CalendarKit，見其 `CLAUDE.md`）gate 只涵蓋 format + build，gate 綠**不等於**行為沒壞 —— 拆 commit 時要比有測試的 repo 更保守。

### 動到 ez-framework-ios 時

共用 SPM package 的改動在**另一個 repo**，本 repo 的 commit 整理管不到它。
**MUST 分別整理三個 repo（ez-framework-ios / ezstore-ios / provider-ios）各自的分支**，並在回報中說明彼此的相依順序（framework 先合）。

---

## 🔴 備份與前後比對（第一鐵律）

> 歷史改壞了，working tree 看起來還是好的，**不會有任何錯誤訊息**。沒有這道安全網就是在賭。

### 動手前 MUST 備份 —— 備份分支一律放 `backup/` 路徑，鏡射原分支名

```bash
BR=$(git rev-parse --abbrev-ref HEAD)   # 例：feat/#26133
git branch -f "backup/$BR" HEAD         # →  backup/feat/#26133
git rev-parse HEAD^{tree}               # 記下整理前的 tree hash
```

- **MUST 用 `backup/` 前綴**，**NEVER** 用 `backup-xxx`、`tmp`、`old` 這種散在根層的名字 —— 全部收在 `backup/` 底下，`git branch --list 'backup/*'` 一眼看完、要清也一次清得乾淨，且永遠不會與真正的工作分支混在同一層。
- 名稱 **MUST 鏡射原分支完整路徑**（`backup/<原分支名>`），光看 ref 名就知道它備份的是誰。同一支分支整理第二次 → `backup/<原分支名>-2`，**NEVER** 覆蓋掉上一份備份。
- ⚠️ git ref 是檔案系統路徑，`backup/a/b` 與 `backup/a` **不能同時存在**（D/F conflict，`git branch` 會直接拒絕）。本專案群同時有 `feat/#26133` 與 `wii/feat/#25807` 兩種命名，撞到時先 `git branch -D` 清掉不合命名慣例的舊 ref，或改用 `backup/<原分支名>-2`。
- 備份分支是**純本機安全網**，**NEVER** push 上遠端。

### 整理後 MUST 前後比對，三項全過才算完成

```bash
git diff "backup/$BR" HEAD --stat              # MUST 完全無輸出
git diff "backup/$BR" HEAD                     # MUST 完全無輸出
git rev-parse HEAD^{tree} "backup/$BR^{tree}"  # 兩個 hash MUST 相同
```

- `tree` hash 相同是**最硬的證明**（整棵檔案樹逐 byte 相同）；`git diff` 為空是同一件事的另一種說法，兩個都跑是為了避免打錯 ref 名而得到「假空白」。
- 三項通過就代表**行為不可能改變** ⇒ 不需要再跑一輪行為驗證（別浪費時間重跑 App）。整理後唯一還要驗的是「**每個** commit 各自能過 gate」，做法見下方執行鐵律最後一條。
- **NEVER 只看 exit code 或「沒噴東西」就當作通過** —— ref 名打錯時 `git diff` 會直接報錯而不是回空，在 `&&` 串接裡很容易被滑過去。**MUST 親眼確認 tree hash 那行印出兩個一模一樣的 hash。**
- **MUST 一併確認 commit 數量與各 commit 的檔案清單符合預期**：
  ```bash
  git log --oneline <base>..HEAD
  git log --format='--- %h %s' --name-only <base>..HEAD
  ```

### 通過之後

- 回報「整理完成」**MUST 附上 tree hash 相同的證據**。
- **NEVER 自行刪除 backup ref** —— 留到使用者確認或分支已合併；要刪由使用者開口。

### 沒通過（內容有差異）

**MUST 立刻 `git reset --hard "backup/$BR"` 回到整理前**，重新規劃拆法。**NEVER** 在已經歪掉的歷史上繼續疊 patch 想補回來。

---

## 動手前的其他檢查（MUST）

- **MUST 先列出「整理後的 commit 清單 + 各自檔案」給使用者確認再執行。** 拆法有多種合理解時攤開選項，**NEVER** 默默選一種就改寫歷史。
- **MUST 確認分支未推上遠端**：`git ls-remote --heads origin <branch>`。已推過的分支要改寫歷史 → **先問使用者**（推過之後必須 `--force-with-lease`，而 force push 屬於不可逆操作，一律先問）。
- **NEVER 在 `master` / `main` / `develop` / `wii/develop` / `release/*` 上整理。** 那是共用歷史，本專案群沒有 hook 會攔你，全靠這條規則。
- **MUST 確認工作樹只剩該進去的東西。** `Podfile.lock`、`Package.resolved`、pbxproj 常有與本次無關的既有改動，**NEVER** 讓它們被捲進整理範圍。

---

## 執行鐵律（MUST / NEVER）

- **NEVER 用 `git stash` 暫存。** 工作樹要乾淨就先 commit，不要 stash —— stash 會讓變更脫離分支追蹤，合併時容易遺失。
- **`git commit --fixup` 會吃掉整個 index。** 動手前 **MUST** 用 `git diff --cached --name-only` 確認只有該進去的檔案。
  > **血淚**：曾因 `git mv` 的檔名變更早就躺在 index 裡，被 `--fixup` 一起吞走；autosquash 時那個 rename 在歷史早期無檔可套，整個 rebase 卡死只能 abort 重來。
- **摺疊修正 commit** —— 一個目標一個 fixup：
  ```bash
  git add <只屬於該目標的檔案>
  git commit --fixup=<target-sha>
  # …對每個目標各做一次…
  GIT_SEQUENCE_EDITOR="cat" git rebase -i --autosquash <最早目標>~1   # 先預覽 todo
  git rebase --quit                                                   # 確認歸位後退出預覽
  GIT_SEQUENCE_EDITOR=: git rebase -i --autosquash <最早目標>~1       # 真的執行
  ```
  **MUST 先預覽 todo**，確認每個 `fixup` 都排在正確的 `pick` 下面再執行。
- **同時要 autosquash + 改 message** 時一次 rebase 搞定（macOS 的 `sed` 要 `-i ''`）：
  ```bash
  printf '#!/bin/sh\ncat /tmp/new-msg.txt > "$1"\n' > /tmp/reword.sh && chmod +x /tmp/reword.sh
  GIT_SEQUENCE_EDITOR="sed -i '' '1s/^pick /reword /'" GIT_EDITOR=/tmp/reword.sh \
    git rebase -i --autosquash <target>~1
  ```
- **拆一個 commit 成多個**：
  ```bash
  GIT_SEQUENCE_EDITOR="sed -i '' '1s/^pick /edit /'" git rebase -i <target>~1
  git reset --mixed HEAD~1        # 內容退回工作樹
  git add <第一組檔案> && git commit -F /tmp/msg-a.txt
  git add <第二組檔案> && git commit -F /tmp/msg-b.txt
  git rebase --continue
  ```
- **有 `.pre-commit-config.yaml` 的 repo，rebase 期間 hook 會跑 swiftformat** —— 若它改動了檔案，該 commit 的內容就跟備份不一致，前後比對會抓到。
  **MUST 在整理前先跑一次 `swiftformat <該 repo 的原始碼目錄>` 並把格式修正併進原本的 commit**，讓整理過程中 hook 無事可做。
- **整理完 MUST 逐個 commit 跑 gate**，**NEVER 只在 HEAD 跑一次** —— 只驗 HEAD 照定義驗不到中間狀態，而漏切的生成物 / 依賴變更正是只會在中間爆的問題：
  ```bash
  git rebase <base> --exec '<該 repo CLAUDE.md 的 gate 指令>'
  ```
  逐個 commit 執行，任何一個紅就停在那裡讓你修。
  > ⚠️ `xcodebuild` 單次數分鐘，commit 數多時 `--exec` 會跑很久。趕時間可只對「有行為變更」的 commit 跑，
  > 但 **MUST 在回報中明講跳過了哪幾個**，NEVER 靜默省略。長時間 build 依全域偏好用 osascript 開外部 Terminal 跑。
  > `git status` 乾淨**不是**這件事的證據 —— 它只反映工作樹，與歷史中某個 commit 能不能編過毫無因果關係。

---

## Commit message（MUST）

格式一律走 [`commit-message` skill](../commit-message/SKILL.md) 的 `[type][#票號] 描述`（繁體中文），**此處不重抄**。整理時額外要求：

- **body MUST 逐情境陳述行為變化**（iPhone / iPad、美業 / 餐飲、新增 / 編輯、各訂單狀態、各付款方式、新舊版相容），**NEVER** 用「嚴格變好」「不影響其他情境」這種一句總括 —— 總括必然掩蓋反例，而 reviewer 會拿那句話當事實引用。
- **MUST 寫「為什麼不那樣做」**：刻意不收攏、不抽象、不加分支的地方要交代理由，否則 reviewer 會重問一次。
- **subject MUST 對應該 commit 真正動到的範圍**。拆分後每個 commit 的 type / Module 可能不同（鋪路的那刀是 `refactor`、真正修的那刀才是 `fix`），**NEVER** 整批沿用原本那一個。

### 🔴 數量宣稱 MUST 用指令數過並貼出指令

- 任何寫進 commit message / 報告 / PR 的**數量**（N 個呼叫點、N 處落差、N 個檔案、N 條測試）**MUST 用指令實際數過**，**NEVER** 憑印象、憑「我剛剛看過」、憑目測掃一遍。這種錯特別毒：**它讓 reviewer 與 QA 以為稽核已經做過了。**
- **MUST 把數出來的指令一起寫進文件**（如 `grep -rn "foo()" <原始碼目錄> | grep -vc "func foo"`），讓下一個人能重跑驗證。數字沒有附指令 = 沒數過。
- **MUST 檢查 grep pattern 本身會不會誤判**，兩種都要想過：
  - **多算**：pattern 命中了語意不同的行。
  - **少算**：目標不含 pattern 字串。
  - ⚠️ 這兩個錯會**互相抵銷**，湊出一個看起來很合理的數字 —— 比單純數錯更難察覺。**MUST 逐條列出命中項並肉眼確認**，NEVER 只看 `grep -c` 的總數。
- 數不出精確值時 **MUST 寫「至少 N 個」或直接列舉**，**NEVER** 寫一個沒把握的確數。

---

## 產出（回報 MUST 包含）

1. **整理後的 commit 清單**：`<sha> <subject>` + 各自檔案，並標出每個對應到哪一級階梯。
2. **前後比對證據**：三項檢查的實際輸出，含兩個相同的 tree hash。
3. **逐 commit gate 結果**：`git rebase <base> --exec '<gate>'` 全綠（或明講跳過了哪幾個）。
4. **備份 ref 名稱**，並說明未刪除。
5. **僅限會被 squash 合併的分支**：squash commit body 草稿。
6. **僅限有動到 ez-framework-ios**：三個 repo 的分支與相依合併順序。

---

## 相關

- [`commit-message`](../commit-message/SKILL.md) —— commit message 格式正本
