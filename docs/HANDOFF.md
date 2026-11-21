## LARGE GODOT SMOKE FIX + SIX BIOME LANDMARKS — 2026-11-21
- **Godot fix `5f6680d`**: removed `mesh.get_surface_count()` from recursively checking every `MeshInstance3D` in headless smoke. The user showed Godot 4.3 dummy RenderingServer `mesh_get_surface_count(null)` errors. Querying GPU surface counts under `--headless` can trigger these backend errors even for resources present; smoke now checks non-null meshes and Python GLB validators check actual geometry. This is a concrete suspected error source removed, but not a proven complete fix without green CI.
- **3D graphics `3e0e6be`**: implemented `_build_biome_landmarks` in `scripts/battlefield_3d.gd`, six region-specific groups outside the 8x8 chessboard: (0) forge furnaces and crenellated chimneys; (1) fractured ice cathedral and floating core; (2) ancient grove trees with branched crowns and roots; (3) astral rune pylons and portal rings; (4) storm batteries, coils and antennae; (5) void crypt gravestones, ritual circles and crown shards. Shared cached meshes, no added dynamic lights, region switching frees old scenery. This is substantive environment geometry, still procedural rather than final art.
- **Graphics tests `90d652a`**: all six biomes must expose their named landmark node, >=10 direct mesh children, all with non-null mesh resources. Existing six-region geometry and lighting assertions remain.
- **CI diagnostics `32320c5`**: missing smoke success marker prints first 120 and last 100 log lines, exposing original root failure instead of only repeated renderer warning tail. Existing focused `TEST FAILED` detection retained.
- **User constraint**: APK, Android SDK and export intentionally removed from CI (`bd622896`, `848e20e5`); do not resume until user explicitly requests. Prior game poison movement fix `10c04aa`, 3D impact effects `943b969`, tests `13ad94e`, `c671b3e` remain.
- **Verification**: source changes committed to main; Godot 4.3 runtime smoke **not yet verified green**. No local Godot binary, and GitHub connector lacks latest-run listing/dispatch. Next actual CI log is needed to establish remaining failures. Do not claim game or 3D production graphics finished.

## LARGE GODOT-ONLY / GAMEPLAY / GRAPHICS PASS — 2026-11-21
- **Mandatory user priority:** no APK export, no Android SDK setup, no signing or templates until user explicitly reauthorizes. Concentrate on Godot 4.3 gameplay smoke and finished 3D graphics. Do not call project done without green run and visual review.
- **CI `bd622896`, `848e20e5`**: `.github/workflows/android.yml` now operates as a Godot-only workflow (historical filename retained for Actions URL). Removed Java setup, Android SDK installation, signing key setup, Android export templates download/verification, APK export and APK upload. Godot 4.3 editor download, 93-asset generation/cache and validation, project import, main scene launch and smoke tests remain. Job renamed `godot`, summary says APK paused. This cuts Android-only setup time and avoids misleading APK status. **No current green run verified.**
- **Gameplay `10c04aa1`**: `_move` in `scripts/main.gd` now transfers `poison_marks` with the moving enemy and clears captured unit poison, mirroring existing `hero_poison` movement; prevents poison sticking to an empty square or being inherited by a capturer. **Tests `13ad94ee`** cover enemy movement, capture replacement and reset.
- **Godot mesh diagnostics `aa16d513`**: `tests/smoke.gd` recursively inspects all `MeshInstance3D` nodes under battlefield and checks `mesh != null` and positive surface count; prints full node path for failures. This targets the user-provided `mesh_get_surface_count(null)` log tail but **root cause remains unverified until fresh Actions logs**.
- **Graphics `943b969d`**: `scripts/battlefield_3d.gd` adds shader-free, light-free 3D radial impact shockwave + class-tinted 4/8 flying sparks for medium/high graphics; low tier creates none. All transient geometry tweened and freed. **Tests `c671b3e3`** verify 0/5/9 new nodes across tiers. Earlier work includes character idle breathing, six biome scenery sets, ambient transitions, 72 procedural rigged GLBs. These are still procedural assets, not final polished models.
- **Unresolved:** get actual Godot CI log including first `TEST FAILED` or `SCRIPT ERROR` and fix until smoke passes; current headless renderer may emit dummy mesh errors. Run visual checks on actual Godot 4.3 renderer. Continue significant character mesh, animation, environment and effects refinement. Do not spend time on APK or cosmetic border ornaments.

## GODOT SMOKE RENDERER + BIOME GRAPHICS — 2026-11-21
- **CI `b5cb4f0`**: Godot smoke runs explicitly with `--headless --rendering-method gl_compatibility` to request compatibility rendering; full logs and assertion failures retained. This may not eliminate Godot dummy-renderer `mesh_get_surface_count(null)` errors: must verify with a new Actions run. Screenshot from user shows failing `Run gameplay smoke tests` and null-mesh warnings, but not first failure lines; no green run proven.
- **3D art `4d1259a`, `086ccff`**: per-biome background and ambient light now crossfade over ~1 second without extra dynamic lights or allocations; biome rim light updates immediately for existing region-identity smoke assertions. Enemy/environment 3D scene rebuild and chess logic unchanged. Needs runtime verification.
- **User constraint is mandatory**: Android APK export and artifact remain disabled (`if: false`) in `.github/workflows/android.yml`; do not resume until explicitly requested. Focus on Godot gameplay smoke and substantive character/environment graphics.
- **Current blocker**: retrieve first `TEST FAILED`/`SCRIPT ERROR` from new smoke log if run fails; don't mistake headless renderer warnings for definitive root cause. No local Godot binary; connector supports repo edits but not dispatch/list latest workflow runs. No verified successful Godot smoke yet.

## USER PRIORITY CHANGE: FIX GODOT, PAUSE APK, FINISH 3D GRAPHICS — 2026-11-21
- **Explicit user instruction**: Android APK is NOT wanted now. Do not resume APK build/export until user asks. Priority: Godot 4.3 gameplay smoke passing, then full 3D character/environment polish. This overrides older handoff APK priorities.
- **Observed from user screenshot**: current Actions job reaches `Run gameplay smoke tests` and exits code 1; log tail repeatedly reports `ERROR: Parameter "m" is null` at `mesh_get_surface_count (servers/rendering/dummy/storage/mesh_storage.h:120)`. APK export was skipped as a consequence. Screenshot only contains the tail; full first error/assertion is unknown, so do not attribute all failures to renderer without complete log.
- **Code `28ab6f85`**: corrected fallback reward power clamp to legal maximum for final level/rarity (level-one common <=11). Previous fallback could retain level-two power after level downgrade and fail newly added starter loot assertions.
- **CI `c08f23bd`**: renamed workflow to Godot gameplay and 3D art verification; APK export and APK artifact upload explicitly disabled with `if: false`. Smoke step now prints focused `TEST FAILED`, `SMOKE ASSERTIONS FAILED`, script and parse errors to distinguish assertion failures from headless dummy-renderer noise. Godot import, game launch, art validation and gameplay smoke remain active. Next Actions run required for confirmation.
- **Graphics `b0bf4449`**: added distinct per-unit low-amplitude breathing/weight-shift idle motion to 3D battlefield actors, respecting active move tween ownership and low-quality tier.
- **Not yet verified**: fresh green Godot smoke result or on-device visual appearance. Need inspect new run full logs; fix root cause, then prioritize detailed models/rigs/animation/lighting over decorative board ornaments.

## GODOT / APK RELEASE BLOCKER — 2026-11-21
- **Build diagnostics commit `27298169`**: CI now reports runner disk/RAM, Python/Java, checks actual Godot 4.3 executable version, validates Android debug/release export template files and project/preset before import. Push to `main` triggers the existing Android workflow automatically; no APK is claimed without a completed workflow and artifact.
- **Verified constraints this session**: local runtime has no `godot`/`godot4` executable, and terminal DNS cannot reach `github.com` or `api.github.com`. GitHub connector can read/write files and inspect a known run ID but exposes no workflow dispatch or latest-runs listing. Therefore no local build or newly verified APK can be produced here. Old run `44927365536` was cancelled during art generation before Godot import; it does not diagnose a Godot parse failure.
- **Immediate priority**: get current Actions job URL/logs and artifact, diagnose any failing step, fix and rerun until APK exists. Do not label this as fixed until verified. Then finish production-level 3D characters, animation, environment and Android playtest. Do not waste steps on cosmetic border details ahead of build blocker.

## LOOT POWER BALANCE + REGRESSION COVERAGE — 2026-11-21
- **Code `e6733ec`, `48eff14`**: `scripts/progression.gd` no longer silently downgrades a high-rarity random reward while keeping high-tier combat stats when the 40-roll fallback is reached. It generates a normal fallback item and, if necessary, adjusts power, attack, armor, HP, crit, lifesteal, penetration, block, bleed and rarity to the player's legal cap. The fallback preserves equipment slot and uses normal item stat formulas. The ordinary reward path is unchanged.
- **Tests `6cd6eb0`**: `tests/smoke.gd` adds 100 starter reward draws with 200 assertions for common-tier level-one power budget (<=11) and immediate equippability. Existing 420 random rewards x 2 assertions remain.
- **CI status**: source changes committed, **no fresh Godot execution or Android APK verified**. Earlier run 44927365536 was cancelled before Godot import. Need inspect current GitHub Actions jobs/logs, verify parser, smoke, APK; CI art cache and skip-reproducibility optimizations from `bc871e1` and `877ed69` are in main.
- **Graphics**: 3D board trim/studs/crests from `9629c2e` and `f9895310` are committed but not visually verified in running Godot. Further character/environment polish required.

## ANDROID BUILD THROUGHPUT + 3D FRAME DETAIL — 2026-11-21
- **CI `877ed697`**: `.github/workflows/android.yml` now runs full 93-GLB deterministic regeneration (`check_reproducibility.py`) only for manually dispatched workflows; regular pushes still generate/cache all 93 GLBs and run all asset validity, motion, skin, sockets, corruption tests, real Godot editor import, game launch, gameplay smoke, and Android APK export. This removes a second expensive complete art generation pass from every APK push. Manual reproducibility verification remains available. Not yet proven green.
- **Graphics `f9895310`**: 3D chessboard receives four inset two-tone rails and eight angled heraldic corner plate details, complementing bronze border studs and crests from `9629c2e`. Shared meshes, no added lights, no chess square modifications.
- **Known unresolved**: no confirmed current Godot 4.3 Actions green run or exported APK from these commits. Previous cancelled run `44927365536` ended at art generation before Godot; cancellation was not a parser error. Verify latest workflow job logs and artifacts. 3D models are procedural blockouts and not yet final-quality assets.

## GODOT BUILD BOTTLENECK + BOARD VISUALS — 2026-11-21
- **CI commit `bc871e1`**: `.github/workflows/android.yml` now caches all 93 generated GLBs via `actions/cache@v4`, keyed by the two art generator source files and runner OS. Cache hits skip expensive generation and verify exactly 72 character GLBs plus 21 equipment GLBs. Cache misses generate normally; all downstream art validation, Godot import, real main scene launch, smoke tests and Android APK export remain required. This optimizes repeated CI runs; **it does not yet prove Godot build success**.
- **3D visual commit `9629c2e`**: `scripts/battlefield_3d.gd` adds 32 bronze border studs and four sculpted bronze corner crests on the 3D board, outside chess squares. Shared primitive meshes/materials limit mobile GPU cost. Visuals are still procedural rather than finished production character art.
- **Verified historical CI evidence**: run `44927365536`, job `136916368114`, status `cancelled` specifically at `Generate original GLB character blockouts`; Godot import/launch/smoke/APK steps were skipped. This is a cancelled build, **not a confirmed Godot parser error**. Prior concurrency fix `f3b5f720` prevents subsequent commits cancelling active builds. No current successful run or APK verified here; direct public Actions webpage access was unavailable. Need inspect newer run's actual logs and APK.
- Next: confirm current Android Actions run completes, fix exact Godot errors if any, test on Android hardware, iterate on characters, animation and environment art. Always update this HANDOFF with concrete code commits and validation state.

## COMBAT EVENT LOG FIX — 2026-11-21
- **Gameplay code commit `cba65058`**: `scripts/main.gd` now appends critical-hit and block events instead of overwriting the previous battle log, and renders bleed messages with an actual newline rather than a visible `\\n` escape. This preserves turn-by-turn feedback for multiple combat effects in a single action.
- Previously committed loot usability fix `dd060bf` and 420 reward-generation Godot smoke assertions `8186686` remain in main. These changes were committed but **not verified by a current Godot execution**.
- **Handoff updated in this commit**. Environment has no local Godot binary or working direct GitHub clone; obtain actual Actions run status, Godot 4.3 parser/import/smoke output and APK before claiming build success. Prior run 44927365536 was cancelled, not a successful APK build. Remaining: CI green, playable Android validation, visual polish and broader battle testing.

## CAMPAIGN LOOT USABILITY FIX — 2026-11-21
- **Code `dd060bf`**: `Progression.roll_item_for_progress` now rejects generated loot with `item.level > player.level`, in addition to rarity exceeding `rarity_cap(wins, level)`. The old `roll_item` deliberately rolls levels from `level - 1` through `level + 1`, so a valid-rarity drop could previously be unusable when earned. It now retries for a usable item and, after 40 retries, clamps the generated item's rarity and level to the earned gates without inflating stats. Level input is bounded to 1..50.
- **Godot test `8186686`**: 420 generated drops across 7 levels × 5 victory counts × boss/non-boss × 6 iterations with maximum luck, asserting each is valid and `Progression.can_equip` returns true. Added to `tests/smoke.gd`; **not yet executed in Godot**, no APK green claim.
- Existing prior changes: `32bced48` rejects forged core equipment stats >10,000; `d177babf` adds regression tests. CI `f3b5f720` prevents cancellation of running Android jobs by subsequent commits; docs-only changes are ignored.
- **Known limitation**: Godot binary is absent in this execution container and direct GitHub clone failed DNS; use GitHub Actions actual Godot 4.3 import/launch/smoke/APK to verify. CI results for these new commits are still unverified. Next pass must get current Actions job logs and fix the first failing stage; graphics remain procedural blockouts, not finished production 3D.

## SAVE INTEGRITY / GODOT REGRESSION — 2026-11-21
- **Code commit `32bced48`**: `scripts/progression.gd` rejects saved equipment with `power`, `attack`, `armor` or `hp` greater than 10,000 (and negative stats). Previously `is_valid_equipment_item` allowed these fields up to 1,000,000, enabling edited local saves to equip extremely overpowered gear. Existing percentage stat ceilings remain 100; generated items are expected to remain below the generous ceiling.
- **Test commit `d177babf`**: `tests/smoke.gd` verifies legitimate generated equipment is accepted, forged oversized values in all four core stats are rejected, and `sanitize_profile` removes a forged item and clears the equipped weapon slot. These are added to the actual Godot smoke suite, **not yet reported passing**.
- Android CI no longer cancels in-progress builds and docs-only commits no longer trigger builds (`f3b5f720`). This pass changed actual gameplay progression validation and test code. **No local Godot binary/network access**; must inspect fresh GitHub Actions run and APK before claiming green. Latest run ID/actual Godot launch remain unverified.
- Next: obtain concrete CI job diagnostics, fix any parser/import/smoke failure, verify APK; further develop battle flow, animations and high-quality character/environment assets. Do not claim the procedural blockouts are production-quality graphics.

## ANDROID CI UNBLOCKING / GODOT EXECUTION — 2026-11-21
- **Commit f3b5f720** fixes repeated build cancellation: `.github/workflows/android.yml` now uses `concurrency.cancel-in-progress: false` and ignores documentation-only pushes (`docs/**`, `**/*.md`) for the Android push trigger. Manual `workflow_dispatch` remains available. Android job timeout is explicitly 55 minutes. This allows a real long-running Godot import, main-scene launch, smoke and APK export to finish without being cancelled by frequent handoff commits; queued builds may still run sequentially.
- **Execution environment limitation:** this assistant's local container has no `godot`/`godot4` executable and `git ls-remote https://github.com/sitepushlic/kingdom-chess.git HEAD` failed with `Could not resolve host: github.com`. Therefore Godot was **not launched locally**, and no current APK success or device screenshot is claimed. The repository's GitHub Actions Android workflow contains Godot 4.3 download, actual headless main-scene launch, gameplay smoke, export and APK ZIP validation. Confirm the new workflow run's job steps and artifact before calling the fix verified.
- Previous checked Android run 44927365536 ended cancelled during GLB generation (no Godot launch or APK); it is not evidence of a code failure. Next: inspect latest GitHub Actions Android job status/logs; fix the first actual failed step, rerun to green; then inspect real Godot rendering and implement remaining art and tactical piece-duel gameplay. Keep this handoff current without triggering needless Android runs.

## CI VERIFICATION CHECKPOINT — 2026-11-21
- GitHub connector confirmed Android workflow run **44927365536** ended **cancelled**, not failed: checkout, Java, Android SDK, Godot download and Python compile steps succeeded; character GLB generation was cancelled, so Godot import, gameplay smoke and APK export were **not run** in that attempt. Do not mistake cancellation for a passing build.
- `.github/workflows/android.yml` uses `concurrency.cancel-in-progress: true`; each new commit to `main` cancels the previous Android run. The workflow does contain actual Godot 4.3 headless import, main-scene launch, smoke tests and APK ZIP integrity checks. Their success for the latest code remains unverified.
- This checkpoint is based on GitHub Actions job metadata, not local Godot execution. Local clone was blocked by network DNS in the execution container. Next pass must inspect newest Android run and failed job logs; avoid rapid pushes during long builds. No new gameplay or graphics implementation is claimed in this checkpoint.

## ART GENERATOR PERFORMANCE / DETERMINISTIC TEXTURE CACHE — 2026-11-21
- **New commits 1aa15d2a and ae7cbde0**: `tools/art/generate_blockouts.py` now caches the **five 128×128 albedo PNGs and five 128×128 tangent-space normal PNGs** in one module-level `_PNG_CACHE`, shared across **all 72 exported character GLBs**. These textures have no per-character colors: glTF `baseColorFactor` tints each model, so byte-identical PNG payloads are correct. This removes repeated pixel/noise/compression work in the 72-model generation batch, preserving the original embedded texture data and deterministic output.
- **New generator invariant**: `main()` asserts `len(_PNG_CACHE)==10` after generating 30 heroes, 6 bosses and 36 enemies. Cache does not remove embedded textures from GLBs: each character remains standalone and portable with 10 PNGs and five PBR materials.
- Last **confirmed** art CI green **44926764406** at a0a37097. Android run **44927365536** for previous mesh-cache handoff was still in progress when checked; latest art and Android runs for texture-cache commits are queued/in progress. Check final results and logs, do not claim latest APK passed.
- Graphics are still procedural stylized low-poly, not finished. Next priorities: confirm full Android Godot smoke and build; inspect any new failures, capture device screenshots/FPS, improve 3D characters/animations/castle and implement documented anti-classic-engine tactical chess-piece duel combat. Handoff updated every pass.

## GPU RESOURCE SHARING / 3D ART PERFORMANCE — 2026-11-21
- **New substantial runtime optimization commits eb535dc3 + 059410d0:** `scripts/battlefield_3d.gd` now uses a per-battlefield `primitive_mesh_cache` to share Godot `BoxMesh`, `CylinderMesh`, `SphereMesh` and `TorusMesh` resources across repeated castle, board and character-fallback details. Keys include the complete shape dimensions, preserving different silhouettes; every `MeshInstance3D` still retains its own position, scale, material and visibility. Reduces redundant procedural mesh creation and GPU resource uploads. **This does not imply fewer draw calls or measured FPS improvement**; benchmark on Android remains necessary.
- **Regression test 7c9dab6e** in `tests/smoke.gd`: creates two same-size boxes and rings and asserts mesh resources are shared while box materials/positions remain independent. Smoke also tests low/medium combat VFX, zero-distance spells, castle detail, hero progression, chess/raid mechanics.
- Last confirmed fast art success remains **44926764406** (a0a37097). Android workflow run **44927151856** (da170796) was **cancelled** by newer commits, with no failed steps before cancellation. New Android CI for this pass queued/in progress; **do not claim successful latest APK** until it finishes. Concurrency auto-cancels previous builds on each push, so minimize subsequent commits while waiting.
- Prior low-tier combat VFX optimizations and six-boss animation tests remain. Graphics are still stylized procedural low-poly, not complete, and Android screenshots/FPS unavailable. Next: confirm Android build and smoke, fix any GDScript compile failures, inspect render screenshots, improve characters/environment and complete board duel gameplay as designed in `docs/GAME_VISION_AND_LEARNING_ROADMAP.md`.
- Handoff updated as requested.

