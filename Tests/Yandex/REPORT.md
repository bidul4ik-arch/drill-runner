# Yandex Games web build verification — 2026-10-04

- Godot 4.3 Compatibility / WebGL 2, single-thread export. Native Godot 4.2.2 editor and import cache remain separate.
- Final ZIP: 53,211,213 bytes; uncompressed contents: 82,984,720 bytes. SHA-256 in `build.json`.
- Archive CRC, root index.html, ASCII filenames, 100 MB limit and shipped bridge checked. SDK is loaded from /sdk.js; no SDK mock is shipped.
- Chromium, portrait 430×932, touch input: actual exported menu loads, tap starts a 3D run; ready/start/stop events observed.
- Platform pause and resume tested, browser progress survives page reload, Russian and English SDK locales render correctly. Screenshots and browser.json accompany this report.
- Local browser tests inject an SDK test double through Playwright routing; live Yandex-hosted SDK and moderation have NOT been verified.
- SDK adapter tests cover one-time ready, state transitions, focus, SDK pause, menu resume and storage.
- Native regression: LOBBY TEST 0 failures; PLATFORM PAUSE 0 failures (game state, audio mute, restoring previous mute, manual resume).
- Full campaign playthrough on the Yandex-hosted build, physical phones, Safari and performance certification are not covered by this smoke test. No cloud saves or monetization is advertised.
