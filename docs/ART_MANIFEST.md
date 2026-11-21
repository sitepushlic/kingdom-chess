# KINGDOM CHESS — 30-HERO VISUAL MANIFEST

Generated from `scripts/hero_roster.gd` (canonical roster) on 2026-11-21. The costume silhouettes listed here are **existing procedural runtime geometry**, not completed authored GLB art. Names and quest gates are canonical; art directions are implementation proposals. Each row needs a final rigged 3D model, UV/PBR materials, clips idle/move/attack/hit/death/cast, and Android visual verification.

| ID | Герой | Титул | Класс | Редкость | Текущий 3D-силуэт | Головной знак | Условие открытия |
|---|---|---|---|---:|---|---|---|
| hero_01 |  |  |  | 0 | королевский плащ, широкие наплечники | низкая гербовая корона |  |
| hero_02 |  |  |  | 0 | асимметричная броня налётчика, зубчатые фалды | низкая гербовая корона |  |
| hero_03 |  |  |  | 0 | капюшон следопыта, колчан, дорожный плащ | низкая гербовая корона |  |
| hero_04 |  |  |  | 0 | тяжёлый нагрудник кузнеца, наколенники | низкая гербовая корона |  |
| hero_05 |  |  |  | 0 | мантия мага, высокий воротник, парящий фокус | низкая гербовая корона |  |
| hero_06 |  |  |  | 0 | королевский плащ, широкие наплечники | парные рога |  |
| hero_07 |  |  |  | 0 | асимметричная броня налётчика, зубчатые фалды | парные рога |  |
| hero_08 |  |  |  | 0 | капюшон следопыта, колчан, дорожный плащ | парные рога |  |
| hero_09 |  |  |  | 0 | тяжёлый нагрудник кузнеца, наколенники | парные рога |  |
| hero_10 |  |  |  | 0 | мантия мага, высокий воротник, парящий фокус | парные рога |  |
| hero_11 |  |  |  | 0 | королевский плащ, широкие наплечники | высокий конусный шлем |  |
| hero_12 |  |  |  | 0 | асимметричная броня налётчика, зубчатые фалды | высокий конусный шлем |  |
| hero_13 |  |  |  | 0 | капюшон следопыта, колчан, дорожный плащ | высокий конусный шлем |  |
| hero_14 |  |  |  | 0 | тяжёлый нагрудник кузнеца, наколенники | высокий конусный шлем |  |
| hero_15 |  |  |  | 0 | мантия мага, высокий воротник, парящий фокус | высокий конусный шлем |  |
| hero_16 |  |  |  | 0 | королевский плащ, широкие наплечники | тройной зубчатый гребень |  |
| hero_17 |  |  |  | 0 | асимметричная броня налётчика, зубчатые фалды | тройной зубчатый гребень |  |
| hero_18 |  |  |  | 0 | капюшон следопыта, колчан, дорожный плащ | тройной зубчатый гребень |  |
| hero_19 |  |  |  | 0 | тяжёлый нагрудник кузнеца, наколенники | тройной зубчатый гребень |  |
| hero_20 |  |  |  | 0 | мантия мага, высокий воротник, парящий фокус | тройной зубчатый гребень |  |
| hero_21 |  |  |  | 0 | королевский плащ, широкие наплечники | ореол с камнем |  |
| hero_22 |  |  |  | 0 | асимметричная броня налётчика, зубчатые фалды | ореол с камнем |  |
| hero_23 |  |  |  | 0 | капюшон следопыта, колчан, дорожный плащ | ореол с камнем |  |
| hero_24 |  |  |  | 0 | тяжёлый нагрудник кузнеца, наколенники | ореол с камнем |  |
| hero_25 |  |  |  | 0 | мантия мага, высокий воротник, парящий фокус | ореол с камнем |  |
| hero_26 |  |  |  | 0 | королевский плащ, широкие наплечники | маска с центральным шпилем |  |
| hero_27 |  |  |  | 0 | асимметричная броня налётчика, зубчатые фалды | маска с центральным шпилем |  |
| hero_28 |  |  |  | 0 | капюшон следопыта, колчан, дорожный плащ | маска с центральным шпилем |  |
| hero_29 |  |  |  | 0 | тяжёлый нагрудник кузнеца, наколенники | маска с центральным шпилем |  |
| hero_30 |  |  |  | 0 | мантия мага, высокий воротник, парящий фокус | маска с центральным шпилем |  |

## Final asset paths and checks

Target: `res://assets/characters/hero_01.glb` through `hero_30.glb`, with individually recognizable geometry and animation clips. A class-only mesh or color variant is insufficient. Enemy and boss assets must be mapped by enemy identity/region. Verify rig scale, pivot, material import, 720x1280 portrait legibility, 3 equipment attachment sockets and all 6 clips. No model from this table is verified as authored GLB.

## Remaining graphics acceptance

- [ ] 30 original hero GLBs + source Blender files
- [ ] All 30 animated and connected by hero ID
- [ ] Enemy minions and six authored region bosses
- [ ] 21 modular authored gear meshes + seven physical tier looks
- [ ] Six polished region environments with 18 mission variants
- [ ] VFX integration, death/victory and mobile quality tuning
- [ ] Godot 4.3 import + smoke tests + CI Android APK
- [ ] Visual QA and actual Android device performance measurements