## ANDROID VFX SMOKE QA + ZERO-LENGTH SPELL FIX — 2026-11-21
- **Last confirmed art CI green**: fast art run **44926764406** at SHA a0a37097 (all 72 characters, motion, rig, materials). Android run **44927004517** for prior handoff was still running when checked; subsequent Android runs queued due to new commits, older runs cancelled by concurrency. Do not claim latest APK green until completion.
- **New regression test 3c0d5c3e**: `tests/smoke.gd` verifies that low graphics tier (0) allocates zero transient 3D meshes for attacks and hits, while medium tier (1) creates visible hit impact VFX. Verifies self-targeted attack works at low tier without allocating VFX. Existing smoke tests still check castle geometry, inventory, PvE, chess moves, saved progression and gear.
- **Fix 70d0fd65**: zero-distance/self-targeted spells no longer spawn a degenerate attack beam at any quality tier. Actor animations still play, and `_spawn_attack_trail` already avoids zero-distance trajectories. Previously added safe fallback direction remains for animation displacement.
- **Regression test 1f4221ee**: medium quality also asserts self-targeted spells do not create a zero-length beam.
- These runtime fixes and tests are pending full Android CI, not yet device-tested. Next: check latest Android logs, repair any smoke/GDScript errors, then continue substantial art and gameplay. The game remains incomplete. Combat design that prevents *ordinary chess engine* from directly solving board outcomes is documented in `docs/GAME_VISION_AND_LEARNING_ROADMAP.md`.
- Handoff updated in this pass as requested.

## ANDROID GRAPHICS QUALITY + BATTLE VFX SAFETY — 2026-11-21
- **Art pipeline recovered**: fast art CI **SUCCESS** run **44926764406** at SHA a0a37097, verifying the ForgeKneeRivet lower-joint QA correction and the six unique boss attack/cast motion tests, alongside all 72 character GLBs and 21 equipment assets. Android build for the previous handoff **44926807762** still in progress when checked; earlier commits were cancelled by concurrency. Last confirmed successful Android APK remains **44925921035** at c722392f. Check current run status before claiming full success.
- **Runtime mobile VFX optimization 205d0032** in `scripts/battlefield_3d.gd`: attack beams and camera shake now respect graphics quality. Low (tier 0) skips translucent attack beam, medium draws reduced 8-segment beam, high draws 12-segment beam and permits camera shake. Actor animations and combat rules still execute at every tier.
- **Runtime VFX optimization f51337a4**: hit shockwave geometry now respects the same quality setting; low tier keeps hit reactions but avoids translucent torus mesh/tween allocations. Impact sparks were already quality gated.
- **Safety fix 3538071f**: self-targeted attacks/spells use a safe fallback direction rather than normalizing a zero-length vector to construct an invalid beam quaternion.
- **New Godot Android CI pending** for the above commits; not yet visually reviewed on actual device. Next: check Android parse/smoke tests, add explicit low-tier VFX regression tests, profile GPU draw calls, polish character geometry and UI. Do not call the graphics finished. User's anti-chess-engine board duel combat design remains in `docs/GAME_VISION_AND_LEARNING_ROADMAP.md` for subsequent implementation.
- **Handoff updated this pass** as required.

## FIX ACTUAL RED CI + CASTLE SMOKE REGRESSION — 2026-11-21
- **Root cause identified from GitHub Actions logs**: Android run **44926597644** and art run **44926564343** both failed at `tools/art/test_rig_attachments.py`, reporting `hero_04.glb: ForgeKneeRivet1 detached from Leg1`. Generator correctly rebinds all ForgeKnee accessories to `Leg1Lower`/ `Leg-1Lower` after subdividing skinned leg geometry. The newly added assertion incorrectly expected parent `Leg1`. **Fixed assertion in commit a0a37097** to expect the lower-leg bone for ForgeKneeRivet. This tests the physically correct joint while retaining its world-space rest pose.
- **New Godot integration regression commit cb53ca9c**: `tests/smoke.gd` now verifies all 7 named portcullis bars, all 5 roof ridge nodes and both named windows on every castle building, in addition to existing castle/tower/upgrade checks. Ensures the detailed 3D castle pass cannot silently disappear in future scene rebuilds.
- **CI status when written**: art run **44926764406** for a0a37097 in progress; Android **44926764391** in progress; new Android for cb53ca9c queued. No claim of green yet. If CI fails again, fetch failed step and job logs, fix before new art. Prior Android success **44925921035** at c722392f remains last verified green.
- This pass prioritizes actual failed builds over cosmetic unverified changes. Graphics remain procedural low-poly and incomplete; Android screenshots/real device FPS not measured. User's anti-engine chessboard tactical duel design documented in `docs/GAME_VISION_AND_LEARNING_ROADMAP.md`. Continue substantive art, QA and handoff updates every turn.

## ART CI REPAIR + CASTLE DETAIL PASS — 2026-11-21
- **Real CI regressions identified and fixed** instead of continuing to pile on unchecked art changes:
  - Fast art run **44926398011** failed: `ForgeKneeRivet1 detached from Leg1`. Cause: legacy ForgeKnee handler parsed the suffix as `Rivet1` and searched for non-existent `LegRivet1`, bypassing the newer generic limb attachment. **Fixed in 598f9435** by extracting actual ±1 side suffix. Regression test `tools/art/test_rig_attachments.py` already covers the behavior.
  - Fast art run **44926415271** failed: `Expected 6 different boss casting signatures, got 5`. Root cause: two distinct authoring curves collapsed to the same value when resampled onto three cast keyframes. **Fixed in 02f72365 and cdf76819** by altering actual midpoint samples for Thorn and Glacier bosses; all six sampled cast signatures should now differ. Verify new CI before claiming green.
- **Castle graphics commit f69a9708:** `scripts/battlefield_3d.gd` now models castle portcullis with seven metal bars and horizontal braces, front-wall masonry courses, all five building roof ridges and paired emissive windows, and twin watchtower gilded rings/windows. All placed outside board collision and hit-test grid, generated using existing mobile-friendly Godot primitive meshes. Existing skyline and level-dependent ornament toggles retained.
- Latest **confirmed** Android APK success remains run **44925921035** at c722392f; earlier fast art green **44926388273** at 37de092b, before new stricter QA. New Android and art runs for current changes are pending. Check GitHub Actions and repair failures, particularly GDScript parse errors and art rig assertions.
- User demands maximum graphics progress and handoff every pass. Graphics are still procedural low-poly; actual device screenshots, effects and optimization pending. Tactical anti-engine piece-versus-piece combat requirements are specified in `docs/GAME_VISION_AND_LEARNING_ROADMAP.md`; not yet implemented. Avoid claiming complete game.

## GRAPHICS RIG INTEGRITY + SIX-BOSS MOTION QA — 2026-11-21
- At start of pass, **fast art CI SUCCESS** run **44926267965** at SHA 2841895b, confirming previous distinct boss animation curves. Latest confirmed **Android SUCCESS** remains **44925921035** at SHA c722392f; Android run for animation handoff was superseded/cancelled by newer commits. Never claim latest Android build green without checking.
- **Fix e5344e3c:** discovered newly modeled class armor was parented under the static BodyRig, not the animated limb joints, so it could visually float during attacks/walking. `tools/art/generate_blockouts.py` now attaches RoyalPauldronWing, RaiderArmSpike, RangerForearmWrap, ForgeShoulderTower, MageShoulderSigil to Arm±1; RoyalGreaveCrest, RaiderShinFang, ForgeKneeRivet, MageBootRunes, BossBootSpur and CrimsonClaw to Leg±1, preserving rest-space transforms. This affects all relevant generated heroes/enemies/bosses.
- **Fix 37de092b:** RoyalShieldRim and RoyalShieldCore now follow the left shield arm, not the stationary torso.
- **Regression QA 53570fd0:** `tools/art/test_rig_attachments.py` verifies all new limb-attached armor and both shield meshes inherit the correct animated joints across **all 72 generated character GLBs**.
- **Regression QA d7e31eec:** `tools/art/validate_motion.py` now asserts **six distinct boss attack signatures and six distinct boss cast signatures**, with return to rest. Existing checks cover all 30 heroes and 36 enemies.
- **CI for this new pass is pending**, and earlier in-progress runs may be cancelled due to workflow concurrency. Check latest fast art and Android; repair failures before further development.
- Art is still procedural stylized low-poly, not approved production graphics; next: Godot visual screenshot/render review, mesh/material polish, animation/FX and Android device performance. User's requirement for tactical piece-versus-piece board combat resistant to ordinary external chess-engine advice remains documented in `docs/GAME_VISION_AND_LEARNING_ROADMAP.md`, deferred until graphics complete. Update this handoff every pass.

## ART ANIMATION PASS — 2026-11-21
- Latest **full Android APK CI SUCCESS** at run **44925921035** SHA c722392f; fast art validation **SUCCESS** at run **44925901094** SHA 4f08327c. These confirm previous five-material normal-map generation and 10-PNG validation were working in CI, and the APK pipeline completed.
- New **commit 2841895b** modifies `tools/art/generate_blockouts.py` to give **all six region bosses individually authored attack windup/recovery and casting curves** (different pose sequences and opposing-arm response), plus faster raider gait, heavier sentinel gait, and symmetrical two-arm mage casting. All use the existing glTF clip names and deterministic generated GLBs. **New animation pass not yet confirmed CI green.**
- New geometry and PBR normal maps are generated before Android export in `.github/workflows/android.yml`; art QA workflow regenerates and validates all 72 character GLBs. No need to commit generated binary assets for CI builds. Art QA and reproducibility tests are required.
- User repeatedly requires maximum substantial progress and handoff update every pass; graphics are still stylized procedural low-poly, **not** finished production quality. Need Android device screenshots/performance and further material/mesh/UI work. Anti-external-chess-engine board duel spec is in `docs/GAME_VISION_AND_LEARNING_ROADMAP.md`, implementation follows graphics milestone.
- Check latest fast art and Android runs after this handoff commit; fix any failures rather than claiming success prematurely.

## GRAPHICS-FIRST PBR NORMAL-MAP PASS — 2026-11-21
- **Latest confirmed full Android APK SUCCESS**: run **44925678500**, SHA 53becca3, containing six boss silhouettes and rig QA. **Latest confirmed art fast SUCCESS**: 44925658893, SHA 27c2d88b.
- New graphics commits **498479e7**, **ec9e7315**, **28a5cd80**, **4f08327c**: generator `tools/art/generate_blockouts.py` now embeds five **additional 128×128 tangent-space normal maps** alongside existing five PBR albedo atlases in each of the 72 GLBs. Material-specific procedural relief: cloth weave, metal scratches, skin pores, gold filigree, arcane circuitry. All textures are embedded, deterministic and share one sampler; normal intensity 0.65. `tools/art/validate_blockouts.py` checks 10 embedded PNGs, glTF material normal bindings, dimensions and PNG headers for all generated GLBs. Binary PNG signature and test escape errors were corrected in ec9e7315/4f08327c. **Do not call this new normal-map pass CI-verified until latest fast art and Android runs pass.**
- The initial fast art run 44925851446 at 498479e7 failed before the binary PNG signature correction; subsequent CI was in progress at handoff. Workflow concurrency cancels older Android runs on commits. Check new art CI failures and repair immediately if needed.
- Visual scope: still stylized procedural low-poly characters, not final high-end authored art; screenshots and real Android frame rate not verified. Next prioritize checking latest fast art and full APK CI, then materially improve mesh topology, bespoke animation and UI readability. User's anti-engine board-duel requirement remains recorded in `docs/GAME_VISION_AND_LEARNING_ROADMAP.md` and is deferred until art phase is complete. Handoff updated every turn.

## SIX BOSS SILHOUETTES — GRAPHICS-FIRST PASS 2026-11-21
- Owner insists **maximum substantial progress per turn and update handoff every turn**. This pass focuses on six distinctive regional bosses, not more gameplay. User's anti-external-chess-engine tactical board duel requirement remains documented in `docs/GAME_VISION_AND_LEARNING_ROADMAP.md`; gameplay redesign awaits graphics milestone.
- **Art commit 8a654160:** added 3D beveled geometric silhouette structures to all six region bosses, sharing existing glTF meshes/materials for mobile: Ash Tyrant vents, flames, jaw, furnace heart/crown; Glacier Monarch multi-layer ice wings and crystal horns; Thorn Colossus bark trunks, twig antlers and roots; Obsidian Oracle floating glyph plates and third eye; Astral Sovereign eight-point starburst, orbit nodes and diadem; Crimson Dragon triple wing fingers, horns and claws. Each boss now has unique geometric landmarks, not only a palette swap. Geometry remains original procedural low-poly, not finished production sculpting.
- **Rig fix a5625b98:** newly added crown, jaw and eye pieces are parented to the animated head pivot with correct rest-space offsets. Other boss ornaments are body-mounted intentionally.
- **Art QA commit 27c2d88:** `tools/art/test_rig_attachments.py` checks all six boss GLBs for their distinctive mesh nodes and head attachment of crown/third-eye pieces, in addition to previous 72-character checks.
- **CI:** fast art run 44925465134 SUCCESS at a5d4c5f2 (previous pass); earlier full Android SUCCESS run 44925224956 at 379041c4. Latest boss pass workflows for 27c2d88 are **pending** (fast art 44925658893; Android 44925658877) and need verification. Older superseded Android runs were cancelled by concurrency. Never call these new changes Android-verified until green.
- **Remaining:** actual in-engine screenshots/Android device QA, physically richer non-box geometry, professional PBR material maps, authored character motion, readable effects/UI, scene and mobile performance. Next agent should check CI first, fix any art validation failure and continue graphics with meaningful improvements. Handoff must remain current.

## ART RIG FIX + AUTOMATED QA — 2026-11-21
- Confirmed **full Android APK CI SUCCESS run 44925224956** at SHA 379041c4, which includes owner combat design specification and full-body procedural art. Fast art CI SUCCESS 44925203396 at SHA 0b6164c6.
- Found actual visual/animation bug: the previous facial detail pass created class-specific beveled facial meshes under the static BodyRig, not the animated Head node. **Fixed** in commit **b679d350** by explicitly parenting all 18 new class-specific facial/helmet prefixes to the head pivot, preserving authored rest coordinates. The animated head now carries these details during attack/hit/death clips.
- Commit **a5d4c5f** extends `tools/art/test_rig_attachments.py` to check the facial detail nodes are actual Head children in **all 72 GLBs**, with finite world positions, verifies every class has real extra armor silhouette geometry, and verifies boss chest/shoulder/back crests. This prevents visually floating helmets during animation.
- **CI for b679d350/a5d4c5f is not yet confirmed green**; runs 44925433656, 44925433649 were in progress and superseded by a5d4c5f runs 44925465134 (fast art), 44925465090 (Android). Check the latest runs and fix failures. Handoff commit will start a newer Android run.
- Owner requires substantive graphics-first progress and updates every pass; the board-duel/anti-engine requirement is in `docs/GAME_VISION_AND_LEARNING_ROADMAP.md`. Graphics remain procedural low-poly, not complete production assets. Next: improve authored boss silhouettes, more varied 3D topology/materials, motion and screenshot validation. No unsupported claims of finished art.

## OWNER COMBAT REQUIREMENT + FULL-BODY ART PASS — 2026-11-21
- **Owner's design mandate:** Ordinary chess is easy to outsource to a chess engine or external AI; Kingdom Chess needs **actual battles between pieces on the chessboard**, with HP, armor, abilities, tactical action points, counterplay and scenario objectives, so a standard chess best-move hint is not sufficient. The goal is to make outside advice less useful, **not to falsely claim outside assistance can be prevented absolutely**. This is now recorded as a detailed normative design section in `docs/GAME_VISION_AND_LEARNING_ROADMAP.md` (commit **89cd86e**), including fair deterministic duels, 8×8 positional chess identity, PvP power/rating brackets, postbattle learning, server authority and measurable tests. **Design specification only; do not claim the combat model is fully implemented.** Owner insists graphics first; implement new combat design only after visual quality phase.
- **Art commit 0b6164c:** `tools/art/generate_blockouts.py` now adds a second pass of physically modeled full-body silhouettes to all 72 animated generated characters: royal shield rim/core, shoulder wings and crest; raider diagonal harness, arm spikes and back spine; ranger split tabard, arrow fletching and forearm wraps; sentinel segmented chest, tower shoulders and glowing chest gem; mage hanging stoles, runic shoulder sigils, focus and back scroll; all six boss GLBs gain shoulder crests, rib cage and standards. Uses existing beveled mesh, five materials, and existing rig. **This is still procedural stylized low-poly art, not finished production graphics.**
- At start of pass latest confirmed fast art CI green was **44925056468** at SHA d309a856; prior Android full green **44924853023** at SHA 19552c9c. New fast art and full Android CI for 0b6164c were pending. Verify final CI and fix failures. Handoff commit itself may cancel and restart the Android workflow.
- Prioritize substantial graphics work, visual screenshots and Android frame budget. No more gameplay feature work until graphics approved. Tests should validate new silhouette geometry and rig attachments. Update handoff each pass.

## ART PASS: DISTINCT ANIMATED HELMET/FACE GEOMETRY — 2026-11-21
- At start of this pass, latest **confirmed Android SUCCESS** was run 44924837813 at SHA 0255d26e. A newer workflow for SHA 19552c9c was in progress; verify latest again before asserting green.
- Commit **d309a856** extends `tools/art/generate_blockouts.py` with physically modeled, beveled, class-specific head/face details across all 72 generated animated GLBs: herald cheek plates/diadem/gems, raider tusks/jaw/warpaint, ranger hood seams/straps/nose guard, sentinel layered visor/faceplate/bolts, mage temple lenses/runes/chin sigil; regional veteran enemies and bosses gain extra brow emblems and spikes. These nodes use the existing head pivot parenting mechanism and existing material slots. **Not yet verified in full Android CI after this commit**.
- The existing generator already produces 128px procedural PBR textures (do not describe them as 32px). Models are still procedural low-poly, not production-quality authored meshes; no evidence of device screenshots. This art pass does not mean graphics are finished.
- User insists: graphics first, substantial changes each pass, handoff updated, then gameplay. Next steps: verify full Android CI and fix; evaluate actual rendered silhouettes; refine bosses, skeletal motion, materials and lighting without sacrificing mobile FPS.

## GRAPHICS-FIRST CHARACTER ART PASS — 2026-11-21
- **Last confirmed full Android green**: run 44924485119, SHA 3a6d7c5c, validating live-upgrade reactive 3D castle and APK export.
- New procedural art commits 2ef9470, d2ea685, f0541ac, 0255d26: upgraded embedded albedo textures from 32x32 to **128x128 RGBA** for five PBR materials (woven/brocade armor, brushed/riveted steel, freckled skin, gold filigree, arcane etched circuits), with subtle material-specific RGB tint. Texture generator remains deterministic, all images embedded in each GLB. `validate_blockouts.py` now asserts 128x128 RGBA PNG headers. Added five distinct helmet silhouettes and physical details to each generated hero/enemy/boss: gorget, breastplate ridge, belt trim, wrist cuffs, boot toes, shoulder rivets, royal crown / raider horns / ranger mask / forged visor / mage circlet and forehead gem. Named wrist/boot pieces attach to articulated arm/leg pivots. Existing six animation clips and skinned meshes preserved.
- **Important CI failure fixed**: initial run 44924782214 failed art validator because Python generator wrote literal escaped text `\\x89PNG` instead of binary PNG signature. Fixed generator Python byte literal in 0255d26. Verify **latest fast art and full Android runs** for 0255d26 or later before declaring success. Rapid commits cancel older runs.
- Scope honesty: This is improved procedural low-poly art, **not finished professional 3D graphics**. No commissioned/sculpted high-poly hero meshes, bespoke animations or hand-painted production textures. Continue graphics work before expanding mechanics, per explicit user instruction. Next milestones: CI green, image capture/render review, character silhouettes and animation refinement, polished UI, performance on real Android hardware.
- User requests maximum meaningful work in each pass, actual GitHub edits and this handoff refreshed every pass. Never claim complete until verified.

