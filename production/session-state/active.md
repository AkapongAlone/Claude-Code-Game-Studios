# Session State — Kaster's War

**Last updated**: 2026-06-12
**Current task**: Save/Load GDD complete — all 14 MVP GDDs designed ✅
**Stage**: Systems Design (14/35 GDDs designed, 3 approved) + Early Implementation (3 systems coded & tested)

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

1. ~~Design Morale System (design order #4)~~ ✅ DONE — `design/gdd/morale-system.md`
   - Requires: update `combat_resolver.gd` to add SHAKEN (morale_mod = 0.75)
   - Requires: expand `MoraleState` enum in `squad.gd` (STEADY/SHAKEN/BROKEN)
2. ~~Design Facing & Flank System (design order #5)~~ ✅ DONE — `design/gdd/facing-and-flank.md`
3. ~~Design Hex Movement System (design order #6)~~ ✅ DONE — `design/gdd/hex-movement.md`
4. ~~Design Fog of War / Vision System (design order #7)~~ ✅ DONE — `design/gdd/fog-of-war.md`
5. ~~Design Victory/Defeat Conditions System (design order #8)~~ ✅ DONE — `design/gdd/victory-defeat-conditions.md`
6. ~~Design Duel System (design order #9, ⚠️ HIGH RISK)~~ ✅ DONE — `design/gdd/duel-system.md`
7. ~~Design Officer Passive Ability System (design order #10, ⚠️ HIGH RISK)~~ ✅ DONE — `design/gdd/officer-passive-ability.md`
8. ~~Design Duel UI (design order #12)~~ ✅ DONE — `design/gdd/duel-ui.md`
9. ~~Design Portrait & Character Display System (design order #13)~~ ✅ DONE — `design/gdd/portrait-display.md`
10. ~~Design Tactical HUD (design order #11)~~ ✅ DONE — `design/gdd/tactical-hud.md`
11. ~~Design Save/Load System (design order #14)~~ ✅ DONE — `design/gdd/save-load.md`
    - 2 save scopes: Campaign (3 manual + 1 auto) and Tactical (1 slot, turn-start auto)
    - Modular manifest contract: each system implements serialize()/deserialize()
    - Provisional: campaign layer state (Resource, Settlement, Intel, etc. not yet designed)
    - Mid-duel save blocked; tactical save only in MOVEMENT/COMBAT phase
    - 4 formulas: checksum, migration rule, file path, playtime accumulator
    - 14 edge cases; 21 acceptance criteria
    - Resolves Hex Movement GDD open question #1: flat-top hex orientation
    - Resolves Fog of War GDD open question #3: partial visibility during AI turn only
    - CanvasLayer: TacticalHUDLayer = 5; Duel UI = 10; battle-end = 15; pause/menu = 20
    - Registry updated: staleness_threshold + route_fraction referenced_by
   - Three rendering tiers: Full Panel / Compact Bar / Miniature Icon
   - Four display contexts: CAMPAIGN / TACTICAL / DIPLOMATIC / RECRUITMENT
   - Heirloom Blade constraint enforced upstream in get_display_passives() — renderer is unaware
   - 4 display formulas: stat_bar_fill, stat_bar_color, growth_visible, thumbnail_crop
   - 14 edge cases; 29 acceptance criteria
   - Campaign State interface provisional (unavailable_turns, current_assignment)
   - Registry: no new entries; all 7 named officers already registered
   - 6 display formulas: resolve_fill_fraction, stamina pips, yield_button_visible, stance_available, bar_color_zone, damage_label
   - 44 acceptance criteria
   - Full component inventory: DuelOverlayLayer → DuelFrame → Opponent/PlayerPanel → ActionBar → YieldButton
   - 6-phase screen lifecycle: INIT → SELECTING → RESOLVING → READ_HINT → YIELD_AVAILABLE → END
   - Push-driven interface: Duel System calls DuelUI methods; UI never polls
   - Open questions: private stance commit visibility, scripted deliberation time, flavor text authorship, sig move tooltip, Mission 6 resolve color subversion
   - Registry updated: 5 formula/constant referenced_by entries updated (duel_resolve, duel_stamina, duel_attack_damage, duel_read_accuracy, duel_yield_threshold)
   - 9 named passives (Kaster×2, Alexsen, Thane×2, Zhuge Jian, Jin Tao, Bon, Sander)
   - Heirloom Blade: hidden passive, 5% proc, NO UI disclosure (P3 ambiguity)
   - Systems designer corrections: F-1 use bracket table (Kaster=4hex); F-3 proc 3%→5%; F-4 Vital Strike −15→−10, process through cascade
   - 44 acceptance criteria (QA Lead reviewed)
   - Registry updated: 5 new constants
   - Formulas: duel_resolve = floor(CHR/2)+40, duel_stamina = floor(INT/10)+5, attack_damage = floor(WAR/10)+5
   - Systems designer correction: offset raised +30→+40 (Thane fragility fix)
   - 3-way RPS, Stamina budget, Read mechanic (WAR-based, 70%), Signature Move hook interface
   - 3 contexts: field challenge / scripted (with intentional_miss) / diplomatic
   - 40 acceptance criteria (QA Lead reviewed)
   - Entity registry updated: 3 formulas + 5 constants
7. Run `/design-review design/gdd/morale-system.md` in a fresh session (independent review)
6. Run `/design-review design/gdd/facing-and-flank.md` in a fresh session (independent review)
7. Run `/design-review design/gdd/hex-movement.md` in a fresh session (independent review)
8. Run `/design-review design/gdd/fog-of-war.md` in a fresh session (independent review)
9. Backfill ADRs for the 3 implemented systems
10. Continue MVP GDDs: Officer Passive Ability System (#10, ⚠️ HIGH RISK — 7 named passives, Heirloom Blade edge case)…
    NOTE: Terrain GDD Dependencies section needs backfill — add Hex Movement and Fog of War as downstream consumers
    NOTE: Duel System GDD open question #1 (simultaneous tie scripted fallback) needs narrative director input before Duel System impl.
