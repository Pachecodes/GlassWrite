import XCTest
@testable import GlassWriteCore

final class SafetyTests: XCTestCase {
    func testRemoteAndCredentialURLsRejected() {
        for value in ["https://example.com", "http://localhost", "http://user:placeholder@127.0.0.1:11434", "http://127.0.0.1:11434?token=placeholder", "file:///model"] {
            XCTAssertFalse(TextSafety.isLocalURL(URL(string: value)!))
        }
        XCTAssertTrue(TextSafety.isLocalURL(URL(string: "http://127.0.0.1:11434")!))
    }
    func testCaptureAndAutomaticReplacementDisabledAtLaunch() {
        XCTAssertFalse(AppSettings().liveMode)
        XCTAssertFalse(AppSettings().autoReplaceSafeTypos)
    }
    func testSecureAndSensitiveFieldsRejected() {
        XCTAssertFalse(TextSafety.isReadable(role: "AXTextField", subrole: "AXSecureTextField", protected: false, metadata: []))
        XCTAssertFalse(TextSafety.isReadable(role: "AXTextField", subrole: nil, protected: true, metadata: []))
        for name in ["password", "API token", "credit card", "verification code", "secret", "SSN"] {
            XCTAssertFalse(TextSafety.isReadable(role: "AXTextField", subrole: nil, protected: false, metadata: [name]))
        }
    }
    func testUnknownRoleRejectedAndOrdinaryTextAllowed() {
        XCTAssertFalse(TextSafety.isReadable(role: nil, subrole: nil, protected: false, metadata: []))
        XCTAssertTrue(TextSafety.isReadable(role: "AXTextArea", subrole: nil, protected: false, metadata: ["Message"]))
    }
    func testReplacementRejectsChangedFocusOrText() {
        XCTAssertFalse(TextSafety.canReplace(sameElement: false, expectedDigest: "a", currentDigest: "a", snippet: "hello", text: "hello"))
        XCTAssertFalse(TextSafety.canReplace(sameElement: true, expectedDigest: "a", currentDigest: "b", snippet: "hello", text: "hello"))
    }
    func testReplacementRejectsMissingSnippet() {
        XCTAssertFalse(TextSafety.canReplace(sameElement: true, expectedDigest: "a", currentDigest: "a", snippet: "missing", text: "hello"))
    }
    func testReplacementAllowsUnchangedTarget() {
        XCTAssertTrue(TextSafety.canReplace(sameElement: true, expectedDigest: "a", currentDigest: "a", snippet: "hello", text: "hello"))
    }
}