## GRAPHICS-FIRST CONTINUATION: REACTIVE 3D CASTLE — 2026-11-21
- **Verified Android SUCCESS for previous skyline + castle-save fix:** run 44922872362, SHA ae4dce80. This validates Godot smoke tests and APK export; not actual device visual quality.
- New art commits **0802026**, **46b7458**, **62c9bb7**: The five skyline castle buildings are now **visually linked to persistent base levels**. Levels 0-4 are starter silhouettes; every five building upgrades add an architectural tier, up to stage 4 (level 20). Each stage enlarges the building and reveals one more gilded physical ring ornament; ornaments are created once per region and only toggled on updates. All five building types preserve their distinct forge chimney, barracks rack, treasury dome, academy observatory, infirmary cross. `Battlefield3D.set_castle_visual_levels` handles save load and upgrades without rebuilding units or changing gameplay; `main.gd` calls it when 3D board starts and after successful upgrade. Smoke tests check all five construction tiers, scaling, named ornaments and visibility, and restore state.
- **CI status:** full Android workflow for the new reactive castle code at/after 62c9bb7 is pending at handoff time; verify and fix before claiming green. CI workflow cancels superseded runs on each push. Avoid more commits while waiting unless fixing a failure.
- **Important scope honesty:** This is procedural art progress, not final AAA/hand-authored characters or a navigable base. Current GLBs use 32x32 procedural textures, and character models/animations remain stylized blockouts. Do not move to next gameplay stage; user's current priority is finish visual quality. Need actual screenshot review on Godot/Android, professionally detailed rigged characters/bosses, hand-painted/high-resolution PBR maps, better animations, mobile lighting optimization and polished castle interaction UI.
- Handoff must be updated on every substantial pass. Next: check latest Android CI, fix issues, and make the next art pass focused on unique character silhouettes/texture quality, not another minor cosmetic tweak.

## GRAPHICS-FIRST: CASTLE ARCHITECTURE PASS — 2026-11-21
- User explicitly prioritizes **finishing graphics before more gameplay work**. Do not switch back to economy, PvP, or progression until the user approves graphics quality. Art remains **unfinished**, not professional authored/sculpted 3D.
- Commits fd7c703, 9629122: `scripts/battlefield_3d.gd` now builds a named 3D castle skyline behind the tactical arena in each region: continuous curtain wall, 20 battlements, two multi-level cylindrical watchtowers with tapered roofs and glowing finials, central gatehouse with banners, and five visually differentiated building silhouettes (forge chimney, barracks spear racks, treasury dome, academy observatory, infirmary cross). Uses existing palette colors and low-poly primitives; scenery is outside playable chess grid and follows existing graphics-quality visibility. Godot smoke checks the geometry anchors. **This is a new visual backdrop, not a navigable or upgrade-reflecting 3D base.**
- **CI issue found and corrected:** Android run 44922626766 for previous functional castle economy FAILED its gameplay smoke test: `Castle save rejects forged, negative and malformed upgrades`. Root cause: `safe_save_int` clamps 100000 to 100; castle sanitizer now rejects negative/out-of-range numeric levels to 0 (commit c417afc). New full Android CI for the combined fixes/skyline must pass before claiming success. Earlier full Android green baseline: 44921918541.
- Remaining graphics work: inspect actual Godot screenshots on Android, high-quality authored character and boss assets, detailed PBR textures and normal maps, polished attack and idle animations, navigable 3D castle with building upgrade visual states, coherent UI, lighting/shadows and mobile optimization. 32x32 embedded procedural PNGs are placeholder textures. Do not represent generated primitive silhouettes as finished graphics.
- Next agent: check latest GitHub Actions Android run, fix any smoke/import failures, continue meaningful graphics production with testable changes, update this handoff, wait for successful APK build. Keep user responses factual and concise.

## FIRST PLAYABLE KINGDOM / CASTLE PROGRESSION LOOP — 2026-11-21
- **Baseline full Android SUCCESS**: run 44921918541, SHA 725874d2, including previous collectible-board gallery and embedded PBR GLB texture pipeline. https://github.com/sitepushlic/kingdom-chess/actions/runs/44921918541
- New commits 1f7a8ed, 5948d4c, 68b427e implement **five persistent, upgradeable castle buildings**: Forge (+2 PvE attack/level capped +30), Barracks (+5 friendly PvE HP/level capped +100), Treasury (+3% raid gold/level capped +50%), Academy (+3% raid XP/level capped +50%), Infirmary (+3 potion healing/level capped +30). All five upgrade to level 100, cost base_cost*(level+1)^2 gold, require initial raid wins per building and two additional wins per next level. These are deliberately PvE-only; arena retains original gear-neutral classic combat rules. The bonuses are capped to prevent runaway stat inflation while building levels provide longer-term progression.
- Main menu now has "🏰 МОЁ КОРОЛЕВСТВО" opening a functional castle building list with level, benefits, requirements, gold, and an upgrade action. Upgrades deduct gold once, persist immediately in the player profile, and refresh HUD. Existing saves migrate to five level-0 buildings. Save sanitization rejects malformed and out-of-range levels. Core raid combat, healing and gold/XP reward paths read castle bonuses.
- Smoke tests cover five building definitions, malformed save sanitation, capped bonuses, rising prices, victory/gold gates, max level, actual UI purchase/deduction, repeat attempt rejection, and PvE-vs-arena separation. **New full Android CI for these changes is not yet verified**: check the latest run at or after 68b427e and fix parser/runtime failures. Do not claim green without the result.
- **Not yet implemented**: visual 3D explorable castle, building placement, castle siege PvP, clans, land ownership, offline production, cloud saves, online account backend, unbounded level/prestige and gear-sensitive rating-restricted PvP. Existing player level still caps at 50 and this first building loop caps at 100. Treat this as an initial functional vertical slice, not a completed kingdom-management game. Next priorities: verify Android, then 3D castle presentation and deeper economy/progression while preserving competitive balance.

## PLAYER-OWNED COSMETIC CHESSBOARDS: END-TO-END GAMEPLAY — 2026-11-21
- **Implemented a playable feature, not just 3D decorations** (commits b7beda0, 453a389, c47f4c8). Four existing chessboard palettes are now collectible cosmetic items. Main menu button "♟ МОЯ КОЛЛЕКЦИЯ ДОСОК" opens a gallery with ownership, lock requirements, purchase and equip actions. First board is always owned. Others require raid victories **2/6/12** and a one-time gold purchase **300/900/1800** respectively. Re-selecting an owned board is free; selecting a locked one does not charge. Equip changes shared 3D tile, frame, metal and gem materials immediately; no chess rule, piece, stats or PvP modifiers change.
- Progression profile now saves `owned_boards` and `selected_board` alongside gold and raid wins. Sanitization rejects malformed, fractional, duplicate or out-of-range board IDs, ensures starter board and prevents selection of unowned skin from a corrupted save. Old saves default safely to [0], selection 0. The 3D board applies saved style after SubViewport creation. Gallery shows current ownership and win/gold gating.
- Godot smoke assertions test collection sanitation, old-save fallback, ownership gating, sufficient-gold purchase, exact one-time deduction, selecting a board and applying 3D palette. Tests restore state afterward. Note this is **local persistence**; no backend/account cloud sync, anti-cheat or multiplayer board inventory yet.
- **CI verification:** the last known successful 93-GLB fast art run is 44921652995. Full Android run for board ownership and smoke tests is 44921873957 (queued/in progress at writing); check latest run after this handoff commit and fix parser/runtime failures before claiming success. Full Android prior commits were cancelled by later pushes. The project is not yet release-ready or device-tested.
- Next: finish professional original 3D hero/boss sculpted art, UV/PBR authoring, distinct animations, environments and mobile optimization; later rating-gated gear-sensitive PvP, endless progression, chess lessons/puzzles, base and loot upgrades. Current art is procedural placeholder quality. Design roadmap: docs/GAME_VISION_AND_LEARNING_ROADMAP.md.

## COMPLETE CHARACTER UV + EMBEDDED PBR TEXTURE PIPELINE — 2026-11-21
- Major graphics pass (commits 24e7b19, 4bc6945, 517594c, 6ac56d9, 558ffac, 2b68106, 2690463, 3182224): **all five beveled rigid materials and all six deformable two-bone surfaces (mantle, torso, both arms and both legs)** now have glTF TEXCOORD_0 VEC2 UV coordinates. The deterministic Python stdlib generator creates five original 32x32 RGBA PNG patterns (engraved armor, brushed steel, skin freckles, chased gold, arcane circuitry), embeds them directly as aligned GLB BIN bufferViews, and assigns each as baseColorTexture with one shared sampler. Existing per-hero/biome baseColorFactors remain, multiplying neutral procedural patterns. No external texture dependencies, no new draw calls for UVs. Character GLBs are generated during CI, not checked into Git.
- Validator now enforces exactly five embedded PNG images/textures, correct binary signatures and IEND, material bindings, UV coverage/vertex-count parity across **every character mesh**, and all previous rig/animation checks. Fast art validation **SUCCESS** run 44921652995 on commit 31822241, validating 93 GLBs and generator reproducibility/corruption tests: https://github.com/sitepushlic/kingdom-chess/actions/runs/44921652995
- Fixed real CI failures: accidental escaped newline in Python glTF dictionary (2b68106) and double-escaped PNG magic in validator (3182224). Earlier runs 44921524563 and 44921581301 failed; latest art run is green. Do not describe failures as green.
- **Full Android Godot import/smoke/APK for the new embedded textures still unverified** as of this handoff; inspect latest workflow for 31822241 or later. Previous runs were repeatedly cancelled by follow-up commits. Wait for final Android run to finish, investigate any import warnings or errors. Last known green full Android baseline remains 44920377315.
- Textures are intentionally original low-res procedural placeholders, NOT finished hand-painted PBR textures or professional sculpted character art. Remaining graphics: high-quality unique sculpted hero/boss assets, UV atlas, normal/ORM textures, animation refinement, environment polish, mobile performance profiling. After art, complete endless progression, rating-gated gear-sensitive PvP, board ownership/unlocks, bases and chess education per docs/GAME_VISION_AND_LEARNING_ROADMAP.md. Game remains unfinished.

## RIGID CHARACTER UV CHARTS — 2026-11-21
- Commits ca87ddb, 23ec6ed: procedural 96-vertex beveled rigid character meshes now have deterministic per-face planar glTF TEXCOORD_0 VEC2 UVs, shared by the five armor/steel/skin/gold/glow materials for all 72 generated hero/enemy/boss GLBs. Reuses existing split flat-shaded vertices, no additional draw calls or vertices. This prepares the meshes for later authored PBR textures; **no texture images or UV atlas packing yet**.
- Fast validator enforces UV presence, float VEC2 format, vertex-count parity and valid [0,1] accessor bounds for all five character rigid meshes. Skinned limb/torso/cape surfaces and equipment GLBs are not UV mapped by this pass; they require later art work.
- Prior runtime visual changes: four cosmetic board palettes, pulsing corner gems and high-quality-only animated halos/motes. Latest full Android workflow for those prior changes 44921218526 was cancelled by subsequent commits; **no green full Android result for these combined changes yet**. Latest known complete Android SUCCESS is older run 44920377315. New art and Android workflows queued for 23ec6ed: check, fix any failures and allow Android CI to complete before claiming verified.
- Priority: professional graphics first. Then user-approved RPG progression, gear-power PvP gated by rating, endless leveling, cosmetic board ownership, learning real chess. Current project remains an unfinished procedural 3D prototype.

## AMBIENT 3D VFX + MOBILE QUALITY GATING — 2026-11-21
- New runtime visual commits f9aa11f, 01086c8, 6cb2ed6, 32a02ff: four 3D chessboard corner gems now pulse using deterministic sin motion; four rotating emissive halos appear **only** in high-quality mode. Each biome gets at most 12 gently drifting colored ambient motes outside the playable 8x8 board, also **high-quality only**. No particle emitters, no additional dynamic lights, no per-frame material allocations; low/medium hide halos and motes. Default remains medium for Android.
- Smoke tests verify four gems and halos, high/medium/low visibility gating, bounded mote count and palette switching from preceding pass. Cosmetic-only, no gameplay effects.
- Prior full Android builds have been cancelled by consecutive code/doc commits; latest known full Android SUCCESS remains 44920377315. **Check the latest full Android workflow for commit 32a02ff or later and fix any errors** before claiming this VFX pass is verified. Prior fast GLB validation 44920981455 SUCCESS covers 3D character assets but not runtime VFX.
- Outstanding graphics-first work: replace low-poly procedural character blockouts with original sculpted/UV textured assets, art-directed materials, richer animations, cohesive environment and UI, mobile device performance testing. Later implement approved gear-powered rating-restricted PvP, endless progression, chess education, base/loot upgrades and ownership of cosmetic boards (current board styles are visual-only presets without ownership UI or persistence). Game NOT complete.

## FOUR COSMETIC 3D CHESSBOARD PALETTES — 2026-11-21
- New code commits a241fa4 and 2b853f8: scripts/battlefield_3d.gd has four named chessboard looks: Royal Marble, Ice Palace, Obsidian Throne, Emerald Garden. set_board_visual_style(index) updates existing shared materials for dark/light squares, frame, metallic inlay and corner gemstones; clamps out-of-range selection. Visual-only: does not touch hitboxes, pieces, movement, stats, ratings, loot or game logic.
- tests/smoke.gd asserts four palettes, visible material change, selection clamping, exact restoration, and no combat piece rebuild. **No in-game ownership/unlock/save UI yet**; these are renderable cosmetic palettes prepared for the eventual player-owned boards requirement. Current default style remains Royal Marble.
- Last art validation for animated facial detail 44920981455 SUCCESS. Full Android run 44920995942 was still in progress when palette commits began; queued newer Android run 44921092321 for 2b853f8. Check latest run after handoff, fix any GDScript parser, smoke, or Android export issue. Do not claim the palette code is verified until the full workflow is green.
- Keep graphics-first priority. All 93 procedural GLBs and runtime chessboard remain low-poly work in progress, not final game art. Remaining: hand-authored character sculpting/UV textures, refined environments and lighting, animation, VFX, UI polish, device frame profiling. User-approved progression, rating-gated PvP with meaningful gear, bases, endless upgrades and chess education follow art completion. Do not claim completed game or installed APK.

## FACE DETAIL / BOSS VISOR ART PASS — 2026-11-21
- Added carved corner plinths and glowing gems on the 3D chessboard in previous pass; those full Android builds were cancelled by newer commits, not proven successful. The latest known fully successful Android run remains 44920377315; chamfered 93-GLB art validation succeeded at 44920705314.
- New character art commits c9591ce, 2927891, a6913fc: heroes/enemies gain distinct eye highlights and brow accents; six bosses receive emissive ominous visors. Face geometry is parented to the animated Head pivot so it follows neck movement; validator now requires proper head binding and distinguishes bosses from regular characters.
- The first fast art validation after adding facial geometry succeeded at run 44920952516, but that preceded head-rig parenting and new regression assertions. **Check newer fast art validation and full Android CI for commit a6913fc or later before claiming complete verification.** Watch mobile triangle budget <= 2500 per character; new face meshes add ~88–132 triangles.
- Finish actual professional graphics before the gameplay economy/learning redesign per user instruction. Current procedural art is not final sculpted/UV-textured art; real Android device QA deferred. Roadmap: docs/GAME_VISION_AND_LEARNING_ROADMAP.md.

## CHESSBOARD CORNER SCULPT + BUILD STATUS — 2026-11-21
- New 3D visual commits 3bc87c1 and cc38279: board now has four physical carved corner plinths with metallic caps and emissive gemstone insets, placed outside the 8x8 play area; smoke tests assert all eight named objects exist. This is cosmetic 3D geometry, not gameplay board customization or purchased board ownership.
- **Last confirmed full Android success:** 44920377315 (previous board labels). **Latest fast art success:** 44920705314 for the new chamfered rigid character meshes (93 GLBs). A subsequent full Android run 44920737550 was cancelled by newer code changes before completion; there is NO confirmed full Android success for the chamfered mesh + corner plinth combination yet.
- **Pending:** check latest Android run for commit cc38279 or later. Diagnose/fix any Godot parse errors, smoke regressions or export failures. Previous rapid sequential commits triggered CI cancellations; allow final run to finish.
- Remaining visual milestones: replace procedural character blockouts with authored/varied meshes and UV textures, richer facial anatomy, detailed materials, environment polish, animation, particle effects, accessible board contrast, real Android frame-time measurements. User requires graphics first; RPG redesign after graphics. No claim of completed game.

## BEVELED MESH CI FIXES — 2026-11-21
- **Fast art validation SUCCESS**: run 44920705314 for commit 405eb4b0. This validates all 93 generated GLBs, six character skins, rig attachments, class/biome identity, chamfered 96-vertex/44-triangle rigid mesh, equipment, corruption tests and reproducibility according to the workflow. https://github.com/sitepushlic/kingdom-chess/actions/runs/44920705314
- Initial fast runs 44920577124 and 44920630533 FAILED because old validator assumed all meshes had 24 vertices and the former 2k triangle ceiling; fixed in commits 364e5ea and 3610c36. Run 44920669765 FAILED because equipment GLBs legitimately still use 24-vertex cube topology; fixed in 405eb4b0 by enforcing chamfers only on animated character GLBs. These failures are resolved by latest fast green; do not conceal them.
- **Android full CI for new chamfered meshes still pending**: run 44920705310 at the time of this handoff; prior full green 44920377315 applies to previous geometry. Check and fix Godot import and smoke failures if any.
- New visual meshes improve silhouette quality but are still procedural low-poly, not final professional character art. Priority remains graphics before RPG redesign. Keep material budget and monitor 2.5k triangles/character; actual Android GPU performance unverified.

## BEVELED HARD-SURFACE ART PASS — 2026-11-21
- **Verified baseline:** Full Android CI run 44920377315 (commit 442d5617) SUCCESS: Godot 4.3 import, scene smoke and Android debug export passed with the 3D board labels, class/biome silhouettes, 93 GLBs. https://github.com/sitepushlic/kingdom-chess/actions/runs/44920377315
- New graphical commits fcf5abc, 04c559b, 18180b2: replace the former six-face rigid cube shared meshes with a genuine closed **96-vertex, 44-triangle chamfered hard-surface mesh**, shared by the five materials and all rigid parts across 72 generated characters. Faces, 12 edge chamfers and eight corner triangles use flat normals and consistent outward winding. Existing six GPU-skinned deformable components retain their original topology and animation.
- Validator now rejects fallback to cube blockouts by requiring 96+ vertices and 40+ triangles in each of five rigid meshes. This is a tangible topology improvement, not just added colored cubes. Still **not final authored high-fidelity art**; no textured UVs, facial sculpting or hand-authored characters yet.
- **Pending verification:** fast art run 44920577124 and Android run 44920577120 were queued after latest mesh changes; inspect results and fix all failures before claiming success. Earlier completed green baseline does not validate this new mesh topology.
- User requires graphics completed before gameplay economy/rating/learning redesign. Next art: original character proportions, silhouette differentiation, high-quality material/texture pipeline, VFX, environment, animation polish and performance profiling. Roadmap: docs/GAME_VISION_AND_LEARNING_ROADMAP.md. Device install testing deferred.

## CHESSBOARD VISUAL IDENTITY PASS — 2026-11-21
- Previous full Android CI run 44919946820 was SUCCESS, and fast art validation for the latest class/biome silhouettes (44920213580) was SUCCESS. Android run 44920245578 for those silhouettes was still in progress when next edits began; check most recent run for definitive result.
- New commits 36294c9 and caf6dc7: built an in-world sculpted 3D board frame, metallic gold edge inlays, visible A–H file labels and 1–8 rank labels on both sides of the chessboard; labels are Label3D nodes on the physical board, not just UI text. New Godot smoke assertions check representative file/rank labels. This improves chess recognition while retaining RPG presentation.
- New commits are **not verified yet** by a complete Godot/Android run; check latest Actions and fix any Godot Label3D property/scene smoke errors. Coordinate labels and gold inlay are cosmetic only, not a game advantage.
- User's required priority is to finish actual 3D graphics before redesigning progression/PvP/loot/learning. Existing character models remain procedural low-poly blockouts and are not final quality. Continue art production: higher-quality original meshes/materials, richer lighting and environment, character animations, VFX, board skins and visual QA. Roadmap: docs/GAME_VISION_AND_LEARNING_ROADMAP.md.
- Do not claim complete game or physical-device QA. APK device testing deferred per user.

