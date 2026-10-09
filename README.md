# GlassWrite

A macOS menu-bar writing-assistant **prototype** by Jesus Pacheco / Akitá Labs, prepared for Pachecodes. It reads an eligible focused text field through macOS Accessibility and asks a local Ollama model for a correction. Review every suggestion before using it.

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

## Privacy and safety

- No automatic clipboard reading, analytics, accounts, prompt logs or document history. Preferences store only the local URL, model, mode and legacy toggles in UserDefaults.
- Password/secure/protected fields and fields whose exposed labels/identifiers indicate passwords, tokens, payment cards or verification codes are excluded **before AXValue is read**. Unknown roles are rejected. This relies on other applications correctly exposing Accessibility metadata and is **not a universal sensitive-data detector**. Never use it for secrets, financial, clinical or confidential text.
- The full field value is read transiently to extract a snippet and compute an in-memory SHA-256 change guard; it is not kept in the snapshot or written to disk. At most 500 characters of snippet are sent. Fields above 100,000 UTF-8 bytes and longer snippets are declined (AXValue may still allocate the field before the size check).
- Snippets and suggestions remain in memory/overlay while active, and are cleared on focus/text invalidation, settings changes, Ignore, replacement or request failure. An in-flight request can retain its bounded snippet until cancellation completes. Swift strings do not provide guaranteed secure memory erasure. Manual mode re-reads only while an explicit analysis snapshot remains active to detect invalidation.
- Requests use an ephemeral URLSession without disk cache/cookies or configured proxies. Only local loopback requests are permitted, but another local process can serve that port. Ollama, its logs, model behavior, OS diagnostics, swap and clipboard history are outside GlassWrite's control. Inspect your local service configuration.
- Automatic replacement is disabled even if a model claims a correction is safe. Explicit replacement rechecks element identity and exact full-text digest, then rechecks focus and text immediately before writing. No fallback overwrites the entire field when the snippet is missing.

## Prototype limitations

Not production-ready, notarized, sandboxed, or App Store-ready. No global shortcut, undo integration, cursor-aware context, app allowlist, OCR, comprehensive browser/editor compatibility, or physical/interactive Accessibility QA guarantee. The extraction heuristic takes trailing text, **not the sentence at the cursor**; punctuation and short sentences use a trailing-word fallback. Replacement uses AXValue on the whole field and may lose rich formatting. Copy/paste is safer.

Accessibility has no atomic compare-and-swap, so a target may still change in the tiny interval between the final check and the write. Focus moving to GlassWrite itself can correctly reject replacement. Mislabelled sensitive fields cannot be reliably detected. Models can change meaning, hallucinate, or return malformed JSON; all suggestions are untrusted. JSON extraction is basic and does not recover multiple competing objects. Local inference quality/latency and an end-to-end Ollama session were not verified as part of the source release gates.

## Development and tests

```sh
xcodegen generate
xcodebuild -project GlassWrite.xcodeproj -scheme GlassWrite \
  -destination 'platform=macOS' -derivedDataPath "$HOME/Library/Developer/Xcode/DerivedData/GlassWriteTests" \
  test CODE_SIGNING_ALLOWED=NO
```

Tests run unhosted against GlassWriteCore (the same service/model source files the app compiles). They cover field-policy rejection, focus/text change guards, URL restrictions, safe launch defaults, decoding, extraction, and the bundle version. They do not exercise real third-party app AX behavior. See [CONTRIBUTING](CONTRIBUTING.md), [SECURITY](SECURITY.md), and [PROVENANCE](PROVENANCE.md).

## License

Original project code is MIT; see [LICENSE](LICENSE). Apple's SDK/frameworks and independently installed Ollama/model weights retain their respective licenses. No third-party code or model weights are vendored here.
