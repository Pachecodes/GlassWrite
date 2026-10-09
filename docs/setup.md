# Setup guide

[← Project overview](../README.md) · [Documentation index](README.md)

## Requirements and installation

- macOS 14 or newer; Xcode with macOS SDK and command-line tools selected.
- XcodeGen (`brew install xcodegen`) to regenerate the checked-in project.
- Ollama installed separately from <https://ollama.com>. Model licenses are separate from this repository's MIT license.

```sh
xcodegen generate
xcodebuild -project GlassWrite.xcodeproj -scheme GlassWrite \
  -configuration Release -destination 'platform=macOS' \
  -derivedDataPath "$HOME/Library/Developer/Xcode/DerivedData/GlassWriteRelease" \
  build CODE_SIGNING_ALLOWED=NO
```

Open `GlassWrite.xcodeproj` in Xcode, select the GlassWrite scheme, and Run. For repeated local use, copy the built `Build/Products/Release/GlassWrite.app` into Applications and use that stable path. This is a source build, not a signed/notarized distribution. macOS may require local signing or permission re-approval after rebuilding or moving the app. Do not bypass Gatekeeper for untrusted downloads.

## Local Ollama setup

```sh
ollama serve                 # only if the Ollama app/service is not already running
ollama pull qwen3.5:0.8b     # default model; choose another installed model if unavailable
ollama list
curl http://127.0.0.1:11434/api/tags
```

In ✦ → Settings, use API URL `http://127.0.0.1:11434`, click Test / Refresh, and select an installed model. The app accepts only the literal loopback address `127.0.0.1`, no URL credentials/query/fragment/path prefix, and refuses redirects. `localhost`, LAN and remote URLs are deliberately unsupported. Ollama/model installation and model availability are external prerequisites, not bundled dependencies or guaranteed model-quality claims.

## Permissions and usage

1. Open ✦ → Request Accessibility Permission. In System Settings → Privacy & Security → Accessibility, enable the actual GlassWrite app you are running; restart it if needed.
2. Focus a normal text field with non-sensitive sample text in another app.
3. Choose ✦ → Analyze Now (or Analizar in the nonactivating overlay). **Live is off on every launch.** Optionally enable Live to analyze eligible text after a typing debounce.
4. Review the suggestion. Reemplazar requests replacement only if the same field and exact text are still current. Copiar explicitly writes the suggestion to the system clipboard. Ignorar clears the current text/suggestion.
5. Turn Live off to stop automatic capture, or quit from ✦.

Screen Recording, microphone and camera permissions are not used. Accessibility is broad system access: grant it only to a build you trust. Settings contains some Spanish labels; full English UI localization is not implemented.

