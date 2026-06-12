# Session State — Kaster's War

**Last updated**: 2026-06-12
**Current task**: Playable MVP battle build — complete, 171/171 tests passing
**Stage**: MVP Implementation (12/14 MVP systems coded; playable in Godot via F5)

---

## Progress

- [x] All 14 MVP GDDs designed (see PROJECT-SUMMARY.md)
- [x] Officer Stats / Terrain / Combat Resolution implemented + tested (previous session)
- [x] **Morale System** — `src/gameplay/morale/morale_system.gd` (4 triggers, aura, 2-pass cascade, recovery)
- [x] **Facing & Flank** — `src/gameplay/combat/facing_system.gd` (arc check, forest ambush)
- [x] **Hex Movement** — `src/core/cube_hex.gd`, `src/gameplay/battle/battle_grid.gd`, `src/gameplay/movement/movement_rules.gd` (AP pool, Dijkstra, A*, LOS, routing)
- [x] **Fog of War** — `src/gameplay/fog/fog_of_war.gd` (3 states, ghosts, staleness, Stratagem hook)
- [x] **Victory/Defeat** — `src/gameplay/victory/victory_checker.gd` (4-tier eval order, route fraction, objectives)
- [x] **Duel System** — `src/gameplay/duel/duel_engine.gd` (RPS, stamina, Read, Crushing Blow, yield)
- [x] **Officer Passives** — `src/gameplay/officers/passive_registry.gd` (Juggernaut, Old Guard, Shadow Work, Vital Strike, Stratagem, Heirloom Blade-hidden)
- [x] **Battle Controller** — `src/gameplay/battle/battle_controller.gd` (turn loop, placeholder enemy AI, routing phase)
- [x] **Tactical HUD (functional)** — `src/ui/battle/tactical_hud.gd` (CanvasLayer 5)
- [x] **Duel UI (functional)** — `src/ui/duel/duel_overlay.gd` (CanvasLayer 10, Q/W/E/R/Y keys)
- [x] **Playable scene** — `scenes/battle/Battle.tscn` = main scene; demo battle `assets/data/battles/open_field_demo.json`
- [x] **Test suite: 171/171 passing** (Godot 4.6.3 headless)
- [ ] Save/Load (designed, NOT implemented — not required to play)
- [ ] Portrait Display (designed, NOT implemented — tokens show officer initials)

---

## How to Play

Open the project in Godot 4.6 → press **F5**.

- Click a blue squad to select; click a highlighted hex to move
- Click a visible enemy in range to attack (ranged needs LOS, no adjacent shots)
- **D** = challenge an adjacent enemy officer to a duel (Q/W/E stances, R = Crushing Blow for Alexsen, Y = yield)
- **Enter** = end turn · **Esc** = deselect
- Win: break ≥50% of enemy squads · Lose: ≥50% of yours break, Kaster's squad is eliminated, or 20 turns expire

## How to Run Tests

```bash
"/Users/ek/Downloads/Godot.app/Contents/MacOS/Godot" --headless --path . --import     # once
"/Users/ek/Downloads/Godot.app/Contents/MacOS/Godot" --headless --path . --script tests/headless_runner.gd
```

---

## Implementation Notes / Deviations (this session)

1. **Enemy AI is a placeholder** — Tactical AI is Alpha-tier (#23, no GDD). AI advances toward nearest player squad and attacks when legal. Marked in battle_controller.gd.
2. **HUD / Duel UI are functional MVP versions** — no portraits, flank-arc overlay, path preview, or aura rings yet. Full specs live in tactical-hud.md / duel-ui.md / portrait-display.md.
3. **Save/Load skipped** — designed but not needed to make the battle playable.
4. **Campaign-scope passives inactive** — Read the Field (Inspect action), Treatises, Quartermaster register flags but have no consumers yet.
5. **Mutual resolve depletion = DRAW** per duel AC-25 (Core Rules tiebreak text conflicts; ACs chosen as authoritative).
6. **Heirloom Blade ceiling bypasses the 90 damage cap** per passive AC-12 (91 expected) — flagged as GDD-internal conflict with combat Formula 3.
7. **Field duels**: enemy always accepts (refuse penalty config exists, unused); enemy duel stances are weighted-random.
8. **Enum collision fix**: `Squad.side` annotation must be qualified (`Squad.Side`) — bare `Side` collides with Godot's @GlobalScope Side enum.
9. Wet-season Road/Village exemption, additive ranged terrain mods, `officer.intel()` naming — carried over from previous session.

---

## Known Gaps (process)

- No ADRs for any implemented system — backfill via `/architecture-decision`
- 11 GDDs still pending `/design-review`
- No CI workflow — `/test-setup`
- GUT named in tech prefs; custom addon-free runner in use
- Demo battle is a single authored map; no campaign layer

---

## Next Steps

1. Playtest the demo battle (F5) — tune morale pressure & AI aggression from feel
2. Implement Save/Load (`src/core/save/`) — last MVP system
3. Portrait Display + HUD/Duel UI polish passes per their GDDs
4. Backfill ADRs; run `/design-review` on the 11 pending GDDs; `/gate-check pre-production`
