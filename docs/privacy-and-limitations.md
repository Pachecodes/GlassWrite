# Privacy and prototype boundaries

[← Project overview](../README.md) · [Documentation index](README.md)

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

