# Contributing

Use a branch and submit a focused pull request with an English description. Preserve attribution and any third-party license notices; do not contribute code you cannot legally license.

Run XcodeGen, the unhosted test suite, and a Release build using the commands in README before requesting review. Add regression tests first for security boundaries and rejection paths. Do not rely on model output to authorize replacement. Keep secure-field metadata checks before text capture, retain no full field in snapshots, and do not restore automatic clipboard capture or remote inference silently.

Do not commit `.env` files, credentials, personal paths, Xcode user state, DerivedData, recordings, real user text or build/test artifacts. Use synthetic sample text and placeholder configuration values. Generated project updates should come from `project.yml`, not manual-only edits. Document manual AX compatibility results separately; do not present unit tests as end-to-end validation.
