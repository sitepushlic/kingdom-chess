# KINGDOM CHESS — WORK EXECUTION HANDOFF (3D GRAPHICS)
Updated 2026-11-21. **Read this first. This document is the execution brief for ChatGPT Work, not a claim that the graphics are finished.**

## 0. Mission, scope, and non-negotiable user instructions
Repository: https://github.com/sitepushlic/kingdom-chess ; default branch: `main`. Godot **4.3**, portrait **Android** chess/RPG. User wants **priority 1, the entire 3D graphics production, finished**. Do not start priority 2 (battle mechanics) or any other roadmap priority without explicit user confirmation. Do not send routine progress updates, small-change summaries, or ask for confirmation between implementation steps. Work in large, sequential batches within the available execution session. **Never imply that work continues after a session stops**. Report only verified completion, or accurately state what remains if interrupted. Do not claim completion based on a code commit alone.

User communication: Russian, concise, concrete, no fluff. User is frustrated by repeated small commits and promises of future/background work. This document should allow a new agent to resume without making the user repeat requirements.

## 1. What the finished graphics MUST include
- **30 individual, visually recognizable heroes** matching every entry in `scripts/hero_roster.gd` (name, class, rarity, story). Each needs original full 3D character geometry, silhouette, face/headwear, class-specific gear, color/style and readable rarity progression. Not six class models with recolors or generic chess sculptures.
- Distinct **enemies, minions and region bosses** with meaningful character geometry and clear visual attack/readability cues.
- **Equipment: seven rarity levels** for weapon, armor/body, relic; distinct physical models and materials, not just a colored gem, hue swap or shader. Gear must actually update on the equipped hero and respect selected loadout. Avoid combinatorial explosion through modular attachments.
- **Animations:** idle, locomotion, attack (melee and magical where applicable), hit/recoil, death/defeat, ability/cast, and victory where used. Proper authored skeletal clips / animation tree preferred; procedural fallback alone is insufficient for final acceptance. Ensure animation playback hooks from actual battle events.
- **Six fully distinct 3D regions** and coherent environmental storytelling (landmarks, architecture/terrain, materials, particles, lighting, weather/ambience) while preserving chess-square readability. Cover all **18 missions** with appropriate variations and bosses. No 2D concept-image substitution for playable 3D scenes.
- **Effects:** physically legible attack trails, magical/projectile VFX, impacts, buffs, hazards, rarity effects, health indicators and environmental ambience; use mobile-conscious budgets and pooling.
- **Android integration:** Godot 4.3 GL Compatibility renderer, portrait 720x1280 design, quality tiers 0/1/2, controlled draw calls/mesh counts/texture memory, no missing imports, usable performance on a real Android device.
- **Finish criteria:** project imports cleanly; Godot headless smoke tests pass; CI Android APK export passes; manual on-device inspection of each hero, equipment tier, region, animation and combat effect passes; no placeholders or silent broken fallbacks. If no physical Android device available, clearly mark device validation **not verified** and do not call the work fully completed.

## 2. Ground truth: current implementation, NOT final art
- `project.godot`: Godot 4.3, GL Compatibility, 720x1280 portrait, main scene `scenes/main.tscn`.
- `scripts/battlefield_3d.gd`: ~45K GDScript, 3D SubViewport chess board, lighting, terrain/region procedural scenery, hazard markers, selection effects, gear rarity insignia, animated torches, attack trails, selected-hero crests, 6 procedural humanoid class fallback silhouettes and articulated fallback limbs. Optional authored `res://assets/characters/{pawn,rook,knight,bishop,queen,king}.glb` takes precedence when present. **Existing procedural visuals are NOT production-quality final assets.**
- `scripts/main.gd`: ~89K GDScript, battle/UI, hero selection, progression, scene rendering and event hooks; passes `HeroRoster.get_hero(selected_hero)` to `battlefield_3d.set_selected_hero_visual(...)`, and equipped gear via `set_hero_gear`. Keep all existing gameplay logic working.
- `scripts/hero_roster.gd`: canonical 30 heroes `hero_01`–`hero_30`, Russian names, lore, class (`K,Q,R,B,N,P`), rarity, role and unlock conditions. **Read all 30 entries before creating the art manifest.**
- `scripts/progression.gd`: equipment rarities and 6 regions / 18 missions. Read before mapping environment/boss assets.
- `tests/smoke.gd`: existing headless regression tests. Extend with model import, animation clips, gear visual swaps, hero uniqueness and region loading tests. Tests are necessary but not substitutes for visual/device validation.
- `.github/workflows/android.yml`: Godot 4.3 download, headless checks and Android export; check actual GitHub Actions status, errors and downloadable debug APK.
- `docs/HANDOFF.md`: long chronological history (~94K). **Use this document for current mission and consult historical handoff only as needed.** Keep this file and `docs/HANDOFF.md` updated with verified state.

### Most recent graphics changes
- `41b281181deb056d135cfa207f2aa6279bebcff8`: six class-specific procedural humanoid fallback models with armor/weapons.
- `628c12f1dc35d7d4f160897ccfaf730dd0b829e4`: articulated fallback arms/legs and movement, attack, hit, healing procedural clips.
- `d35bc4120004c6e7a719bcc01d58bd25cc7157e0`: tests for fallback limb nodes.
- Earlier `3d207d93850bc5cf05cc0244dfbee1f18d21156a`, `7a693fccdda9f3ed7a39292f23dcd421db2e1b2b`, `6cb321270bf929e2fd240cceabf258950b37d837`: 30-hero selected-identity crest wiring/tests.
- **Do not assume any of the above passed CI or device tests.** Last confirmed fact: GitHub accepted file updates. There was also a subsequent priority-2 bugfix (`97585ed`, `ae59a95`) to stalemate; preserve it, but do not develop gameplay further until the user approves.

