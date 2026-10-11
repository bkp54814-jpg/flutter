# VINZZX STUDIO — Mobile 2D Editor Prototype

This project keeps the Android wrapper and GitHub Actions split-per-ABI build workflow from the supplied base project. The editor is a Flutter prototype; it is not yet a production-ready engine equivalent to Unity/Godot.

## v0.6 changes
- New scenes start empty; preview no longer draws a hard-coded test arena, player, enemy, ground, or HP bar.
- Imported PNG assets are added to the library but are not automatically selected. Select an asset manually before editing it.
- PNG asset library includes a delete-asset control.
- Sprite sheet rows/columns update live when valid values are entered; FPS updates live when valid.
- Frames can be excluded from the animation sequence with **Hapus frame terpilih**. This does not erase pixels from the source PNG; changing rows/columns resets the exclusion list.
- Excluded frame indices are included in project JSON.
- Preview draws only objects actually present in the scene. Add objects in Scene Editor and assign their imported sprite in Inspector.

## Build APK with GitHub Actions
1. Upload the contents of this project folder to the root of your GitHub repository (including hidden `.github` folder).
2. Push to `main`/`master`, or open Actions and manually run **Build VINZZX STUDIO APK**.
3. Download artifact `vinzzx-studio-split-apks` from a successful workflow run.
4. Install the APK matching your device ABI; most modern Android phones use `arm64-v8a`.

## Known limitations
- Build has not been verified in this environment; GitHub Actions is the compile check.
- Sprite sheet grid is still regular rows/columns. Automatic trimming, irregular frame rectangles, margins/spacing controls and undo are not implemented yet.
- Delete frame excludes it from the animation sequence; it does not modify the source PNG.
- The script editor stores text only; user-authored scripts are not executed.
- Preview is a scene renderer, not yet a complete runtime with physics, collision, health system, gameplay flow or functional joystick controller.
- Save Project copies JSON to clipboard; robust project file/folder persistence is not implemented yet.
