# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 共用 AI 指引（symlink 到兄弟目錄）

@.agents/shared/GUIDELINES.md

正本是兄弟目錄 `../ezpretty-agent-guidelines`（clone 自 github `wiilinxxxxxx/ezpretty-agent-guidelines`），`.agents/shared` 是指向它的 symlink；`.claude/rules` 與 `.claude/skills/{code-review,tidy-commits,commit-message,release-merge,_shared}` 再指進去。**換機器要先在 `EZPretty/` 同層 clone 該 repo**，否則 rules 與 skills 靜默不載入——開工前 `ls .agents/shared/rules` 確認非空。改共用指引：直接在該 clone 改、commit、push，五個 repo 立即生效，沒有 bump 這回事；新增 skill 時各 repo 補一個 `.claude/skills/<name>` symlink。

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