## 3. Work execution order — stay within graphics priority 1
**A. Audit + establish test baseline.** Fetch full repo tree and all relevant source. Inspect existing `assets/` for true GLB/GLTF files, OBJ placeholders, textures and animations. Check Godot/Blender installed in Work environment, install/setup as needed if allowed. Run Godot 4.3 editor import and `tests/smoke.gd` before modifications. Inspect Android CI runs. Record errors before fixing. Do not rely on the text in prior handoff as proof.

**B. Asset manifest + production pipeline.** Create `docs/ART_MANIFEST.md` enumerating all 30 heroes (exact ID, name, class, style, silhouette, rig, animation clips, gear sockets), enemy archetypes/bosses, 7 rarity sets, 6 environments and 18 missions. Create a reproducible Blender pipeline (e.g. `tools/art/`) generating original editable `.blend` sources plus exported `.glb` files. Avoid relying on unavailable external copyrighted models or unlicensed assets. Commit the actual source assets and exports, not screenshots. If GitHub connector cannot upload binary, use Work's cloud computer/terminal/git access and check commit contents.

**C. Heroes + enemies.** Model and rig all 30 uniquely. Use a consistent shared skeleton where practical, while varying geometry, facial/head details, costumes, proportions, signature weapons and hero-specific features. Build enemy minions and all bosses. Provide animation clips `idle`, `move`, `attack`, `hit`, `death`, `cast` (and any game-specific needed). Export as Godot-importable GLB. Verify per-file imports and animation playback.

**D. Equipment.** Build modular 3D meshes for 7 rarity tiers × weapon/armor/relic, with socket alignment and real geometry/material differences. Implement selected hero equipment swapping and preview; ensure the highest tier cannot visually appear for unearned low-tier equipment. Test all slots and tiers.

**E. Environments/VFX.** Build six distinct 3D biomes/region scenes and 18 mission variants with bosses/lighting/particles. Integrate to existing region selection. Keep tiles, hazard indicators, targets and unit silhouettes visible from the portrait camera. Optimize effects for 0/1/2 quality.

**F. Integrate/validate.** Wire hero-ID-specific assets, enemy/boss assets, animation player and gear attachment into `battlefield_3d.gd` without breaking `main.gd` chess/RPG mechanics. Run Godot headless smoke and scene import tests; inspect GitHub Actions; produce APK; visually inspect 30 heroes, 7 rarity tiers, 6 regions and animations; run on Android if device available. Fix regressions. Document actual FPS/memory only when measured, never invent numbers.

**G. Completion.** Commit all files, source assets, manifests, tests and `docs/HANDOFF.md`. Final report in Russian with verifiable commit(s), checks performed, and explicit unverified items. **Do not call graphics finished unless every acceptance criterion is met.** Do not move to priority 2 without user approval.

## 4. Known implementation risks / verify first
- The latest fallback limb animation calls `_animate_limbs` on a rig. Confirm actual node hierarchy and that `VisualRig` owns `Arm_L/R`, `Leg_L/R`. Verify `_animate_hit` hook, authored animation player path, and all test assertions against real Godot runtime. If import fails, fix before adding more assets.
- The 30-hero identity mechanism currently attaches an ID crest to matching **piece class**; it does not load 30 unique meshes. Implement hero-specific asset resolution without wrongly replacing every unit of the same class with the selected hero.
- `_load_authored_character` currently resolves six class GLB paths, not hero-ID GLBs. Add robust hero-ID and enemy/boss path routing with deterministic fallbacks, not silent placeholders at release.
- 3D animation must not interfere with gameplay coordinates, hitboxes, turn order, chess safety or 2D HUD.
- Godot 4.3 GL Compatibility may limit shader/particle features; test on that renderer rather than relying on Blender render quality.
- Some test and code changes were committed without running Godot. Check compile/parser errors, typed GDScript inference, missing materials/nodes and failing assertions.
- Keep CI workflow intact; no production deployment without successful checks. Back up working baseline before invasive art integration.

## 5. How to start in Work
Open repo, read this file and `docs/HANDOFF.md`, inspect current source/assets, establish Godot CI baseline, then **execute A–G autonomously in the current Work session**. Do not stop after writing a plan or a couple of minor commits. If runtime/tool limits prevent finishing, preserve complete reproducible handoff and honestly state exact remaining blockers; do not pretend background execution is happening.

**Prompt to Work:** “Открой `sitepushlic/kingdom-chess`, прочитай `docs/WORK_GRAPHICS_HANDOFF.md` и `docs/HANDOFF.md`. Полностью реализуй только пункт 1 — 3D-графику по критериям приёмки. Создай и подключи реальные 3D-ассеты и анимации, проверь Godot 4.3/Android CI, исправь ошибки, обнови хэндоф. Не переходи к пункту 2 и не присылай промежуточные отчёты. Не заявляй о завершении без фактической проверки.”

