# AGENTS.md

## Cursor Cloud specific instructions

This is a single Flutter app (`hanzi_app` / 宝宝识字), a Chinese-character learning
app for preschool kids. The primary dev/CI target is **Flutter Web**. Standard dev
commands (`flutter pub get`, `flutter run -d chrome`, `flutter build web`,
`build_runner`, etc.) and the dependency/tech-stack overview are documented in
`CLAUDE.md` — refer to it rather than duplicating.

Non-obvious notes for working in this environment:

- **Flutter SDK**: 3.41.6 (matches `.fvmrc`) is installed at `~/flutter` and added to
  `PATH` via the agent's `~/.bashrc`. FVM itself is not installed; the SDK is used
  directly. The update script runs `flutter pub get` to refresh dependencies.
- **`cs_ui` dependency**: pulled from a public git repo (`github.com/bryanpeng-777/cs.git`),
  not a local path — `flutter pub get` needs network access to GitHub + pub.dev.
- **Running the app on a headless VM**: use the web-server device (no GUI auto-launch):
  `flutter run -d web-server --web-port 8080 --web-hostname 0.0.0.0`, then open
  `http://localhost:8080` in the Desktop pane's Chrome. First compile takes ~30s.
- **Guest mode**: the app opens on a login screen. Click **跳过** (skip) to enter as a
  guest. Core learning flows work fully offline via guest mode + `SharedPreferences`;
  the Supabase backend (hard-coded, hosted) is **optional** and only needed to test
  login / cloud progress sync.
- **`flutter pub get` side effects**: running it regenerates `pubspec.lock` and the
  desktop `*/flutter/generated_plugin*` files (SDK-version churn). These are not
  meaningful changes — do not commit them.
- **Tests**: `flutter test` runs the widget/unit suite. A few tests (e.g.
  `test/t011_test.dart`) currently fail with `RenderFlex overflowed` layout
  assertions; these are pre-existing app/test layout issues, not environment problems.
- **Chinese fonts on web**: rendering Chinese glyphs relies on the Google Fonts CDN
  (`google_fonts` + the preload in `web/index.html`); without network the text shows
  as tofu boxes.
