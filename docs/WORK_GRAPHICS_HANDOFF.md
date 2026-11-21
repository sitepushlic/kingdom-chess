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