## 6. Manual graphics implementation batch — 2026-11-21 (after initial Work brief)
This batch is committed to `main`, not verified in Godot:
- `db31da2d1d1722c56d6b1b41528ae16741220eed`: `_add_hero_signature_costume` generates 30 deterministic **procedural** costume/head silhouettes: five body archetypes × six signature head geometries, plus rarity metalwork; called by `_add_selected_hero_identity`. This improves differentiation but **does not satisfy the requirement for 30 authored/rigged GLBs**.
- `315c920f70085257646c8816cd102b68b52c206a`: tests 30 costume recipes.
- `346c09eba885de6de8d80d6dd3783e2f7bdc5d30`, `11fa154b21755abab2d7a92f9c820688b3ce6258`, `6f427ff0f063b39b07d369694a34c3c80b2dac45`: seven physical gear silhouettes per weapon/body/relic slot, selected-gear 3D integration. This is procedural geometry, not final authored equipment.
- `5826ab4cda349a3aa1a14431f5cbd6065dd09162`: tests 21 tier/slot mesh combinations.
- Environment check in this session: local runtime has neither Godot nor Blender; no actual Godot parser/test run, Android APK or visual device inspection was performed. **The code is unverified and may have errors.** Run Godot 4.3 headless and fix any errors before relying on it.
- Highest priority next: install/run Godot in a capable environment; audit smoke test and 3D node tree; produce original rigged GLB characters, boss art and modular equipment; integrate authored animation clips and mobile performance; complete 6 regions and Android checks. Preserve priority 1 restriction.

## 7. Subsequent graphics batch — 2026-11-21
Committed to `main`:
- `8b460b5cd86a7086158e4902446aa0d305898ab2`: six unique large region background constructions (furnace gate, glacier arch, sacred tree, astral library portal, storm observatory, void throne) beyond the existing 12 perimeter props and four corner monuments.
- `7e70db4d5c666c2813ff198e7a43d6d310e1168f`: smoke tests building all six region backdrops and checking nonempty 3D geometry.
- `1ab1b9da0cf0eeca5058b2874a47fb58ace0b54c`: six region-specific boss adornment silhouettes integrated into `_build_piece` when `is_boss`. Boss model still uses procedural base mesh; not a finished authored/rigged boss.
- Environment check: local execution runtime has Python `trimesh` and `numpy` but neither Godot nor Blender binaries. Godot smoke tests and Android export **not run**; tests are added but **unverified**. Need inspect actual Godot import and CI errors as next priority.
- **Important:** current boss model is constructed using `current_region`; when changing region while the same boss node persists, `sync_board` may need explicit rebuild to refresh boss adornments. Verify and fix.
- Do not report priority 1 as completed. Original rigged GLBs, animation library, authored 21 equipment variants, mission-specific environments, device performance and Android validation remain.


## GRAPHICS CONTINUATION — 2026-11-21 — commits 9073566, 0cde743
- `90735660232b0ce404fa489f5f8e21656957a12e`: when `set_region` changes biome, rebuild the existing square-4 enemy king boss to apply the new biome's boss costume, without changing board logic; when `hit` occurs, play imported `hit` or `cast` animation if available, in addition to fallback limb motion.
- `0cde743577438fd910341422c523b9861eeb6d72`: `docs/ART_MANIFEST.md` lists all 30 canonical hero names, titles, chess classes, rarities and unlock quests, plus current procedural costume recipes and art acceptance checklist. A first manifest commit `f974cda` was immediately corrected because its parser omitted names; use the corrected current file.
- No Godot 4.3 binary or Blender is installed in the available container (verified via `command -v`). Python `trimesh` and `numpy` are installed. No headless Godot tests, CI result verification or Android runtime measurements were performed in this batch. Commits prove code saved, **not functioning art**.
- **Still remaining:** original authored 30 rigged hero GLBs, original rigged enemies and six bosses, 21 authored modular equipment meshes and true rarity visual progression, all animation clips incl. idle/move/attack/hit/death/cast, complete six polished authored regions and 18 mission variations, final VFX, integration/optimization, headless tests, Android CI APK and real device QA. Procedural hero costume/boss geometry is temporary and not sufficient for final acceptance.
- **Next recommended action:** obtain Godot 4.3 runtime and run all tests; inspect failures and fix; establish a Blender asset creation/export pipeline, then produce and integrate authored 3D art. Do not start priority 2.

## 8. Environment ownership correction — 2026-11-21
User explicitly requires **zero user-side installation or setup**. The agent owns toolchain setup, 3D creation, GitHub commits, tests and troubleshooting. Do not ask the user to install Godot/Blender or perform builds.
- Current local container: root privileges and apt-get available; `godot` and `blender` executables absent. Direct outgoing internet from container failed DNS lookup to github.com; **do not claim local installation succeeded**. If external downloads are blocked, use GitHub Actions (workflow already downloads Godot 4.3, runs smoke tests and exports Android APK), or another tool-enabled environment. Check CI logs/results instead of repeatedly blaming missing local software.
- The workflow `.github/workflows/android.yml` already includes Godot 4.3 import, `tests/smoke.gd`, and Android APK export on each `main` push. Need inspect its actual run results and fix errors. CI does not replace visual QA or Blender modeling.
- No new models or test execution completed in this correction step. **Remaining unchanged:** 30 authored rigged hero GLBs, enemies/six bosses, modular gear, authored animations, six final biomes/18 missions, Android optimization and actual validated APK/device QA.