## 3D CLASS AND BIOME ART PASS — 2026-11-21
- Confirmed green Android build 44919946820 (SHA 2bae3676), plus fast 3D validation 44919927266 success. Prior chest heraldry/boss emissive core details pass actual Godot import, main scene, gameplay smoke and APK export.
- New art pass commits 6ed5e37, df15a445, b278f780: 30 heroes get class-specific royal/raider/ranger/forge/mage detail, wristbands and boot toes; 36 enemies get distinct ash/ice/sea/obsidian/sky/night silhouette accents; bosses retain luminous chest cores. New wrist and toe pieces parent to articulated lower bones; GLB validator now asserts each hero class, enemy biome and boss core exists.
- Fast 3D workflow 44920213580 and Android workflow 44920213579 were queued/in progress at last check; NOT YET VERIFIED for these latest edits. Check run logs, fix any generator/validator/rig or Godot import failure before claiming success.
- User insists finish graphical work FIRST. These assets are still procedural blockouts with reused cube meshes, NOT finished professional art. Next: higher-quality distinct mesh topology, UV/material textures, environment, VFX, animations, LOD/performance and UI art. Only after final art, implement owner-approved infinite RPG, rating/Power Points PvP, gear drops, cosmetic personal boards, base upgrades and chess teaching as specified in docs/GAME_VISION_AND_LEARNING_ROADMAP.md.
- Device install QA remains deferred by user. Do not claim finished game.

## OWNER REVISED LONG-TERM GAMEPLAY + MARKET EVIDENCE + ART — 2026-11-21
- User revised PvP: gear, hero progression and upgrades MUST affect PvP, gated by chess-like rating/Power Points and division equipment budgets, with matchmaking preventing impossible mismatches. This supersedes equal-stat PvP plan. Ratings and progression need no hard caps, but combat bonuses need diminishing returns and division constraints. Hero/item/base upgrades, cosmetics-only personal 3D chessboards, endless advancement, social and educational loops are required.
- Full design and sourced 2025/2026 market statistics: docs/GAME_VISION_AND_LEARNING_ROADMAP.md (commit 9c8d0497). Sources: Sensor Tower Q1 2025 global mobile charts, Newzoo 2025 Roblox engagement, Qustodio 2025 child gaming usage, Sensor Tower Dec 2025. Market evidence is not proof of viability or uniqueness. Avoid pay-to-win and exploitative mechanics for minors.
- User wants FINISH GRAPHICS FIRST, then implement new RPG/PvP/chess academy and economy. Current arena equal-stat normalization and win-based hero unlocks are temporary, to replace after graphics.
- Graphics improvement commit 3f83d212: front-facing chest rivets and belt studs for procedural characters, hero rank chevrons, boss emissive chest cores with frames. Still procedural blockouts, NOT final authored art. New art CI and Android import/smoke must validate changes.
- Latest verified green Android before these edits: 44918616358; check Actions for subsequent results. Continue 3D silhouettes, lighting, animation, environment, equipment, graphics quality. APK device installation deferred.

## USER-DIRECTED PRODUCT VISION — 2026-11-21 (HIGH PRIORITY, IMPLEMENT AFTER GRAPHICS)
- User clarified the purpose of Kingdom Chess: engaging, modern chess-inspired RPG for younger players that teaches genuine chess through fun tactical gameplay, not just quick boss fights. **Finish all final graphics first**, then implement the comprehensive gameplay/learning redesign. Device APK testing remains deferred.
- Canonical detailed specification and acceptance criteria: **`docs/GAME_VISION_AND_LEARNING_ROADMAP.md`** (commit `fc94ca9`). Read it before changing hero unlocks, loot, campaign, match durations, monetization or chess learning.
- Critical requested changes **NOT YET IMPLEMENTED**: heroes acquired by progression or currency/money rather than boss-kill gates; bosses drop highly varied dynamically rolled equipment; chess identity remains recognizable but clearly distinguishes RPG variants; integrate original/licensed chess teaching, verified historical PGNs and book-inspired (not copied) analysis; balance short and long battles, progression and engagement for younger audiences. PvP must stay fair, no pay-to-win or paid lootboxes for minors.
- Existing 30-hero `wins` gates, victory unlock messages and current loot implementation are interim mechanics and need redesign **after final graphics**, per explicit user sequencing. Current 93 procedural GLBs are blockouts, not finished art. Next immediate development priority: final art quality/animations/visuals; after graphics, follow roadmap in order. Do not claim vision document equals implementation.

## Campaign reward feedback and next hero target — 2026-11-21
- **Confirmed green baseline after hero quest UI:** Android run `44918616358` completed `success` for commit `5faa8abf`; 93 GLBs, Godot import/main scene, smoke tests, APK export all passed. https://github.com/sitepushlic/kingdom-chess/actions/runs/44918616358
- Commits `21c852cc` and `de5fcb6b` implement visible **next earnable hero** and victory feedback: during raid `_draw()` displays next hero name, victories and level required; `_raid_victory()` announces newly unlocked heroes when boss win crosses their win threshold, with both level and victory gates enforced. Added smoke coverage that nearest target is locked and boss victory can unlock heroes. No changes to PvP equal-stat balance or gate thresholds.
- **Unverified changes:** new gameplay/UI commits above require a fresh green Android run. Inspect newest Actions workflow for parser/smoke failures before further work. The latest completed success applies only to previous baseline.
- User prioritizes full gameplay, visuals, balance and content over device installation. Remaining: more distinctive final authored 3D models, combat polish, story progression, sound, LAN and end-to-end QA; do not equate passing CI/debug APK with a finished game.

## Hero progression UX and unlock quest tests — 2026-11-21
- User explicitly deprioritized physical Android APK installation; focus on completing game mechanics, content, graphics and quality. Keep previously verified green APK run `44918311345` as baseline.
- New gameplay/UI feature in commits `5b81e8f3`, `8c006672`, `a866231b`: `HeroRoster.quest_progress()` computes bounded victory and level progress for any hero; `HeroRoster.next_unlock()` finds nearest locked reward; hero roster detail dialog now displays exact victory and level gates. Tests cover starter, late-game boss gate, level gate, fully unlocked endgame, next-unlock behavior. This does NOT alter rarity/balance thresholds or permit bypasses.
- New Android workflow `44918598903` was pending when checked; **not yet verified** for these new commits. Re-check latest workflow and logs, fix GDScript parser/test failures if any. Docs commit may cancel prior run and trigger a new one.
- Highest priority after CI: finish actual game systems, narrative/mission variety, polish combat feedback/portrait UX, improve authored 3D art beyond procedural GLB blockouts, audit PvP fairness and LAN, keep gameplay tests green. Physical device QA deferred per user.

## FIRST VERIFIED GREEN ANDROID APK — 2026-11-21
- **VERIFIED SUCCESS** GitHub Actions `Build Android APK` run `44918311345` for commit `7bbe7668b2b3d5ba7b9e6419ee619f82d2f63421`: https://github.com/sitepushlic/kingdom-chess/actions/runs/44918311345 . All steps succeeded: 93-GLB validation, skeleton/attachment/animation/corruption/reproducibility checks, Godot 4.3 editor import, headless main-scene launch, gameplay smoke suite, Android debug export, ZIP/manifest/native-library/package-integrity checks, artifact upload.
- **VERIFIED APK artifact** `kingdom-chess-android`, artifact ID `14712695972`, 24,882,457 bytes (GitHub artifact archive size; NOT necessarily raw APK size), nonexpired at verification. Download from the Actions run Artifacts section. Other artifacts: `kingdom-chess-93-glb-art-pack`, `kingdom-chess-art-manifest`, `kingdom-chess-godot-diagnostics`.
- Source fix `05d01c7e9999b4978fc944902eb55ccff7c6a16b` normalized exact JSON numeric integers only in local disk restore path, resolving autosave/poison smoke failures while preserving strict network snapshot validation. Tests passed in the green run. Earlier test fixture fix `8998fda` resolved independent king safety/gear randomness fixture failures.
- **Not release ready:** Android hardware install, portrait UI, FPS/memory/thermal performance, network co-op, device suspend/resume, persistence, audio, balance, full campaign playthrough and authored final 3D character/equipment art remain unverified/incomplete. Procedural 3D blockouts and debug APK are NOT a finished polished game. Next: install/test APK on real Android, collect crashes and screenshots, fix gameplay/UX, then expand final assets and QA. Preserve this verified green run as baseline; subsequent changes require fresh green build.

## Autosave deserialization bug fixed in source — 2026-11-21
- Android CI run `44918109464` completed **failure** at gameplay smoke, with 5 remaining assertions, all autosave/poison-related. Prior fixture repair `8998fda` eliminated the check-safety and randomized-armor failures (7 -> 5). The 93 GLB validations, Godot import and main scene launch passed. Actual smoke log: `Autosaved battle restores`, `Restored piece matches saved state`, `Autosave with poison restores`, `Poison duration survives disk save`, `Poison recovery rejects enemy...`.
- Root cause in `scripts/main.gd`: `JSON.parse_string` deserializes JSON numeric fields as floating-point while `valid_raid_snapshot` intentionally requires `TYPE_INT` for network payload. `_restore_battle()` passed disk JSON directly into network validator and always rejected its integral fields. Commit `05d01c7e9999b4978fc944902eb55ccff7c6a16b` converts ONLY finite exact integral scalar and acted-array values to int in the **disk restore path**, then runs existing strict network snapshot validation; fractional/nonfinite/oversized values are rejected. Network input validation remains strict. This is an actual save/load bug fix, not test relaxation.
- New Android run `44918288447` was queued at handoff writing; docs update can supersede it. Check newest Actions run and exact logs. Goal: all gameplay smoke tests green and debug APK artifact produced. Android device QA, real performance, final character art and full game completion remain outstanding.

## Gameplay smoke regression fixture repair — 2026-11-21
- **Verified Android run `44917798596` failed at gameplay smoke**, after passing all 93 GLB validation, Godot 4.3 project import and headless main-scene launch. Log: seven assertions failed: nonlethal strike king safety; autosave restore/piece; poison autosave/restore/sanitization; armor stat. No APK was produced. https://github.com/sitepushlic/kingdom-chess/actions/runs/44917798596
- Commit `8998fda50a09a10a9fe3bedadf3e5144736000c4` updates `tests/smoke.gd` fixtures: checker rook at 4 and friendly rook at 5 no longer accidentally block the check; reset board before autosave fixture, clear acted array and assert snapshot validity; zero random inherited gear stats before setting deterministic test attack/armor/HP. These are test-fixture corrections, NOT evidence of gameplay correctness until CI passes. Preserve actual chess king-safety rule and strict save validation.
- Android CI run `44918084443` started for the change, results **PENDING** at handoff writing. The docs-only commit may supersede/cancel it; inspect newest run instead. Next: read precise remaining smoke assertions and fix underlying gameplay code if reproducible; confirm full Godot smoke and Android APK export; perform device testing and improve game art/content. 3D assets are still procedural blockouts, NOT final production art.

## Godot import recovered — 2026-11-21
- Android workflow run `44917661870` for commit `0e5c7d9` successfully completed 93-GLB validation and **Godot 4.3 project import** after fixing explicit `Node3D` types in `tests/smoke.gd` (commit `1bd3cea`). The run had progressed to `Launch actual Godot main scene` at observation time; its outcome, smoke tests and APK export remain **UNVERIFIED**. Link: https://github.com/sitepushlic/kingdom-chess/actions/runs/44917661870
- Important CI behavior: documentation commits trigger Android workflow and may cancel previous in-progress runs. Inspect latest run and its actual logs before changing files again. Prior art-only workflow `44916777543` verified green.
- Immediate priority: verify headless main-scene launch, smoke tests, Android export and downloadable APK; diagnose exact next failure from job logs. Then do real Android installation/gameplay/performance QA. No claims of finished graphics, balance or release readiness.

## Godot 4.3 import parser repair — 2026-11-21
- Android run `44916821652` FAILED at `Import project` after successfully generating/uploading all 93 GLBs. Actual job log shows `res://tests/smoke.gd:140` and `:187`: `Cannot infer the type of original_hero_visual / rare_hero_visual` because `_build_piece()` does not provide a statically inferable return type.
- Commit `1bd3cea4ad30a584372f7b0bb5a5d5eaa0a20352` changed both smoke-test declarations to explicit `Node3D` typing, matching how other 3D visuals are typed in the same test. Requires fresh Godot import verification.
- Fast art CI run `44916777543` remains verified green; Android APK NOT YET VERIFIED. Next: check newest Android workflow, fix further import/smoke/export errors based on actual logs, confirm APK artifact, then device QA and finish game content. Do not assert successful build until GitHub confirms.

## VERIFIED 3D art CI recovery — 2026-11-21
- Read real failure logs for fast art run `44916702025`: `hero_01.glb: Leg1 must be an articulated pivot`. Generator moves rigid armor to distal bones; a valid upper pivot can therefore have one child (the lower bone), while validator incorrectly required two. Commit `ace201052d94e22d1f599700f5b998f2938e5ed4` corrected the minimum from 2 to 1; lower-bone membership, skin integrity and attachment checks remain enforced.
- **VERIFIED PASS:** GitHub Actions fast art job run `44916777543` concluded `success`: all 93 generated GLB structures, animated joints/recovery, 288 skinned limbs, 432 armor sockets, deliberate corruption regression, deterministic regeneration and art QA manifest succeeded. Link: https://github.com/sitepushlic/kingdom-chess/actions/runs/44916777543 . This is a CI result, not visual/production art QA.
- Android build run `44916777549` was in progress at last check (preparing Android SDK); Godot import/smoke, debug APK, install, FPS and gameplay still NOT VERIFIED. Check this run after the handoff commit and repair any subsequent failure. Do not confuse procedural blockouts with finished 3D art.
- Next: obtain Android CI result and APK, test import/gameplay, then advance original character/equipment art, boss encounters, mobile UX, LAN reliability and balancing; update handoff after actual evidence.

## CI repair — 2026-11-21, distal armor attachment
- Retrieved actual GitHub Actions job logs for fast art run `44916618506` and Android run `44916626233`. Both fail at `tools/art/validate_blockouts.py` assertion `Gauntlet1 must follow animated limb` for `hero_01.glb`. Generator deliberately reparents gauntlets, shin plates, boots and forged knee guards from upper pivot to lower elbow/knee bone, preserving bind pose. Validator incorrectly inspected direct children of upper joint.
- Commit `48bfc06bd0d52b0960473a474f513e021791fe80`: validator now confirms lower joint is a child of the upper joint and requires gauntlet/shin armor under the lower joint. No relaxation of weight, skin, transform or animation integrity checks.
- New fast art run `44916702025` and Android run `44916702024` started, results NOT VERIFIED at handoff writing. Inspect their logs and fix further failures. Then verify 93 GLBs, Godot import/smoke, debug APK and Android device QA. All generated character assets remain procedural blockouts, not finished authored art. Do not claim release readiness.

## CI follow-up — 2026-11-21
- Verified via GitHub Actions API: run 44916494123 failed in `Validate all GLB structures and six skins`; Android run 44916507094 failed in `Validate all generated GLB assets`. Thus commit `6225aa2` did NOT resolve all validation failures. The exact new traceback is not accessible through the connected GitHub logs endpoint; do not claim success.
- Commit `65087b656af13ccd64affc58844eb69349f0e45a`: fast art workflow now pipes validator output through `tee` with `pipefail` and uploads `kingdom-chess-glb-validation-log` even on failure. This preserves the precise traceback for diagnosis without weakening the validator.
- Next: inspect the log artifact from the newest art-validation run; fix the specific assertion in generator or validator, rerun all 93 GLB checks, motion/limb/socket/corruption/reproducibility tests, Godot import and Android APK. Continue authored assets and gameplay only after restoring green CI. Godot execution and APK remain unverified.

## CI validation repair — 2026-11-21
- Commit `6225aa2e7b5c3d388b428a4039950fe7a3ca6c6e`: changed `tools/art/validate_blockouts.py` to select the cape primitive by explicit `skin == 0` and `SkinnedCape` name instead of relying on the first skinned node's ordering. The prior assertion required exactly 24 cape vertices and failed for `hero_01.glb` with "skinning vertex count mismatch". Generic per-primitive count checks remain intact. This is a validator selection correction, not a change to the generated meshes.
- CI after commit: queued at inspection; Android APK and Godot tests NOT YET VERIFIED. Check https://github.com/sitepushlic/kingdom-chess/actions/runs/44916494129 and https://github.com/sitepushlic/kingdom-chess/actions/runs/44916494123 . If failure persists, inspect actual cape accessor counts and generated node order rather than relaxing GLB integrity checks.
- Next: verify all 93 GLBs, Godot import/smoke tests, Android debug APK artifact, then continue 3D art and gameplay QA. No claim of production readiness.

# KINGDOM CHESS — DEVELOPMENT HANDOFF

Updated: 2026-11-21 (torch mesh visibility and shadow pass). Repository: https://github.com/sitepushlic/kingdom-chess ; branch `main`.

## FULL CURRENT HANDOFF — 2026-11-21, Android decorative-light optimization

### Product requirements and acceptance
Godot 4.3 portrait Android chess RPG: preserve legal chess movement, king safety/checkmate, HP/AP, class abilities, 30 heroes with level/quest unlocks, seven meaningful equipment rarities, six regions, 18 missions, bosses and fair PvP/LAN co-op. Finished art requires original rigged GLB hero and enemy models, distinct gear geometry and PBR materials, authored environments, animations and VFX, polished UI/audio and measured Android performance. Prototype is NOT commercial-ready.

### Actual architecture
- `scripts/main.gd`: chess/RPG gameplay, UI, save/load, LAN state, 3D integration.
- `scripts/progression.gd`: mission data, equipment, rarity and progression gates.
- `scripts/hero_roster.gd`: hero roster and unlock rules.
- `scripts/battlefield_3d.gd`: 3D board, class model GLB/OBJ fallbacks, equipment crests, six procedural region environments, lighting, effects, three graphics tiers.
- `tests/smoke.gd`: headless gameplay/render state regressions.
- `.github/workflows/android.yml`: headless smoke tests and debug Android APK export.

### New source/test commits accepted by GitHub
- `03ce0bdf78d3c6a1b6ca9393bc6eb4782be045ec`: hide decorative flame meshes whenever the corresponding tier-controlled torch light is disabled. Previously the light was disabled but its emissive mesh still rendered.
- `b4eb38355c2c8a5bbf6edbb31c695eab3e9ad04e`: smoke assertions for low/medium/high flame visibility.
- `f86ea1e2a5b27c6b87fe50dfe6e40e257812bf5a`: disable shadow casting on emissive torch flame meshes.
- `2799edec72ae680acff410fa0f3211a6ca928330`: smoke assertion that flames never cast shadows, even in high quality.
- This documentation update is a separate commit; retrieve its exact SHA from Git history.

### Verification (do not overstate)
GitHub accepted the four code/test writes above. Godot 4.3 headless test execution: **NOT VERIFIED**. GitHub Actions: commit-workflow lookup returned an empty list because the available connector filters to PR-triggered runs; push workflow result **NOT VERIFIED**. Debug APK and artifact: **NOT VERIFIED**. Android FPS, GPU draw calls, memory, heat and battery: **NOT MEASURED**. Expected render-work reduction is not a measured FPS improvement. Check https://github.com/sitepushlic/kingdom-chess/actions for latest run and debug artifact.

### Known issues, risks and art status
Original rigged GLB characters/enemies and complete skeletal clips: **NOT VERIFIED / outstanding**. Six low-poly static OBJ class silhouettes and import hooks exist, but are not commercial art. Seven rarity insignias are geometric placeholders, not seven authored 3D equipment families. Six procedural regions and tiered lighting exist; authored environment assets/PBR polish outstanding. Hazards, attack trails and status markers are primitive VFX. Need visual QA for torch changes on real Android devices. Chess HP/checkmate edge cases, LAN authority/reconnect, unique mission objectives, progression balance, production signing, two-device tests and release readiness remain risks. Recent parallel changes to battle save/LAN validation (`17ec8ff`, `5bf5ca5`) require CI confirmation.

### Exact next execution
1. Fetch latest `main` and read this entire file and changed sources; account for concurrent development commits before editing.
2. Inspect newest noncancelled GitHub Actions run and logs; run Godot 4.3 import/headless smoke tests; fix any parser/runtime regression and confirm debug APK artifact only after success.
3. Replace procedural class placeholders with original rigged GLB heroes and enemies and verified move/attack/ability animation clips. Add asset validation and scene import tests. Build visually distinct weapon/armor/relic assets for all seven rarity tiers.
4. Continue six authored region sets, lighting/VFX, LOD/culling and real-device Android performance measurement. Preserve chess legal moves, checkmate, HP/AP and progression gates.
5. Re-update full handoff with precise commits, tests/CI evidence, known bugs, art/Android status and next actions. Preserve all historical sections below; no empty commits or unsupported quality claims.

