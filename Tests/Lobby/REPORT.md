# Illustrated lobby, missions and cap — 3 October 2026

## Delivered

- New main-menu illustration based on the supplied character/cover, with live wallet, best score, settings, mission/reward indicators and four bottom navigation buttons. Artwork and prompt provenance: `Art/UI/Lobby/ARTWORK.md`.
- Supplied cover used as engine splash and loading screen. Loading bar follows threaded resource-loading progress; there is no artificial waiting timer.
- Play resumes a suspended run or starts the highest unlocked campaign level immediately. Endless mode remains separate. Optional level selection moved into settings; it is not in the main navigation.
- Eight lifetime achievements and three deterministic daily missions selected from five templates. Runs, picked-up coins, distance, successful jump/slide actions, buffs and boss victories feed saved counters. Goals and coin rewards are configured in `Config/goals.json`.
- One-time claims update the coin wallet and atomically save through Profile. Daily selection/progress/claims persist across restarts, reset on a later local calendar day, and are not reset by moving the clock backwards. This is an offline local system, not server-side anti-cheat. A timer shows time to local midnight. Existing completed bosses/started profile are considered when initializing lifetime stats.
- Separate skinned cap, normal hair, cap-fitted hair and goggles. The cap hairstyle is clamped beneath the crown in Blender; toggling the cap switches meshes in gameplay, previews and wardrobe. Editable source: `Art/Blender/hero_cap_fit.blend`; reproducible conversion: `Tools/fix_cap_fit.py`. Original full-hair source is preserved.
- Russian and English UI strings, reward screen with rotating coin, Android Back handling.

## Checks

- `check.log`: 0 failures — daily rollover, same-day persistence, claims before completion, duplicate claims, saved reward state, backwards clock, lifetime achievements, cap mesh visibility, navigation, modal Back and direct run start.
- `hero.log`: 0 failures — run, sprint, lane changes, jump/fall/land, prone slide and animation mapping after GLB changes.
- `campaign.log`: 0 failures — all three levels and both phases of every boss.
- `systems.log` / `polish.log`: 0 assertion failures — existing save/retry/purchase/navigation and rare-buff behaviour.
- `screens.log` / `tall.log`: inspected RU/EN main menu, missions, achievements, reward screen and cap variants at ordinary and tall portrait dimensions. Images are captured from Godot.
- Some older campaign/polish tests still report two retained GPU textures at renderer shutdown, as in the previous build. No script/shader errors were observed in the new screen captures or final lobby check.

- Android 0.6-lobby (code 6) and macOS builds exported successfully. The actual packaged macOS application passed `packaged.log` with 0 failures: artwork/catalog presence, daily reward deduplication, menu navigation, one-tap start of unlocked level 2 and cap mesh switching. Artifact sizes/checksums are in `builds.json`.

Physical-device testing and Yandex Games web/SDK integration are not included in this change. The illustrated lobby does not imply that the in-game 3D hero now matches the illustration.