## 9. Graphics continuation — generated original GLB blockout pipeline (2026-11-21)
**Saved commits:**
1. `231a925384a3ecd001b62d6c68f7fd4125bf80ed` — added `tools/art/generate_blockouts.py`: Python standard-library-only GLB 2.0 writer, 30 unique hero-ID low-poly geometry combinations and six region boss models; each includes six named **rigid-node** animation tracks (`idle`, `move`, `attack`, `hit`, `death`, `cast`). No Blender needed to generate these initial GLBs.
2. `484599dc887472929eacfaa27ff35a9289cf9146` — GitHub Actions runs generator **before Godot editor import** and APK export, so CI generates 36 GLB files without user intervention. Generated binaries are build products, not committed; reproducible generator source is committed.
3. `1dab0571b2e17d8fb1998474f4177520b600e4ab` — `battlefield_3d.gd` resolves `res://assets/characters/hero_XX.glb` for the selected matching hero class and `boss_region_N.glb` for the region boss, falling back to legacy class model when missing. Adds `boss` metadata.
**Status:** source code committed, no verified GitHub Actions result or Godot import. These GLBs are **simple original mesh blockouts, not final professional rigged/skinned hero models**. Clips animate whole-model transforms, not skeletal limbs. The selected-hero model is currently used on all white units of matching chess class; correct per-piece identity mapping is still required before claiming proper 30-hero integration. Boss clips and generated hero clips must be visually tested.
**Remaining, mandatory:** verify CI logs/GLB imports, fix any generator or Godot errors, real per-unit hero-ID mapping, rigged original hero and boss assets with skeletal animations, 21 authored equipment models and socket attachment, six authored regions and 18 mission variants, VFX/death/victory, optimized APK and Android device QA. **Priority 1 still unfinished.**

## 10. GLB pipeline repair and automated art validation — 2026-11-21
Every development step saved to `main`:
1. **`fd7ad972fa69507c22daac0e1afd7427c7161eb2`**: fixed fatal Python GLB generator bug: `struct.pack` was passed a list as one argument rather than expanded numeric values. Previous 36-file generation could not complete. Now uses `*data`.
2. **`c29276a7c0ad3e0b72049c787854b8a7dab2eb96` + `932721bf2b48b43a75a86a92a3f4166065f3974a`**: added `tools/art/validate_blockouts.py`, validating 36 GLB headers, JSON/BIN chunks, buffer/accessor bounds, node meshes, all six named clips, and hero geometry variety.
3. **`ce9cc08d78c0a1efc1857e710084740520f85c45`**: Android GitHub Actions now runs GLB validation after generation, before Godot import.
4. **`7b0c4f6a6461e7ed817d78027ffc27693a72b6cf`**: imported hero/boss scenes automatically play looping `idle` animation when available.
5. **`634c1f7e587a88ec53e850e7ce90f8e99b991cdf`**: Godot smoke tests require five representative hero/boss GLBs to import as PackedScene and expose `idle/move/attack/hit/death/cast`.
**Verification:** local container has no Godot/Blender and cannot reach github.com (DNS failure). GitHub commits confirmed; **the generated GLB validation, Godot import and Android CI have not been observed running successfully**. The new tests can still expose additional issues. Do not claim successful APK export.
**Remaining:** inspect actual Actions logs, fix any import/parser failures, original authored rigged/skinned 30 heroes + six bosses and enemy units, proper hero-ID mapping per piece, modular authored equipment, 18 mission environments, final VFX, mobile performance, Android APK and real-device QA. These are blockouts with rigid clips, not final graphics. Continue only priority 1.

## 11. Selected hero identity mapping — 2026-11-21
- **`695680c9ce60447a9816c5a9df54050ee90ea99d`**: `scripts/battlefield_3d.gd` now has `hero_model_cell` and assigns the selected hero's GLB/insignia to **one** allied chess piece of the selected class, not every same-class piece. The bearer is chosen deterministically if missing, preserved during `animate_move`, and its scene is refreshed if the selection changes. `_build_piece` has an optional `selected_hero_piece` argument; direct preview calls retain previous default.
- **`2a47c0441c700756c2017030f7535f69c2b4c5b1`**: regression smoke test ensures a second unit of the same chess class does not receive selected hero's crest.
- **Verification:** GitHub commits saved; **Godot tests and APK not verified** in this execution environment. Selection currently attaches to the first available matching piece (not a persistent per-unit gameplay identity); full roster/team deployment and true per-unit hero assignment remain a design/integration task.
- **Still remaining:** test CI import and animation results; create genuinely rigged/skinned hero GLBs with articulated animation (current 36 assets are rigid blockouts); authored gear and enemy assets, six final authored biomes and 18 mission variants, VFX and Android mobile performance/QA. Do not mark graphics complete.

## 12. Gear ownership and scene rebuild optimization — 2026-11-21
- **`b94a7a3b63dce981de0d2c58520acd4f07a7b059`**: equipment geometry and rarity insignia are now attached only to the selected hero's bearer (`white and selected_hero_piece`), instead of being duplicated onto every allied chess piece. `set_hero_gear` invalidates only the bearer for a visual rebuild rather than queue-freeing all 64 pieces, clearing piece types and disrupting moving units. This improves visual identity correctness and should reduce redraw cost on equipment changes.
- **`0d3282e3745fba3575c03eec98c98a2e7786db13`**: smoke regression asserts equipped selected king has weapon rarity insignia and another allied king does not.
- **Verification:** changes committed to `main`; no Godot smoke or Android run result verified. Must check actual CI before claiming pass.
- **Remaining:** verify CI and fix Godot errors; replace all 36 generated rigid-animation blockouts with authored rigged/skinned hero/boss models, enemy assets, 21 authored modular gear models with attachment sockets, six finished biome environments plus 18 mission variants, VFX, optimization and Android APK/device QA. The game is not yet visually complete.

