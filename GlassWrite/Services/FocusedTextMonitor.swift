import Foundation
import ApplicationServices
import AppKit
import CryptoKit

struct FocusedTextSnapshot: Equatable {
    let appName: String
    let element: AXUIElement
    let textDigest: String
    let snippet: String
}

final class FocusedTextMonitor {
    var onChange: ((FocusedTextSnapshot?) -> Void)?
    var shouldReadText: () -> Bool = { true }
    private var timer: Timer?
    private var lastSnapshot: FocusedTextSnapshot?

    func start() {
        stop()
        timer = Timer.scheduledTimer(withTimeInterval: 0.35, repeats: true) { [weak self] _ in self?.poll() }
        if let timer { RunLoop.main.add(timer, forMode: .common) }
    }
    func stop() {
        timer?.invalidate()
        timer = nil
        lastSnapshot = nil
        onChange?(nil)
    }
    static func accessibilityTrusted(prompt: Bool = false) -> Bool {
        if prompt {
            let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
            return AXIsProcessTrustedWithOptions(options)
        }
        return AXIsProcessTrusted()
    }
    private func attribute(_ element: AXUIElement, _ name: String) -> CFTypeRef? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, name as CFString, &value) == .success else { return nil }
        return value
    }
    private func focusedElement() -> AXUIElement? {
        guard Self.accessibilityTrusted(), let value = attribute(AXUIElementCreateSystemWide(), kAXFocusedUIElementAttribute),
              CFGetTypeID(value) == AXUIElementGetTypeID() else { return nil }
        let element = value as! AXUIElement
        var pid: pid_t = 0
        guard AXUIElementGetPid(element, &pid) == .success, pid != getpid() else { return nil }
        return element
    }
    // Read role/security metadata BEFORE requesting AXValue. Never inspect secure-field contents.
    private func readable(_ element: AXUIElement) -> Bool {
        let metadata = [kAXTitleAttribute, kAXDescriptionAttribute, kAXHelpAttribute, kAXIdentifierAttribute, "AXPlaceholderValue"].compactMap { attribute(element, $0) as? String }
        return TextSafety.isReadable(role: attribute(element, kAXRoleAttribute) as? String,
                                     subrole: attribute(element, kAXSubroleAttribute) as? String,
                                     protected: (attribute(element, "AXProtectedContent") as? Bool) == true,
                                     metadata: metadata)
    }
    private func digest(_ text: String) -> String {
        SHA256.hash(data: Data(text.utf8)).map { String(format: "%02x", $0) }.joined()
    }
    func currentSnapshot() -> FocusedTextSnapshot? {
        guard let element = focusedElement(), readable(element),
              let text = attribute(element, kAXValueAttribute) as? String,
              !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              text.utf8.count <= 100_000 else { return nil }
        let snippet = Self.extractCurrentSentence(from: text)
        guard !snippet.isEmpty, snippet.count <= 500 else { return nil }
        return FocusedTextSnapshot(appName: NSWorkspace.shared.frontmostApplication?.localizedName ?? "Unknown",
                                   element: element, textDigest: digest(text), snippet: snippet)
    }
    func replace(snapshot: FocusedTextSnapshot, with corrected: String) -> Bool {
        guard corrected.count <= 2_000, let element = focusedElement(), readable(element),
              let text = attribute(element, kAXValueAttribute) as? String,
              TextSafety.canReplace(sameElement: CFEqual(element, snapshot.element), expectedDigest: snapshot.textDigest,
                                    currentDigest: digest(text), snippet: snapshot.snippet, text: text),
              let range = text.range(of: snapshot.snippet, options: .backwards),
              let finalFocus = focusedElement(), CFEqual(finalFocus, element), readable(finalFocus),
              let finalText = attribute(finalFocus, kAXValueAttribute) as? String, finalText == text else { return false }
        // AX has no compare-and-swap: a target can still mutate between this check and the write.
        let replacement = text.replacingCharacters(in: range, with: corrected)
        return AXUIElementSetAttributeValue(element, kAXValueAttribute as CFString, replacement as CFTypeRef) == .success
    }
    private func poll() {
        let snapshot = shouldReadText() ? currentSnapshot() : nil
        guard snapshot != lastSnapshot || snapshot == nil else { return }
        lastSnapshot = snapshot
        onChange?(snapshot)
    }
    static func extractCurrentSentence(from text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "" }
        let separators = CharacterSet(charactersIn: ".!?\n")
        let ns = trimmed as NSString
        var start = 0
        var index = ns.length - 1
        while index >= 0 {
            let ch = ns.character(at: index)
            if let scalar = UnicodeScalar(ch), separators.contains(scalar) { start = index + 1; break }
            index -= 1
        }
        let sentence = ns.substring(with: NSRange(location: start, length: ns.length - start)).trimmingCharacters(in: .whitespacesAndNewlines)
        if sentence.count > 20 { return sentence }
        return trimmed.split(separator: " ").suffix(24).joined(separator: " ")
    }
}
