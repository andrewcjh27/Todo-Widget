# Todo Widget

A macOS menu bar todo app built with SwiftUI. Keeps daily, weekly, and monthly task lists accessible from the top menu bar, with local persistence via UserDefaults.

## Features

- **Menu bar app** — lives in the macOS menu bar for quick access
- **Multiple lists** — switch between daily, weekly, and monthly views
- **Weekly planner** — dedicated weekly planning view
- **Local persistence** — tasks saved automatically via UserDefaults
- **Launch at login** — optional, set from the widget

## Tech Stack

- Swift 6 / SwiftUI
- macOS 13+
- Swift Package Manager

## Install

Paste this into Terminal (requires macOS 13 or later):

```
curl -fsSL https://raw.githubusercontent.com/andrewcjh27/Todo-Widget/main/scripts/install.sh | bash
```

This downloads the latest release into your Applications folder and opens it. You can [read the script](scripts/install.sh) first.

Todo Widget is free and isn't notarized by Apple, so installing from the [Releases](https://github.com/andrewcjh27/Todo-Widget/releases) page instead may show a macOS security warning. To turn on launch at login, tick the checkbox at the bottom of the widget.

To uninstall, untick launch at login, then delete `TodoWidget.app` from your Applications folder.

## Build from source

Requires Xcode 26 or later.

```
scripts/build-app.sh 1.0.0
open dist/TodoWidget.app
```

To run it during development:

```
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
swift run --scratch-path .build/scratch
```

## Publishing a release

Pushing a version tag builds the app and publishes it to GitHub Releases:

```
git tag v1.0.0
git push origin v1.0.0
```

## License

[MIT](LICENSE)
