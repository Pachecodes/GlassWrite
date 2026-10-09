# Provenance and licensing

GlassWrite is a local macOS prototype credited to Jesus Pacheco / Akitá Labs and prepared for release under Pachecodes with the owner's explicit authorization for original code.

The release tree was assembled from an explicit allowlist of Swift source/test files, `project.yml` and `Info.plist`; the Xcode project was regenerated. No git history, Xcode user state, compiled artifacts, model weights or credentials were imported. Source was not a git repository, so historical authorship/chain-of-title could not be independently reconstructed from commits. Owner authorization is the basis for the original-code MIT grant; it is not an assertion that a historical upstream search proved uniqueness.

The inspected files contained no third-party source headers, vendored libraries, Swift package dependencies or copied license notices. Apple platform frameworks are referenced, not redistributed. XcodeGen is build tooling; Ollama and model weights are separately installed and retain their own licenses. If previously unknown third-party material is identified, retain its notices and resolve licensing before including it in a release.

Release hardening adds explicit field privacy checks, stale-target replacement guards, local-only transport, safe launch defaults, unhosted regression tests, documentation and CI. Existing obsolete tests referenced a service no longer present; they were replaced with tests for the actual current models/services. No screenshots, badges, binary-release claims or upstream endorsement are included.
