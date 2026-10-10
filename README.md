# Mini Arena Flutter — HTML Game Edition

This build packages the supplied `mini_arena_full_rebuild.html` game inside an Android Flutter APK using the local WebView engine. This is deliberate: it keeps the game's original canvas rendering, character drawing, AK-47/pistol visuals, 360-degree aiming, touch joysticks, jetpack, grenades, explosions, radar, HUD, and menu instead of replacing them with a visually different prototype.

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

## Local build

```bash
flutter pub get
flutter analyze
flutter build apk --release --split-per-abi
```

## Notes

- The game HTML is bundled as an app asset, so the game does not need a website or internet connection at runtime.
- The Android app opens in landscape mode and hides the system bars for a full-screen game.
- GitHub Actions requires permission to run workflows in the repository.
- This package uses Flutter for the Android application shell and the supplied HTML/Canvas game for the gameplay layer. It is not a line-by-line native Dart rewrite of the game engine.
