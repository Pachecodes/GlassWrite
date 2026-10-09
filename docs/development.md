# Development and licensing

[← Project overview](../README.md) · [Documentation index](README.md)

## Development and tests

```sh
xcodegen generate
xcodebuild -project GlassWrite.xcodeproj -scheme GlassWrite \
  -destination 'platform=macOS' -derivedDataPath "$HOME/Library/Developer/Xcode/DerivedData/GlassWriteTests" \
  test CODE_SIGNING_ALLOWED=NO
```

Tests run unhosted against GlassWriteCore (the same service/model source files the app compiles). They cover field-policy rejection, focus/text change guards, URL restrictions, safe launch defaults, decoding, extraction, and the bundle version. They do not exercise real third-party app AX behavior. See [CONTRIBUTING](../CONTRIBUTING.md), [SECURITY](../SECURITY.md), and [PROVENANCE](../PROVENANCE.md).

## License

Original project code is MIT; see [LICENSE](../LICENSE). Apple's SDK/frameworks and independently installed Ollama/model weights retain their respective licenses. No third-party code or model weights are vendored here.
