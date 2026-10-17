import Cocoa
import WebKit

final class Tracker: NSObject, NSApplicationDelegate, WKUIDelegate, WKNavigationDelegate {
    var window: NSWindow!
    var web: WKWebView!
    let testing = CommandLine.arguments.contains("--smoke-test")
    var phase = 0
    var dataURL: URL {
        if testing { return URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("leetcode-tracker-smoke-\(ProcessInfo.processInfo.processIdentifier)/progress.json") }
        return FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("LeetCode Tracker/progress.json")
    }
    func applicationDidFinishLaunching(_ notification: Notification) {
        let menu = NSMenu()
        let appItem = NSMenuItem(); menu.addItem(appItem)
        let appMenu = NSMenu(); appItem.submenu = appMenu
        appMenu.addItem(withTitle: "Quit LeetCode Tracker", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        let edit = NSMenuItem(); edit.title = "Edit"; menu.addItem(edit)
        let editMenu = NSMenu(title: "Edit"); edit.submenu = editMenu
        for (title, action, key) in [("Undo", "undo:", "z"), ("Cut", "cut:", "x"), ("Copy", "copy:", "c"), ("Paste", "paste:", "v"), ("Select All", "selectAll:", "a")] {
            editMenu.addItem(withTitle: title, action: Selector(action), keyEquivalent: key)
        }
        let windowItem = NSMenuItem(); windowItem.title = "Window"; menu.addItem(windowItem)
        let windowMenu = NSMenu(title: "Window"); windowItem.submenu = windowMenu
        let minimize = windowMenu.addItem(withTitle: "Minimize", action: #selector(NSWindow.performMiniaturize(_:)), keyEquivalent: "m")
        minimize.keyEquivalentModifierMask = [.command]
        NSApp.windowsMenu = windowMenu
        NSApp.mainMenu = menu
        let config = WKWebViewConfiguration()
        config.websiteDataStore = .nonPersistent()
        web = WKWebView(frame: .zero, configuration: config)
        web.uiDelegate = self; web.navigationDelegate = self
        window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 1200, height: 820), styleMask: [.titled, .closable, .miniaturizable, .resizable], backing: .buffered, defer: false)
        window.title = "LeetCode Tracker"; window.contentView = web; window.center()
        window.makeKeyAndOrderFront(nil); NSApp.activate(ignoringOtherApps: true)
        let url = Bundle.main.url(forResource: "tracker", withExtension: "html")!
        web.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
    }
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }
    func validate(_ text: String) throws -> Data {
        let data = Data(text.utf8)
        guard let obj = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let items = obj["items"] as? [String: Any] else { throw NSError(domain: "Invalid progress file", code: 1) }
        for (_, value) in items {
            guard let item = value as? [String: Any], let status = item["status"] as? String,
                  ["todo", "in-progress", "done"].contains(status), item["notes"] is String else {
                throw NSError(domain: "Invalid problem record", code: 2)
            }
        }
        return data
    }
    func handle(_ command: String, value: String?) throws -> Any {
        switch command {
        case "load":
            if !FileManager.default.fileExists(atPath: dataURL.path) { return NSNull() }
            let text = try String(contentsOf: dataURL, encoding: .utf8)
            _ = try validate(text); return text
        case "save":
            let data = try validate(value ?? "")
            try FileManager.default.createDirectory(at: dataURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            if FileManager.default.fileExists(atPath: dataURL.path) {
                let previous = try Data(contentsOf: dataURL)
                let oldObject = try JSONSerialization.jsonObject(with: previous) as? [String: Any]
                let newObject = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                let backup = dataURL.deletingLastPathComponent().appendingPathComponent("progress-before-shared-status.json")
                if (oldObject?["version"] as? Int ?? 1) < 2,
                   (newObject?["version"] as? Int ?? 1) >= 2,
                   !FileManager.default.fileExists(atPath: backup.path) {
                    try previous.write(to: backup, options: .atomic)
                }
            }
            // Atomic replacement prevents a partial JSON file if the app is interrupted.
            try data.write(to: dataURL, options: .atomic)
            return true
        case "export":
            let data = try validate(value ?? "")
            let panel = NSSavePanel(); panel.nameFieldStringValue = "leetcode-progress.json"
            if panel.runModal() == .OK, let url = panel.url { try data.write(to: url, options: .atomic) }
            return true
        default: throw NSError(domain: "Unknown tracker command", code: 3)
        }
    }
    func webView(_ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (String?) -> Void) {
        guard prompt == "tracker-native", frame.isMainFrame, frame.request.url?.isFileURL == true else { completionHandler(nil); return }
        let result: [String: Any]
        do {
            let request = try JSONSerialization.jsonObject(with: Data((defaultText ?? "").utf8)) as? [String: Any]
            result = ["value": try handle(request?["command"] as? String ?? "", value: request?["value"] as? String)]
        } catch { result = ["error": error.localizedDescription] }
        completionHandler(String(data: try! JSONSerialization.data(withJSONObject: result), encoding: .utf8))
    }
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        let alert = NSAlert(); alert.messageText = message; alert.runModal(); completionHandler()
    }
    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        let alert = NSAlert(); alert.messageText = message; alert.addButton(withTitle: "Reset"); alert.addButton(withTitle: "Cancel")
        completionHandler(alert.runModal() == .alertFirstButtonReturn)
    }
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url else { decisionHandler(.cancel); return }
        if url.isFileURL { decisionHandler(.allow); return }
        if navigationAction.navigationType == .linkActivated, ["https", "http"].contains(url.scheme ?? "") { NSWorkspace.shared.open(url) }
        decisionHandler(.cancel)
    }
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        guard testing else { return }
        if phase == 0 {
            phase = 1
            do {
                try FileManager.default.createDirectory(at: dataURL.deletingLastPathComponent(), withIntermediateDirectories: true)
                try Data("{\"version\":1,\"items\":{}}".utf8).write(to: dataURL, options: .atomic)
            } catch { fail(error.localizedDescription); return }
            web.evaluateJavaScript("document.querySelector('[data-id=\"nc-217\"] [data-act=status]').click(); var t=document.querySelector('[data-id=\"nc-217\"] textarea'); t.value='Persistence test ✓'; t.dispatchEvent(new Event('input',{bubbles:true}));") { _, error in
                if let error = error { self.fail(error.localizedDescription); return }
                do {
                    let data = try Data(contentsOf: self.dataURL)
                    let backup = try String(contentsOf: self.dataURL.deletingLastPathComponent().appendingPathComponent("progress-before-shared-status.json"), encoding: .utf8)
                    guard backup == "{\"version\":1,\"items\":{}}" else { self.fail("Legacy backup mismatch"); return }
                    let obj = try JSONSerialization.jsonObject(with: data) as! [String: Any]
                    let item = (obj["items"] as! [String: Any])["nc-217"] as! [String: Any]
                    guard item["notes"] as? String == "Persistence test ✓", item["status"] as? String == "in-progress" else { self.fail("Disk save mismatch"); return }
                    self.web.reload()
                } catch { self.fail(error.localizedDescription) }
            }
        } else {
            web.evaluateJavaScript("document.querySelectorAll('#lists .row').length === 380 && document.querySelector('[data-id=\"nc-217\"] textarea').value === 'Persistence test ✓' && document.querySelector('[data-id=\"nc-217\"] .st').classList.contains('st-prog') && document.querySelector('[data-id=\"additional-217\"] .st').classList.contains('st-prog') && document.getElementById('fatal').style.display !== 'block'") { value, error in
                guard error == nil, value as? Bool == true else { self.fail("Reload mismatch: \(String(describing: error))"); return }
                try? FileManager.default.removeItem(at: self.dataURL.deletingLastPathComponent())
                print("PASS: 380 entries rendered; legacy backup preserved; shared status and immediate note saved to disk and restored after reload.")
                NSApp.terminate(nil)
            }
        }
    }
    func fail(_ message: String) { fputs("FAIL: \(message)\n", stderr); exit(1) }
}
let app = NSApplication.shared
let delegate = Tracker()
app.delegate = delegate
app.setActivationPolicy(.regular)
app.run()
