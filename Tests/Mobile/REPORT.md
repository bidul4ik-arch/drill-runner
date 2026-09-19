# Mobile update — 19 September 2026

## Delivered functionality

- Android ARM64 debug APK, Godot 4.2.2 Compatibility renderer, portrait layout that expands to tall displays and accounts for safe areas. Offline gameplay, swipe controls, background pause, on-screen boss combo control.
- Russian from the device's Russian locale; English for other languages. Both static and formatted gameplay strings use the translation catalog.
- Long ore train (10.8 m) and overhead conduit (6 m), swept collisions using the complete obstacle length. An empty lane remains available per section; sections only move their safe lane by one lane.
- Blender volume dust source and transparent rendered texture, integrated with speed-dependent particles.
- Wearable cap saved with the player profile, framed 3D skin previews, prices under each frame with rotating coin drawings. All four skins use ordinary coins (0/120/280/450).
- Revised skinned hero mesh and 13 motion clips, cloth folds, face atlas, hair locks, cropped jacket; Blender source and exported GLB are included.

## Validation

- `campaign-en.txt`: automated full completion of all three levels and bosses, zero failures. Updated traversal handles long obstacle tails before changing sections.
- `systems-results.txt`: purchases, duplicate debit protection, persistence, boss retry, checkpoint, pause and attack escape routes — zero failures, graphical Godot run.
- `features-results.txt`: both locale rules, translated formatted HUD, cap show/hide/persistence, 250 populated obstacle sections and long-hazard behavior — zero failures.
- `hero-results.txt`: movement-to-animation mapping, actual lowered skeleton during slide, required clips — zero failures.
- `screens-results.txt`: both localized menus and wardrobes rendered.
- Android 11 ARM64 Pixel 7a emulator: APK installed, menu and level launched; Russian selected through Android system language; swipes and background pause exercised. Runtime log contains an emulator shader-cache recompilation warning, no script error at that point. Emulator uses software rendering; its speed is not a physical-device performance measurement.

## Not complete

- **The hero does not match the approved reference closely enough.** This is still a procedural stylized model. Better surface details do not satisfy the requested final sculpt quality, facial likeness, clothing fit and hair silhouette. Current Blender render is review evidence, not an approved final character.
- No physical Android device test, Play Store release or release signing.
- No signed iOS build; Apple Team ID/provisioning are absent.
- No remote Git URL was provided; local source control only.

## Save isolation correction

An early invocation of the systems test omitted `--test` and changed fields in the local desktop `campaign.json` (coins, owned/selected skins, completion state). The pre-test values were not backed up, so they cannot be reliably restored. Android's separate save was unaffected. Explicit guards now prevent the mutable test scenes from running without `--test`; successful reruns use the separate `campaign_test.json`.

## Reproduction

Use Godot 4.2.2, Blender 5.2.2. Run tests with `-- --test`; additionally pass `--language=ru` for systems.gd's Russian expected messages. Source generators and export steps are in README. APK and signing keys are excluded from Git, while Blender sources, GLBs, texture atlases and test sources are included.
