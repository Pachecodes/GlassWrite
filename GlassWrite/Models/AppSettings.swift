import Foundation

final class AppSettings: ObservableObject {
    @Published var ollamaURL: String { didSet { UserDefaults.standard.set(ollamaURL, forKey: "ollamaURL") } }
    @Published var selectedModel: String { didSet { UserDefaults.standard.set(selectedModel, forKey: "selectedModel") } }
    @Published var correctionMode: CorrectionMode { didSet { UserDefaults.standard.set(correctionMode.rawValue, forKey: "correctionMode") } }
    @Published var liveMode: Bool { didSet { UserDefaults.standard.set(liveMode, forKey: "liveMode") } }
    @Published var autoReplaceSafeTypos: Bool { didSet { UserDefaults.standard.set(autoReplaceSafeTypos, forKey: "autoReplaceSafeTypos") } }

    init() {
        ollamaURL = UserDefaults.standard.string(forKey: "ollamaURL") ?? "http://127.0.0.1:11434"
        selectedModel = UserDefaults.standard.string(forKey: "selectedModel") ?? "qwen3.5:0.8b"
        correctionMode = CorrectionMode(rawValue: UserDefaults.standard.string(forKey: "correctionMode") ?? "spelling") ?? .spelling
        liveMode = false // Explicit opt-in each launch; never restore background capture
        autoReplaceSafeTypos = false // Legacy setting retained; automatic replacement is disabled
    }
}

enum CorrectionMode: String, CaseIterable, Identifiable {
    case spelling
    case clarity
    case professional
    case direct

    var id: String { rawValue }
    var label: String {
        switch self {
        case .spelling: return "Ortografía"
        case .clarity: return "Claridad"
        case .professional: return "Profesional"
        case .direct: return "Directo"
        }
    }
}

struct CorrectionSuggestion: Codable, Equatable {
    var needsChange: Bool
    var corrected: String
    var reason: String
    var safeAutoReplace: Bool

    enum CodingKeys: String, CodingKey {
        case needsChange = "needs_change"
        case corrected
        case reason
        case safeAutoReplace = "safe_auto_replace"
    }
}
