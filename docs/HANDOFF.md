# KINGDOM CHESS — DEVELOPMENT HANDOFF

Updated: 2026-11-21. Repository: https://github.com/sitepushlic/kingdom-chess ; default branch: `main`.
This file is the persistent handoff for the next development session. Update it after every substantial implementation, with actual commits and CI status; never label the game production-ready without device and playtesting evidence.

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
