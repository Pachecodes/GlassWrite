import SwiftUI
import AppKit

struct FloatingOverlayView: View {
    @ObservedObject var state: AppState

    var body: some View {
        ZStack {
            VisualEffectView(material: .hudWindow)
            VStack(alignment: .leading, spacing: 12) {
                header
                if !state.accessibilityOK { permissionView }
                else { mainView }
                footer
            }
            .padding(18)
        }
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.white.opacity(0.22), lineWidth: 1))
        .shadow(color: .black.opacity(0.22), radius: 24, x: 0, y: 12)
        .frame(minWidth: 410, minHeight: 220)
    }

    private var header: some View {
        HStack {
            Text("✦ GlassWrite")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
            Spacer()
            Button("Settings") { AppDelegate.shared?.openSettings() }
                .buttonStyle(.borderless)
                .font(.caption2)
            Circle().fill(state.ollamaOK ? Color.green : Color.orange).frame(width: 9, height: 9)
            Text(state.settings.selectedModel.isEmpty ? "No model" : state.settings.selectedModel)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private var permissionView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Necesito Accessibility para leer/reemplazar texto activo.")
                .font(.callout)
            Button("Pedir permiso") { state.requestAccessibilityPermission() }
        }
    }

    private var mainView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(state.currentApp.isEmpty ? "Escribe en cualquier app…" : "App: \(state.currentApp)")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(state.currentSnippet.isEmpty ? "Usa Analyze Now desde el menú ✦ o escribe en un campo de texto." : state.currentSnippet)
                .font(.system(size: 13, design: .rounded))
                .lineLimit(3)
                .foregroundStyle(.primary)
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))

            if state.isAnalyzing {
                ProgressView("Analizando…")
            } else if let s = state.suggestion, s.needsChange {
                VStack(alignment: .leading, spacing: 8) {
                    Text(s.corrected)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .lineLimit(4)
                    Text(s.reason).font(.caption).foregroundStyle(.secondary)
                    HStack {
                        Button("Reemplazar") { _ = state.replaceWithSuggestion() }
                            .keyboardShortcut(.return, modifiers: [])
                        Button("Copiar") { NSPasteboard.general.clearContents(); NSPasteboard.general.setString(s.corrected, forType: .string) }
                        Button("Ignorar") { state.clearText() }
                    }
                }
                .padding(10)
                .background(Color.cyan.opacity(0.12), in: RoundedRectangle(cornerRadius: 14))
            } else if state.suggestion != nil {
                Text("Se ve bien.").font(.callout).foregroundStyle(.secondary)
            }
        }
    }

    private var footer: some View {
        HStack {
            Picker("", selection: $state.settings.correctionMode) {
                ForEach(CorrectionMode.allCases) { mode in Text(mode.label).tag(mode) }
            }
            .pickerStyle(.menu)
            Toggle("Live", isOn: $state.settings.liveMode).toggleStyle(.switch)
            Spacer()
            Text(state.status)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.tail)
            Button("Analizar") { state.analyzeCurrentSnippet(force: true) }
        }
        .font(.caption)
        .help(state.status)
    }
}
