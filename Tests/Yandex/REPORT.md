# Yandex Games verification — 2026-10-07

- Final artifact and SHA-256: `build.json`, `Builds/DrillDrop-Yandex.zip`.
- Godot 4.3 single-thread WebGL 2 export; native editor remains on 4.2.2.
- Chromium browser smoke: actual exported menu, touch starts 3D gameplay, platform pause/resume, ready/start/stop, RU/EN, reload persistence and contextmenu prevention; zero JS errors.
- Desktop canvas centered at 480×720 in a 1280×720 viewport; mobile 430×932. Captures included.
- GPU: ANGLE Metal Renderer Apple M2. Five-second gameplay sample: 300 frames, 60 fps average, p95 18.7 ms, max 18.8 ms. Not a guarantee for other devices or long sessions. Initial SwiftShader software-rendering measurement (~1 fps) was not representative of hardware performance; test now explicitly enables Metal.
- Cloud tests: initial remote restore, local save, write throttling, offline failure/recovery, account isolation, disabled storage. Browser SDK double implements getPlayer/getData/setData; real Yandex server behavior still needs verification in draft.
- Profile no longer loads another account's unscoped user:// save on web. Legacy browser saves migrate once; cloud writes disabled for the session if initial remote read fails, preserving unknown remote progress.
- Native lobby/pause regression passed earlier; current changes keep the native profile path unchanged.
- The user's draft URL could not be accessed using available browser tools. Do not claim hosted SDK validation or moderation approval.
- All 23 screenshot items, remaining cabinet fields and content notes: `Web/PUBLICATION-CHECKLIST.md`. Suggested localized listing: `Web/STORE-LISTING.md`.