---

# KINGDOM CHESS — DEVELOPMENT HANDOFF

Updated: 2026-11-21 (manual material optimization). Repository: https://github.com/sitepushlic/kingdom-chess ; default branch: `main`.
This file is the persistent handoff for the next development session. Update it after every substantial implementation, with actual commits and CI status; never label the game production-ready without device and playtesting evidence.

## FULL HANDOFF UPDATE — 2026-11-21, mobile rendering pass

### Product and acceptance criteria
Portrait Godot 4.3 Android tactical chess RPG. Preserve legal chess movement, king safety/checkmate, HP/AP combat, skills, progression gates and fair PvP. Required: 30 heroes, seven equipment rarities, six regions, 18 missions, LAN co-op. Commercial acceptance requires original rigged 3D heroes and enemies, bespoke rarity gear, textured authored environments, VFX/animations/audio, tested Android performance, signed release and two-device multiplayer QA. NOT production-ready.

### Actual architecture
- scripts/main.gd: chess/RPG state, UI, save, LAN.
- scripts/progression.gd: economy, rarity gates, mission data.
- scripts/hero_roster.gd: hero collection and unlocks.
- scripts/battlefield_3d.gd: 3D board, lights, 3 graphics tiers, region scenery, character GLB/OBJ fallback, 3D effects.
- tests/smoke.gd: Godot headless regressions.
- .github/workflows/android.yml: debug APK CI.

### This run: accepted commits
- 52697048a5c677f7d73f061cb5528e75777e9b82 — 64 legal-move highlight markers reuse one material.
- be55b01ecc83498a055c74d82cf156116eef1b77 — smoke test verifies marker count and material identity.
- 3772c8c3a2c2fcb38cadd488d0b69716d50b716a — skip torch animation/light updates when hidden or low tier.
- 6046f9cdc925359e1887535237b46de97442ad02 — smoke regression checks low-tier static flame.
- This handoff commit documents all changes; older detailed history is preserved below.

### Verification and known risks
GitHub accepted four code/test commits. Godot headless tests: NOT VERIFIED. Latest GitHub Actions: NOT VERIFIED (Actions page DisabledError; available connector only lists PR-triggered runs). Debug APK artifact: NOT VERIFIED. Real Android FPS, memory, thermals, input, multiplayer: NOT VERIFIED. Shared material reduces duplicate allocations but no measured FPS gain. Low-tier torch meshes still exist. Existing six original OBJ class silhouettes are low-poly/static; imported rigged GLBs and original enemies are NOT verified. Seven-rarity insignias and six region environments remain predominantly procedural placeholders. Chess HP/checkmate interactions, LAN authority/reconnect, balance and unique mission objectives remain risks.

### Exact next execution
1. Fetch main, read this entire document and latest source. Check newest noncancelled CI logs and APK artifact, fix regressions and rerun.
2. Execute Godot 4.3 headless smoke tests. Verify all three graphics tiers, transitions, marker sharing, animation and import paths.
3. Deliver original rigged GLB heroes/enemies and move/attack/ability clips with PBR textures and licensing; unique equipment meshes for all seven rarities; authored regional assets and VFX. Commit assets and tests.
4. Measure real Android FPS/draw calls/memory/thermal behavior; test portrait touch and two-phone LAN. Test chess legality, HP/AP, progression locks and save compatibility.
5. Update full handoff with exact commit IDs, verified/unknown CI, bugs, 3D asset status, Android status and remaining tasks. Preserve historical notes. No empty commits or unsupported quality claims.

---

## FULL CURRENT HANDOFF — 2026-11-21 (read this first)

### Goal and acceptance criteria
- Build a commercial-quality, portrait Android 3D tactical chess RPG on Godot 4.3. Keep legal chess movement, king safety, check/mate and meaningful HP/AP tactical combat; six themed regions, 18 campaign missions, bosses, co-op, 30 unlockable heroes, seven rarity tiers and progression gates. A debug APK alone is NOT a finished release.
- Finished requires original rigged characters and animation sets, distinct equipment silhouettes, polished environments/VFX/audio/UI, balanced campaign/PvP, tested multiplayer and Android performance on physical devices, verified release signing/store readiness. None of those may be claimed without evidence.

### Repository and working architecture
- Repository: `sitepushlic/kingdom-chess`, branch `main`. Source files: `scripts/main.gd` (UI, chess/RPG rules, save, LAN), `scripts/battlefield_3d.gd` (SubViewport 3D renderer, camera, lighting, markers, procedural pieces/scenery), `scripts/progression.gd` (economy, items, campaign), `scripts/hero_roster.gd` (30 heroes), `tests/smoke.gd` (headless tests), `.github/workflows/android.yml` (CI debug export).
- Chess safety includes threat geometry, pinned-piece handling and check-aware end turns; still needs systematic HP-aware checkmate/action testing and rules decisions for nonlethal attacks, stalemate, castling and en passant.
- Six region palettes and procedural 3D scenery, warning markers, character import hooks and equipment markers exist. Most art is still procedural geometry, NOT verified commercial-grade authored 3D assets.
- Graphics tiers 0/1/2: low disables shadows, torch/rim lighting and optional region scenery; medium shows scenery with two torch lights, no directional shadow; high enables full lighting and shadow. Main-menu graphics button cycles tiers and persists `user://graphics.cfg`.

### Changes in THIS run — verified GitHub writes, not verified runtime
1. `227d4b5`: `scripts/battlefield_3d.gd` hides optional region scenery in low tier, restores it in medium/high, and skips decorative orb animation when effects are disabled. Reapplies visibility when a region is rebuilt. Gameplay board and chess pieces remain visible.
2. `25623b6`: `tests/smoke.gd` adds assertions for low-tier scenery culling and high-tier restoration.
3. This handoff commit: current full state and next-session instructions. Prior commits `48a2b61`, `a9d2294`, `271ae34`, `cbb22f9`, `c5fb6e8`, `0747298`, `59d0fd2` implement/test graphics tiers, UI setting and king-check 3D warning. See detailed chronological notes below.

### Verification and known risks
- Confirmed only that GitHub accepted the above source changes. **No Godot runtime, Android device FPS, APK installation or CI pass verified in this run.** Inspect latest Actions job for `25623b6` and this handoff; collect failure logs and fix before marking successful.
- Earlier CI #282 failed on a test-initialization race; `1c1176e` changed smoke tests to wait one frame, but follow-up CI status remains unconfirmed here.
- Scenery culling reduces draw submissions but does not free the created meshes or measure FPS. Tier switching does not change mesh complexity, texture budgets or viewport resolution. Quality button may need mobile UI layout verification.
- Check/mate and HP combat interactions can soft-lock in some situations; enemy AI, LAN authority, balancing and campaign variety still need gameplay tests. No device performance evidence or signed production APK.

### Required NEXT execution (autonomous, multiple stages)
1. Fetch latest `main`, read this full handoff and source before edits; avoid conflicting with hourly automation. Inspect newest GitHub Actions runs, identify smoke failures and repair with tests.
2. Improve actual authored 3D model/rig/animation pipeline and asset validation, not just primitive geometry; preserve legal movement and visual clarity. Add substantive code/assets plus regression tests in separate commits.
3. Profile low/medium/high tiers on representative Android hardware when available; document FPS, draw calls, memory, battery and thermal measurements instead of claiming speculative performance gains.
4. Validate HP-aware check and mate, AP, pawn promotion and LAN consistency; resolve high-risk combat edge cases. Continue multiple stages in one session rather than stopping after one commit.
5. **Every run must update this full handoff snapshot** (goals, architecture, real commits, tested vs untested, open issues, exact next actions), preserving history below. In the user response, provide a full structured handoff, not just a one-line status.

## Product brief — what the finished game MUST become
Portrait-first Android commercial-quality **3D tactical chess RPG**, with intuitive gameplay:
1. Select a hero chess unit, see legal 3D squares, spend two action points per turn to move, attack, or cast class-specific abilities.
2. Defend the allied king; defeat a boss through readable telegraphed attacks, different enemy types and multi-phase fights.
3. Complete a coherent 18-mission story through six regions, with unique mission objectives, cinematics and a clear ending; then unlock genuinely varied endgame expeditions.
4. Collect distinctive weapon, armor and relic loot across seven rarity tiers. Items must differ not only numerically but visually and mechanically (affixes, sets, status effects, special triggers, unique boss loot, meaningful build choices). No predictable repetitive loot loop.
5. Play solo and via two-phone Wi-Fi co-op, with synchronized authoritative state and reconnect/failure handling.
6. Ship polished *authored* 3D characters, rigged animations, bespoke environments, VFX, sound, UI, onboarding, balancing, localization, performance optimization, monetization/store assets, and tested release Android build. Current primitive-based models are **not** the target art quality.

## Current verified architecture / work already implemented
- Godot 4.3, portrait 720x1280, `gl_compatibility`; GitHub Actions workflow `.github/workflows/android.yml` runs headless smoke tests and exports a **debug** Android APK artifact.
- `scripts/battlefield_3d.gd`: real Node3D chess board and meshes, lights, 3D camera, picking, movement tweens, attacks, hit effects, health bars, boss phase effects, equipment visuals; mostly procedural primitive meshes, NOT finished art.
- `scripts/main.gd`: portrait game UI, combat, abilities, 2 AP turn system, enemy AI, raid phases, inventory, economy, save/load, LAN ENet snapshots, 3D viewport integration.
- `scripts/progression.gd`: 7 rarities, three gear slots, stats (attack, armor, HP, crit, lifesteal, penetration, block, bleed), six special legendary traits, set bonuses, upgrades, chapter-first-clear rewards, 18 authored mission records and variable post-story expeditions.
- `tests/smoke.gd`: smoke tests for layout, movement, equipment, campaign, damage, networking snapshots, 3D state.
- Story missions currently vary **encounter composition, modifiers and text**; full unique objectives, scripted narrative events, distinctive bosses and environmental mechanics are NOT yet implemented. Post-story expedition generator uses a deterministic combination of existing modifiers; NOT fully nonrepeating procedural content.

## Work in this session (2026-11-20)
- Commit `c23f5d8b95595afc14536fe13dd8b42d7f5c7c74`: fixed `_equip_best()` to independently select the strongest **level-eligible** item in EACH of three equipment slots. Previously it chose only one global item, and could reject all items if the strongest happened to be level-locked. Also updates `equipped` to the selected weapon index.
- Commit `2389a09aaa60c17cfb1ff14eec8dc0c2ff2b9988`: added regression tests to verify locked weapons are skipped and all three slots are filled.
- This handoff file is itself another commit; see Git history for its SHA.

## Latest implementation session — 2026-11-21
- Confirmed CI #146: **success**, smoke tests and Android debug APK exported for commit `5b92343699c571746d619e40e9241a17f6220df4`. URL: https://github.com/sitepushlic/kingdom-chess/actions/runs/44798032045
- Commit `781909808daf425eb04b905874e4c5c8c42617ba` (`scripts/main.gd`): implemented six **actual turn-triggered** tactical encounter modifiers in `_apply_mission_modifier()`, called from `_boss_action()` before enemy reinforcements:
  - frost: every 3 rounds damages heroes in forward rows 0–4;
  - poison: every 3 rounds damages heroes in columns 1 and 6;
  - fury: every 3 rounds restores minion HP;
  - fortified: every 4 rounds restores garrison HP;
  - ambush: every 4 rounds summons a pawn on an available flank entry;
  - rift: every 3 rounds damages heroes in central columns 3 and 4.
  Effects are deterministic, depend on mission and round, and reuse the existing damage system; they can defeat the player king. Existing raid-stage mechanics remain active and can stack.
- Commit `45a6e1b86cc78a05fc8ba8662a30c433f0dddf23` (`tests/smoke.gd`): added tests for campaign modifier coverage, fury healing, ambush spawning and frost damage.
- **Latest CI**: inspect newest run after this handoff commit. Do not claim success until verified.
- **Known shortcomings**: environmental effects currently lack **advance visual telegraphs**, poison is instant damage rather than a persistent debuff, and modifiers reuse existing meshes. Combat balancing, touch readability and 3D FX require further work.

## Latest implementation — 3D danger forecasts (2026-11-21)
- `be34e7f` (`scripts/progression.gd`): pure `Progression.hazard_cells(modifier, next_round)` enumerates threatened board cells for frost (rows 0–4), poison (columns 1,6), rift (columns 3,4) only on scheduled strike rounds.
- `6d8230d` (`scripts/battlefield_3d.gd`): 64 pulsing 3D floor hazard markers, distinct blue/green/violet materials, `set_hazards()` caching and clearing. These are real 3D meshes in the board viewport, not a flat 2D overlay.
- `d849451` (`scripts/main.gd`): next enemy turn's forecast is derived from `raid_round + 1` and displayed in the 3D board before players end their turn; warnings clear when not applicable or when a battle ends.
- `1dfd923` (`tests/smoke.gd`): regression tests for danger-zone shape, round scheduling, marker rendering and cleanup.
- CI run for latest code must be verified at https://github.com/sitepushlic/kingdom-chess/actions before claiming success.
- **Known limitations**: boss target marker is separate from mission hazards; some region-specific boss attacks remain untelegraphed. The warning overlays are pulsing primitive geometry, not commercial-grade authored effects. Additional QA needed for warnings overlapping selected/legal squares and for mobile visibility.

## Current session — boss attack warnings (2026-11-21)
- Commit `3d9108e`: `Progression.boss_hazard_cells(stage, next_round, encounter)` forecasts the stage-2 ice storm, stage-5 sky lightning, stage-6 whole-board darkness, and every-4th-turn rift-line attacks. Stage-3 targeted ghost strike is **not** yet forecast because its victim selection is dynamic; stage-4 boss healing is not a damaging zone.
- Commit `7dae961`: `main.gd` merges mission and boss hazard forecasts for the next round and sends them to the 3D battlefield. Boss forecasts take red visual priority when overlapping other hazards.
- Commit `cda3c3d`: red emissive 3D warning material for boss strikes.
- Commit `325cccc`: smoke tests for boss warning coverage and scheduled timing.
- Latest CI needs verification at https://github.com/sitepushlic/kingdom-chess/actions . This handoff is not evidence of a passing build.
- **Final-state gap**: no production-grade rigged character models, authored combat animations, full original environments, audio, narrative cutscenes, release signing, real-device QA or reliable two-phone Wi-Fi co-op validation. Do not market or release the current prototype as a finished commercial product.

## Follow-up implementation — ghost telegraph and lethal hazard correctness (2026-11-21)
- Commit `1e4af78` (`scripts/main.gd`): the chapter-3 ghost strike now forecasts its weakest-hero target on the 3D board on its scheduled next turn. The encounter's rift-line damage now uses `_boss_aoe_hit`, so deaths remove units and a killed allied king causes defeat (previously `_deal_damage` alone did not enforce either).
- Commit `c681f45` (`tests/smoke.gd`): regression tests for the ghost strike warning and lethal environmental hit.
- Latest workflow: check https://github.com/sitepushlic/kingdom-chess/actions . Do not assume CI success until completed.
- Limitations: boss warning prioritization uses one color for overlapping hazards; ghost target can change as HP changes (forecast refreshes on redraw); mobile and network QA remain undone.

## CI regression and fix (2026-11-21)
- CI #162 **failed** during Godot gameplay smoke tests: runtime error `Trying to assign an array of type "Array" to a variable of type "Array[int]"` in `_draw()`, caused by ternary `else []` in typed hazard forecast variables. Debug APK export was skipped.
- Commit `b9a1d46` (`scripts/main.gd`): initialize `Array[int]` explicitly and populate only within the raid branch; eliminates the typed-array assignment error.
- Verify the newest CI before claiming this fix works. Link: https://github.com/sitepushlic/kingdom-chess/actions

## CI follow-up — typed test argument (2026-11-21)
- CI #164 **failed** at smoke test `tests/smoke.gd:155` with `Invalid type in function 'set_hazards' ... Array does not have the same element type as the expected typed array argument`. The prior `main.gd` typed-array runtime error was resolved; this is a distinct untyped `[]` argument in the test.
- Commit `28f2ce6` replaces `set_hazards([], "none")` with the typed empty result of `Progression.hazard_cells("none", 1)`.
- CI #165 is the first retest; verify completion before claiming green build.

## Recent earlier milestones
- CI #137 passed: procedural 3D arena, visual equipment, attack trails, phase VFX and associated smoke tests.
- CI #143 passed: 18 authored missions, variable enemy modifiers, campaign finale, HUD mission text, save and LAN sync; fixed a Godot 4.3 type-inference parse error in the mission generator.
- Check the most recent workflow at https://github.com/sitepushlic/kingdom-chess/actions before asserting any newer commit passed.

## Automated development session — save equipment integrity (2026-11-21)
- Verified GitHub Actions **#166 success**: Godot gameplay smoke tests passed, Android debug APK exported and artifact upload completed. https://github.com/sitepushlic/kingdom-chess/actions/runs/44800820117
- Commit `686ba3a` (`scripts/progression.gd`): save loading now validates each equipped index against inventory bounds, actual item slot, item dictionary type and current character level. Invalid or level-locked references are unequipped; legacy `equipped` weapon index is synchronized to validated weapon slot. Prevents stale saved indices from granting wrong-slot or locked bonuses after inventory changes.
- Commit `10b8375` (`tests/smoke.gd`): regression coverage for level-locked weapons, wrong-slot references, valid relic retention, out-of-bounds indices and malformed inventory entries.
- Latest CI after these commits is **not yet verified** at handoff-writing time; inspect Actions, repair any failure and confirm APK upload. The project remains a prototype, not commercial-ready.
- Next: strengthen inventory item schema validation, implement unique objectives and persistent poison/status effects; real-device testing, authored 3D art, release signing and co-op QA remain outstanding.

## Automated development — inventory schema hardening (2026-11-20)
- Verified **CI #169 success** (prior code): https://github.com/sitepushlic/kingdom-chess/actions/runs/44801466232 . This is the last confirmed passing APK at session start.
- Commit `5c039ec` (`scripts/progression.gd`): new `is_valid_equipment_item()` validates item slot, numeric fields, level 1–50, rarity 0–6, upgrade 0–12, set/trait IDs, and nonnegative combat stats. `sanitize_equipment_slots()` rejects corrupted equipped items; `set_bonus()` safely ignores malformed inventory entries rather than crashing or counting invalid sets.
- Commit `147af5d` (`tests/smoke.gd`): regressions for negative attack, nonnumeric level, impossible set ID, corrupt saved slots and malformed set-bonus inventory.
- CI #170/#171 were pending/in progress at writing time; verify latest after handoff commit and fix any failures. The latest passing APK is not proof that these changes pass yet.
- Known limits: item validator currently checks structural integrity and range, not cryptographic tamper-proofing or complete save-file migration. Next: persistent status effects, genuinely unique mission objectives, visual and real-device QA.

## Automated development — numeric equipment integrity (2026-11-21)
- Confirmed CI **#175 success** before this session's edits: Godot smoke tests and Android debug APK: https://github.com/sitepushlic/kingdom-chess/actions/runs/44823263285 .
- Commit `c99b59a` in `scripts/progression.gd`: reject fractional, non-finite, >1,000,000 absolute-value equipment fields and chance stats above 100%; previously values like level 1.5 could silently truncate, while oversized stats could distort combat. This is save-file integrity hardening, not cheat-proof authentication.
- Commit `f807382` in `tests/smoke.gd`: regression cases for fractional level, oversized attack, impossible crit, plus acceptance of valid generated equipment.
- CI #176 was running when handoff was written. **Do not claim this patch passes** until newest Actions run completes successfully and APK artifact is present. Repair any Godot parser/test failure before moving on.
- Next: meaningful campaign objective variants and persistent statuses, then 3D authored art, UX and Android device QA. Do not confuse CI run count with game completion.

## Required next steps (prioritized)
1. **Verify latest CI** and fix failed tests immediately. Ensure APK artifact exists; inspect headless test output, not just a green commit.
2. Implement genuinely unique mission **win conditions** and scripted objectives, boss-specific behavior, environmental hazard telegraphs, persistent status effects and campaign storytelling. Six modifiers now affect combat but are not yet visually telegraphed.
3. Replace primitive chess piece art with licensed or original professionally modeled, rigged 3D assets, animations and textures; optimize for mid-range Android devices. Add character silhouettes and visible equipment rarity/traits.
4. Expand loot with unique item identities and meaningful build-defining effects, deterministic boss pools, affix synergies, pity/duplicate mitigation, upgrade paths and fair economy; test drop distributions and save compatibility.
5. Fix remaining UX and combat balance issues; full onboarding, tooltips, responsive touch controls and accessibility.
6. Test real Android devices, 3D frame rate, crashes, input, save recovery and Wi-Fi two-device co-op. Current CI smoke tests do not substitute for these.
7. Create production release pipeline, signing, privacy/store requirements and promotional assets after game is demonstrably complete.

