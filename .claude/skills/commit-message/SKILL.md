---
name: commit-message
description: 撰寫或修訂 git commit message 時使用——一般 commit、fixup、版號更新、release merge。提供 EZPretty iOS 五個 repo 共用的 `[type][#票號] 描述` 格式。觸發詞：「commit message」「怎麼寫 commit」「/commit-message」。
user-invocable: true
---

# Commit Message 格式

> **EZPretty iOS 五個 repo 共用正本，五份內容逐 byte 相同。** 改這份 = 五份一起改，見各 repo `CLAUDE.md` 的「共用規則檔」章節。
>
> 格式來自五個 repo `git log` 的既有慣例（2026-10-18 核對近 40 筆：subject 全部繁體中文，App repo 97% 為 `[type][#票號]`，framework 為 `[type][Module][#票號]`），不是另立新規。

## 格式

```
[type][#票號] 描述（繁體中文）
```

- **type** 小寫（見下表）
- **票號** 是 Redmine issue id，從分支名 `feat/#<number>`、`fix/#<number>` 取；沒有票的 tooling／文件改動用 `[type][Module]`（如 `[chore][Tooling]`、`[docs][CLAUDE]`）
- **多 library 的 repo**（`ez-framework-ios` 有 EZCore / EZThermalPrinter / EZLabelPrinter / EZPrinterSettings）在票號前加模組：`[feat][EZThermalPrinter][#26378] …`
- **描述**陳述這個 commit 做了什麼，句尾不加句號；中括號內的 type／Module／票號維持原文

## type

| type | 用途 |
|---|---|
| `feat` | 新的使用者可見功能 |
| `fix` | 修 bug |
| `refactor` | 內部重整、不改行為（舊歷史的 `R` 即此類，新 commit 一律用 `refactor`） |
| `style` | 純格式（swiftformat 輸出、空白） |
| `docs` | 文件／註解／`CLAUDE.md`／`.claude/` 指引 |
| `test` | 新增或調整測試 |
| `chore` | build、依賴、tooling、release 周邊 |
| `perf` | 效能 |
| `ci` | CI／CD 設定 |

## 範例

```
[feat][#26660] designer_bookings POST / PUT 一律帶 booking_start_time
[fix][#26561] 開票失敗時結帳提示改為「發票未開立」，不再只顯示結帳成功
[refactor][#26643] 移除已被 message_center WebView 取代的原生訊息中心
[feat][EZLabelPrinter][#26532] 標籤類型列接上桌號
[test][EZCore] 補上 AutoDecode 選填欄位的預設值測試
[chore][Tooling] 新增五 repo 共用 code-review skill
```

## 版號與 release

沿用既有慣例，前綴是版號不是 type：

```
[v48.4(1)] Merge branch 'feat/#26772' into release/v48.4   ← release 分支的 merge commit
[v14.3(1)] 版號更新                                          ← 版號 bump
```

`(N)` 是該版第 N 次合併／bump。歷史上的 `🚀` 前綴是 2022 年以前的舊寫法，不再使用。

## body

- 有行為變化的 commit MUST 有 body，**逐情境陳述**（iPhone／iPad、美業／餐飲、新增／編輯、各訂單狀態、各付款方式、新舊版相容），NEVER 用「不影響其他情境」一句總括
- 寫「為什麼不那樣做」：刻意不收攏、不抽象、不加分支的地方要交代理由
- 動到送後端的欄位 → 寫明欄位名來源（`api-field-contract.md` 四種之一）與真實 API 前後 GET 對照結果
- 動到 framework → 註明兩個 App 的驗編譯結果；跨 repo 的改動互相指名對方 repo 的分支

## 硬規則

- **subject 繁體中文**，陳述做了什麼；NEVER 寫「修改了一些東西」這種無資訊描述
- **票號從分支名取**，NEVER 憑記憶打；沒票才用 `[Module]`
- **type 從上表取**，NEVER 自創（`NA`、`Feat` 大寫這類是舊歷史，不要照抄）
- **句尾不加句號**
- 一個 commit 一個關注點；要整理歷史用 `tidy-commits` skill
