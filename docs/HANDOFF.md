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

## Recent earlier milestones
- CI #137 passed: procedural 3D arena, visual equipment, attack trails, phase VFX and associated smoke tests.
- CI #143 passed: 18 authored missions, variable enemy modifiers, campaign finale, HUD mission text, save and LAN sync; fixed a Godot 4.3 type-inference parse error in the mission generator.
- Check the most recent workflow at https://github.com/sitepushlic/kingdom-chess/actions before asserting any newer commit passed.

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
