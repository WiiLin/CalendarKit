# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 共用規則檔（五個 repo 必須同步）

EZPretty iOS 的五個 repo 共用同一份 `.claude/rules/`、`.claude/skills/{code-review,tidy-commits,commit-message,_shared}/`、`.claude/docs/`，**內容逐 byte 相同**：

| repo | 角色 | 路徑 |
|---|---|---|
| `provider-ios` | iPhone 店家 App（ezDesigner） | `/Users/wiilin/Documents/iOS/EZPretty/provider-ios` |
| `ezstore-ios` | iPad POS（ezStore） | `/Users/wiilin/Documents/iOS/EZPretty/ezstore-ios` |
| `ez-framework-ios` | 共用 SPM package（EZPrinterKit） | `/Users/wiilin/Documents/iOS/EZPretty/ez-framework-ios` |
| `ezhair-ios` | 消費者端 App（ezHair） | `/Users/wiilin/Documents/iOS/EZPretty/ezhair-ios` |
| `CalendarKit` | 行事曆 UI library（fork） | `/Users/wiilin/Documents/iOS/EZPretty/CalendarKit` |

現有規則檔（每輪自動載入）：

- `.claude/rules/ai-core-rules.md` —— AI 行為鐵律（NEVER / MUST）、任務分級、動手前宣告、抽象化與送審前自檢、呼叫點稽核、Post-Edit Verification、Checkpoint
- `.claude/rules/evidence-driven-bugfix.md` —— 證據驅動除錯 8 步法、靜默失敗四層定位、wiring test 與 sabotage 鐵律
- `.claude/rules/session-retrospective.md` —— 任務結束前把通則回寫 rules / skill / CLAUDE.md（本專案群不用 memory 系統）
- `.claude/rules/ui-view-structure.md` —— UI 元件結構（可複用區塊抽成 `UIView` 子類、closure `private let` 宣告、`UIStackView.vstack/.hstack` 在宣告處填滿、callback 回傳完整物件、顏色集中到色票檔）
- `.claude/rules/api-field-contract.md` —— API 欄位契約（NEVER 自創後端欄位名、欄位來源四種、送出後用真實 API 前後 GET 對照驗證、既有欄位優先）

共用 skill 與文件：

- `.claude/skills/code-review/` —— 審查引擎，合併前 local review 迴圈走它；`references/` 含 STANDARDS / TESTING / CONVENTIONS / OUTPUT-FORMAT
- `.claude/skills/tidy-commits/`、`.claude/skills/commit-message/` —— 整份共用，不含任何 repo 專屬段落；gate 指令、commit type 一律讀該 repo `CLAUDE.md` 與 commit-message skill
- `.claude/skills/_shared/skill-template.md` —— 新 skill 一律從這份範本起（7 段式提示契約）
- `.claude/docs/ai-engineer-persona.md` —— **僅當任務是「寫／改 skill、rules、本指引體系」時才讀**；寫 Swift / 修 bug NEVER 需要它

### 同步鐵律

- 改動任一 repo 的共用檔，**MUST 同步套用到其餘四個**，NEVER 只改一邊。
- 同步後 **MUST 用 checksum 驗證五份逐 byte 相同**（五行輸出的 hash 必須一樣）：
  ```bash
  cd /Users/wiilin/Documents/iOS/EZPretty
  for d in CalendarKit ezhair-ios ezstore-ios provider-ios ez-framework-ios; do
    echo "$d: $(cat "$d"/.claude/rules/*.md "$d"/.claude/skills/code-review/SKILL.md "$d"/.claude/skills/code-review/references/*.md "$d"/.claude/skills/tidy-commits/SKILL.md "$d"/.claude/skills/commit-message/SKILL.md "$d"/.claude/skills/_shared/*.md "$d"/.claude/docs/*.md | shasum | cut -d' ' -f1)"
  done
  ```
- `CLAUDE.md` 的**共用章節**（本章節、共用邏輯歸屬、commit 規範）同樣五份同步；**專案專屬內容**（build 指令、目錄結構、該 repo 才有的 gotcha）留在各自 `CLAUDE.md`，NEVER 塞進共用 rules 檔。
- 規則檔每輪都會載入，**膨脹本身就是傷害**：新增規則優先併入既有條目、案例只留一行 tell（`session-retrospective.md` Step 2）。

## Project Overview

CalendarKit is a Swift calendar UI library for iOS/iPadOS/Mac Catalyst that provides an Apple Calendar-like interface. It uses UIKit, targets iOS 9.0+, and has no external dependencies.

## Build & Development

**Swift Package Manager (primary):**
```bash
swift build
```

**CocoaPods:**
```bash
cd CalendarKitDemo && pod install
# Then open .xcworkspace in Xcode
```

**Linting (SwiftFormat):**
```bash
swiftformat Source/
```

There is no test suite in this project. Use the `CalendarKitDemo/` app for manual verification.

## Code Style

- 2-space indentation (spaces, not tabs)
- No file headers
- Opening braces on same line as code
- SwiftFormat config: `--disable unusedArguments`, `--trimwhitespace nonblank-lines`

## Architecture

### View Hierarchy

```
DayViewController (main entry point, subclass this)
  └── DayView (root container)
        ├── DayHeaderView (date display + navigation)
        │     ├── DaySelector/ (date picker chips)
        │     ├── SwipeLabelView (month/year label)
        │     └── GroupNameView (group name display)
        └── TimelinePagerView (horizontal day paging)
              └── TimelineContainerController (one per visible day)
                    └── TimelineView (hourly grid + events)
                          ├── EventView (individual event blocks)
                          ├── AllDayView (all-day event bar)
                          └── CurrentTimeIndicator
```

### Key Protocols

- **`EventDataSource`** — Implement `eventsForDate(_:)` to provide events
- **`EventDescriptor`** — Protocol defining event properties (start/end date, text, color, etc.). `Event` is the default concrete class.
- **`DayViewDelegate`** — Handles user interactions (tap, long-press, event creation/editing)
- **`DayViewStateUpdating`** — Observer protocol for state changes across views

### Event Editing Pattern

Events use a clone-edit-commit workflow:
1. `makeEditable()` — creates a mutable copy for drag editing
2. User drags handles to resize/move (snaps to 15-min intervals)
3. `commitEditing()` — finalizes changes back to the original

### Performance

- **`ReusePool<EventView>`** — shared event view recycling pool across all timeline instances
- Group/column layout is calculated dynamically based on overlapping events
- Layout calculations are batched with performance timing instrumentation

### Styling

Customization via `CalendarStyle` struct with nested style objects (`TimelineStyle`, `DayHeaderStyle`, `DaySelectorStyle`, etc.). Apply via `dayView.updateStyle(style)`.

### Localization

12 languages supported via `.lproj` bundles in `Localizations/`. Uses iOS system locale for month/day names and first day of week.

## Source Layout

- `Source/Timeline/` — Timeline rendering, event views, all-day view, paging
- `Source/Header/` — Day header, date selector, group name
- `Source/Extensions/` — Date, UIColor, and other utility extensions
- `Source/DayViewController.swift` — Main public API entry point
- `Source/DayViewState.swift` — Observable state management (observer pattern)
- `Source/CalendarStyle.swift` — All style/theme configuration
