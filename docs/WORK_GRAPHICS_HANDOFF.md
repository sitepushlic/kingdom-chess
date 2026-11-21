# KINGDOM CHESS — MASTER HANDOFF FOR CHATGPT WORK
**Updated:** 2026-11-22. **Repository:** https://github.com/sitepushlic/kingdom-chess, branch `main`.
**Purpose:** authoritative execution instructions for a new Work session. This is NOT evidence of completion. Read this entire file, then inspect the current repository and CI before editing.

## SESSION UPDATE — 2026-11-22
Starting source SHA: `ae427c0eb0405d18f79348cf0e26562e1ccca87b`.

### Fixed in this session
- `tools/art/generate_blockouts.py`: both `EnemyRookTower` helmet pieces now parent to animated `Head`; `EnemyRookBulwark` remains attached to `Arm-1`. This fixes the actual geometry hierarchy; the older `HANDOFF.md` entry saying towers should follow the arms is superseded.
- `scripts/main.gd`: fixed the indentation error in `_cycle_graphics_quality()` that stopped Godot parsing.
- `scripts/battlefield_3d.gd`: optional tween/rig/health metadata now uses a `has_meta()` guard, preventing repeated engine errors during normal redraws and animation transitions. Self-targeted attacks still animate the actor but no longer allocate zero-length attack effects.
- `tests/smoke.gd`: fixed a duplicate local variable that prevented the smoke suite from parsing. Made board palette setup deterministic, aligned cache checks with added VFX materials, searched heraldry under the rig hierarchy, used float tolerance for marker height, and guarded optional tween metadata reads.

