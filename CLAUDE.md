# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 共用規則檔（五個 repo 必須同步）

EZPretty iOS 的五個 repo 共用同一份 `.claude/rules/`，**內容逐 byte 相同**：

| repo | 角色 | 路徑 |
|---|---|---|
| `provider-ios` | iPhone 店家 App（ezDesigner） | `/Users/wiilin/Documents/iOS/EZPretty/provider-ios` |
| `ezstore-ios` | iPad POS（ezStore） | `/Users/wiilin/Documents/iOS/EZPretty/ezstore-ios` |
| `ez-framework-ios` | 共用 SPM package（EZPrinterKit） | `/Users/wiilin/Documents/iOS/EZPretty/ez-framework-ios` |
| `ezhair-ios` | 消費者端 App（ezHair） | `/Users/wiilin/Documents/iOS/EZPretty/ezhair-ios` |
| `CalendarKit` | 行事曆 UI library（fork） | `/Users/wiilin/Documents/iOS/EZPretty/CalendarKit` |

現有規則檔：

- `.claude/rules/ui-view-structure.md` —— UI 元件結構（可複用區塊抽成 `UIView` 子類、closure `private let` 宣告、`UIStackView.vstack/.hstack` 在宣告處填滿、callback 回傳完整物件、顏色集中到色票檔）

### 同步鐵律

- 改動任一 repo 的 `.claude/rules/*.md`，**MUST 同步套用到其餘四個**，NEVER 只改一邊。
- 同步後 **MUST 用 checksum 驗證五份逐 byte 相同**：
  ```bash
  cd /Users/wiilin/Documents/iOS/EZPretty
  for d in CalendarKit ezhair-ios ezstore-ios provider-ios ez-framework-ios; do
    shasum "$d/.claude/rules/ui-view-structure.md"
  done
  ```
- `CLAUDE.md` 的**共用章節**（本章節、共用邏輯歸屬、commit 規範）同樣五份同步；**專案專屬內容**（build 指令、目錄結構、該 repo 才有的 gotcha）留在各自 `CLAUDE.md`，NEVER 塞進共用 rules 檔。
- `.claude/skills/` 的共用 skill（`tidy-commits`、`commit-message`）同理：規則本體改一份要同步其餘，gate 指令這類專案專屬段落各自保留。

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