## Development workflow / handoff rule
For EVERY future implementation session:
- Work in this GitHub repository and commit changes.
- Run/check the latest GitHub Actions workflow; record run number, URL, result and APK status truthfully.
- Update THIS `docs/HANDOFF.md` with commits, changed files, implemented behavior, tests, known defects, next tasks and final product goal.
- Give user a concise Russian summary and direct links to commit, workflow and this file.
- Do not say “finished” or “commercial ready” while art, gameplay, real-device tests and release pipeline are unfinished.

## Automated CI recovery — 2026-11-20 (run #172)
- Inspected failed run #172: https://github.com/sitepushlic/kingdom-chess/actions/runs/44812941111 . Godot reported `Could not preload resource script res://scripts/progression.gd` and smoke tests could not start. Root cause found in `set_bonus`: five literal `\\n` sequences and `\\t` escapes had been committed into the GDScript source rather than actual line breaks/tabs.
- Commit `141d001` converted the escaped source sequences into valid GDScript indentation and lines; this repairs the parser-breaking regression from inventory schema hardening.
- Commit `60c5b63` strengthens Android CI: after the smoke success marker, reject parser/script errors in smoke.log to avoid a false green build.
- **Next run must verify** the current latest Actions run and debug APK artifact before claiming recovery. #172 was failed; #169 was the last verified successful APK at session start.
- Product gaps remain: original production-quality 3D art/animation, authored distinct objectives, persistent status effects, mobile/co-op QA, signing and commercial release readiness.

## Automated development — saved slot index type safety (2026-11-21)
- Verified CI **#178 success** before edits: https://github.com/sitepushlic/kingdom-chess/actions/runs/44830167615 (headless smoke and Android debug APK workflow).
- Commit `b68b8fb` changes `Progression.sanitize_equipment_slots()` to reject string, boolean, non-finite and fractional saved slot indices rather than coercing them with `int()`. A malformed saved value like `"0"` must not equip item zero.
- Commit `09da905` adds smoke regressions for string, boolean and fractional saved slot references. Legitimate integer references still use the existing validation path.
- CI for these edits must be checked after this handoff commit; **do not claim success until it finishes**. Next: make save-profile scalar loading robust to malformed JSON types; implement unique mission objectives and persistent statuses. Commercial art and device QA remain outstanding.

## Automated development — profile scalar recovery (2026-11-21)
- Confirmed CI **#181 success** before edits: https://github.com/sitepushlic/kingdom-chess/actions/runs/44834978788 .
- Commit `a9e250b` (`scripts/progression.gd`): introduced `safe_save_int()` and `sanitize_profile()`. Profile load now rejects strings, booleans, fractional, non-finite and oversized numeric save values for level, XP, gold, potions, wins and dry loot streak instead of coercing them with `int()`. Malformed values revert to safe defaults; valid integral JSON floats are supported, in-range values preserved and bounded values clamped. Invalid items and slots continue through existing equipment sanitization.
- Commit `cd377bb` (`tests/smoke.gd`): regressions for malformed profile fields, fractional gold, negative streak, invalid inventory/slots, integral float compatibility and string currency rejection.
- **CI #182 running** at handoff time: https://github.com/sitepushlic/kingdom-chess/actions/runs/44841894440 . Verify smoke tests and Android debug APK export; do not claim this change passes until complete. Latest verified successful prior run #181.
- Next: implement unique mission victory conditions and persistent status design with tests; original 3D art, device QA, co-op validation and release signing remain unfinished. Commercial readiness is not implied by run number.

## Automated development — inventory compaction with slot remapping (2026-11-21)
- Verified GitHub Actions **#184 success** before edits (Godot smoke tests and Android APK workflow): https://github.com/sitepushlic/kingdom-chess/actions/runs/44841919263 .
- Commit `ffee8fa` (`scripts/progression.gd`): `sanitize_profile` removes malformed or invalid saved inventory entries, retaining valid items in their original order. Equipped indices are remapped from the original inventory to the compacted inventory; removed, locked and wrong-slot references remain unequipped. Legacy weapon index follows the validated result. This prevents malformed inventory entries from reaching normal item UI code after load.
- Commit `9e2b923` (`tests/smoke.gd`): regression for mixed invalid/valid inventory, weapon and armor remapping, invalid relic rejection, legacy weapon index.
- Check the latest CI after these changes; do not claim APK success until gameplay tests, export and artifact upload complete. https://github.com/sitepushlic/kingdom-chess/actions
- Next: unique mission victory conditions and persistent statuses; production-quality original 3D art, real-device Android and LAN co-op QA, signing and store readiness remain unfinished.

## Automated development — persistent toxic fog (2026-11-21)
- Verified **CI #187 success** (Godot smoke tests, debug Android APK export) before edits: https://github.com/sitepushlic/kingdom-chess/actions/runs/44848204226 .
- Commit `ea41633` (`scripts/main.gd`): poison mission fog now applies two enemy-turn ticks of damage-over-time to surviving heroes, rather than only an instant strike. Status follows a hero when it moves, expires after two ticks, is removed on death or encounter reset, and lethal ticks use `_boss_aoe_hit` so king defeat is enforced. Initial fog still deals its existing direct hit. This is gameplay logic, not a polished visual status icon.
- Commit `d4d38a9` (`tests/smoke.gd`): smoke regressions for poison following movement, periodic damage, expiry, dead-unit cleanup and reset.
- New CI after these commits **must be checked**; #187 only validates the preceding version. Check https://github.com/sitepushlic/kingdom-chess/actions and verify debug APK upload. Fix parser/test errors before treating feature as validated.
- Known limitations: poison state is not yet serialized in LAN snapshots or battle autosaves, and no status VFX/UI indicator exists. Implement those next; continue distinct mission win conditions and commercial-grade 3D art/device testing. Do not claim production readiness.

## Automated development — poison persistence and LAN sync (2026-11-21)
- Verified **CI #190 success** before edits: https://github.com/sitepushlic/kingdom-chess/actions/runs/44855073299 . This is a debug Android APK, not a signed production release.
- Commit `58a2be0` (`scripts/main.gd`): battle snapshots now include `hero_poison` for both autosave and LAN host-to-client state. Battle restore and LAN snapshot reception sanitize recovered poison statuses against board occupancy, square indices and remaining duration; older saves without status remain compatible.
- Commit `21e0485` (`tests/smoke.gd`): added smoke regression confirming poison status is present in the serialized battle snapshot and that an unauthenticated snapshot is ignored.
- Verify the latest Actions run after these commits before asserting they pass; if it fails, inspect logs and fix. Remaining tasks: distinct mission objectives, poison VFX/status icons, authored 3D assets, actual two-phone Wi-Fi QA, release pipeline.

## Automated development — poison disk round-trip regression (2026-11-21)
- At start, latest workflow #193 pending, #192 in progress; last verified success #190: https://github.com/sitepushlic/kingdom-chess/actions/runs/44855073299 . No #200 success yet.
- Commit `0c24e10` (`tests/smoke.gd`): extended smoke tests to write a poisoned battle to disk, clear live status, restore it and verify the remaining two ticks. Added invalid-status recovery cases for enemy units, out-of-range cells, excessive durations and nonnumeric values, plus legacy save compatibility.
- These tests exercise the existing implementation in `58a2be0` rather than introducing an untested new combat feature. Newest CI must complete before claiming regression coverage passes; verify Android debug APK artifact in the successful run.
- Next: display poisoned-unit status in 3D/UI, implement distinct mission objectives and victory checks, test LAN reconnect and actual Android devices; replace procedural art with authored production assets. No release readiness claim.

## Automated development — 3D poison status feedback (2026-11-21)
- Verified **CI #195 success** before edits: https://github.com/sitepushlic/kingdom-chess/actions/runs/44860866721 (debug Android APK workflow). This validates the preceding poison save round-trip regression, not the new visuals.
- Commit `0a55f5b`: 3D battlefield now renders a small green emissive status marker above poisoned heroes and removes markers when the effect expires or is cleared.
- Commit `15e62e1`: battle redraw feeds current poison statuses to the 3D battlefield; status markers clear outside active raid battles.
- Commit `3b1964f`: smoke tests assert marker creation and removal.
- Latest CI after these commits requires verification. Known limitations: marker is a simple procedural sphere rather than final authored VFX; device visibility and performance are not tested. Prioritize distinct mission win conditions, authored art, two-phone networking tests and signed Android release pipeline.

## Automated development — lethal poison regression (2026-11-21)
- Checked Actions: #199 succeeded; #200 was **cancelled**, not a successful APK build; #201 was in progress at session start (https://github.com/sitepushlic/kingdom-chess/actions/runs/44868700226). A run number of 200 does not establish successful delivery.
- Commit `1a114c9` (`tests/smoke.gd`): added gameplay smoke assertions that a two-tick persistent poison status can lethally defeat the allied king, removes the dead king from the board and clears remaining poison statuses. Existing poison cleanup and reset coverage remains.
- CI for this new commit is not yet verified; check newest run and artifact upload, fix any failures before claiming a passing APK. Next: genuinely distinct mission objectives and victory rules, authored 3D models/animation, Android device and LAN QA, signed release pipeline. Prototype is not commercial-ready.

## Milestone — successful Android build beyond #200 (2026-11-21)
- **CI #203 PASSED**: https://github.com/sitepushlic/kingdom-chess/actions/runs/44868768648 . Godot gameplay smoke tests, Android debug APK export and artifact upload all completed successfully. Builds #200–202 were superseded/cancelled by subsequent commits; #203 is the verified milestone. This is a DEBUG APK, not production-ready.
- Commit `adff40a` (`scripts/main.gd`): poisoned status restoration now permits only known allied chess glyphs K/Q/R/B/N/P, rather than any uppercase string.
- Commit `79eb9dd` (`tests/smoke.gd`): regression tests for invalid glyph, enemy pawn and valid hero pawn status.
- Next: finish unique mission objectives, authored character art and animations, real Android device QA, two-device Wi-Fi tests, production signing and release readiness. Do not confuse CI run count with completeness.

## Visual-art priority session — 2026-11-21
- User explicitly prioritized continuing development until **full high-quality 3D visuals**, not merely a CI run number. The existing hourly development automation was updated accordingly.
- Commit `ad191d7` (`scripts/battlefield_3d.gd`): added 3D torus cast-metal plinth trim and distinct elevated class heraldry (knight ears, bishop halo, queen finial, pawn collar) to improve silhouette readability. These are actual 3D meshes; still procedural and **not** commercial-grade authored character models.
- Verify the newest CI before claiming Android export success. Next: replace primitive piece models with imported rigged original GLB characters, skeletal animation and animation trees, high-quality PBR textures and material variation, six distinct environments, VFX, mobile performance testing. Do not claim complete 3D art until assets are implemented and visually inspected on target phones.

## Focused multi-step 3D environment implementation (2026-11-21)
- Baseline **CI #206 success** before edits: https://github.com/sitepushlic/kingdom-chess/actions/runs/44869928114 . The latest post-edit CI #209 is pending and must be verified separately.
- Commit `d4a3c35` (`scripts/battlefield_3d.gd`): added a dedicated `RegionScenery` node and six region-specific actual 3D environments outside the chessboard: ember fortress battlements, ice spires, overgrown ruins, arcane obelisks, storm lightning rods, and broken void pillars. Four larger landmarks frame each region. On region change, previous scenery is cleared before regeneration, avoiding accumulation. This is still procedural environment work, not authored production art.
- Commit `9db26ce` (`tests/smoke.gd`): tests region scenery generation across six regions, different geometry between fortress and frostlands, and deterministic cleanup/rebuild.
- Commit `7799927` (`scripts/battlefield_3d.gd`): adds four gently floating emissive landmark orbs in frost/arcane/storm/void regions, animated in `_process` without per-frame mesh allocation.
- Remaining: authored imported rigged character GLBs and skeletal animations, high-quality texture and lighting, character-class action animations, richer VFX, visual inspection/screenshots, mobile performance profiling, and actual device QA. Do not claim commercially complete 3D graphics based on these procedural meshes.

## Focused 3D character import pipeline and CI repair (2026-11-21)
- Inspected **CI #210 failure**: Godot 4.3 smoke test parser could not infer the type of `scenery` at tests/smoke.gd:272. Commit `60b89bf` fixes it with explicit `Node3D` type. CI success for this repair is not yet confirmed.
- Commit `1f3266e` adds `CHARACTER_SCENE_PATHS` mapping for six chess classes (pawn, rook, knight, bishop, queen, king), `_load_authored_character` to load imported GLB PackedScenes and fallback to existing procedural geometry if absent or invalid. This establishes a direct replacement path for art without rewriting board/HP/combat mechanics; **no authored GLB models have been supplied yet**. Imported model must fit a 1x1 tile, face local -Z, with base at local Y=0.
- Commit `4efab6f` adds smoke checks for six class asset slots and fallback model HP bar.
- Verify newest CI, correct any remaining GDScript parser/runtime failures and inspect artifact upload. Next actual asset work: create and import six ORIGINAL rigged GLBs, class animations and PBR materials, add rarity-specific armor and weapon meshes, benchmark on Android. This is a pipeline, not completed character art.

## Multi-commit 3D character animation stage (2026-11-21)
- Verified **CI #214 success** before these edits: https://github.com/sitepushlic/kingdom-chess/actions/runs/44870536829 . It confirms the previous region environment and GLB-import pipeline smoke tests and debug APK export.
- Commit `a68534a`: character geometry is parented under independent `VisualRig` per chess piece; battle health bars remain outside the animated pivot. Attack and movement trigger rig rotation tweens. If an imported GLB exposes an `AnimationPlayer` with `attack` or `move` clips, the runtime plays the authored clip as well. This is a meaningful animation step but NOT skeletal animation until rigged GLBs are actually supplied.
- Commit `50c3b79`: smoke tests verify all six classes expose populated `VisualRig` nodes.
- Commit `cb63985`: `assets/characters/README.md` documents original GLB requirements, six class paths, orientation, dimensions, animation names, licensing and Android QA. **No authored character GLB files are in this commit**.
- CI after edits is pending; verify newest non-cancelled run, inspect failures, and fix before claiming it passes. Continue with original GLB character asset production and mobile visual QA.

## Automated 3D region lighting pass — 2026-11-21
- Commit `9dba514` (`scripts/battlefield_3d.gd`): each of six regions now updates actual WorldEnvironment background/ambient colors, directional key light, and rim light color/energy on region switches, alongside existing scenery and tile palettes. Cached references avoid creating lights on each switch. This is a concrete visual distinction, **not** authored commercial-quality scenery.
- Commit `aa83fea` (`tests/smoke.gd`): regression checks that region WorldEnvironment and key light exist and that rim-light palettes differ across regions.
- CI for these changes: **not verified at handoff time**; GitHub connector exposes no repository-wide run listing and direct GitHub API access failed DNS resolution in the execution container. Check https://github.com/sitepushlic/kingdom-chess/actions and repair any Godot parser or smoke failure before claiming success.
- Remaining highest-priority visual gaps: actual six original rigged GLB class models and skeletal clips, differentiated enemy models, seven-rarity equipment geometry and materials, authored six-region environment art, combat VFX, device screenshots and Android frame-time profiling. Do not equate procedural lighting with production-ready 3D.


## 3D equipment rarity geometry pass — 2026-11-21
- Commit `d5b42a9` (`scripts/battlefield_3d.gd`): equipped weapon, armor and relic now each receive a separate named 3D rarity insignia. Tier 0 has one rivet; tiers 1–6 add 1–6 physically raised gems arranged around the rivet, with slot-specific rarity materials. This provides seven geometric distinctions instead of color-only rarity coding. Geometry is parented into the existing VisualRig so it follows attacks and movement; no textures or imported models are implied.
- Commit `356fdc1` (`tests/smoke.gd`): regressions construct all seven tiers across three equipment slots and check each crest has exactly rarity+1 meshes.
- CI: direct Actions page access was unavailable (web fetch DisabledError); GitHub connector does not expose a repository-wide workflow-run list. **No claim that these new commits passed CI or produced an APK.** Check https://github.com/sitepushlic/kingdom-chess/actions and inspect Godot smoke output and artifact upload.
- Art limitations: these are still procedural geometry accents, not authored character GLBs or bespoke equipment meshes. Major remaining work: six original rigged class models with authored clips, differentiated enemies, optimized seven-tier item assets, six finished environments, VFX, screenshots and profiling on real Android devices. Next prioritize importing one original rigged hero with tested move/attack animations, then scale to remaining classes.

## Original 3D character mesh delivery — 2026-11-21
- Baseline **CI #224 passed** before this art pass: https://github.com/sitepushlic/kingdom-chess/actions/runs/44873075980 .
- Commit `df3d50b`: `_load_authored_character` now loads actual imported original OBJ Mesh resources for six chess classes when available, then GLB PackedScene, then procedural fallback. Sets hero/enemy material on the OBJ MeshInstance. Imported rigged GLB pipeline remains available.
- Six original **low-poly 3D OBJ meshes committed** under `assets/characters/`: pawn `32afee0`, rook `c448d33`, knight `1667cd7`, bishop `5f8c1e7`, queen `7d22ffa`, king `318ac91`. Meshes have distinct chess silhouettes, authored vertex and face data, and use the existing VisualRig movement/attack pivot animation. **Not skeletal rigged, not high-poly, no texture maps**; they are a concrete first authored mesh asset pack, not final commercial art.
- Commit `320bb1d`: tests assert all six OBJ meshes are present and load as Godot Mesh resources.
- Commit `c468f3c`: asset README documents real shipped OBJ art and limits.
- Check newest CI after these commits for OBJ importer/parser errors and Android APK. Next: textured and rigged GLBs, animation clips, unique enemy art, Android performance and visual screenshots.

## Original character surface detail and asset precedence (2026-11-21)
- Verified **CI #234 SUCCESS**: https://github.com/sitepushlic/kingdom-chess/actions/runs/44874156688 ; this confirms the six original OBJ meshes import, smoke tests and Android debug export passed.
- Commit `450d74d`: corrected asset selection order: **rigged animated GLB first**, original static OBJ second, procedural fallback third. This prevents future production models being masked by the newly shipped low-poly OBJ meshes.
- Commit `635e5c6`: added per-class 3D costume accents, metallic trim and emissive gems for six chess classes. These are actual 3D geometry and render within the animated VisualRig; still procedural additions, not commercial-quality textured or rigged models.
- Commit `58653fe`: smoke tests assert each class has layered geometry within its VisualRig.
- Commit `1f12e05`: updated character art README with asset selection order and limitations.
- Latest post-edit CI was queued during handoff; verify its actual result and fix any failures. Highest-priority missing: original production rigged GLBs with authored animation clips, high-quality PBR textures, unique enemy meshes, device visual QA and frame-time profiling.

## Hero collection and quest unlocks — 2026-11-21
- User requested **many selectable named characters with lore, classes, different values and strongest heroes earned through specific gameplay tasks**.
- Commit `d115d8d` adds `scripts/hero_roster.gd` with **30 individually named heroes**, Russian backstories, chess-piece classes (K/Q/R/B/N/P), combat roles (Бастион, Натиск, Точность, Магия), seven rarity tiers (common through relic), and explicit attack/armor/HP/crit stats. Every hero has an unlock quest requirement; six starter heroes available immediately, rare heroes unlocked by campaign/expedition boss wins, mythic requires level 20, relic requires level 35 and 22–25 wins. These are deterministic earned rewards, not paid random loot.
- Commit `012e2d2` adds persistent `selected_hero` to profile defaults/sanitization; rejects selection of locked or nonexistent heroes when loading saves.
- Commit `12c897a` adds in-game 30-hero roster popup, story/stat/quest details, selection, saved leader, and HP bonus. Commit `86b0f78` adds menu entry and integrates leader attack/armor/crit into raid combat, displays leader identity. Locked heroes cannot be selected; leader cannot be changed mid-raid.
- Commit `2f4c683` adds smoke tests for 30 unique heroes, 7 tiers, 6 starter options, earnable full roster, and locked save selection.
- **Important limitations**: these are 30 gameplay identities sharing six chess class mesh silhouettes, NOT 30 distinct authored 3D character models. Quest requirements are currently cumulative boss wins + levels, not unique mission-specific objectives. Need expand to actual varied quest trackers, individual abilities, per-hero art, party composition and meaningful tactical selection.
- CI after changes queued at #244; verify and repair before claiming success. Check https://github.com/sitepushlic/kingdom-chess/actions .