## 13. Articulated GLB motion and animation state recovery — 2026-11-21
1. **`42aecaa8217e609402e713f2b6dc99c22ab74809`** — enhanced the deterministic 36-GLB generator: separate left/right arm rotation channels for all six clips, separate leg rotation channels for `move` and `death`, in addition to existing body translation. Character arms/legs can now move independently. **Still rigid mesh-node articulation, NOT a skinned bone skeleton**, and not production animation.
2. **`1392adfbf91da9d6cd8f4ad96b071393f782c0a9`** — GLB validator now checks that every clip has root translation and independent arm rotation and that move/death include leg rotation. Existing Android CI runs validator before Godot import.
3. **`0269abcc1c1c7e74e5fa58a82885befbcc1aff85`** — imported AnimationPlayer resumes looping `idle` when a one-shot move/attack/hit/cast clip finishes, rather than freezing in its final action pose.
**Verification:** GitHub commits saved, but Godot 4.3 import, Actions success, visual motion, and Android APK **not yet verified**. Generator and validator are not yet demonstrated to run successfully in this chat.
**Remaining priority-1:** actual skinned/rigged hero GLBs (30), unique rigged enemies and six bosses, original 21 modular gear meshes with sockets, six polished authored biomes and 18 mission variants, improved materials/lighting/VFX, verified Godot/CI import and Android device performance. Generated blockouts remain temporary.

## 14. Biome-specific enemy GLB pipeline — 2026-11-21
- **`af9f9e331a48fc10165048c0cfc76c569569c7b5`**: generator now creates 36 additional enemy GLB blockouts (six chess classes × six regions). Total generated models: **72** (30 heroes, six bosses, 36 enemy variants).
- **`25ec06aded9faa5e988519999888c8cd97421ef2`**: Python binary/animation validator requires all 72 assets.
- **`5ea3aa057b7d976ce31fcebbe44cd25d8fb82224`**: battlefield loads `enemy_<class>_region_<region>.glb` for enemy non-boss pieces; bosses retain dedicated region GLBs.
- **`e9e7f3155ff1f2fc098aeab7782010156f333743`**: enemy archetypes have distinct head silhouettes and region-marked geometry; later regions gain extra armor.
- **`634c35bd80d5090b8d092bfdffe36cb50ae75adc`**: Godot smoke includes representative regional enemy GLB import and six animation checks.
- **Verification:** GitHub code commits confirmed. 72 generated binaries, Python validation, Godot imports and Android APK have **not been observed successfully running**. All generated models remain stylized blockouts with independently animated rigid mesh nodes, not final skinned characters.
- **Remaining:** actual CI run inspection and fixes; 30 fully skinned hero assets, enemy and boss art polish, skinned animation, 21 gear meshes with sockets, six polished regions and 18 mission variants, VFX, device performance, Android QA. Priority 1 not complete.

## 15. Three distinct mission layouts per region — 2026-11-21
- **`1f4b78d4b1361a13286e2886c9b15437c97b89dc`**: `battlefield_3d.gd` adds `mission_visual_variant` and `set_mission_visual_variant(0..2)`; the three layouts use flags/standards, runic obelisks, or ward circles. All decorations sit beyond the 8×8 chess board. Six region themes × three layout styles = 18 procedural visual variants; these are **not 18 final authored level environments**.
- **`fd7855c26e9a8d3ce57d8ab8b2be0abf87196c00`**: `main.gd` selects the layout via `raid_wins % 3` while in raid mode; arena mode uses layout 0.
- **`d87fb82a77a549a1587074ee5e2706c9a544dfce`**, **`7f85ae85e4ccc707abdf76375fdeb0ea9f70a85b`**: smoke regression checks three variants have different numbers of generated geometry nodes.
- **Verification:** code committed. No successful Godot smoke, GLB import, Android build, or visual device test confirmed. Visual layouts are procedural low-poly dressing only.
- **Remaining:** verify CI, fix import/parser/runtime issues, 30 rigged heroes + 36 enemies + six bosses with proper skinning, 21 authored gear assets, polish all 18 environments, VFX, lighting, performance and Android QA.

## 16. Large-batch 3D equipment + enemy asset integration — 2026-11-21
Implemented as one continuous batch (no user involvement):
1. **`4dbd2b4edbb482aa67d01cd4f82dfe97ba55399e`**: new `tools/art/generate_equipment.py` generates 21 original low-poly modular GLB props: seven physically distinct weapon tiers, seven armor tiers, seven relic tiers, with metallic PBR materials and named mesh parts.
2. **`b58baae6146ba37018d748237551f9d7878e35eb`**: GLB validation extended to all 21 gear assets, enforcing different node/geometry signatures per tier. Combined expected GLB count: **93** (30 heroes + 36 regional enemies + 6 bosses + 21 gear).
3. **`c8c8bd1b1bd153bd19cc7d0b5701b9e9f9d18723`**: Android Actions now generates gear before Python GLB validation and Godot import.
4. **`4f00bac41340d11d5c8ceaf1d5535c56034aa3fe`**: `battlefield_3d.gd` loads `res://assets/equipment/{weapon,armor,relic}_tier_N.glb` via independent equipment socket nodes; procedural mesh fallback remains for missing assets.
5. **`ac90b5decdb36af9348ab7bdde70d3bbbaa52785`**: changing biome refreshes **all** enemy model scenes (not only boss), retaining chess cell indices. Captured hero bearer cell is invalidated.
6. **`0f5f30fed8c9cdd7619f8fddb869eb916307e808`**: smoke tests require import of all 21 gear GLBs and distinguish tiers by actual mesh node names rather than top-level node count.
7. **`27304bbcbd6b0627baef201727622d12bc4c60d7`**: six enemy classes get physically different equipment silhouettes, plus six region-specific material palettes.
**Verification:** all code and test commits saved in GitHub; generator execution, Godot import, Actions and APK have not been observed succeeding. Assets are procedural blockouts, **not final polished or skinned assets**. CI will generate 93 GLBs; generated binaries are not committed to repository.
**Remaining priority 1:** verify Actions logs and correct failures; replace blockouts with professionally detailed/skinned models and skeletal animations; add authored material maps, detailed equipment attachment sockets to actual bones, finished 18 environments, polished VFX/lighting, Android performance profiling and on-device QA.

