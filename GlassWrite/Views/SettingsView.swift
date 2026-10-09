import SwiftUI

struct SettingsView: View {
    @ObservedObject var state: AppState

    var body: some View {
        Form {
            Section("Ollama") {
                TextField("API URL", text: $state.settings.ollamaURL)
                    .textFieldStyle(.roundedBorder)
                Picker("Model", selection: $state.settings.selectedModel) {
                    ForEach(state.models) { model in Text(model.name).tag(model.name) }
                }
                HStack {
                    Button("Test / Refresh") { Task { await state.refreshOllama() } }
                    Text(state.status).foregroundStyle(.secondary)
                }
            }
            Section("Corrección") {
                Picker("Modo", selection: $state.settings.correctionMode) {
                    ForEach(CorrectionMode.allCases) { mode in Text(mode.label).tag(mode) }
                }
                Toggle("Live mode con debounce", isOn: $state.settings.liveMode)
                Text("Replacement always requires your explicit approval.").font(.caption)
            }
            Section("Permisos") {
                Button("Pedir Accessibility") { state.requestAccessibilityPermission() }
                Text("Screen Recording no es necesario para este MVP porque usamos texto activo, no imagen/OCR.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(width: 520, height: 360)
    }
}
