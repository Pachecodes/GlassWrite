import Foundation

enum TextSafety {
    static func isLocalURL(_ url: URL) -> Bool {
        ["http", "https"].contains(url.scheme ?? "") && url.host == "127.0.0.1" &&
        url.user == nil && url.password == nil && url.query == nil && url.fragment == nil &&
        (url.path.isEmpty || url.path == "/")
    }
    static func isReadable(role: String?, subrole: String?, protected: Bool, metadata: [String]) -> Bool {
        guard ["AXTextField", "AXTextArea"].contains(role ?? ""), !protected,
              subrole != "AXSecureTextField" else { return false }
        let labels = metadata.joined(separator: " ").lowercased()
        let sensitive = ["password", "passwd", "passcode", "secret", "token", "credit", "card", "cvv", "cvc", "ssn", "social security", "verification", "one-time", "otp", "contraseña", "clave"]
        return !sensitive.contains(where: labels.contains)
    }
    static func canReplace(sameElement: Bool, expectedDigest: String, currentDigest: String, snippet: String, text: String) -> Bool {
        sameElement && expectedDigest == currentDigest && !snippet.isEmpty && text.range(of: snippet, options: .backwards) != nil
    }
}
