# Session State — Kaster's War

**Last updated**: 2026-06-12
**Current task**: Godot 4.6 implementation of the 3 designed systems — complete, all tests passing
**Stage**: Systems Design (3/35 GDDs) + Early Implementation (3 systems coded & tested)

---

## Progress

- [x] Art Bible complete — `design/art/art-bible.md` (9/9 sections)
- [x] Engine configured — Godot 4.6, GDScript, Forward+, Jolt
- [x] Systems index created — `design/gdd/systems-index.md` (35 systems)
- [x] Officer Stats GDD complete — `design/gdd/officer-stats.md`
- [x] Terrain GDD complete — `design/gdd/terrain-system.md`
- [x] Combat Resolution GDD complete — `design/gdd/combat-resolution.md`
- [x] **Godot project scaffolded** — `project.godot` (Godot 4.6, Forward+, Jolt)
- [x] **Officer Stats implemented** — `src/gameplay/officers/` (officer.gd, officer_registry.gd)
- [x] **Terrain implemented** — `src/gameplay/terrain/` (terrain_system.gd, terrain_tile.gd)
- [x] **Combat Resolution implemented** — `src/gameplay/combat/` (squad.gd, combat_resolver.gd)
- [x] **Headless test suite** — 61/61 passing (Godot 4.6.3, exit code 0)

---

## How to Run Tests

```bash
# One-time after clone (builds global class cache):
"/Users/ek/Downloads/Godot.app/Contents/MacOS/Godot" --headless --path . --import

# Run the suite (exit 0 = pass, 1 = fail):
"/Users/ek/Downloads/Godot.app/Contents/MacOS/Godot" --headless --path . --script tests/headless_runner.gd
```

Test runner is addon-free (`tests/headless_runner.gd` + `tests/helpers/test_case.gd`).
Technical preferences name GUT as the framework — migration is possible later;
test files follow `[system]_[feature]_test.gd` / `test_[scenario]_[expected]` naming.

---

## Files Created This Session

- `project.godot` — Godot 4.6 project (Forward+, Jolt)
- `assets/data/officers.json` — 7 named officers + 4 archetypes (data-driven)
- `assets/data/terrain.json` — 8 terrain types, season multipliers, combat mods
- `assets/data/combat.json` — combat constants + unit types (max_hp = placeholder)
- `src/core/config_loader.gd` — JSON config loader (DI-friendly)
- `src/gameplay/officers/officer.gd` — 5-stat block, read-only contract, clamping
- `src/gameplay/officers/officer_registry.gd` — init, generic recruits, act growth, battle deferral
- `src/gameplay/terrain/terrain_system.gd` — movement cost, combat mods, flammability, vision
- `src/gameplay/terrain/terrain_tile.gd` — per-hex state (charred, ford crossing)
- `src/gameplay/combat/squad.gd` — HP pool, unit type, morale placeholder
- `src/gameplay/combat/combat_resolver.gd` — deterministic 4-formula damage pipeline
- `tests/headless_runner.gd`, `tests/helpers/test_case.gd`, `tests/helpers/fixtures.gd`
- `tests/unit/officers/` (3 files), `tests/unit/terrain/` (2 files), `tests/unit/combat/` (2 files)

**Not committed** — awaiting user instruction per collaboration protocol.

---

## Implementation Notes / Deviations

1. **GDD interface `officer.int()`** → implemented as `officer.intel()` (`int` is reserved in GDScript). Documented in doc comment.
2. **Wet ×1.5 movement multiplier** applies only to types the GDD table marks seasonal (Road/Village = "No change"); cost = `ceil(base × mult)` → Ford 3 AP / Bridge 2 AP in Wet, matching GDD river rules.
3. **Ranged terrain mods stack additively** (attacker hill +0.25, defender cover −0.25/−0.15) staying in the GDD's [0.75, 1.25] range. Hill-vs-village = 1.10.
4. **Squad max_hp values are placeholders** (no Squad/Unit GDD yet) — flagged in combat.json.
5. **Morale is a 2-state placeholder enum** (NORMAL/BROKEN) until Morale System GDD (design #4).
6. Range/line-of-sight validation deferred to Hex Movement & Facing/Flank systems (design #5–6).

---

## Known Gaps (process)

- No ADRs yet for the 3 implemented systems (coding standards require ADRs in `docs/architecture/`) — `/architecture-decision` or `/create-architecture` pending
- No CI workflow (`.github/workflows/`) — `/test-setup` can scaffold
- GUT framework named in technical-preferences; current runner is custom/addon-free

---

## Open Questions (from GDD Appendix B)

1. Fire Plan outcome: GDD assumes success — confirm with novel canon
2. Zhuge Jian join timing: Act II (treatise) → Act III (physical) — confirm
3. Mission 8 duel: allow loss without game-over?
4. Post-unification island name: Kasteria or Kastera?
5. Loyalty system depth: single value per city sufficient?

---

## Next Steps

1. Design Morale System (design order #4): `/design-system morale-system` — combat already exposes the seam (`Squad.MoraleState`, `morale_mod`)
2. Backfill ADRs for the 3 implemented systems
3. Continue MVP GDDs: Facing & Flank, Hex Movement, Fog of War…
