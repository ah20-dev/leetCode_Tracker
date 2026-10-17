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

Additional Problems and shared status (v1.1)
- Additional Problems contains 107 distinct named LeetCode problems from the two
  interview PDFs, grouped like NeetCode. Each entry shows its source PDF/page.
  The supplied PDFs had no visible highlight annotations, so named problem lists
  and explicit examples were used. Repeated mentions appear once in this tab.
- Matching LeetCode numbers share To do / In progress / Done across all tabs.
  Changing a status back also updates every matching entry immediately.
- Custom List entries with multiple LeetCode links have individual status buttons.
  Their main row button changes all linked problems; the row is complete only
  when every linked problem is complete. The existing custom-problem mappings are used.
- Notes stay with their own entry to avoid overwriting separate notes.
- Older saves are migrated on load: Done takes precedence over In progress and
  To do if formerly independent copies disagree. New changes then stay in sync.
- The first save upgrading old data preserves the original JSON as:
  ~/Library/Application Support/LeetCode Tracker/progress-before-shared-status.json
- Export/import supports the new shared statuses and older progress backups.

Rolling 24-hour counter
The top-right counter counts unique problems currently marked done whose completion
was within the preceding 24 hours. There is no 8 AM start or midnight reset.
Each completion drops out exactly 24 hours later. Hover over the window label to
see its start and end in CST (fixed UTC-6 year-round).
Matching LeetCode IDs count once across tabs; standalone custom problems count too.
Undoing a completion removes it. Editing notes does not change completion time.
The counter uses saved status timestamps and survives reopening. It refreshes
while the app is open. Records without a known completion timestamp are excluded.

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
