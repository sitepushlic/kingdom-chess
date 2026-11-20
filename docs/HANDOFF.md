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
