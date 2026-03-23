# Todo Widget Learning Path (macOS Menu Bar)

This project is a minimal menu bar todo widget built with SwiftUI.

Goal: keep daily, weekly, and monthly tasks in a top menu bar app.

## 1. What we built

- `TodoWidgetApp.swift`: app entry point and menu bar icon.
- `TodoStore.swift`: data model + local persistence with `UserDefaults`.
- `TodoListView.swift`: UI for add, toggle complete, delete, and list switching.

## 2. Run it locally

Use Xcode's Swift toolchain:

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swift run --scratch-path .build/scratch
```

Or open the package in Xcode and click Run:

```bash
open Package.swift
```

When it runs, look for a `checklist` icon in the macOS menu bar.

## 3. Step-by-step learning checkpoints

### Step A - App shell

In `TodoWidgetApp.swift`, we use `MenuBarExtra` so the app lives in the top bar:

- app icon/title in menu bar
- popup window style (`.menuBarExtraStyle(.window)`)
- shared state injected with `.environmentObject(store)`

### Step B - Data model

In `TodoStore.swift`:

- `TodoBucket` splits data into `daily`, `weekly`, `monthly`
- `TodoItem` is one task (`title`, `isDone`, `createdAt`)
- `TodoStore` is the single source of truth

Core operations:

- `add(_:to:)`
- `toggle(_:in:)`
- `delete(_:in:)`

### Step C - Persistence

`TodoStore` encodes all lists to JSON and saves to `UserDefaults`.

This gives:

- data survives app restarts
- no database needed for a minimal app

### Step D - UI behavior

In `TodoListView.swift`:

- segmented picker to switch daily/weekly/monthly
- text field + add button
- task rows with complete + delete actions
- empty state when no tasks exist

## 4. Suggested practice exercises

Try these one-by-one to learn faster:

1. Add "Clear Completed" button for the selected list.
2. Sort tasks so incomplete items stay on top.
3. Add keyboard shortcut to focus the input field.
4. Add "Reset Daily Tasks" button.
5. Color-code list type (daily/weekly/monthly).

## 5. Next upgrade path

If you later want this as a true desktop WidgetKit widget:

- keep this menu bar app for fast capture
- add a second target with WidgetKit
- share data via App Group storage

This is the best path when you want both menu bar speed and home/desktop widgets.
