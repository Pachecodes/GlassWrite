import Foundation
import SwiftUI
import AppKit
import Combine

@MainActor
final class AppState: ObservableObject {
    @Published var settings = AppSettings()
    @Published var models: [OllamaModel] = []
    @Published var status = "Ready — manual analysis by default"
    @Published var currentApp = ""
    @Published var currentSnippet = ""
    @Published var suggestion: CorrectionSuggestion?
    @Published var isAnalyzing = false
    @Published var accessibilityOK = false
    @Published var ollamaOK = false
    private let monitor = FocusedTextMonitor()
    private var latestSnapshot: FocusedTextSnapshot?
    private var debounceTask: Task<Void, Never>?
    private var analysisTask: Task<Void, Never>?
    private var subscriptions = Set<AnyCancellable>()
    private var generation = UUID()

    func bootstrap() {
        accessibilityOK = FocusedTextMonitor.accessibilityTrusted()
        monitor.onChange = { [weak self] snapshot in
            Task { @MainActor in self?.handle(snapshot: snapshot) }
        }
        settings.objectWillChange.sink { [weak self] in
            self?.objectWillChange.send()
            self?.clearText()
        }.store(in: &subscriptions)
        // Poll for invalidation even in manual mode, but do not read text in manual mode.
        monitor.shouldReadText = { [weak self] in self?.settings.liveMode == true || self?.latestSnapshot != nil }
        monitor.start()
        Task { await refreshOllama() }
    }
    func clearText() {
        generation = UUID()
        debounceTask?.cancel()
        analysisTask?.cancel()
        latestSnapshot = nil
        suggestion = nil
        currentSnippet = ""
        currentApp = ""
        isAnalyzing = false
    }
    func requestAccessibilityPermission() {
        accessibilityOK = FocusedTextMonitor.accessibilityTrusted(prompt: true)
        status = accessibilityOK ? "Accessibility enabled" : "Waiting for Accessibility permission"
    }
    func refreshOllama() async {
        guard let url = URL(string: settings.ollamaURL) else { status = "Invalid Ollama URL"; return }
        do {
            let found = try await OllamaClient(baseURL: url).tags()
            models = found
            ollamaOK = true
            if !found.contains(where: { $0.name == settings.selectedModel }), let first = found.first { settings.selectedModel = first.name }
            status = "Ollama connected"
        } catch { ollamaOK = false; status = "Local Ollama unavailable or URL not allowed" }
    }
    private func handle(snapshot: FocusedTextSnapshot?) {
        guard settings.liveMode || latestSnapshot != nil else { return }
        guard let snapshot else { clearText(); return }
        if !settings.liveMode {
            if snapshot != latestSnapshot { clearText() }
            return
        }
        clearText()
        latestSnapshot = snapshot
        currentApp = snapshot.appName
        currentSnippet = snapshot.snippet
        guard snapshot.snippet.count >= 8 else { return }
        debounceTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 700_000_000)
            guard !Task.isCancelled else { return }
            self?.analyzeCurrentSnippet(force: false)
        }
    }
    func analyzeCurrentSnippet(force: Bool) {
        // Always re-read the target. No automatic clipboard fallback or stale snapshot reuse.
        guard let snapshot = monitor.currentSnapshot() else {
            clearText()
            status = "No eligible focused text. Check Accessibility permissions."
            return
        }
        clearText()
        latestSnapshot = snapshot
        currentApp = snapshot.appName
        currentSnippet = snapshot.snippet
        guard snapshot.snippet.count >= 3, let url = URL(string: settings.ollamaURL) else { return }
        let token = generation
        let model = settings.selectedModel
        let mode = settings.correctionMode
        isAnalyzing = true
        status = "Analyzing locally…"
        analysisTask = Task { [weak self] in
            do {
                let result = try await OllamaClient(baseURL: url).suggest(text: snapshot.snippet, mode: mode, model: model)
                guard let self, !Task.isCancelled, self.generation == token else { return }
                guard self.monitor.currentSnapshot() == snapshot else { self.clearText(); return }
                self.suggestion = result
                self.isAnalyzing = false
                self.status = result.needsChange ? "Suggestion ready" : "Looks good"
            } catch {
                guard let self, !Task.isCancelled, self.generation == token else { return }
                self.clearText()
                self.status = "Local model request failed"
            }
        }
    }
    func replaceWithSuggestion() -> Bool {
        guard let snapshot = latestSnapshot, let suggestion, suggestion.needsChange else { return false }
        let ok = monitor.replace(snapshot: snapshot, with: suggestion.corrected)
        clearText()
        status = ok ? "Replaced" : "Target changed or replacement unsupported. Nothing replaced."
        return ok
    }
}
