# Session State — Dominion of Ages

**Last updated**: 2026-06-15
**Current task**: Prototype playtest — awaiting user verdict
**Stage**: Concept Prototype (pre-design)

> **PROJECT PIVOT** — Kaster's War superseded. New concept: **Dominion of Ages**.
> Old Kaster's War session state archived below in "Prior Project" section.

---

<!-- STATUS -->
Epic: Dominion of Ages — Concept Prototype
Feature: Council Stacking
Task: Playtest prototype.html — awaiting user verdict
<!-- /STATUS -->

## Current Task: `/prototype council-stacking`

**Hypothesis:** "If the player slots a leader and sees stats animate, they'll feel Brotato-style satisfaction — confirmed if ≥3 voluntary swaps in 5 min."

**Phase:** 6 — Playtest Debrief (user opens and plays `prototype.html`, then reports back)

**Prototype path:** `prototypes/council-stacking-concept/prototype.html` (HTML, open by double-click)

### Prototype Features
- 4 category slots (Military / Economy / Diplomacy / Science) + 1 Supreme Leader slot
- 12 leaders with ranks S/A/B, flat+% bonuses, conditional scaling synergies
- Animated stat deltas — green tick-up / red tick-down per swap
- Supreme Leader: exclusive skill text + downside debuff shown
- Auto-battle test using Military stat vs escalating enemies (4 tiers)
- Click-to-place + drag-and-drop from roster

---

## New Project: Dominion of Ages

- **Concept doc**: `design/gdd/game-concept.md` ✅
- **Pillars locked**: Every Choice Tops Up / Dream Team Across Time / Many Roads to Glory / Strategy Not Micro
- **Core mechanic**: Council of historical leaders (5 lanes: Military/Economy/Diplomacy/Science/Civilian) — Brotato-style stacking stats + Supreme Leader capstone
- **Engine**: Godot 4.6 (unchanged)

### Next Steps (after prototype verdict)
1. User plays `prototypes/council-stacking-concept/prototype.html` → reports PROCEED / PIVOT / KILL
2. Write `prototypes/council-stacking-concept/REPORT.md`
3. Archive old Kaster's War GDDs → `design/gdd/archive/`
4. If PROCEED → `/art-bible` → `/map-systems` → `/design-system` per system

---

## Prior Project: Kaster's War (SUPERSEDED)

Kaster's War tactical battle build — 171/171 tests passing, playable via F5 in Godot.
GDDs in `design/gdd/` are superseded by Dominion of Ages pivot.
Source code in `src/` is Kaster's War code — will be replaced or repurposed.

Key files:
- `src/gameplay/battle/battle_controller.gd` — main battle loop
- `src/ui/battle/tactical_hud.gd` — HUD
- `scenes/battle/Battle.tscn` — main scene
- `tests/` — 171 passing GUT tests (headless runner)
