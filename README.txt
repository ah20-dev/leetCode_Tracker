LeetCode Tracker — local Mac app

Study lists: NeetCode 150, Custom List (123 entries), and Additional Problems
(107 entries), plus Learn: Data Structures and Patterns reference tabs.
Custom List rows include expandable problem details.

Double-click LeetCode Tracker.app in this folder to open it.
You can move the app to Applications or add it to your Dock.
Press Command-M (⌘M), or choose Window > Minimize, to minimize the window.

Every status change and note edit saves immediately to:
~/Library/Application Support/LeetCode Tracker/progress.json
The app restores that file on launch. Moving the app does not move or erase progress.
No account, server, browser storage, or internet connection is needed.
Clicking a LeetCode/source link opens that website in your default browser.

If you have progress in the old HTML tracker, open that original file in the
browser you used before, choose Download progress (JSON), then use Import
progress in this app once. The app cannot automatically read another browser's data.

Export backup (JSON) lets you save an extra copy anywhere you choose.
Import progress merges records from that JSON into the current tracker.
Reset clears statuses and notes after confirmation.
If saving fails, a red message appears at the top: export a backup before quitting.

The app uses the macOS built-in WebKit engine. Its source is in src/main.swift;
the bundled tracker HTML is in LeetCode Tracker.app/Contents/Resources/tracker.html.

Rolling 24-hour counter to track problem completion 

Build from source (macOS with Swift command-line tools installed)
Run from the project directory:
  swiftc src/main.swift -o /tmp/LeetCodeTracker -framework Cocoa -framework WebKit
  mv /tmp/LeetCodeTracker "LeetCode Tracker.app/Contents/MacOS/LeetCodeTracker"
  codesign --force --deep --sign - "LeetCode Tracker.app"

Validation
  node tests/daily-counter.cjs
  node tests/tracker.cjs (requires Playwright and Google Chrome)
  "./LeetCode Tracker.app/Contents/MacOS/LeetCodeTracker" --smoke-test
The native smoke test uses temporary progress, not your saved study data.
