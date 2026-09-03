# API 欄位契約

> **EZPretty iOS 五個 repo 共用正本，五份內容逐 byte 相同。** 改這份 = 五份一起改，見各 repo `CLAUDE.md` 的「共用規則檔」章節。
>
> 適用範圍：所有送往後端的 request 欄位 —— 新增欄位、改名、改語意都算。

## 鐵則

- **NEVER 自己發明後端欄位名。** request 只能帶「已確認後端會讀」的欄位。前端自創的欄位，後端照常回 `200 success` 然後整包丟掉 —— 看起來成功、實際無效，而且從 App 端完全看不出差別。

- **欄位來源 MUST 是下列之一**，並在 commit message 寫明是哪一個：
  1. API 文件 / Swagger
  2. 後端 repo（`ezhair-web`）的實際程式
  3. Redmine 單上**明文寫出**欄位名
  4. 後端 RD 的書面確認（Redmine 回覆／訊息），且該確認要貼回單裡留紀錄

  > 單上寫「欄位名稱由 RD 依 API 規範決定」＝**要求你去協調**，NEVER 讀成「授權前端自行命名」。

- **來源不明就不要寫進 request。** 缺欄位就是缺欄位：當成阻塞回報到單上，NEVER 先送一個猜的名字、再用 commit message 註記「待後端支援」蓋過去 —— 那不是完成，是把一個不會生效的功能推進送測流程，QA 必退。

- **後端回 200 不等於欄位生效。** 動到送出欄位後 MUST 用真實 API 驗證：送出前 GET、送出、再 GET，比對目標欄位真的變了。只看 HTTP status 或 `success: true` 一律不算驗證。

- **既有欄位優先。** 要表達新語意前，先翻 GET 回應裡後端已經有的欄位（訂金相關就有 `deposit` / `deposit_flag` / `set_deposit_person`），確認有無現成機制可用，再談請後端開新欄位。

- **同一支 API 在多個 repo 共用時**（`provider-ios` / `ezstore-ios` 的 `designer_bookings`），欄位名與送出條件 MUST 一致，兩邊 commit message 互相指名。

## 反例：#26217 `clear_deposit`

單子寫「實際欄位名稱由 RD 依 API 規範決定」，前端逕自定了 `clear_deposit`，兩個 App 都送出，commit message 標註「需後端同步支援」就進了送測。

實測（`PUT /api_v17/designer_bookings/{id}.json`，帶 `deposit: 0` + `clear_deposit: 1`）：後端回 `200 {"success":true,"data":{"status":2}}`，但重新 GET 後 `deposit` 仍是原值、`paymethod=7` 的付款紀錄原封不動。**功能從第一天就沒生效，卻走完了整個開發到送測流程。**

## 自我檢查（動到 request 欄位就掃一遍）

- [ ] 這個欄位名我能指出來源（文件／後端程式／單上明文／RD 書面確認）
- [ ] 沒有把「單上說由 RD 決定」當成自己取名的授權
- [ ] 已用真實 API 前後 GET 對照，確認後端真的吃了這個欄位
- [ ] 多個 repo 共用同一支 API 時，欄位名與送出條件已同步
