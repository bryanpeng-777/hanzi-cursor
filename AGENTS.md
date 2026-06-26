# AGENTS.md

This repo is a Flutter app (宝宝识字 / "Baby Literacy") for preschool Chinese-character
learning. Day-to-day development commands, project structure, data models, and tech-stack
rules are documented in `CLAUDE.md` — read it first for anything app-specific.

## Cursor Cloud specific instructions

These notes are for cloud agents running after the startup update script has already run.
They focus on non-obvious caveats; standard commands live in `CLAUDE.md` and `pubspec.yaml`.

### Toolchain / environment
- Flutter SDK **3.41.6** (matching `.fvmrc`, Dart 3.11.4) is installed at `/opt/flutter`.
  It is added to `PATH` via the agent's `~/.bashrc`, so interactive shells already have
  `flutter`/`dart`. **Non-interactive shells (and the startup update script) may not source
  `~/.bashrc`** — if `flutter` is not found, run `export PATH="/opt/flutter/bin:$PATH"` or
  call the binaries by full path (`/opt/flutter/bin/flutter`).
- Chrome is preinstalled at `/usr/local/bin/google-chrome` for the web target.
- The startup update script runs `flutter pub get`, which **clones the in-house `cs` packages
  (`cs_ui`/`cs_core`/`cs_auth`) from `github.com/bryanpeng-777/cs.git`** — this step needs
  network access to GitHub.

### Running the app (web is the simplest target)
- Headless dev server (what was used for testing here):
  `flutter run -d web-server --web-port 8091 --web-hostname 0.0.0.0` then open
  `http://localhost:8091`. To drive a real browser instead, set
  `export CHROME_EXECUTABLE=$(which google-chrome)` and use `-d chrome`.
- The app is **landscape-locked** (`main.dart` forces landscape). In a portrait/narrow
  browser window some screens scroll and bottom buttons can be partially cut off — this is a
  layout consequence of the orientation lock, not a setup failure.

### Code generation
- Generated files (`*.g.dart`, `*.freezed.dart`) are **committed**, so a fresh checkout runs
  without codegen. After editing any `@riverpod` / `@freezed` / `@JsonSerializable` annotation
  you must regenerate: `dart run build_runner build --delete-conflicting-outputs`.

### Backend / auth (why blank images & guest mode are expected)
- Supabase is configured with a hard-coded URL + anon key in `lib/main.dart`. In the sandbox,
  remote `CsImage` config assets and Supabase cloud sync may not load, so **character/illustration
  image areas can render blank** — this is an environment networking limitation, not an app bug.
- The login page has a **"跳过，先试试" (Skip) → guest mode** entry. Core flows (pinyin,
  character learning, quizzes, games, star rewards) work fully in guest mode using local
  `SharedPreferences`, with no real login required for testing.

### Testing notes
- `flutter analyze` is clean (info-level lint hints only, no errors/warnings).
- `flutter test`: most tests pass; the pinyin-learning UI tests in `test/t011_test.dart` and
  `test/pinyin_screen_test.dart` fail with `RenderFlex` overflow assertions. These are
  **pre-existing, layout/viewport-dependent failures** unrelated to environment setup.
