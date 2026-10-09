import XCTest
@testable import GlassWriteCore

final class OllamaServiceTests: XCTestCase {
    func testSuggestionDecoding() throws {
        let result = try JSONDecoder().decode(CorrectionSuggestion.self, from: Data(#"{"needs_change":true,"corrected":"Hello","reason":"Capitalization","safe_auto_replace":false}"#.utf8))
        XCTAssertEqual(result.corrected, "Hello")
        XCTAssertFalse(result.safeAutoReplace)
    }
    func testBundleVersionIsString() throws {
        let url = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("GlassWrite/Resources/Info.plist")
        let plist = try PropertyListSerialization.propertyList(from: Data(contentsOf: url), options: [], format: nil) as? [String: Any]
        XCTAssertEqual(plist?["CFBundleVersion"] as? String, "1")
    }
    func testSentenceExtraction() {
        XCTAssertEqual(FocusedTextMonitor.extractCurrentSentence(from: ""), "")
        XCTAssertEqual(FocusedTextMonitor.extractCurrentSentence(from: "Earlier sentence. This is the current sentence needing correction"), "This is the current sentence needing correction")
    }
}
