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