## Progressive power gates and fair PvP — 2026-11-21
- User explicitly requires **start weak**, no immediate best heroes/gear, no hopeless low-stat/low-level vs high-level chess PvP.
- **Verified baseline CI #245 SUCCESS**: https://github.com/sitepushlic/kingdom-chess/actions/runs/44878025967 . This verifies the preceding 30-hero roster implementation.
- Commit `5a57fe5` in `scripts/progression.gd`: added deterministic `rarity_cap(wins, level)`, `upgrade_cap(wins, level)`, `can_equip(item,wins,level)`, and gated loot. Rarity requires BOTH campaign milestones and level milestones: new player rarity 0, 3 wins and level 6 -> rarity 1, 18 wins and level 31 -> rarity 6. Upgrade starts at +2, reaches +12 only with progression. Save sanitization removes equipped items above caps.
- Commit `0049aae` in `scripts/main.gd`: loot drops, equip button, auto-equip, upgrade, runtime combat item stats and trait checks enforce gates. Commit `261c922` caps deterministic chapter rewards as well. Commit `e05ba6e` prevents ineligible gear granting set bonuses and shows lock notices.
- Commit `06eb9df`: local arena PvP now **fully normalized**: no gear, rarity, level or equipment traits affect `_item_stat`, `_attack_bonus`, `_armor_bonus` or `_has_trait`. Each side uses baseline chess-piece HP and damage, leaving victory to tactics. The LAN mode is currently **cooperative PvE**, not competitive matchmaking; no ranked PvP queue exists.
- Commits `7579da7`, `7d04996`: smoke regressions for rarity/upgrade gates, anti-skip via luck/boss loot, endgame availability, and arena stat normalization.
- **Not yet validated by newest CI at handoff time**. Verify https://github.com/sitepushlic/kingdom-chess/actions and fix parser/runtime failures. Need actual measured balancing: difficulty playtests across 1/6/12/18/25 wins, 30-hero damage/TTK simulations, PvP matchmaking design if online ranked PvP is introduced, and gradual board/roster onboarding. Current rarity gates are conservative and may need tuning for reward cadence.

## Imported animation namespace compatibility — 2026-11-21
- Commit `4e9076e` updates `scripts/battlefield_3d.gd`: move and attack use a shared `_play_authored_clip` helper. It recognizes both plain clip names and library-qualified names such as `Imported/move` and `Imported/attack` (also `|` qualified names), so authored glTF animations can play without renaming their imported libraries. Missing clips safely retain the procedural motion tween.
- Commit `f219b23` updates `tests/smoke.gd`: creates a real `AnimationPlayer` with a named `AnimationLibrary` and checks qualified move/attack playback and missing-clip behavior.
- GitHub Actions result for these commits **not verified**: repository-wide workflow-run listing is unavailable in the connected GitHub actions, and external search did not expose the current workflow. Check https://github.com/sitepushlic/kingdom-chess/actions and fix any GDScript parser/test failures. No new APK success claim.
- Still missing: production rigged GLB character assets with skeletal animation tracks, per-hero art, seven-rarity 3D equipment models, authored regional environments, VFX, screenshots and mid-range Android frame-time measurements. This compatibility fix alone does not improve mesh quality.

## Chess-first combat safety step — 2026-11-21
- Product owner confirmed chess movement and king-centric victory must remain the foundation; HP, attacks, armor, skills, bosses and progression layer on top. Design contract: `docs/CHESS_RPG_COMBAT_RULES.md` (commit `baf490f`).
- Commit `17ce65c` updates `scripts/main.gd`: pure `_chess_attacks_square` checks pawn diagonals, knight leaps, king adjacency and unobstructed sliding attacks; `_king_destination_safe` simulates a king move and rejects attacked destination squares in **arena only**. `_legal` now rejects out-of-bounds cell indices. Raid behavior intentionally unchanged.
- **Unverified**: no Godot runtime or CI test was run for this commit. Verify GitHub Actions and GDScript parse; add dedicated regression tests. This is not checkmate or complete orthodox chess. Still missing: king-in-check response, pinned pieces, castling, en passant, promotion, turn/attack semantics and consistent RPG check resolution.
- Concurrent hourly automation may update main; always fetch current blob SHA before editing.

## Chess-RPG king safety and pin regression batch — 2026-11-21
- Commit `25adf6e`: adds `_king_threatened` and `_move_preserves_king` in `scripts/main.gd`. Arena empty-square moves cannot expose the moving side's king; pinned sliding pieces may move along the pin line. Nonlethal RPG attacks remain stationary and are not modeled as instant chess captures. Raid remains exempt pending boss-specific check rules.
- Commit `9ef48fa`: king attacks onto occupied enemy squares must also satisfy safe-destination simulation, preventing a lethal king capture onto an attacked square.
- Commit `e0364f5`: `tests/smoke.gd` now includes rook pin, check escape, knight and pawn attack geometry regression cases.
- **CI/runtime not verified.** Inspect latest GitHub Actions build and smoke tests before release. This batch is partial chess safety, not complete checkmate or chess rules. Remaining major work: enforce mandatory responses to check across multi-AP RPG turns, pin-safe lethal captures by non-king units, castling/en passant/promotion, AI and boss threat semantics, robust PvP end conditions, Android device QA and 3D assets.

## Chess-RPG lethal-capture safety, pawn promotion and check UI — 2026-11-21
- Commit `b48d6a0` updates `scripts/main.gd`: arena RPG captures must leave the friendly king safe even if the target dies; pawn reaching last rank auto-promotes to queen while preserving current HP. This is **automatic queen promotion**, not yet player-selectable underpromotion.
- Commit `6ecbea4` adds smoke regression assertions for lethal pinned captures and white/black pawn promotion with HP preservation.
- Commit `924a552` shows **ШАХ!** in arena status when the active king is geometrically threatened.
- **CI not verified; no Android APK or device validation claimed.** Must check GitHub Actions and fix errors before declaring playable. The current arena still has two action points per turn, and the check indicator does not yet force a legal check resolution. Boss raid uses its own rules. Next: check-resolution turn gate, persistent combat states and safe end conditions; castling, en passant, underpromotion and balance remain open.

## Arena check-response gate — 2026-11-21
- Commit `ad50146`: `_end_turn` refuses to hand over an arena turn while the active king remains geometrically checked; grants a defensive AP and clears acted restrictions so HP-based chess-RPG battles can resolve a threat over several strikes. Raid boss turns unchanged.
- Commit `a94865a`: checks for at least one legal arena action when the king is threatened; declares victory for the other side if no actions exist. This is a **simplified no-legal-action checkmate**, not yet fully HP-aware: a nonlethal attack might be legal without actually resolving check.
- Commit `692994a`: smoke test covers refusal to pass a checked king, defensive AP and acted reset.
- CI/runtime **not verified**; review Actions and test on Godot 4.3 before release. Outstanding: HP-aware mate solver, potential repeated defensive AP if all strikes fail, special chess moves, PvP balancing, mobile QA, production 3D assets. Do not call orthodox chess complete.

