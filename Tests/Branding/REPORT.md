# Branding and music verification — 2026-10-03

- Graphic transparent logo replaces the plain main-menu title. Inspected 640×960 and 430×932 captures; placement adjusted to keep the hero's eyes visible.
- Generated full-bleed app icon configured as project icon and Android standard/adaptive launcher artwork. Extracted APK icons verified at 192×192 and 432×432.
- User's MP3 copied byte-for-byte (104.143 seconds), original speed. Menu and gameplay use the new track and existing music controls.
- `check.gd -- --test`: isolated profile, icon/logo resources, music playback in menu/run, mute/unmute and looping after seeking to the end of the track.
- Same test run against exported macOS executable with `-- --test --packaged`.
- Android debug APK and macOS ad-hoc signed build export successfully. SHA-256 hashes are in `builds.json`.
- Android installation/audio on a physical phone and store signing are not verified by this change.

Asset generation prompts and provenance: `Art/UI/Lobby/BRANDING.md`. Music provenance: `Audio/GAMEJAM.md`.
