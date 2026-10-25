import AppKit
import os

let appBundleID = "com.satejbidvai.air-traffic-control"
let diaBundleID = "company.thebrowser.dia"
let logger = Logger(subsystem: appBundleID, category: "routing")
let rulesFile = FileManager.default.homeDirectoryForCurrentUser
    .appendingPathComponent(".config/air-traffic-control/rules.json")

struct Rule: Decodable {
    let url: String?
    let app: String?
    let profile: String
}

struct Config: Decodable {
    let rules: [Rule]
}

func loadRules() -> [Rule] {
    do {
        let data = try Data(contentsOf: rulesFile)
        return try JSONDecoder().decode(Config.self, from: data).rules
    } catch {
        logger.error("Cannot read rules: \(String(describing: error), privacy: .public)")
        return []
    }
}

/// Domain matches itself and all subdomains. Path prefix matches only on a full path segment.
func matches(pattern: String, url: URL) -> Bool {
    guard let host = url.host?.lowercased() else { return false }
    var pattern = pattern.lowercased()
    if let scheme = pattern.range(of: "://") {
        pattern = String(pattern[scheme.upperBound...])
    }
    let parts = pattern.split(separator: "/", maxSplits: 1)
    guard let domain = parts.first.map(String.init) else { return false }
    guard host == domain || host.hasSuffix("." + domain) else { return false }
    guard parts.count > 1 else { return true }

    var prefix = "/" + String(parts[1])
    while prefix.hasSuffix("/") { prefix.removeLast() }
    if prefix.isEmpty { return true }
    let path = url.path.lowercased()
    return path == prefix || path.hasPrefix(prefix + "/")
}

func profile(for url: URL, sourceApp: String?) -> String? {
    for rule in loadRules() {
        if rule.url == nil && rule.app == nil {
            logger.error("Skipped rule for \(rule.profile, privacy: .public): it has no url and no app")
            continue
        }
        if let pattern = rule.url, !matches(pattern: pattern, url: url) { continue }
        if let app = rule.app, app.lowercased() != sourceApp?.lowercased() { continue }
        return rule.profile
    }
    return nil
}

func appleScriptString(_ value: String) -> String {
    let escaped = value
        .replacingOccurrences(of: "\\", with: "\\\\")
        .replacingOccurrences(of: "\"", with: "\\\"")
    return "\"\(escaped)\""
}

func openInProfile(_ url: URL, profile: String) -> Bool {
    let source = """
    tell application id "\(diaBundleID)"
        set p to first profile of window 1 whose name is \(appleScriptString(profile))
        set t to make new tab at end of tabs of p
        set URL of t to \(appleScriptString(url.absoluteString))
        focus t
        activate
    end tell
    """
    var error: NSDictionary?
    NSAppleScript(source: source)?.executeAndReturnError(&error)
    if let error {
        let message = error[NSAppleScript.errorMessage] as? String ?? String(describing: error)
        logger.error("AppleScript failed for \(profile, privacy: .public): \(message, privacy: .public)")
        return false
    }
    return true
}

/// Opens the Link in Dia without a Profile choice. This path cannot loop back into this app.
func passThrough(_ url: URL) {
    guard let dia = NSWorkspace.shared.urlForApplication(withBundleIdentifier: diaBundleID) else {
        logger.error("Dia is not installed")
        return
    }
    NSWorkspace.shared.open([url], withApplicationAt: dia, configuration: NSWorkspace.OpenConfiguration())
}

func route(_ url: URL, sourceApp: String?) {
    let host = url.host ?? "?"
    let source = sourceApp ?? "unknown"
    guard let profile = profile(for: url, sourceApp: sourceApp) else {
        logger.info("\(host, privacy: .public) from \(source, privacy: .public): no rule, pass-through")
        passThrough(url)
        return
    }
    if openInProfile(url, profile: profile) {
        logger.info("\(host, privacy: .public) from \(source, privacy: .public): opened in \(profile, privacy: .public)")
    } else {
        passThrough(url)
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationWillFinishLaunching(_ notification: Notification) {
        NSAppleEventManager.shared().setEventHandler(
            self,
            andSelector: #selector(handleGetURL(_:withReply:)),
            forEventClass: AEEventClass(kInternetEventClass),
            andEventID: AEEventID(kAEGetURL)
        )
    }

    @objc func handleGetURL(_ event: NSAppleEventDescriptor, withReply reply: NSAppleEventDescriptor) {
        guard let string = event.paramDescriptor(forKeyword: keyDirectObject)?.stringValue,
              let url = URL(string: string)
        else {
            logger.error("Dropped a link that is not a valid URL")
            return
        }
        route(url, sourceApp: sourceApp(of: event))
    }

    /// macOS lists a default browser only if it claims HTML files. Dia opens these files.
    func application(_ application: NSApplication, open urls: [URL]) {
        urls.forEach(passThrough)
    }

    /// macOS sends a Handoff page here only if Info.plist claims NSUserActivityTypeBrowsingWeb.
    func application(
        _ application: NSApplication,
        continue userActivity: NSUserActivity,
        restorationHandler: @escaping ([any NSUserActivityRestoring]) -> Void
    ) -> Bool {
        guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
              let url = userActivity.webpageURL
        else { return false }
        route(url, sourceApp: nil)
        return true
    }

    private func sourceApp(of event: NSAppleEventDescriptor) -> String? {
        guard let pid = event.attributeDescriptor(forKeyword: AEKeyword(keySenderPIDAttr))?.int32Value,
              pid > 0
        else { return nil }
        return NSRunningApplication(processIdentifier: pid)?.bundleIdentifier
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