### Verified evidence for source commit `066764bdd52468e318f622cb295188f06044f54b`
- Art pipeline passed: `compileall`; generators reported 30 heroes + 36 enemies + 6 bosses and 21 equipment GLBs; structure validation checked 72 characters; motion validation passed; limb QA checked 288 limbs/72 torsos; rig QA checked 72 GLBs/432 armor attachments; corruption tests rejected all 16 malformed GLBs; reproducibility passed for 93 GLBs; art report: 93 GLBs, 6,693,376 bytes, 283,248 aggregate triangles.
- Godot **4.3**: editor import exited 0; main scene ran to the expected 25-second timeout (124) without matched script/import errors; `tests/smoke.gd` exited 0 with `KINGDOM CHESS: GAMEPLAY LOGIC SMOKE TESTS PASSED`.
- Godot 4.7.2 local import/smoke also passed as an additional check. Earlier 4.7.2 smoke failures exposed a test parse issue and outdated assertions; those were corrected before the passing run.
- No rendered screenshot, mobile frame-time profile, physical device test, or APK build/export/sign/upload was performed. Generated models remain procedural blockouts; the graphics priority is not complete.
- GitHub Actions passed on this exact source SHA: [fast art run 44940064543](https://github.com/sitepushlic/kingdom-chess/actions/runs/44940064543) and [Godot run 44940064537](https://github.com/sitepushlic/kingdom-chess/actions/runs/44940064537), job `136955084394`. Godot 4.3 import, actual main-scene launch, and gameplay smoke all passed. Both GLB validation and 432-socket rig QA passed. The full Godot workflow skipped only cache-hit verification and reproducibility because it was a push run; reproducibility passed in the fast-art workflow and locally.
- The previous failures `44936307760` and `44936307793` were both on `4b027da6` and failed at the rook-head attachment assertion before Godot import; that blocker is resolved.

### Next action from that source commit (completed below)
Inspect the canonical roster and expand `docs/ART_MANIFEST.md` into a per-asset production/QA matrix. The next-session action is recorded in the current update below.

## SESSION UPDATE — 2026-11-22 — HERO PRODUCTION MATRIX
Starting branch SHA: `71de2e3dcdf50ae7b1a40fbe7a39af78fcba7446`.

- Reworked `docs/ART_MANIFEST.md` against all 30 canonical `hero_roster.gd` records. Added individual proposed silhouettes, weapons and palettes; exact ID/path; current generation and QA status; runtime socket mapping (`Arm1`, `SpineChest`, `Arm-1`); clip contract; proposed mobile budgets; and explicit screenshot/acceptance counts.
- Added a category status ledger for 30 heroes, 36 enemies, 6 bosses, 21 equipment models, 6 regions and 18 mission variants. It distinguishes CI-generated/imported content from authored source and visually accepted work. All authored-source and visual acceptance counts remain zero; no screenshots or art files were created in this session.
- Blender 4.3.2 is installed in the Work environment. Use it for the next actual authoring batch; preserve `.blend` source, export GLB, and integrate exports so CI does not overwrite them with the procedural generator.
- This documentation-only change was not run through tests. The last code verification remains source commit `066764b` and exact passing Actions runs listed above.

### First next action
Author `hero_01`–`hero_06` as one Blender source batch using the new briefs; export the six GLBs, preserve the shared rig/socket/animation contract, import them in Godot 4.3, visually inspect front/three-quarter/in-game views, then update the asset pipeline and CI so generated placeholders cannot overwrite accepted models. No APK.

## SESSION UPDATE — 2026-11-22 — HERO SIGNATURE DETAILS BATCH 01
Starting SHA: `b5858e4618c25f6fe1481c8aaea3d1f0cf086f69`.

- Added `tools/art/create_hero_signatures_batch_01.py` and editable Blender source `assets/characters/authored_details/hero_signatures_batch_01.blend`. It produces six original, rigid head-detail GLBs for Aelin, Bran, Mira, Toren, Lissa and Orwin (`hero_01`–`hero_06`). Blender 4.3.2 export completed: each GLB is 37–55 KB; source is about 1.3 MB.
- `scripts/battlefield_3d.gd` now mounts a selected hero's matching detail scene under the imported animated `Head` pivot. `tests/smoke.gd` asserts all six named geometry modules load below that pivot. This is accessory integration only: all 30 character bodies and animation clips remain procedural; no full hero is authored or accepted.
- Python/GLB verification passed on this source: compileall; generation of 30 heroes, 36 enemies, 6 bosses and 21 equipment assets; structure validation (72 characters + 21 equipment), motion, limb geometry, rig attachments (432), corruption rejection (16/16), reproducibility (93 GLBs), and art report (93 GLBs, 6,693,376 bytes, 283,248 aggregate triangles). The six new GLBs' named signature nodes were also checked directly.
- Godot 4.3 local editor import did not finish within the local command window, leaving no import cache. The first smoke invocation therefore failed before loading the game because SVG resources were not imported; this is an environment/import prerequisite failure, not a passing test. The updated Godot workflow must verify the exact source commit. No visual screenshot, Android device QA, FPS measurement or APK work was done.
- Updated `docs/ART_MANIFEST.md`: six authored detail modules are tracked separately from full-body authored heroes; import/visual acceptance remain unverified.

### CI failure and fix — 2026-11-22
- Source commit `2aa3918b47086bff0276f3ddeea11aae01d4c2bb`: fast art workflow passed ([run 44942007310](https://github.com/sitepushlic/kingdom-chess/actions/runs/44942007310)); Godot workflow failed at editor import after 240 s, before main-scene launch or smoke ([run 44942007382](https://github.com/sitepushlic/kingdom-chess/actions/runs/44942007382)).
- Root cause isolated locally: Godot 4.3 treats `.blend` files under the project as Blender-importable scenes and hangs when Blender source is in the scanned resource tree. Six authored GLBs import successfully. Moving the editable `.blend` into `assets/characters/authored_details/blender_source/` with `.gdignore` allows editor import to complete (exit 0).
- With the fix staged locally: Godot 4.3 editor import passed; main scene remained running until expected 25 s timeout (124) with no matched parser/import errors; `tests/smoke.gd` reached `KINGDOM CHESS: GAMEPLAY LOGIC SMOKE TESTS PASSED`, including all six new detail assertions. Headless dummy-renderer `mesh_get_surface_count(null)` warnings were emitted by existing smoke setup. Exact-commit CI is still required.

### Next action
Commit this import fix and updated source path; verify both workflows for the new exact source SHA. Then build the first full original rigged hero body and clips, not only more head accessories. APK remains untouched.

## 1. USER'S DIRECT ORDERS — HIGHEST PRIORITY
1. Finish **priority 1: complete playable 3D graphics** for Kingdom Chess, not a demo, static concept art, or another batch of superficial procedural blockouts.
2. Do the **maximum substantive, coherent work per session**; do not stop after one tiny edit. Act autonomously within the agreed graphics scope, without repeatedly asking for permission. Do not claim work continues when the session has stopped.
3. **DO NOT build, export, sign, upload, or otherwise touch an APK** until the user explicitly reverses this instruction. Android-related *source configuration*, renderer and non-APK validation are allowed. Older notes asking for an APK at graphics completion are superseded.
4. Do not start priority 2 (gameplay mechanics/balance/economy), marketing, deployment or new product scope without explicit permission. Only fix gameplay regressions directly blocking 3D integration, preserving existing rules.
5. Update **both** `docs/WORK_GRAPHICS_HANDOFF.md` and `docs/HANDOFF.md` after every substantive session, with actual commits, test evidence, blockers, exact next actions.
6. Communicate in **concise Russian, facts only**: what was committed, what actually passed, what failed, what remains. Never claim tests, visual quality, mobile FPS or completion without proof. Avoid long speculative status reports and frequent small summaries.
7. Do not overwrite unrelated changes; inspect current branch head and SHA before writing. Prefer cohesive commits and a verified test loop. Back up a known-good baseline before destructive restructuring.

## 2. PROJECT CONTRACT AND AUTHORITATIVE SOURCES
- Engine: **Godot 4.3**, GDScript, GL Compatibility renderer. Project: `project.godot`; startup: `scenes/main.tscn`; Android portrait design **720 × 1280**.
- Game: chess-based RPG with heroes, enemies, bosses, regions, progression, equipment, campaign, 3D board and combat effects. Keep logical chess rules, square indexing, battle events, progression, unlocks and saves unchanged unless a graphics blocker is demonstrated.
- `scripts/main.gd`: game/UI orchestration, 3D battlefield calls, hero and gear selection, effects and battle event hooks.
- `scripts/battlefield_3d.gd`: 3D chess board, meshes, GLB imports/fallbacks, rigs, animation, boss phases, effects, biomes, graphics tiers, coordinate labels, tactical markers.
- `scripts/hero_roster.gd`: **canonical source for all 30 heroes**, their exact IDs `hero_01` through `hero_30`, Russian names, class, rarity, role, stories and unlock conditions. Do not infer details from old notes if the file changed.
- `scripts/progression.gd`: canonical region, mission, gear rarity, rewards and unlock rules. Preserve scarcity of strongest characters/equipment and fair progression.
- `docs/ART_MANIFEST.md`: existing 30-hero inventory, but its procedural silhouettes are **not** final authored art. Extend with actual asset paths, visual identity, rigs, clips, socket compatibility and validation state.
- `tools/art/`: reproducible Python GLB asset generation and validators; `assets/characters/`, `assets/equipment/`: character/equipment asset locations. `tests/smoke.gd`: headless gameplay and graphics regression checks.
- `.github/workflows/art-validation.yml`: fast Python art generation/validation CI; `.github/workflows/android.yml`: Godot import/gameplay/3D checks. Its name is historical: **do not enable APK export**.
- `docs/HANDOFF.md`: chronological history; useful for previously fixed issues, but this document and current source/CI are the execution contract.
- `docs/WORK_GRAPHICS_HANDOFF.md`: this master handoff. Check source truth and actual latest CI rather than assuming historical claims are current.

## 3. VERIFIED BASELINE AND CURRENT BLOCKER (2026-11-21)
**Latest source change preceding this handoff:** `4b027da6e9161c2d86def4bb10c2129221739108` added actual `ArmorAscendantWing*` geometry for tier-six armor, correcting `validate_blockouts.py`'s missing ascendant silhouette failure. `f11770ab` updated the chronological handoff. The earlier failed run `44934284491` had stopped at `armor_tier_6.glb: final rarity missing ascendant silhouette`.
**New verified evidence:** fast art CI run **44936307760** (at `4b027da6`) failed at `Verify 432 rigid armor sockets and rest-pose transforms`, job **136943562093**. Actual log:
`AssertionError: .../assets/characters/enemy_r_region_0.glb: EnemyRookTower-1 not attached to animated head`
from `tools/art/test_rig_attachments.py:166`. Before this, the same run passed art GLB structure validation, motion validation and subdivided limb geometry validation. The full Godot workflow run **44936307793** also failed; inspect its job logs independently to identify the precise first failure. **No green Godot import, smoke test, rendered inspection, or device playtest is established by these observations.**
**Immediate first task:** inspect generated GLB parent hierarchy for `EnemyRookTower-1`, compare all `EnemyRookTower*` attachments, expected joint parents and current validator. Determine whether generator or assertion is wrong. Fix the **real rig attachment or incorrectly modeled expectation**, never just delete the assertion. Run all relevant validators and CI; only then advance to Godot import/smoke. The earlier rook-helmet fix for `EnemyRookTower` may not cover the `-1` mirrored piece. Check both.

## 4. CURRENT ART INVENTORY — DO NOT CONFUSE WITH FINISHED ART
- Python generator reports **72 character GLBs**: 30 heroes, 36 region-specific enemies and 6 bosses; plus **21 modular equipment GLBs** = 3 slots (weapon/armor/relic) × 7 tiers. These are **generated procedural assets/blockouts**; the repo may not commit every generated binary because CI regenerates them. Verify exact tracked files, actual GLB contents, skin/joint assignments and animation clips before declaring coverage.
- Six regional environments/landmarks, 18 mission variants, board cosmetics, biome lights, environmental effects, selected hero identity, boss aura/phase effects, critical HP rings, combat numbers, coordinate labels, last-move markers and equipment rarity halos are partly implemented. They require rendered visual acceptance and performance profiling.
- Existing runtime has class-based fallback geometry and asset resolution; final art must show individual identity and distinct enemies/bosses rather than relying on recolored shared pieces or static OBJ fallbacks.
- Recent movement, attack anticipation, boss phase tween and square-lock race fixes are committed, **not automatically verified**. Preserve them and test their interaction with animations.
- Some earlier environments lacked Godot/Blender; do not assume a local executable is present. In Work, inspect environment, install permitted tools if needed, or use GitHub Actions as the actual test runner.

## 5. FINAL GRAPHICS ACCEPTANCE CRITERIA
**Heroes (30/30):** each hero has its own readable original silhouette, face/headwear, costume, proportions and signature weapon, class and lore-aligned styling, meaningful rarity presentation, functional material/texture setup, correct rig and sockets. 30 uniquely named GLBs alone do not prove uniqueness. Capture a consistent front/three-quarter/in-game view per hero; verify hero selection changes only the intended actor, not every chess unit of that class.

**Enemies (36/36) and bosses (6/6):** recognizable class/region identities, unique boss scale and landmark visual language, appropriate phase changes, readable attacks and telegraphs. Test quick phase reversals, boss recreation, region transitions and despawns. No floating gear, broken head attachments or stale tweens.

**Equipment (21/21):** 7 genuinely distinct geometry/material rarity tiers for each of weapon/armor/relic, socketed to the correct animated bone, correct equipped loadout, no legendary appearance for locked low-tier gear. Validate all combinations and quality-tier visibility. Never fix art tests by weakening real geometric expectations.

**Animations:** authored, correctly imported skeletal clips for idle, locomotion/move, physical attack, cast/magic attack where relevant, hit/recoil, death/defeat and victory/ability where used. Check actual playback triggers, animation transitions, pose reset, rapid consecutive actions and actor deletion. No armor remaining stationary while the animated limb moves.

**Worlds:** six visually distinct fully 3D biomes and 18 mission variants, with readable board squares, hazards, legal moves and boss threat markers in portrait framing. Unique environment architecture, lighting, materials, ambience and meaningful boss/mission visual differences. Avoid decorative clutter obscuring chess logic.

**VFX/HUD:** physically readable melee/projectile effects, hits, spellcasting, buffs/debuffs, environmental effects, equipment glow, HP/damage/healing and selected/last-move indicators. Quality tiers 0/1/2 work at runtime; cap/pool temporary nodes and avoid repeated material/mesh allocations.

**Technical:** reproducible art build; structural GLB/rig/socket validation; Godot 4.3 import and smoke tests pass; no parser/runtime errors, missing resources or unintended gameplay regressions. Inspect actual rendered screenshots/video for clipping, proportions, materials, legibility and camera. Profile mobile-conscious draw calls, memory and frame time. **Physical Android validation remains unverified unless actually performed; no APK creation without new user instruction.** Graphics cannot be called finished until these conditions are verified or blockers are clearly reported.

## 6. EXECUTION ORDER — COMPLETE EACH GATE, KEEP GOING
### Gate A — establish baseline and remove blockers
1. Inspect `git status`, branch head, full tree, `docs/HANDOFF.md`, this handoff, `docs/ART_MANIFEST.md`, art generators/validators, renderer, scene and smoke tests. Record baseline commit SHA.
2. Inspect **latest** fast art and Godot Actions runs, failed step and full logs. Fix first reproducible art/rig failure (`EnemyRookTower-1` currently known), then any subsequent failures. Rerun until art pipeline green. Do not use a later skipped test as proof it passed.
3. Run local `python3 -m compileall -q tools/art`; `python3 tools/art/generate_blockouts.py`; `python3 tools/art/generate_equipment.py`; `python3 tools/art/validate_blockouts.py`; `python3 tools/art/validate_motion.py`; `python3 tools/art/test_limb_geometry.py`; `python3 tools/art/test_rig_attachments.py`; `python3 tools/art/test_validator_failures.py`; `python3 tools/art/check_reproducibility.py`; `python3 tools/art/export_art_report.py` where environment permits. Collect actual output and exit codes.
4. Run **Godot 4.3** editor headless import, main-scene launch and `tests/smoke.gd` using exact CI commands/config. Fix GDScript parsing/import errors before layering more art. **No APK export.**

### Gate B — production art specification and pipeline
5. Read **all** 30 hero records and region/mission/gear records. Update `docs/ART_MANIFEST.md` into an actionable per-asset matrix: exact ID/path, silhouette, lore palette, costume/face, weapon, armor/relic sockets, rig version, required clips, triangle/texture budgets, owner/status and screenshot evidence.
6. Create/upgrade deterministic original art source generation, ideally Blender-authored/editable `.blend` where practical plus importable `.glb`; preserve licenses/provenance and reproducibility. Generated GLBs should be available to CI and local Godot, with exact commands documented. If connector cannot upload binaries, use Work's cloud terminal/git rather than pretending a text-only commit contains finished assets.

### Gate C — heroes and NPCs
7. Build and visually review all 30 hero identities in batches, using one compatible rig architecture with truly distinct character geometry. Implement all required animation clips and stable socket transforms; inspect skins and weights under animation.
8. Build/upgrade all 36 regional enemies and six bosses; verify mirrored attachments (including `-1` variants), armor, boss phases and region changes. Replace broken fallbacks and add tests for missing/malformed assets.

### Gate D — equipment
9. Finish 21 modular gear models with real shape progression, consistent rig sockets and rarity readability. Validate gear swaps on every hero class, equipped item ownership and low/medium/high quality toggles. Add screenshot/animation comparison checks.

### Gate E — regions, effects and camera
10. Complete six region environments and 18 mission visual variations, region-specific boss arena presentation, lighting and weather, with unobstructed 8×8 board. Make VFX animation responsive to gameplay events and safe under rapid moves/attacks/phase changes.
11. Validate portrait camera at 720×1280 and common phone aspect ratios; compare visuals at tiers 0/1/2. Profile geometry, materials, particles, lights, draw calls and memory with real measurements; optimize without destroying distinctiveness.

### Gate F — final regression and delivery
12. Re-run full art pipeline, Godot import, main-scene launch and smoke. Verify CI status on the **exact final commit**; collect logs, GLB inventories and rendered visual evidence. Preserve chess move correctness, save data, equipment ownership, unlocks and battle-state synchronization.
13. Update both handoffs and art manifest with per-category verified/unverified counts, commits, exact failures, run links and next steps. Report graphics complete **only if actual acceptance evidence supports it**. Never create an APK until separately authorized.

## 7. IMPORTANT TECHNICAL INVARIANTS
- The logical board uses **64 indexed cells**; actor movement animation must never alter the authoritative board state or leave a movement lock behind.
- Cancel superseded actor movement, attack anticipation and boss phase tweens; bind animation lifetimes to valid nodes. Verify rapid consecutive moves, captures, actor deletion and boss 1→2→1 transitions.
- VisualRig/node hierarchy may differ from actor root; locate nested boss aura and equipment sockets correctly, not with assumptions about direct children. Helmet/tower should move with animated head; shields should move with their intended arm. Validate mirrored attachments individually.
- Health bars and critical warning rings must preserve current HP after actor/biome recreation; no reset to full HP visually. Preserve gear rarity VFX when switching quality tiers.
- Keep tactical UI (selection, safe moves, captures, danger, hazards, coordinate labels, last move, damage numbers) legible over decorative art. Low quality must not hide necessary tactical information.
- Reuse static mesh/material resources; bound transient tweens and limited pooled combat numbers prevent mobile spikes. Avoid per-frame allocations.
- `main.gd` hero-ID routing must distinguish selected hero from other pieces of the same chess class; test this explicitly.
- Preserve user progression and save compatibility. Strongest heroes and equipment must remain unlock-gated; **do not modify balance as part of graphics production**.

## 8. HOW TO WORK EFFICIENTLY AND SAFELY
- One substantial session should address a coherent end-to-end milestone (e.g. repair art CI + import + rig QA), not dozens of isolated cosmetic one-liners. Run validation after meaningful groups of edits.
- Read source files completely before changing behavior; inspect generated GLB hierarchy instead of guessing. Commit coherent changes with descriptive messages. If changing files concurrently, fetch current SHA before updating; resolve conflicts instead of force-pushing.
- CI trigger caveat: docs-only commits may not trigger art/Godot workflows. Verify that the latest **source** commit has a corresponding completed run; if not, use an allowed manual workflow dispatch or a meaningful source commit. Never report green based on a different SHA.
- Work may use local terminal/cloud browser to download tools, generate binary assets and capture render evidence. GitHub connector alone may not suffice for binary authoring. If tooling unavailable, record precise limitation and leave reproducible scripts; do not claim assets were built.
- Keep a small explicit evidence ledger: commit SHA, workflow run URL/job, exit status, count of checked GLBs, actual screenshot paths, known missing checks, measured performance. Avoid unverifiable percentages.
- Do not deploy, merge destructive rewrites or publish APK. Avoid external copyrighted 3D models unless licensed and provenance recorded.

## 9. SESSION HANDOFF TEMPLATE (UPDATE EVERY SESSION)
- Date/time, starting and ending branch SHA.
- Exact files/assets changed and why; commit URLs.
- Art inventory: 30 heroes / 36 enemies / 6 bosses / 21 gear / 6 regions / 18 missions; for each: generated, imported, animated, visually inspected, accepted (separate statuses).
- Tests actually executed with commands, logs, results, CI URLs and matching commit SHA; explicitly list skipped/blocked tests.
- Visual inspection evidence (screenshots/video) and measured performance (if any).
- New regressions, outstanding bugs in severity order and **the first exact next action**.
- Confirm: **APK untouched**; graphics-only scope maintained; no background work implied.

## 10. DIRECT INSTRUCTION TO THE NEXT WORK SESSION
> Open `sitepushlic/kingdom-chess` on `main`. Read `docs/WORK_GRAPHICS_HANDOFF.md`, `docs/HANDOFF.md`, `docs/ART_MANIFEST.md` and the actual source. First diagnose and fix the latest art CI rig failure for `EnemyRookTower-1`, rerun validators and Godot 4.3 import/smoke, then continue autonomously through full original 3D hero/enemy/boss/equipment/environment production, animation integration, visual review and optimization. Do maximum substantive work per session, not micro-commits. Preserve chess logic, update both handoffs with evidence, and commit work to GitHub. **Do not build/export/sign APK. Do not start gameplay priority 2. Do not claim completion without real test and visual evidence.** Provide a concise Russian final report with commits, proven results and exact remaining blockers.
