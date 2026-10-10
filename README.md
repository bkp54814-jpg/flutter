# Mini Arena Flutter — HTML Game Edition

This build packages the supplied HTML game inside an Android Flutter APK using a local WebView engine. The gameplay canvas stays in HTML/JavaScript so it can be tested in a browser without rebuilding the APK for every HTML change.

## Included in this iteration

- New lobby with Play, Update/Workshop, Rank and Mabar placeholders, controls, and local asset reset.
- The in-game landscape prompt was removed. The Android app itself opens in landscape.
- Victory celebration animation and optional victory audio.
- Workshop for importing a character spritesheet, arena background, jetpack image, shooting audio, and victory audio.
- Size, X/Y offset, sprite-sheet columns/rows, and animation FPS controls. A single image works as a static pose; multiple frames in one spritesheet can animate.
- Asset data is stored locally in the app WebView. No broad photo/storage permission is requested; the Android system file picker is used.
- Rank and online Mabar are lobby placeholders only; online multiplayer needs a separate server and synchronization layer.

The existing built-in weapon/gameplay implementation has been left as-is in this iteration; the workshop does not provide weapon-skin import.

## Build APK automatically on GitHub

1. Extract the ZIP.
2. Upload **the contents** of the ZIP to the repository root (do not upload the ZIP as one file).
3. Commit/push to `main` or `master`.
4. Open the repository's **Actions** tab and select **Build Mini Arena Flutter APK**.
5. Download the `mini-arena-split-apks` artifact after the run succeeds.

The workflow runs `flutter pub get` and `flutter build apk --release --split-per-abi`. It uploads separate APKs for:
- `app-arm64-v8a-release.apk` — most modern Android phones
- `app-armeabi-v7a-release.apk` — 32-bit ARM Android devices
- `app-x86_64-release.apk` — x86_64 devices/emulators

## Test HTML without rebuilding the APK

Open `mini_arena.html` in a modern desktop/mobile browser to test the HTML build. For the APK build, edit the same game source at `assets/game/mini_arena_full_rebuild.html`. Keep those two files in sync when editing the HTML. Browser storage and APK WebView storage are separate, so custom assets are not automatically shared between them.

## Local build

```bash
flutter pub get
flutter analyze
flutter build apk --release --split-per-abi
```

## Notes

- The game HTML is bundled as an app asset, so the game does not need a website or internet connection at runtime.
- The Android app opens in landscape mode and hides the system bars for a full-screen game. There is no extra landscape confirmation screen.
- GitHub Actions requires permission to run workflows in the repository.
- This package uses Flutter for the Android application shell and the supplied HTML/Canvas game for the gameplay layer. It is not a line-by-line native Dart rewrite of the game engine.

## Workshop notes

- Recommended character art: transparent PNG spritesheet, frames arranged in a regular grid.
- Set `Kolom frame` and `Baris frame` to match the sheet layout, then adjust `Kecepatan animasi` (FPS) and `Ukuran`.
- Use `TES DI GAME` to apply the current category and start a match immediately. The lobby's Update button reopens the workshop.
- For this version, each imported file is limited to 2 MB to reduce the chance of local browser storage quota errors. If saving fails, reduce the image/audio size and try again.
- The separate `mini_arena.html` file is for rapid browser testing. For APK builds, copy any final HTML edits into `assets/game/mini_arena_full_rebuild.html` too.

## Build verification status

The HTML JavaScript was syntax-checked with Node.js and the ZIP structure was validated. Flutter is not installed in the generation environment, so a release APK was not built here; use the included GitHub Actions workflow to verify the Android build.