## CI recovery session — 2026-11-21 (run #271)
- Inspected failed [Actions #271](https://github.com/sitepushlic/kingdom-chess/actions/runs/44881590343): `Run gameplay smoke tests` failed; APK export and artifact upload were skipped. Log reports three `SCRIPT ERROR: Invalid assignment ... 'text' ... Nil` at `scripts/main.gd:2013` during `_draw`, plus multiple assertion failures involving equipment, imported animations, and network equipment stats. Many headless dummy renderer `mesh_get_surface_count` messages also occur. These are NOT a successful build.
- Commit `0ab07c896860933c744f10ac894639e29014fe90`: prevent `_draw()` from touching HUD widgets before they have been initialized. This addresses the observed Nil assignment but does not prove the other failing assertions are fixed.
- Commit `3e7d376fbeb35f730ad2bb4e39b025d8bb67c534`: add a pre-`_ready()` redraw regression in `tests/smoke.gd`.
- Next: verify the new workflow result; investigate the remaining equipment / imported-animation / LAN assertions from #271; avoid weakening tests just to get green CI. Do not claim APK or commercial visual quality without evidence. Continue authored 3D art and Android profiling after CI is stable.

## CI regression repair batch — 2026-11-21 (after run #271)
- Reviewed the complete failing Godot job log from [Actions #271](https://github.com/sitepushlic/kingdom-chess/actions/runs/44881590343). Beyond the early HUD Nil errors addressed in `0ab07c8`, smoke assertions used incomplete equipment dictionaries after strict schema validation, and imported clip playback needed a deterministic named-library lookup.
- Commit `60ef585` (`tests/smoke.gd`): replace flaky random starter rarity with a legal common item, construct full-schema set gear and combat fixtures, explicitly name the imported test AnimationPlayer. This preserves production validation and early-game rarity gates instead of weakening them.
- Commit `2d4b332` (`tests/smoke.gd`): test LAN-synchronized item statistics independently of hero class bonuses, and verify armor mitigation using the current armor formula rather than stale hard-coded numbers.
- Commit `abf110a` (`scripts/battlefield_3d.gd`): resolve imported GLB clips by enumerating AnimationPlayer libraries and requesting the exact library-qualified clip; missing animations still fall back safely.
- **Verification status:** #273 was inspected via the GitHub connector and was **cancelled**, not successful. The connector currently cannot list push-triggered workflow runs globally; direct Actions page fetch was unavailable. This batch is committed but its Godot parser, smoke tests and Android debug APK **have not been confirmed passing**. The next session must inspect the first completed CI run containing `abf110a`, obtain job logs, fix any remaining failing assertions, and verify artifact upload.
- **Product gaps unchanged:** commercial rigged models, six authored regions, animation/VFX polish, actual Android GPU profiling, two-phone co-op QA and release build are unfinished. Do not equate repaired test fixtures with validated gameplay or commercial graphics.

## Immediate manual session — 2026-11-21: 3D king threat readability
- `c5fb6e8`: added a dedicated elevated, animated 3D ring around the king in check (`set_checked_king`, `KingCheckWarning`). The indicator rotates and pulses independently of 3D hazard and legal-move markers, and does not cast shadows.
- `0747298`: connected arena king-threat state to the 3D renderer; clears on raid mode and after a win.
- `59d0fd2`: smoke assertions verify visible indicator on checked square and cleanup when check clears.
- This is procedural geometry for gameplay clarity, **not authored commercial-quality character art**. Godot runtime and CI for these commits have **not been verified**. Confirm headless smoke test and Android debug export in Actions; inspect actual Android viewport for legibility and overdraw.


## Automated CI recovery — 2026-11-21 (after #282)
- Inspected GitHub Actions #282 (https://github.com/sitepushlic/kingdom-chess/actions/runs/44890538169): **failed** during gameplay smoke, before Android export. The first fatal assertion was `TEST FAILED: 3D board exists for check warning` at `tests/smoke.gd:71`, followed by a nil `set_checked_king` call. The smoke test was executing from `SceneTree._initialize` immediately after `root.add_child(game)`, before the main scene's 3D battlefield was initialized. Repeated dummy renderer mesh warnings were also present, but the assertion is the immediate failure.
- Commit `1c1176e9345f5ddf9ff75d880b6d0eaa7cfa00a7`: `tests/smoke.gd` now waits one `process_frame` after adding the scene, and explicitly checks battlefield initialization before chess/check-warning assertions. This changes test sequencing, not production chess rules.
- **CI verification pending**: the GitHub Actions list had not yet shown a run for the new commit when checked. Do not claim smoke success or APK availability for this patch. Inspect the next run and fix any remaining failures. The latest confirmed successful run in this inspection was #278, prior to the new check-warning tests.
- Next priorities: verify test scheduling and 3D warning rendering in headless CI; implement original rigged 3D assets and animation sets, Android LOD/material budgets and real-device performance testing. Commercial visual quality remains unverified.

## Immediate development — Android 3D rendering budget (2026-11-21)
- `48a2b61`: added runtime `set_visual_quality(0..2)` to the 3D renderer. Low disables dynamic torch lights, rim light, directional shadows and hazard-marker animation; medium (default) uses two of four torches with shadows disabled; high restores all four torches, rim light and directional shadows. This is a rendering-quality control, **not** proof of measured FPS improvement.
- `a9d2294`: headless smoke assertions for all three light/shadow configurations and restoring medium defaults.
- The setting is currently internal; **no player-facing graphics setting yet**. Need Android device benchmarking (GPU timings, thermal stability, battery), optional dynamic resolution, mesh/texture LOD, and commercial-quality authored GLB assets. CI results for these commits not yet checked.

## Manual session — player-facing mobile graphics settings (2026-11-21)
- `271ae34`: main menu now has a real **ГРАФИКА** button cycling low/medium/high tiers, applies changes to `Battlefield3D.set_visual_quality` immediately and persists tier to `user://graphics.cfg` with `ConfigFile`; loads selection at startup and applies it when creating the renderer. This setting is independent of progression and battle saves.
- `cbb22f9`: smoke tests cover menu control, tier cycling, immediate renderer update and on-disk persistence. Tests reset tier afterward.
- CI **not yet verified** for these commits; mobile UI fit, frame-rate and battery impact require physical Android testing. The three-tier renderer remains procedural art, not commercial-grade authored character meshes.

## Full handoff — current manual session (2026-11-21)

### Product target and current architecture
- Goal: polished Godot 4.3 Android portrait 3D tactical chess RPG; maintain chess moves, king victory/check, RPG HP and abilities, campaign progression and fair normalized arena. Commercial-quality rigged 3D characters, equipment, effects, six distinctive regions and real-device performance remain required.
- Gameplay: `scripts/main.gd` manages combat, UI, save, LAN and 3D viewport. `scripts/progression.gd` handles loot, rarity gating, equipment and 18 missions. `scripts/hero_roster.gd` provides 30 authored hero records. `scripts/battlefield_3d.gd` renders a procedural 3D battlefield and loads authored models where present. `tests/smoke.gd` contains headless regression checks.
- Implemented foundations: seven gear rarities, campaign across six regions, hero progression restrictions, chess movement/check logic, telegraphed hazards, 3D king check warning, three player-selectable graphics quality tiers, and local LAN framework. These features are not evidence of completed game quality or complete gameplay correctness.

### Changes this run
1. `d0e8b7835189d49b0255858ea486998031372526`: replaced 64 per-tile `StandardMaterial3D` allocations with exactly two reusable materials for dark/light board tiles. Region palette updates now mutate those two shared materials rather than looping through all 64 tile instances. All 64 meshes and square patterns remain unchanged.
2. `33e0b63bbd090a732a36d71b8410574e00414483`: smoke assertions for two shared materials, 64 board tiles, alternating colors, and palette propagation on switching to the ice region.
3. This handoff commit records the state, test status and next work. Earlier commits in this branch also implemented Android graphics quality tiers, scenery culling and a player-facing persisted setting; see prior sections for precise SHAs.

### Verification and risks
- **Confirmed:** GitHub accepted both source and test commits. The code now explicitly constructs two tile material resources rather than 64.
- **NOT confirmed:** latest GitHub Actions smoke-test result, Android APK export, physical-device rendering, FPS, thermals, GPU memory, or battery life. Do not infer a measured performance improvement from reduced material count.
- Known issues: chess/RPG checkmate and HP-aware capture edge cases need rule review; LAN reconnect and two-phone sync need field testing; authored rigged models and animations are incomplete; procedural environments and gear visuals are not commercial art; touch readability, UI layout, monetization, audio and onboarding need QA.

### Next execution instructions
1. Read current `docs/HANDOFF.md`, `scripts/main.gd`, `scripts/battlefield_3d.gd`, and newest Actions results; fix any CI failure before stacking more features.
2. Implement additional authored GLB assets or original procedural-to-authored model pipeline with correct licenses, distinct silhouettes and animations; add import/scene smoke tests.
3. Verify graphics tier controls and shared tile materials in Android debug APK; profile FPS, draw calls, memory and thermal stability on low-end and mid-range devices.
4. Improve checkmate/HP-aware captures and test cases, campaign variety and balancing. Commit actual code/tests, not only plans.
5. At the end, update this **full handoff**, retaining architecture, verified status, known blockers, exact commits and concrete next steps. Never claim production-ready until real device/playtest evidence exists.

## FULL HANDOFF — 2026-11-21, HP-aware chess check response

### Product requirements and architecture
- **Target**: portrait Godot 4.3 Android chess/RPG with chess-legal movement and king victory conditions, AP, HP, skills, fair PvP, 30 heroes with quest-gated progression, 7 gear rarity tiers, 18 story missions over 6 regions, authored high-quality 3D art, animations/VFX, audio, and two-phone LAN co-op.
- `scripts/main.gd`: chess/RPG combat, HP, turn handling, arena/raid, UI, save, networking; `scripts/battlefield_3d.gd`: 3D board, procedural models, effects, region lighting and graphics tiers; `scripts/progression.gd`: items and campaign; `scripts/hero_roster.gd`: hero records; `tests/smoke.gd`: headless assertions. Existing history and earlier implementation sessions are retained above.

### Changes in this run
- `e213ca784ecea5cc73bcc65d051fea192d5216a0`: corrected `_move_preserves_king` for occupied destinations in arena. A lethal RPG capture simulates the attacker occupying the target and removing the enemy; a nonlethal strike checks the unchanged board. Previously `current_safe and capture_safe` rejected legal lethal captures of a checking unit. This fixes that specific class of check responses without changing raid combat.
- `acc10c233ceb8e397541c27b524cfd3d7787a3e5`: regression tests for lethal capture of the checking rook versus nonlethal damage that leaves check unresolved.
- This documentation update records exact work, unresolved issues and next execution instructions.

### Validation status
- **Verified**: GitHub accepted source and regression test commits.
- **Not verified**: headless Godot smoke test, latest CI workflow run, Android APK export, real-device playtest or measured FPS for this new code. Do not claim tests passed merely because assertions were committed.

### Known bugs, risks and incomplete work
- HP-aware arena checkmate evaluation is still approximate; `_has_legal_action` does not fully simulate AP, abilities and all post-damage effects. Arena can grant repeated defensive AP while in check. King death via HP and chess check/checkmate may need explicit rules to prevent stalemates or endless turns.
- `_move_preserves_king` assumes base arena DAMAGE and 64 health entries. This matches current normalized arena damage, but future modifiers and skills require separate safety simulation. King capture semantics and castling/en-passant/stalemate/threefold repetition are not fully covered by the current chess/RPG hybrid.
- 3D renderer still relies heavily on procedural meshes; authored rigged characters, animation clips, bespoke gear, environments and VFX are incomplete. Graphics quality tiers and material sharing are not proof of acceptable mobile performance.
- Campaign missions have distinct records and modifiers but not all unique objectives/cinematics. LAN sync/reconnect requires two-phone QA. Save, UX, onboarding, audio, balancing, and Android device matrix need verification.

### Next execution instructions
1. Read latest HANDOFF and source; check newest Actions run and logs. If tests fail, repair and re-run before expanding features.
2. Add precise arena checkmate/defensive AP and king capture rules, with tests for pinned strikes, legal lethal captures, nonlethal attacks, king escape and no-legal-action states.
3. Continue authored GLB/rigged 3D asset pipeline with verified licenses and imported animation clips; verify appearance in Android build.
4. Test on real low-end/midrange Android devices; measure FPS, memory, touch readability and thermals for graphics tiers.
5. Update this full handoff after each development run with actual commit SHAs, confirmed CI status and concrete blockers.

## FULL HANDOFF — 2026-11-21, defensive board validation

### Mission and architecture
- Product goal remains Godot 4.3 Android portrait 3D chess/RPG with chess victory, king safety, HP/skills/AP, balanced normalized arena, 30 unlockable heroes, 7 rarity tiers of equipment, 18 campaign missions in 6 regions, authored characters and animation, visual effects and two-phone LAN.
- Primary modules: `scripts/main.gd` (game rules, UI, LAN, save), `scripts/battlefield_3d.gd` (3D board and graphics quality tiers), `scripts/progression.gd` (items, rewards, gating), `scripts/hero_roster.gd` (30 hero definitions), `tests/smoke.gd` (regressions). The preceding full handoffs and commit history above remain authoritative.

### Changes this session
- `66b9bcd196dfa60bf1f2e7ff1d4153e5d341a3ec`: `_tap` now rejects indices outside 0..63 **before** sending LAN RPC or accessing pieces; `_legal` now rejects incomplete 64-square board or HP arrays before indexing. This hardens untrusted or malformed action input without changing legal chess movement.
- `d56a9e2490c7cc938ab917354c25110cb067c62a`: smoke assertions verify that invalid negative/overflow taps cannot change board and that invalid moves are rejected.
- This handoff update records exact source changes and remaining work.

### Validation
- Confirmed GitHub accepted source/test commits. `get_commit_combined_status` for `d56a9e2` returned **no statuses**, which is **not** evidence that Actions passed or failed.
- Not verified: current headless Godot smoke execution, Android debug APK export, runtime performance, two-device networking, UI touch controls. CI requires checking actual Actions runs/jobs and logs.

### Known issues and limitations
- Chess/RPG hybrid still needs robust HP-aware checkmate, action economy, stalemate and king defeat tests. Current arena legality models basic lethal versus nonlethal attacks, but abilities and future modifiers require more complete simulation.
- Procedural 3D assets are not commercial-grade rigged characters; need original meshes, rigging, animation clips, gear variation, better six-region environments and VFX. Existing quality tiers and material sharing are unbenchmarked on phones.
- Network reconnect, host authority and action replay need two-device testing; profile/save migrations, accessibility, onboarding, sound, balancing and campaign variety need QA.

### Next execution — autonomous priorities
1. Inspect GitHub Actions workflow run for the latest commit and logs, repair errors, verify smoke and Android export.
2. Build full chess/RPG defensive turn and checkmate simulation including AP/HP and regression tests; ensure no softlocks.
3. Add authored/licensed 3D characters and animations, optimize render resources and profile on Android.
4. Run reproducible campaign progression/balance simulations; verify rarity and hero unlocks at all gates.
5. Record exact commits and verified/unverified test outcomes in the next full handoff, without claiming finished game or FPS.

## FULL HANDOFF — 2026-11-21, AP budget integrity

### Product and system state
- Goal: Godot 4.3 portrait Android 3D chess/RPG preserving chess geometry and king victory, with HP, damage, defensive skills, action points, fair PvP, quest-gated heroes and equipment, campaign, authored 3D models, animations and VFX.
- Implemented foundations: 30 hero definitions; seven gear rarity tiers; 18 campaign missions in six regions; arena and raid modes; chess attack geometry and HP-aware capture checks; procedural 3D board, scenery, lighting, check warning and three graphics tiers; save and LAN framework. None of this implies full game QA or commercial-ready graphics.
- Architecture: `scripts/main.gd` gameplay/UI/LAN/save, `scripts/battlefield_3d.gd` 3D presentation, `scripts/progression.gd` loot and campaign, `scripts/hero_roster.gd` heroes, `tests/smoke.gd` headless tests, `.github/workflows/android.yml` CI/export.

### Commits this run
- `42b73cdc6d5450cbffdcbccf92f5a79f383ed8d7`: reject all `_tap` actions when AP is zero or negative. Previously `_tap` lacked an AP guard, allowing an extra action when invoked with AP=0, including through LAN host processing. This preserves intended two-action budget; defensive AP replenishment in `_end_turn` remains separate.
- `e96c21089b7c8711dd1f78c93e3a9429c2fe75e7`: regression tests verify that no-AP taps do not select units or alter the board and that regular play resumes after AP restoration.
- This documentation commit records full state, risks and next steps.

### Validation and unresolved blockers
- GitHub accepted the code and test commits. Latest Actions run status **not confirmed**. Web access to the Actions listing was unavailable and GitHub commit combined statuses previously returned empty. Do not claim the smoke tests or Android APK succeeded.
- Existing test suite needs execution in Godot 4.3 headless; tests for checkmate, king HP, legal captures and AP/turn boundaries need extension. Real-device Android frame-rate, thermal, input and two-phone networking are unmeasured.
- Commercial-quality rigged 3D character art, animations, original regional environments and seven distinct equipment rarity appearances are unfinished. Gameplay balance, campaign variety, audio, UX and persistence migration need QA.

### Autonomous next steps
1. Obtain latest GitHub Actions run/job logs through available connector or GitHub UI; fix failures and verify APK export.
2. Audit LAN host action validation and turn/AP authority; add tests for invalid RPC, action replay and checkmate/AP softlocks.
3. Implement and import original authored GLB heroes and animation sets; verify license and Android rendering.
4. Expand deterministic battle simulation and progression tests for all unlock gates, check responses, and HP rules.
5. Profile Android hardware, then update this full handoff with measured results and exact commits. Do not claim production readiness without real test evidence.

## FULL HANDOFF — 2026-11-21, multiplayer/save state validation

### Product requirements and architecture
- Godot 4.3 Android portrait chess RPG: retain chess moves, king safety and win objective; RPG HP, AP, attacks, defense and skills; 30 named heroes with unlock gates; 7 gear rarity tiers; 18 missions across 6 regions; balanced PvP; LAN co-op; commercial-quality authored 3D characters/animations, VFX, equipment and environments.
- `scripts/main.gd`: combat, chess legality, UI, multiplayer, saves; `scripts/battlefield_3d.gd`: 3D board, models, animation, region scenery and three Android quality tiers; `scripts/progression.gd`: progression, item gates; `scripts/hero_roster.gd`: 30 hero records; `tests/smoke.gd`: Godot headless tests; `.github/workflows/android.yml`: CI smoke/export. Previous full handoffs above retain implementation history.

### Changes and exact commits
1. `91760f4da272c9ede911dc80d6adb9399942e12c`: new `valid_battle_arrays(board, hp_values)` checks exact 64-square arrays, valid chess piece glyphs, numeric finite nonnegative HP <= 1,000,000, and zero HP on empty squares. Used to reject malformed LAN snapshots before replacing live board and to reject malformed disk battle saves before restoring state. This prevents a class of corrupted/hostile payloads from entering game state.
2. `27f33df82d32160d1dd469510adc0e503679ae0d`: smoke regression tests for valid initial state, invalid piece ID, negative HP and excessively large HP.
3. This documentation update is the full handoff for the session.

### Validation status and risk
- **Verified:** GitHub accepted source and test changes. **Not verified:** latest Actions smoke results, Godot runtime syntax and behavior, Android APK export, real-device FPS/thermal/memory, LAN sync on two phones. The new HP invariant must be checked against every real battle snapshot, including defeat, death and save migration.
- Known issues: king HP/checkmate/AP semantics need comprehensive simulation and endgame rules; LAN snapshot sender trust, reconnection and replay still need QA; no commercial-quality rigged character pack yet; 3D effects and 6 regions need further authored art; no physical Android performance benchmark. Current procedural graphics are not finished commercial art.

### Priority sequence for next autonomous run
1. Inspect actual CI Actions run/job logs for the latest commits; fix parse errors and failed smoke tests first. Check snapshot validator against raid/arena defeat and empty-square HP invariants.
2. Strengthen host-authoritative LAN RPC validation and state synchronization, with tests for invalid/duplicate actions.
3. Complete HP-aware checkmate/king defeat logic and action economy, add deterministic scenarios.
4. Continue original authored GLB characters, gear rarity visuals, region art, animation/VFX, then profile on real Android.
5. Record confirmed CI/export results, exact commits and remaining blockers in the next full handoff. No claims of APK/game completion without verified builds and playtests.

## Full handoff — 2026-11-21, LAN snapshot schema

**Game target:** Godot 4.3 Android 3D chess RPG, chess-legal movement/king objective, AP/HP combat, 30 unlockable heroes, seven equipment rarities, 18 missions across six regions, fair PvP, LAN co-op, original rigged 3D models and animations. Architecture: `scripts/main.gd` game/UI/LAN/save; `scripts/battlefield_3d.gd` 3D rendering; `scripts/progression.gd` progression; `scripts/hero_roster.gd` hero data; `tests/smoke.gd` regressions; `.github/workflows/android.yml` smoke and APK.

**This run:** `5bf5ca5430ed338f6cb25f4dae8ea35d43d572d7` adds full `valid_raid_snapshot` validation of required typed network metadata, turn, AP, raid phase/stage, boss HP, target, wave, acted indices, board and HP before applying any client snapshot. `0ad275a4fbf399b0916722967f0c5bf6d317e344` adds tests for valid host snapshots, missing phase, invalid turn and invalid acted square. Source/test commits accepted by GitHub. This commit documents handoff.

**Verification:** Godot CI run, Android APK and two-device LAN are NOT confirmed. Do not claim runtime success. Potential validator compatibility with all raid transitions and snapshots requires executing tests. No FPS measurements or Android playtests.

**Remaining work:** complete HP-aware checkmate and no-softlock defensive AP; test LAN authority, reconnect and action replay; ensure all saved battles migrate safely; create/import commercial-quality original rigged 3D hero models, seven-tier gear visuals, animation/VFX and regional art; benchmark graphics quality tiers on real Android; audit campaign balance and hero unlock gates.

**Next autonomous execution:** (1) obtain and inspect latest Actions job logs; fix errors; (2) verify raid snapshot schema against all gameplay states and extend host authority tests; (3) fix remaining chess/RPG endgame rules with deterministic tests; (4) implement authored GLB/animation and visual polish; (5) test Android and append exact commits, verification and risks to this full handoff. Earlier history retained above.

## Full handoff — 2026-11-21: saved battle integrity

**Product:** Godot 4.3 Android portrait 3D chess/RPG, chess victory/check, RPG HP/AP/skills, fair PvP, 30 heroes, 7 gear rarities, 18 missions/6 regions, LAN co-op, authored rigged 3D assets/animations/VFX. Main modules remain `scripts/main.gd`, `scripts/battlefield_3d.gd`, `scripts/progression.gd`, `scripts/hero_roster.gd`, `tests/smoke.gd` and `.github/workflows/android.yml`. Prior history retained above.

**Commits:** `17ec8ff8878f737a44029fbc0fe161ca3a5024fc` applies strict shared raid/battle schema to disk battle restoration, preventing malformed turn, AP, acted indices, missing metadata and corrupt board/HP from mutating state; `6d4551f53f9cac7ecaef7bbef8190819fc69aceb` adds regression assertions for negative/excessive AP and string action indices. This documentation commit updates full handoff.

**Verification:** GitHub accepted code and tests. Current Godot smoke CI, Android APK export, physical device rendering/performance, and two-device LAN remain **unverified**. Validator assumes existing save schema matches `_snapshot()` plus mode/time fields; verify legacy save compatibility and real run outcomes before release.

**Known limitations:** incomplete HP-aware checkmate/AP edge cases; host networking action replay and reconnection; procedural rather than commercial-quality authored/rigged 3D models; limited authored animations, rarity visuals, region art; campaign balance and Android FPS/thermals unmeasured.

**Next run:** obtain latest Actions logs and fix failures first; audit compatibility of saved battles and LAN snapshots; implement deterministic checkmate and AP edge-case tests; advance actual original 3D asset pipeline; benchmark Android on device; update handoff with exact commits and verified outcomes. Continue without confirmation, but never claim a completed game without tests.

## Full handoff — 2026-11-21, immediate manual graphics session

**Workflow:** User explicitly suspended automation and requested immediate interactive development. Scheduled automation `Automation_d67c67895a088191a0759a2a7766539e` was successfully disabled; do NOT re-enable without explicit user request. User wants no intermediate status messages: report only after a priority item is FULLY complete, unless an actual blocker requires attention.

**Product/architecture:** Godot 4.3 Android portrait chess/RPG, chess legality, HP/AP combat, 30 heroes with gated progression, 7 equipment rarities, 18 missions/6 regions, LAN, high-quality 3D graphics/animation/VFX. `scripts/main.gd` combat/UI/network/save; `scripts/battlefield_3d.gd` 3D render/animation; `scripts/progression.gd` progression; `scripts/hero_roster.gd` hero data; `tests/smoke.gd` tests; `.github/workflows/android.yml` CI.

**Commits:** `eaeb2bf66aea67b2d063085c77137ba01da22b3d` adds 3D burst sparks to impact/healing effects with geometry-only meshes, shared spark mesh/material, quality-tier budget (low 0, medium 5, high 9), short lifetime and cleanup. `506377fb2ce80d6f0a6f77ddd7dd5ac14e227bf3` adds Godot smoke assertions for quality-dependent counts. This documentation commit records the session.

**Verification:** GitHub accepted commits; smoke/CI execution, Android APK and device FPS remain UNVERIFIED. Quality-tier spark behavior has assertions but no confirmed test run. Visual improvement is a small VFX step, NOT full graphics priority completion.

**Graphics priority remaining:** authored original high-quality rigged GLB heroes (30 differentiated appearances), combat animations, distinct gear rarity sets, full six-region environmental art, camera polish, hit feedback, GPU/CPU profiling and Android performance QA. Current procedural piece models and limited VFX are not commercial-ready. Other blockers: chess checkmate/AP/HP edge cases, network replay, progression balance and Android testing. Continue actual graphics implementation before reporting priority complete.

## Full handoff — 2026-11-21, active manual graphics development

**Priority:** complete visual production before user-facing completion notice. User explicitly requested no automation until separately requested; do not call run_now or re-enable schedules. Work in current chat only when prompted. No interim completion claims.

**Target and architecture:** Godot 4.3 Android portrait 3D chess/RPG, original rigged characters, 30 heroes, 7 equipment rarity tiers, 6 regions/18 missions, chess-legal combat with HP/AP, balanced progression and LAN. Code: `scripts/battlefield_3d.gd` visuals, `scripts/main.gd` gameplay, `scripts/hero_roster.gd` heroes, `scripts/progression.gd` gear/campaign, `tests/smoke.gd` Godot regression tests, `.github/workflows/android.yml` Android export.

**This manual session:** `970ee879b407c2a3522412df23f7f510b6d7644d` implements `_spawn_attack_trail`: short-lived layered 3D spark arcs for magical and physical attacks, with mobile visual quality tier budgets (low 0, medium 4, high 8), unshaded shared trail material/mesh and automatic cleanup. Called from existing `attack`. `b44a3d961ffc0d417b783c5c9436970bea6acde0` adds smoke assertions for low/medium transient mesh budgets. This documentation commit updates full handoff.

**Verified:** GitHub accepted commits. **Not verified:** Godot 4.3 smoke CI execution, Android APK, performance, animations on real devices. Visual milestone NOT COMPLETE: original authored rigged GLB models for 30 heroes, unique rarity gear appearances, animation sets, six differentiated environments and gameplay art direction remain to be produced and integrated. Existing procedural chess sculptures and effects are temporary art.

**Next priorities:** obtain working local/CI Godot verification, correct any parser/test failures; import original rigged 3D characters with animation library naming conventions; ensure all 30 hero identities appear visually (not just roster data); implement distinct equipment rarity material sets and regional scenes; optimize meshes/materials, then verify Android FPS and APK. Keep complete history and explicit test caveats in future handoffs. Do not message user claiming priority finished until complete.

## FULL HANDOFF — 2026-11-21, manual visual priority #1: hero identity integration

**Scope and order:** User selected priority 1 (complete 3D graphics), with no move to priority 2 without explicit approval. No scheduled automation requested; do not invoke automation. Do not report graphics as finished until all required art/animation/environment assets exist and have been tested. Work directly in repository in manual turns.

**Game target:** Godot 4.3 portrait Android chess/RPG, 30 unique heroes, 7 equipment rarities, six regional environments, 18 missions, HP/AP chess battles, PvP, LAN. Modules: `scripts/battlefield_3d.gd` visuals; `scripts/main.gd` UI and game; `scripts/hero_roster.gd` roster; `scripts/progression.gd` economy; `tests/smoke.gd` tests; `.github/workflows/android.yml` smoke and APK.

**Changes:** `3d207d93850bc5cf05cc0244dfbee1f18d21156a` adds `set_selected_hero_visual` and class-matched 3D identity insignia with deterministic color, spike silhouettes and rarity halo for each of 30 hero IDs; forces live 3D models to refresh when selection changes. `7a693fccdda9f3ed7a39292f23dcd421db2e1b2b` connects selected roster hero from `scripts/main.gd` to renderer. `6cb321270bf929e2fd240cceabf258950b37d837` adds smoke assertions for starter and relic hero identity visuals. This handoff commit preserves exact status and next steps.

**Verified:** GitHub accepted the source/test commits. **Not verified:** Godot smoke tests, visual rendering on Android, Android APK, frame rates. Identity crests are procedural differentiation, **NOT** 30 original authored rigged character models. Production art remains incomplete: original 30 character meshes and rigs, class/hero combat animations, distinct 7 rarity gear models, six fully authored region environments, VFX/lighting polish and measured mobile performance. Do not claim milestone complete.

**Next execution, same priority only:** obtain Godot/CI test results, fix any parser/runtime failures; implement a reproducible original 3D asset pipeline and import actual animated GLB character variants; integrate per-hero meshes/animations; author seven gear appearance sets and six region assets; validate quality tiers on Android. Update this full handoff after changes. Only after priority 1 is fully implemented and verified should user be asked to approve priority 2.

## FULL HANDOFF — 2026-11-21, manual priority #1 continued: humanoid battlefield figures

**User direction:** finish all of item 1 (production 3D graphics) before announcing completion; do not begin item 2 without explicit approval; automation remains paused. Keep responses concise and factual, avoid interim 'complete' statements.

**Repository:** `sitepushlic/kingdom-chess` main, Godot 4.3 Android portrait. Major files: `scripts/battlefield_3d.gd` 3D board and procedural art, `scripts/main.gd` gameplay/UI, `scripts/hero_roster.gd` 30 heroes, `scripts/progression.gd` 7 rarity tiers and campaign, `tests/smoke.gd` regressions, `.github/workflows/android.yml` build. Prior hero identity/selection wiring commits `3d207d9`, `7a693fc`, `6cb3212`.

**This turn:** `41b281181deb056d135cfa207f2aa6279bebcff8` replaces six abstract primitive chess silhouettes with six procedural humanoid armored classes. All fallback figures have torso, legs, arms, face, boots and class-specific costumes: scout hood/dagger, guardian shield, knight sword/visor, mystic staff/orb, battlemage wand/crown, sovereign cape/crown/scepter. Existing authored GLB loading remains first priority; this procedural character art is fallback. Identity crests for 30 heroes and 7 rarity materials continue to render on top. `ea91f71b05ddd4fcf0e17a754132f9f59c24b3d8` adds basic smoke checks for rig and identity integration.

**Verification:** GitHub accepted both source/test commits. Godot binary was not present in local execution environment; **no smoke-test run, APK or device rendering verified**. This is a visible in-game 3D model improvement, **not** completion of production-quality item 1. Remaining: 30 individually authored/rigged GLB heroes with proper animations, fully distinct gear for seven tiers, detailed six environments, all enemies/bosses, polished VFX and lighting, mobile performance and actual Android build testing. Continue item 1 only and keep handoff current.


## GRAPHICS CONTINUATION — 2026-11-21 — commits 9073566, 0cde743
- `90735660232b0ce404fa489f5f8e21656957a12e`: when `set_region` changes biome, rebuild the existing square-4 enemy king boss to apply the new biome's boss costume, without changing board logic; when `hit` occurs, play imported `hit` or `cast` animation if available, in addition to fallback limb motion.
- `0cde743577438fd910341422c523b9861eeb6d72`: `docs/ART_MANIFEST.md` lists all 30 canonical hero names, titles, chess classes, rarities and unlock quests, plus current procedural costume recipes and art acceptance checklist. A first manifest commit `f974cda` was immediately corrected because its parser omitted names; use the corrected current file.
- No Godot 4.3 binary or Blender is installed in the available container (verified via `command -v`). Python `trimesh` and `numpy` are installed. No headless Godot tests, CI result verification or Android runtime measurements were performed in this batch. Commits prove code saved, **not functioning art**.
- **Still remaining:** original authored 30 rigged hero GLBs, original rigged enemies and six bosses, 21 authored modular equipment meshes and true rarity visual progression, all animation clips incl. idle/move/attack/hit/death/cast, complete six polished authored regions and 18 mission variations, final VFX, integration/optimization, headless tests, Android CI APK and real device QA. Procedural hero costume/boss geometry is temporary and not sufficient for final acceptance.
- **Next recommended action:** obtain Godot 4.3 runtime and run all tests; inspect failures and fix; establish a Blender asset creation/export pipeline, then produce and integrate authored 3D art. Do not start priority 2.
