# Environment visual pass — 24 September 2026

The comparison target is the clear three-lane composition, strong silhouettes and restrained road detail of classic Subway Surfers. DrillDrop retains its own warm timber mine, turquoise minerals and drill-backpack character. References: [official game listing](https://apps.apple.com/us/app/subway-surfers/id512939461), [gameplay screenshot](https://www.notebookcheck.net/fileadmin/_processed_/e/5/csm_Screenshot_20230222_161853_Subway_Surf_f24dd91cd1.jpg), and the user's mine concept in Art/Concepts. This is a visual iteration, not a claim of matching the concept or Subway's production quality.

## Delivered

- Three rebuilt 24 m Blender track modules: old mine, crystal cave, industrial complex. Irregular bevelled rock faces, continuous upper vault, timber/metal ribs, service cables, quieter flagstone paving, rail fasteners, galleries, lamps, pipes and crystal clusters.
- Original editable source: `Art/Blender/environment_polish.blend`. Collections keep each level separate; first mine and a clearly labelled review camera/light collection are visible on opening. GLBs contain only gameplay geometry.
- Reproducible modelling: `Tools/build_environment_polish.py`. Optional source review/render: `Tools/render_environment_polish.py`. Existing hero/boss models and shared textures are not regenerated.
- Three GLBs total 16,865,780 bytes, formerly 35,525,372 bytes (about 53% smaller). Triangle totals per module: 62,280 / 63,728 / 72,704. These are not device performance measurements.
- Neutral ambient colours and renderer-specific lighting preserve warm/cool separation. Runtime renderer detection supports Godot 4.2 and command-line compatibility tests.
- Transparent dust uses the existing Blender-rendered volume texture with an explicit soft billboard shader. It no longer appears as opaque black blobs in the inspected frames; particles do not cast shadows.

## Verification

- Captured and inspected all three levels in both Compatibility and Forward+; final `level-*-gl_compatibility.png` and `level-*-forward_plus.png` are game frames, not Blender illustrations. Their captures use an isolated test profile, fixed obstacle seed and invulnerability solely for the screenshot harness.
- Full campaign automation uses no invulnerability: levels 1/2/3 won at 9,178 / 10,322 / 13,727 simulation ticks; both phases and expected boss hits verified. `playthrough-rendered.log`: 0 assertion failures.
- `polish.log`: 0 failures, 56 buffs across 1,000 sections; menu/navigation and shuffle-bag checks passed.
- `systems.log`: 0 failures; progression, retry, saves and purchases checked with `--test`.
- Final visual captures have no script/shader errors. Headless dummy rendering emitted mesh teardown errors, so campaign was repeated with real rendering. Compatibility campaign/menu test shutdown still reports two retained GPU textures; this remains a release QA issue.
- `before.png` is an older captured pickup frame containing a colour flash, not a controlled colour comparison.

- Android 0.5-environment (code 5) and macOS exports succeeded. Actual packaged macOS navigation check: 0 failures (`packaged.log`). Artifact sizes and SHA-256 values: `builds.json`.

## Limits

Not tested on a physical phone in this pass. Android APK is a development-signed build, not a store release. The hero still differs from the approved illustration; this pass changes the environment, lighting and dust, not character anatomy. Level geometry remains visibly modular. Store signing, sustained mobile frame-time/memory testing and the shutdown texture warnings remain separate release work.