## 17. Art-pipeline hardening — 2026-11-21
- **`cdc5e0d81a6b95d508312562d5161132211917f5`**: CI checks Python syntax for all three art scripts before generating assets.
- **`172b334487be29d81469af83918cabe4dea5f095`**, **`4bc9fce949512c7d17d10bd3d060fe73cd3dd5d0`**: character and equipment blockout PBR materials use double-sided rendering so cuboid faces remain visible despite minimal shared-vertex geometry.
- The 93 GLB files are expected outputs of CI generators, **not** committed binaries or proof of successful execution. Environment lacks Godot/Blender and outbound DNS, so the GitHub Actions result and Android APK are **not verified**. Next highest priority is obtaining real CI logs and resolving any failures before claiming asset pipeline passes.

## 18. Full-batch graphics hardening and articulation — 2026-11-21
User requested the maximum practical work in one pass; changes committed directly to `main`:
- **`e2666df24a106268e1bbe76aa0cdd9b8ce7c82e3`**: imported equipment retains stable `Rarity_<slot>` marker, fixing a regression against existing Godot smoke tests.
- **`963c92ac6839f5e246423f0b0ec0249853ed071f`**: changing selected hero invalidates only the previous bearer, not every unit of that chess class.
- **`f2f27d05816b20cdab0f9884708af7c0d87ba3c6`**: generated characters now have independent shoulder/hip pivot nodes and child limb meshes. Rotations happen at joints rather than mesh centers. **Not skinned/skeletal rigs**.
- **`c8e4ac9bd23bc252d630be6677af18e3e159de98`**: validator enforces pivot-to-mesh hierarchy for arms/legs on all 72 character GLBs.
- **`24efc07f85d013e283f405de84e77c6ea069e488`**: validator checks scene graph indices, animation targets, sampler indices and keyframe counts.
- **`a65cf1a61751f441dbec0edaf1ce0439e2ff0ad1`**: all 30 heroes receive class-family weapon silhouettes and signature runes; six bosses get distinct oversized relic weapons.
- **`f1fe114770ae3f6a9a926d26f97822a57b9eba5d`**, **`b5a0cfb5d8e3f8f64c553f12da5cd33039771f6b`**: new `tools/art/check_reproducibility.py` and CI step regenerate all 93 GLBs and verify byte-for-byte SHA-256 equality.
**Verification:** GitHub commits confirmed; neither local Python generator execution nor Godot import nor Android APK has been observed succeeding. GitHub workflow-run lookup for a prior commit returned no PR-triggered runs, **not** proof of success or failure. Tests are committed but their pass status remains unknown.
**Remaining priority-1:** actual CI execution/logs, skinned/rigged production assets for 30 heroes + 36 enemies + six bosses, refined equipment sockets and textures, six final 3D biomes/18 levels, effects, Android performance and device QA. Do not call this graphics-complete.

## 19. Mesh lighting and mobile asset budgets — 2026-11-21
This batch committed directly to `main`:
- **`3ac1feb21ebd818e21dffb0755702f8f53d511e3`**, **`51aee2db44f36ddf7f8f4156bc86421eda29593a`**: replaced shared eight-corner cubes with 24 per-face vertices and six explicit flat normals, plus consistent triangle winding, across character and equipment GLB generators. This gives sharp low-poly shading and more predictable Godot lighting.
- **`cdfdba11d64b8070db647515cefad028d3bcebff`**: validator requires NORMAL attributes, 24-vertex/36-index cube topology on every mesh primitive.
- **`be6cb832a0625b26603f7ad7f40ab8bf2baa0cab`**: fifth emissive material for hero runes, mage crystal, bishop focus and boss relic prongs.
- **`f1127b3c436dc0bf92e83853dd4e2bdd6c4a21b7`**: mobile asset budgets in Python validator: under 250 KB/GLB, at most 160 nodes and 2,000 estimated rendered triangles per generated asset.
- **`4f1bc6fbbf4800571fcb19ffca1076c41a0f82f7`**: arm/leg locomotion and combat gestures rotate around X for forward/back swings; impact/death gestures use Z.
**Verification:** committed to GitHub. CI and Android import **not verified**; workflow lookup for an earlier commit yielded zero runs, so cannot claim green builds. All 93 GLBs are still procedural low-poly blockouts. Priority-1 graphics remains incomplete: proper skinned rigs and animations, production meshes/materials, detailed regions, VFX and Android device QA.

