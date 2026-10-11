# VINZZX STUDIO — Mobile 2D Game Engine

This repository uses the original uploaded project's Android wrapper and GitHub Actions split-per-ABI build workflow. The previous Mini Arena game UI/gameplay was replaced with a new Flutter-based 2D scene-editor prototype.

## Current prototype
- Dark mobile-first editor UI.
- Scene canvas with grid.
- Starter scene nodes: Player, platforms, enemy, spawn point.
- Add object menu.
- Select nodes from hierarchy and tap/drag on the canvas.
- Inspector fields for X/Y/width/height.
- Delete selected object.
- Play/Stop preview state.
- Save scene JSON by copying it to clipboard.

## Build APK with GitHub Actions
1. Upload the contents of this repository to the GitHub repository root.
2. Push to `main` or `master`, or manually run the workflow from the Actions tab.
3. Download the `vinzzx-studio-split-apks` artifact.
4. Install the APK matching the device ABI; most modern Android phones use `arm64-v8a`.

The workflow builds release APKs with `flutter build apk --release --split-per-abi`.

## Important status
This is **version 0.1 editor prototype**, not yet a complete game engine. The Play button currently toggles preview mode; it does not yet simulate gameplay. Flame is included as the planned runtime foundation but the current editor canvas is drawn using Flutter CustomPainter. Next milestones: persistent project files, runtime entity/component system, physics/collision, sprite importer, player controller, weapons, then multiplayer.
