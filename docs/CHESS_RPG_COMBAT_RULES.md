# Kingdom Chess — Chess-RPG combat contract

Decision confirmed by product owner 2026-11-21: **Chess remains chess.** RPG is layered onto chess rather than replacing chess movement.

## Invariants
- Exactly 8x8 board, six chess classes and orthodox movement vectors and sliding obstruction.
- An attack is legal only along a chess capture vector. Attacking an occupied enemy square deals RPG damage; if the defender survives, the attacker remains on its source square. On lethal damage, the attacker may occupy the captured square, with poison/status and animations following the unit.
- King survival is the strategic win condition. Campaign bosses can be special king-class opponents; victory and loss must not depend only on arbitrary HP pools.
- A chess check is a **threat state**, not an instant kill. The game must define how a defended king responds to a damaging attack; avoid claiming standard chess checkmate until the king-threat resolution system is implemented and tested.
- Knight leaps; bishops stay diagonal; rooks stay orthogonal; queens combine rook+bishop; kings move one square; pawns advance forward and attack diagonally. Castling, en passant, promotion, checks and pins require explicit decisions and automated tests before declaring chess rules complete.
- RPG skills can shield, heal, buff, debuff, or attack, but must not silently grant non-chess movement. Any exceptional mobility must be clearly labeled as a special skill and balanced.
- Every hero has persistent identity, HP, attack, defense, class abilities, cooldowns, and progression gates. Stronger units must be earned gradually.
- Competitive chess PvP should normalize progression advantages and never match fresh accounts against fully geared endgame accounts without protection.

## Current code audit (2026-11-21)
- scripts/main.gd::_legal() checks standard movement patterns and blockers, but does not implement check, pinned pieces, castling, en passant or promotion.
- scripts/main.gd::_apply_curse() applies damage on chess-reachable enemies; health can prevent a capture.
- scripts/main.gd::_raid_victory() currently triggers on boss defeat rather than checkmate.
- Current two-AP turn structure is an RPG variant, **not orthodox alternating one-move chess**. Preserve only as an explicit design variant and test king-safety implications.

## Implementation order
1. Extract pure, deterministic chess movement/threat logic from scene UI; add tests for king threat, pins, castling, en passant, promotion and king-safety exceptions in damage-based combat.
2. Specify and implement attack-versus-move semantics with HP, capture on lethal damage and occupancy preservation on nonlethal hits.
3. Add visible check/threat indicators and unambiguous victory/defeat conditions; prevent abilities from bypassing chess geometry unless explicitly documented.
4. Add class skills and unique hero passives, then test tactical balance at starter, midgame and endgame progression levels.
5. Integrate objectives, boss phases, 3D animation, LAN sync, saves and Android UI; verify CI and device playtests.

This is a gameplay design contract, not evidence these rules have already been implemented.