## 20. Equipment-to-animation binding, boss identity and CI diagnostics — 2026-11-21
A substantial continuous batch was committed directly to `main`:
- **`5edb39480100002d8ba897b85667cc2bac45773d`**: imported GLB weapon sockets now parent to animated `Arm1` and relic sockets to `Arm-1` when available. Armor remains torso-mounted; procedural fallback preserved. Socket offsets are joint-local.
- **`f81d9e594faa736ef6aa1fec1368ec22851a1a4e`**: Godot smoke requires selected hero's weapon socket to follow imported arm pivot.
- **`6a20a519b1342c640a4a502b6f82d60e4869f731`**: captured units play `death` clip and fade in two stages, independently of chess state changes.
- **`1e18f62bf2124c4c2393822374a5169e6a4d1df8`**, **`470c1b43fa12a67ac1fc5bc2f0b77a57f0eb0c10`**: 21 equipment models gain physically distinct enchanted crystal clusters with emissive material for tiers 4–6; validator rejects low-tier enchantments and missing high-tier enchantments.
- **`617f4d7898b4fe292087a274c32f0f134b3493ba`**, **`bbc16217553503e762abf434b12d49fb3d353cb4`**: six biome bosses now have specific unique modeled landmarks (ember horns, glacier spires, thorns, runic tablet, astral wings, crimson wings), enforced by validator.
- **`92fd714502da2f6682f29c7cfb6ccc26b36035d7`**: CI now retains Godot import/smoke logs even on failure, uses `pipefail` and rejects import parser/glTF errors.
- **`b8d9eb15e33dfd07b44f5672567f38709e376df7`**, **`bd34095f78e64a4b70d21bb7c63fa44c31625e67`**, **`38ef59a941e8b0a9a54cae1616a4c85e0cb03378`**: all characters have additional 3D face, armor and gauntlet detail; gauntlets, boots and shin plates are attached to animated limb pivots, verified by Python validator.
- **`b7de4cdbe90428d33a1696358b19b0e273baa078`**: CI publishes all 93 generated GLBs as a downloadable 14-day art-pack artifact.
**Verification:** GitHub commits confirmed. This environment cannot reach GitHub raw URLs to run Python scripts locally; no Godot binary is available. CI status, generated artifact and Android APK remain **unverified**, not passed. The models are low-poly articulated blockouts, not fully skinned character assets.
**Remaining priority 1:** observe real GitHub Actions run and logs, resolve any generator/Godot errors, upgrade to actual skinning and skeletal rigs, build polished hero/monster designs, improve lighting/material textures and 18 locations, Android device profiling and QA.

## 21. Downloadable art inspection manifest — 2026-11-21
- **`fb371b426ac923ba721042cbaa9b35235bc80073`**: `tools/art/export_art_report.py` emits `build/art_manifest.json` listing all 93 GLBs with SHA-256, file size, rendered triangle count, node count, materials, clip names and geometry signatures.
- **`47bf9afe3bb358a8f0a876741b484fdb76355e4b`**, **`2788bc1626eb97c6bd69588c4bed148f530bdf1f`**: Android workflow syntax-checks, generates and uploads this manifest alongside 93-GLB art pack and import/smoke diagnostics.
- **Verification remains pending:** scripts and CI changes committed, but the actual Python run, Godot import and Android build have not been observed succeeding. No green status should be claimed.

## 22. Role identity, mobile VFX, independent body lean — 2026-11-21
This development batch, committed directly to `main`:
- **`3bc617624901a91e9b1cb6024a4c79e63c877faa`**: removed overlapping legacy geometry when modular GLB equipment is available, preserving fallback when absent. Prevents doubled swords, armor and relics.
- **`ce3437997777c2e0fe3edfce1530b70296b83e87`**, **`4158dd99190bdab4fb7c796238ce12a75c65d28e`**: all 30 heroes receive explicit chess-role physical heraldry (king crown, queen diadem, rook battlements, bishop mitre, knight winged helmet, pawn banner). Validator checks each hero's expected role marker.
- **`01e34cde45b4dc80acd600482bbabc187cd92cca`**: rare equipment (tier 4+) gains up to 1–3 socket-bound magic halos depending on graphics quality. These are static low-cost mesh rings, not particle emitters.
- **`9e9cf2a9c25f82510e24706cfa74e75bc98bdfb1`**, **`be22cc628784ca650cc69962ffcf3e342641032c`**: six character animation clips now include independent BodyRig pitch/lean rotation in addition to root translation and arm/leg motion; Python validator checks every clip.
**Build status:** GitHub commits confirmed; GitHub workflow lookup connector filters to PR-triggered runs, whereas this repository workflow triggers on push, so an empty lookup result **cannot** establish CI status. No successful Python generator, Godot import or Android APK was observed.
**Priority 1 remaining:** run and inspect actual Actions build, fix any generated GLB import/runtime failures, deliver production-quality skinned hero/enemy/boss rigs and polished textures/materials, finish 18 levels and Android device QA.

