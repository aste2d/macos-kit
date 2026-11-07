import AppKit
import ApplicationServices
import Darwin

struct DetectionError: Error, CustomStringConvertible {
    let description: String
    init(_ text: String) { description = text }
}

func attribute(_ element: AXUIElement, _ key: String) -> CFTypeRef? {
    var value: CFTypeRef?
    guard AXUIElementCopyAttributeValue(element, key as CFString, &value) == .success else { return nil }
    return value
}

func label(_ element: AXUIElement) -> String {
    // SwiftUI buttons can expose their label as an attributed description.
    if let text = attribute(element, "AXAttributedDescription") as? NSAttributedString {
        return text.string.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    for key in ["AXTitle", "AXDescription"] {
        if let text = attribute(element, key) as? String, !text.isEmpty { return text }
    }
    return ""
}

func buttons(_ root: AXUIElement, deadline: TimeInterval) -> [(AXUIElement, String)] {
    var queue = attribute(root, "AXWindows") as? [AXUIElement] ?? []
    var result: [(AXUIElement, String)] = []
    var index = 0
    while index < queue.count && index < 1500 && ProcessInfo.processInfo.systemUptime < deadline {
        let element = queue[index]
        index += 1
        AXUIElementSetMessagingTimeout(element, 0.3)
        if attribute(element, "AXRole") as? String == "AXButton" {
            result.append((element, label(element)))
        }
        queue += attribute(element, "AXChildren") as? [AXUIElement] ?? []
    }
    return result
}

func optionEvent(down: Bool) throws -> CGEvent {
    guard let event = CGEvent(keyboardEventSource: nil, virtualKey: 58, keyDown: down), event.type == .flagsChanged else {
        throw DetectionError("Cannot create the Option modifier event.")
    }
    return event
}

func pause(_ duration: TimeInterval) {
    RunLoop.current.run(until: Date().addingTimeInterval(duration))
}

func detect() throws {
    guard AXIsProcessTrusted() else { throw DetectionError("Accessibility permission is required for the shortcut launcher.") }
    guard CGPreflightPostEventAccess() else { throw DetectionError("Permission to send the Option key is required for the shortcut launcher.") }
    let opener = Process()
    opener.executableURL = URL(fileURLWithPath: "/usr/bin/open")
    opener.arguments = ["x-apple.systempreferences:com.apple.Displays-Settings.extension"]
    try opener.run()
    opener.waitUntilExit()
    guard opener.terminationStatus == 0 else { throw DetectionError("Cannot open Displays settings.") }

    let loadDeadline = ProcessInfo.processInfo.systemUptime + 7
    var settings: NSRunningApplication?
    repeat {
        settings = NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.systempreferences").first
        if settings != nil { break }
        pause(0.1)
    } while ProcessInfo.processInfo.systemUptime < loadDeadline
    guard let settings else { throw DetectionError("System Settings did not start.") }
    settings.activate()
    let root = AXUIElementCreateApplication(settings.processIdentifier)
    AXUIElementSetMessagingTimeout(root, 0.5)
    let detectLabels: Set<String> = ["检测显示器", "Detect Displays"]
    let readyLabels = detectLabels.union(["夜览…", "夜览...", "Night Shift…", "Night Shift...", "高级…", "Advanced…"])
    let readyDeadline = min(loadDeadline, ProcessInfo.processInfo.systemUptime + 4)
    repeat {
        if settings.isActive && buttons(root, deadline: readyDeadline).contains(where: { readyLabels.contains($0.1) }) { break }
        pause(0.1)
    } while ProcessInfo.processInfo.systemUptime < readyDeadline
    guard settings.isActive else { throw DetectionError("System Settings is not active; no key or button action was sent.") }

    let down = try optionEvent(down: true)
    // Construct release before posting down, so every ordinary exit can release.
    let up = try optionEvent(down: false)
    defer { up.post(tap: .cghidEventTap) }
    down.post(tap: .cghidEventTap)

    let searchDeadline = ProcessInfo.processInfo.systemUptime + 5
    repeat {
        let matches = buttons(root, deadline: searchDeadline).filter { detectLabels.contains($0.1) }
        if matches.count > 1 { throw DetectionError("Multiple Detect Displays buttons found; no button was pressed.") }
        if let (button, _) = matches.first {
            guard (attribute(button, "AXEnabled") as? NSNumber)?.boolValue == true else {
                throw DetectionError("Detect Displays is disabled; no button was pressed.")
            }
            var actions: CFArray?
            guard AXUIElementCopyActionNames(button, &actions) == .success,
                  (actions as? [String] ?? []).contains("AXPress") else {
                throw DetectionError("Detect Displays has no accessible press action.")
            }
            guard detectLabels.contains(label(button)) else { throw DetectionError("Button changed before pressing; no button was pressed.") }
            let result = AXUIElementPerformAction(button, "AXPress" as CFString)
            guard result == .success else { throw DetectionError("Detect Displays action returned \(result.rawValue); result is not confirmed.") }
            print("DETECT_CLICKED")
            return
        }
        pause(0.1)
    } while ProcessInfo.processInfo.systemUptime < searchDeadline
    throw DetectionError("Detect Displays button was not found; no button was pressed.")
}

do {
    if CommandLine.arguments.contains("--release-option") {
        guard CGPreflightPostEventAccess() else { throw DetectionError("Option release is not permitted.") }
        try optionEvent(down: false).post(tap: .cghidEventTap)
    } else if CommandLine.arguments.contains("--version") {
        print("Detect Displays 1.0")
    } else {
        let cache = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Caches/aste2d-macos-kit")
        try FileManager.default.createDirectory(at: cache, withIntermediateDirectories: true, attributes: [.posixPermissions: 0o700])
        let fd = Darwin.open(cache.appendingPathComponent("display-detection.lock").path, O_CREAT | O_RDWR, 0o600)
        guard fd >= 0 else { throw DetectionError("Cannot open the detection lock.") }
        defer { Darwin.close(fd) }
        guard flock(fd, LOCK_EX | LOCK_NB) == 0 else { exit(0) }
        let deadline = ProcessInfo.processInfo.systemUptime + 4
        let modifiers: CGEventFlags = [.maskCommand, .maskControl, .maskAlternate, .maskShift]
        while !CGEventSource.flagsState(.combinedSessionState).intersection(modifiers).isEmpty {
            guard ProcessInfo.processInfo.systemUptime < deadline else { throw DetectionError("Release Hyper and try again.") }
            pause(0.04)
        }
        try detect()
    }
} catch {
    fputs("\(error)\n", stderr)
    exit(1)
}