## 23. Remove double geometry and harden real GLB rendering — 2026-11-21
Changes committed to `main` in one batch:
- **`b6898e9199caabe3d56cfc06c5b166f3576f9186`**: imported regional boss GLBs no longer receive an overlapping generic boss costume, crown or horns; procedural boss fallback remains.
- **`9689796e8dc425ab2a070513231f0d2ce7091ac9`**: imported hero and enemy GLBs no longer receive overlapping static class armor and fallback hero costume. A small HeroIdentity marker/crest remains for roster identity. Fallback costumes remain for missing GLBs.
- **`5d24c3a17445353fbb4fcaebba3f3b8cd01cadf6`**: Godot smoke now checks imported animated limb hierarchy rather than wrongly requiring procedural `Arm_L` and `Leg_L` nodes when GLBs exist.
- **`3faf9fec8f2c9e2e3b7ec9b4588387dc4a591ca6`**: smoke checks imported hero and regional boss physical landmarks.
- **`96c33fb001ab7f852137549847e12e4faa5a5707`**: GLB validator rejects invalid transform lengths/nonfinite values/nonunit static quaternions, cycles, orphans, multi-parent nodes, and unaligned binary views.
- **`536183de98fb5bf5e38926fb538f343278296b0c`**, **`2a0bce4954199450db20d71103abb18e7b9a8db6`**: character and equipment generators now enable backface culling for 24-vertex outward-facing cube meshes, reducing double-sided overdraw.
- **`338bb9d86bb29150cb7047139ab82ce278e22914`**, **`12796e075cfb727db77354d66e9aac96f2e1f285`**, **`1f5a0eae9ee63829968d5e524e4748c274e13753`**: validator decodes real binary vertex/index attributes and checks face winding against normals; validates single-sided PBR materials.
**Verification:** commits confirmed. The tests and generator have **not been executed** in this session; actual Godot import, gameplay smoke and Android build are **not confirmed**. Generated 93 GLBs remain procedural blockouts. The workflow-run lookup currently exposes only PR-triggered runs, while the project builds on push.
**Next:** inspect actual push-triggered Actions status/logs by an available method; fix any CI failures; build proper skinned 3D models, polished VFX, scene environments and on-device QA.

## 24. Full import coverage and terminal death poses — 2026-11-21
This batch committed directly to `main`:
- **`7635596094069681781658d46a45957ab547cbc6`**, **`2253c4330afbd685ee79cd4720c2bd1e48d533d3`**: GLB AnimationPlayer completion callback no longer returns a defeated character to idle after a death clip. Both bare `death` and library-qualified `*/death` clip names are recognized.
- **`a56f04c21dd6277670e7b2ced274df42d46258e4`**: Godot smoke checks all 72 character GLB resources (30 heroes, 6 bosses, 36 region/class enemies) import as `PackedScene`, not just a few samples. The 21 equipment resources are checked in an existing smoke loop.
- **`68a36778491e83eee14f5e801eb7f28270d5637e`**: headless smoke CI timeout increased to 120 seconds to accommodate exhaustive 93-GLB resource import checks.
- **`221e3dd84782f8c42999169edb218eb501b71474`**: captured character's death clip has time to play before the final disappearance, rather than being cut off at 0.5 seconds.
**Verification:** source changes and commits confirmed; Godot and Actions runs not verified. GLB generation/import, Android APK and on-device graphics still require an observed green build.
**Next:** real workflow status and logs, fix any failed imports or tests, true skinned meshes, polished textures and lighting, 18 distinct mission environments, Android performance measurements.

## 25. First real skinned 3D cloth rig — 2026-11-21
This batch is the first step beyond rigid joint-rotated blockouts toward genuine glTF GPU skinning:
- **`257937604c66dd8f482f8ff95b4e6822956e511e`**: all 72 character GLB generators now add a physically modeled mantle mesh with glTF `skins`, two actual skin joints (`CapeShoulder`, `CapeHem`), `JOINTS_0`/normalized `WEIGHTS_0` per vertex, and inverse bind matrices. All six clips animate the hem joint with independent swaying. This is a **real skinned cloth component**, not yet a full humanoid skeleton.
- **`9597333f8ee98ac2a1683b02fc8db68757e36261`**, **`3321f06bb3cbd319229cbf58ce848daa3811ed45`**: validator checks skin structure, bind matrices, mesh attributes, animation channels, actual decoded weights, blended influences and joint indices.
- **`c6264d4faff85cf3555f45d9a7e3a625689850f0`**, **`0d3523fd414b45f798abcd216d62b28637a873ef`**: Godot smoke now checks for an imported `Skeleton3D` with the named cape bones, rather than treating glTF skin joints as ordinary scene nodes.
- **`af315553438d85bc5b814deeb6d38cc90031cbef`**: tapered cape silhouette, shoulder clasps and broader lower hem for more readable deformation.
**Verification:** all commits saved to GitHub; generator, Python validator, Godot skin import, smoke tests and Android APK **not yet observed passing**. The skinned mantle is an experimental first skinning step, not evidence of production-quality full-body rigging.
**Next:** obtain a real passing CI build and validate `Skeleton3D` import; add skinned torso/arms/legs and jointed anatomy; polished character sculpting, material variation, environments and Android QA.

## 26. Animated neck and facial accessories — 2026-11-21
- **`cb6ac44d457f42f7c29fb19ef56d6fd1865d5bd3`**: all 72 characters gain an independent neck/head pivot; eyes, brow, cheek guards, crowns, helmets and relevant boss horns attach to it. Six animation clips include nod/head recoil keyframes.
- **`212d7fdf7975ccf13100faf3945f6fb16874bcba`**: Python validator requires Head pivot, parented face geometry and rotation tracks in all clips.
**Verification:** committed; not run locally or confirmed through Godot Actions. This is articulated rigid head motion, separate from the genuinely skinned two-joint cape. Full-body skeletal deformation still not implemented.
