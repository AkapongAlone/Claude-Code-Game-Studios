# Kaster's War — Project Summary

**Updated**: 2026-06-12
**Stage**: Systems Design (14/35 GDDs) + Early Implementation (3 systems coded, 61 tests passing)
**MVP Progress**: 14/14 MVP systems designed · 3/14 implemented

---

## Game Identity

| Field | Value |
|---|---|
| **Title** | Kaster's War: The Unification War |
| **Genre** | Turn-based Grand Strategy + Tactics (Napoleonic era) |
| **Engine** | Godot 4.6 / GDScript / Forward+ / Jolt |
| **Platform** | PC (Steam) |
| **Team size** | Indie 1–5 |
| **Elevator pitch** | RoTK × XCOM in the Napoleonic era — lead legend-tier officers, use intel to flip battles you're losing, settle it with a duel |

**Design Pillars:**
- **P1 — Victory Through Preparation**: Intel and planning are the real resources
- **P2 — Officers Are the Story**: Every officer must feel mechanically distinct, not just stat-different
- **P3 — Grounded, Barely Fantastic**: Powder, supplies, seasons, morale — all follow real-world logic; the one supernatural element is deliberately ambiguous
- **P4 — Authored Peaks, Player Valleys**: Story setpieces deliver full emotional beats; player choices in between flow into and change those peaks

---

## Design Documents

### Foundation

| Document | Status | Location |
|---|---|---|
| Game Concept (main GDD) | ✅ Complete | `design/gdd/kasters-war-gdd.md` |
| Art Bible | ✅ Complete (9/9 sections) | `design/art/art-bible.md` |
| Systems Index (35 systems) | ✅ Complete | `design/gdd/systems-index.md` |
| **Officer Stats System** | ✅ Approved | `design/gdd/officer-stats.md` |
| **Terrain System** | ✅ Approved | `design/gdd/terrain-system.md` |
| **Combat Resolution System** | ✅ Approved | `design/gdd/combat-resolution.md` |

### MVP Systems (14/14 designed)

| System | Status | Location |
|---|---|---|
| **Morale System** | 🟡 Designed (pending review) | `design/gdd/morale-system.md` |
| **Facing & Flank System** | 🟡 Designed (pending review) | `design/gdd/facing-and-flank.md` |
| **Hex Movement System** | 🟡 Designed (pending review) | `design/gdd/hex-movement.md` |
| **Fog of War / Vision System** | 🟡 Designed (pending review) | `design/gdd/fog-of-war.md` |
| **Victory/Defeat Conditions** | 🟡 Designed (pending review) | `design/gdd/victory-defeat-conditions.md` |
| **Duel System** ⚠️ | 🟡 Designed (pending review) | `design/gdd/duel-system.md` |
| **Officer Passive Ability** ⚠️ | 🟡 Designed (pending review) | `design/gdd/officer-passive-ability.md` |
| **Duel UI** | 🟡 Designed (pending review) | `design/gdd/duel-ui.md` |
| **Portrait & Character Display** | 🟡 Designed (pending review) | `design/gdd/portrait-display.md` |
| **Tactical HUD** | 🟡 Designed (pending review) | `design/gdd/tactical-hud.md` |
| **Save/Load System** | 🟡 Designed (pending review) | `design/gdd/save-load.md` |

---

## Implementation Status

| System | Code | Tests | Notes |
|---|---|---|---|
| Officer Stats | ✅ `src/gameplay/officers/` | ✅ passing | `officer.intel()` (not `.int()` — reserved word) |
| Terrain | ✅ `src/gameplay/terrain/` | ✅ passing | Seasonal multipliers, combat mods, flammability |
| Combat Resolution | ✅ `src/gameplay/combat/` | ✅ passing | Deterministic 4-formula pipeline |
| Morale System | ⬜ Not started | — | GDD done; MoraleState enum needs expansion in squad.gd |
| Facing & Flank | ⬜ Not started | — | GDD done |
| Hex Movement | ⬜ Not started | — | GDD done; flat-top hex orientation confirmed |
| Fog of War | ⬜ Not started | — | GDD done |
| Victory/Defeat | ⬜ Not started | — | GDD done |
| Duel System | ⬜ Not started | — | GDD done |
| Officer Passive | ⬜ Not started | — | GDD done; 9 named passives (Heirloom Blade hidden) |
| Duel UI | ⬜ Not started | — | GDD done |
| Portrait & Character Display | ⬜ Not started | — | GDD done; 3 rendering tiers, 4 display contexts |
| Tactical HUD | ⬜ Not started | — | GDD done; 7 HUD modes, push/pull hybrid interface |
| Save/Load | ⬜ Not started | — | GDD done; campaign + tactical scopes |

**Test suite**: 61/61 passing · Godot 4.6.3 headless · custom runner (no GUT addon yet)

**Run tests:**
```bash
# One-time import:
"/Users/ek/Downloads/Godot.app/Contents/MacOS/Godot" --headless --path . --import

# Run suite:
"/Users/ek/Downloads/Godot.app/Contents/MacOS/Godot" --headless --path . --script tests/headless_runner.gd
```

**Pending code changes from GDDs:**

| Change | Source GDD | Priority |
|---|---|---|
| `squad.gd`: expand `MoraleState { NORMAL, BROKEN }` → `{ STEADY, SHAKEN, BROKEN }` | Morale | Blocking for Morale impl |
| `combat_resolver.gd`: add SHAKEN → `morale_mod = 0.75` | Morale | Blocking for Morale impl |
| New: `assets/data/morale.json` | Morale | Blocking for Morale impl |
| New: `assets/data/duel_config.json` | Duel System | Before Duel impl |
| New: `assets/data/passive_config.json` | Officer Passive | Before Passive impl |
| New: `assets/data/duel_ui_config.json` | Duel UI | Before Duel UI impl |
| New: `assets/data/portrait_config.json` | Portrait Display | Before Portrait impl |
| New: `assets/data/tactical_hud_config.json` | Tactical HUD | Before HUD impl |
| New: `assets/data/save_config.json` | Save/Load | Before Save/Load impl |

---

## Named Officers (locked stats)

| Officer | WAR | LDR | INT | POL | CHR | Duel Resolve | Duel Stamina | Attack Dmg | Signature Passive |
|---|---|---|---|---|---|---|---|---|---|
| Kaster | 82 | 96 | 92 | 85 | 88 | 84 | 14 | 13 | Read the Field + Heirloom Blade (hidden) |
| Bon shi hai | 55 | 78 | 94 | 80 | 62 | 71 | 14 | 10 | Stratagem |
| Alexsen | 98 | 85 | 40 | 25 | 75 | 77 | 9 | 14 | Juggernaut (morale immune) + Crushing Blow |
| Thane | 90 | 50 | 75 | 30 | 45 | 62 | 12 | 14 | Shadow Work + Vital Strike |
| Zhuge Jian | 30 | 70 | 99 | 90 | 80 | 80 | 14 | 8 | The Treatises (+1 Prep Phase slot) |
| Jin Tao | 45 | 60 | 88 | 95 | 50 | 65 | 13 | 9 | Quartermaster |
| Sander | 75 | 88 | 65 | 55 | 70 | 75 | 11 | 12 | Old Guard (flank morale immunity aura) |

> **Security constraint**: Heirloom Blade must never appear in any player-facing UI. Internal ID `"heirloom_blade"` is filtered upstream in `officer.get_display_passives()` (`is_player_visible: false`). The rendering layer is unaware of its existence.

---

## Core Formula Reference

### Combat (Combat Resolution GDD)

```
# Ranged
base = unit_base × (1 + WAR / 100)
# Melee
base = unit_base × (1 + WAR / 200)
# Final
damage = base × terrain_mod × flank_mod × morale_mod
# Defense
effective = damage × (1 − min(LDR × 0.5 × terrain_mod / 100, 0.9))
```

| Constant | Value |
|---|---|
| Flank bonus | +30% |
| BROKEN morale_mod | 0.5 (−50%) |
| SHAKEN morale_mod | 0.75 (−25%) |
| Defense cap | 90% max |
| Hill bonus (ranged) | +25% |
| Forest penalty (ranged) | −25% |

### Morale (Morale System GDD)

```
# States:  STEADY (≥30) · SHAKEN (10–29) · BROKEN (<10)
# Damage triggers per turn:
morale_damage = floor(hp_lost_pct × 50)   # casualties
              + 10                          # if flanked
              + 30                          # if officer lost
              + witnessed_routs × 10       # within 2 hex

# Aura protection (if in LDR aura):
final_damage = floor(morale_damage × 0.75)

# Recovery (end of turn, only if zero damage taken this turn):
recovery = floor(CHR / 25)
```

| Constant | Value |
|---|---|
| Casualty sensitivity | 50 |
| Flank morale penalty | 10 (flat) |
| Officer loss penalty | 30 (flat) |
| Witnessing penalty | 10 per routing squad |
| Aura protection | 25% reduction |
| Cascade pass limit | 2 per turn |
| Officer-led start | 100 morale |
| Officer-less start | 70 morale |
| Campaign recovery | 50% of HP at time of rout |

**Aura radius from LDR:**

| LDR | Aura radius |
|---|---|
| < 50 | 1 hex |
| 50–74 | 2 hexes |
| 75–89 | 3 hexes |
| ≥ 90 | 4 hexes |

### Movement (Hex Movement GDD)

```
ap_pool = min(base_ap[unit_type] + floor((ldr - 1) / 34), max_ap[unit_type])
```

| Unit | Base AP | Max AP |
|---|---|---|
| INF | 3 | 5 |
| LI | 4 | 6 |
| CAV | 5 | 7 |
| ART | 2 | 4 |

LDR AP bonus breakpoints: LDR 1–34 = +0, 35–67 = +1, 68–100 = +2

**Hex orientation**: Flat-top (flat edges top/bottom, vertices left/right). East = direction 0. Directions clockwise.

### Victory/Defeat (Victory/Defeat Conditions GDD)

```
route_fraction = (broken_on_map + routed_off_map + dead_squads) / starting_squads
```

| Constant | Value |
|---|---|
| Route victory threshold | 0.50 (enemy route_fraction ≥ 0.50) |
| Route defeat threshold | 0.50 (player route_fraction ≥ 0.50) |
| Default max turns | 20 |

Victory check order each turn: Hard defeats → Victory conditions → Soft defeat → Turn limit

### Duel System (Duel System GDD)

```
duel_resolve     = floor(CHR / 2) + 40     # range [40, 90]
duel_stamina     = floor(INT / 10) + 5     # range [5, 15]
attack_damage    = floor(WAR / 10) + 5     # range [5, 15]

counter_damage   = ceil(attack_damage × 0.40)   # Defend wins
feint_break      = ceil(attack_damage × 0.60)   # Feint wins
tie_damage       = floor(attack_damage × 0.50)  # Attack ties
```

**Stance RPS**: Attack beats Feint · Feint beats Defend · Defend beats Attack

**Stamina costs**: Attack = 2 · Defend = 1 · Feint = 1 · Crushing Blow = 4

**Exhaustion** (Stamina = 0): Defend only

**Read mechanic**: fires turns 3, 6, 9... for higher-WAR participant · 70% accurate hint

| Constant | Value |
|---|---|
| Read accuracy | 0.70 |
| Yield threshold | 0.30 (opponent resolve ≤ 30% of max) |
| Field duel loser morale | −25 |
| Field duel winner morale | +15 |
| Refuse challenge penalty | −15 (to refusing squad) |

---

## MVP Roadmap (14 systems — all designed ✅)

| # | System | Design | Code | Notes |
|---|---|---|---|---|
| 1 | Officer Stats | ✅ | ✅ | — |
| 2 | Terrain | ✅ | ✅ | — |
| 3 | Combat Resolution | ✅ | ✅ | — |
| 4 | **Morale System** | ✅ | ⬜ | Blocking: needs squad.gd enum expansion |
| 5 | **Facing & Flank** | ✅ | ⬜ | — |
| 6 | **Hex Movement** | ✅ | ⬜ | Flat-top hex orientation confirmed |
| 7 | **Fog of War** | ✅ | ⬜ | — |
| 8 | **Victory/Defeat** | ✅ | ⬜ | — |
| 9 | **Duel System** ⚠️ | ✅ | ⬜ | Open Q: scripted tie fallback (narrative director) |
| 10 | **Officer Passive** ⚠️ | ✅ | ⬜ | Heirloom Blade: never expose in UI |
| 11 | **Tactical HUD** | ✅ | ⬜ | CanvasLayer 5; push/pull hybrid |
| 12 | **Duel UI** | ✅ | ⬜ | CanvasLayer 10; push-driven |
| 13 | **Portrait Display** | ✅ | ⬜ | 3 tiers, 4 contexts |
| 14 | **Save/Load** | ✅ | ⬜ | Campaign + tactical scopes; modular manifest |

**Minimum to make a battle playable** (units can move, fight, and the game can end):
→ Code Morale + Facing & Flank + Hex Movement + Victory/Defeat ≈ 4 implementation sprints

**Full Vertical Slice** (playable battle + duel):
→ Above + Duel System + Officer Passive + Tactical HUD + Duel UI + Portrait Display

---

## Known Gaps

| Gap | Severity | Action |
|---|---|---|
| No ADRs for any implemented system | Medium | `/architecture-decision` for Officer Stats, Terrain, Combat Resolution |
| No CI workflow | Low | `/test-setup` can scaffold `.github/workflows/` |
| GUT named in tech prefs but using custom runner | Low | Migrate after MVP |
| 11 GDDs designed but not yet reviewed | Medium | `/design-review [path]` in a fresh session per GDD |
| Morale / Hex / Facing / FoW / Victory code not started | Blocking for playable battle | Implement in order |
| Duel System open question: scripted tie fallback | Low | Confirm with narrative director before Duel impl |
| Terrain GDD Dependencies section needs backfill | Low | Add Hex Movement + Fog of War as downstream consumers |
| Campaign save state is provisional | Medium | Will be extended as Campaign Layer GDDs (Resource, Settlement, Intel, etc.) are designed |

---

## Key Design Decisions

| Decision | What was chosen | Why |
|---|---|---|
| Officer stats | Fixed blocks, grow +1–3 per act transition only | Identity from spread + passive, not grind |
| Combat | Deterministic (no RNG) | Outcomes are predictable; skill-driven |
| Morale system | 3 states (STEADY/SHAKEN/BROKEN), 2-pass cascade cap | Warning window before rout; domino chains are possible but limited |
| Battle end | Via morale rout, not HP annihilation | P3 (Grounded) — armies break, not disappear |
| Art style | Neoclassical oil painting portraits, painted-map battlefield | IP identity; portrait quality compensates for simple sprites |
| Intel difficulty | Tuning parameter (not content gate) — can adjust until ship | P1 expression without blocking players |
| Duel resolve floor | +40 offset (not +30) | Thane (CHR 45) needed 62 resolve to survive 4–5 hits from Alexsen — +30 gave only 52 (too fragile) |
| Duel RPS tie handling | Attack-Attack tie: each takes 50% of OTHER's attack_damage | Prevents Attack being purely dominant; tie creates mutual risk |
| Victory route threshold | 0.50 | Counts broken+routed+dead together; 8/16 squads is legible and historically grounded |
| Hex orientation | Flat-top (flat edges top/bottom) | Napoleonic line formations → natural horizontal rows |
| Save format | JSON, modular manifest contract | Consistent with project data-driven conventions; each system owns its serialization |
| Mid-duel save | Blocked; reloads to turn start | Simplest correct behavior; avoids mid-duel state complexity |
| Enemy HP display | 5-segment approximate bar (not exact value) | Preserves fog-of-war intelligence uncertainty |

---

## Open Questions (unresolved)

1. Fire Plan outcome in novel canon (GDD assumes success — may need sync)
2. Zhuge Jian join timing: treatise Act II vs physical Act III — confirm with bible
3. Mission 8 duel vs Lycurse: allow loss without game-over?
4. Post-unification island name: Kasteria or Kastera?
5. Loyalty system depth: single value per city sufficient for P3 themes?
6. Hex Movement: does it own routing pathfinding, or does Morale System signal and Hex executes? (tentative: Hex owns it)
7. 1 HP = 1 manpower unit — confirm when Army Composition GDD is authored
8. Duel scripted tie fallback: `outcome_flag_draw` missing → player-loss or context-dependent? (confirm with narrative director before Duel System implementation)
9. Diplomatic duel re-attempt: one attempt per game or resets each campaign turn? (deferred to Diplomacy GDD)
10. Save/Load: Steam Cloud integration — MVP scope or post-launch?
11. Tactical HUD: full CanvasLayer table — confirm complete hierarchy with Technical Director before implementation

---

## File Map

```
design/
├── gdd/
│   ├── kasters-war-gdd.md              ← game concept (start here)
│   ├── systems-index.md                ← 35 systems, design order, status
│   ├── officer-stats.md                ← ✅ Approved
│   ├── terrain-system.md               ← ✅ Approved
│   ├── combat-resolution.md            ← ✅ Approved
│   ├── morale-system.md                ← 🟡 Designed (review pending)
│   ├── facing-and-flank.md             ← 🟡 Designed (review pending)
│   ├── hex-movement.md                 ← 🟡 Designed (review pending)
│   ├── fog-of-war.md                   ← 🟡 Designed (review pending)
│   ├── victory-defeat-conditions.md    ← 🟡 Designed (review pending)
│   ├── duel-system.md                  ← 🟡 Designed (review pending)
│   ├── officer-passive-ability.md      ← 🟡 Designed (review pending)
│   ├── duel-ui.md                      ← 🟡 Designed (review pending)
│   ├── portrait-display.md             ← 🟡 Designed (review pending)
│   ├── tactical-hud.md                 ← 🟡 Designed (review pending)
│   └── save-load.md                    ← 🟡 Designed (review pending)
├── art/
│   └── art-bible.md                    ← ✅ Complete
└── registry/
    └── entities.yaml                   ← officers, formulas, shared constants

src/gameplay/
├── officers/                           ← officer.gd, officer_registry.gd
├── terrain/                            ← terrain_system.gd, terrain_tile.gd
└── combat/                             ← squad.gd, combat_resolver.gd

assets/data/
├── officers.json                       ← 7 named + 4 archetypes
├── terrain.json                        ← 8 terrain types
├── combat.json                         ← unit types + constants
├── morale.json                         ← ⬜ pending (Morale impl)
├── duel_config.json                    ← ⬜ pending (Duel impl)
├── passive_config.json                 ← ⬜ pending (Officer Passive impl)
├── duel_ui_config.json                 ← ⬜ pending (Duel UI impl)
├── portrait_config.json                ← ⬜ pending (Portrait impl)
├── tactical_hud_config.json            ← ⬜ pending (HUD impl)
└── save_config.json                    ← ⬜ pending (Save/Load impl)

tests/unit/
├── officers/                           ← 3 test files
├── terrain/                            ← 2 test files
└── combat/                             ← 2 test files
```

---

## What to Do Next

### Phase: GDD Reviews (all 11 pending — each requires a fresh session)

```bash
/design-review design/gdd/morale-system.md
/design-review design/gdd/facing-and-flank.md
/design-review design/gdd/hex-movement.md
/design-review design/gdd/fog-of-war.md
/design-review design/gdd/victory-defeat-conditions.md
/design-review design/gdd/duel-system.md
/design-review design/gdd/officer-passive-ability.md
/design-review design/gdd/duel-ui.md
/design-review design/gdd/portrait-display.md
/design-review design/gdd/tactical-hud.md
/design-review design/gdd/save-load.md
```

### Phase: Gate Check

```bash
# All 14 MVP GDDs are designed — validate readiness for implementation:
/gate-check pre-production
```

### Phase: Implementation (after reviews, priority order)

```
1. Expand MoraleState enum in squad.gd + add SHAKEN to combat_resolver.gd
2. Implement Morale System (src/gameplay/morale/)
3. Implement Facing & Flank (src/gameplay/combat/facing/)
4. Implement Hex Movement (src/gameplay/movement/)
5. Implement Fog of War (src/gameplay/fog/)
6. Implement Victory/Defeat (src/gameplay/victory/)
→ At this point: a basic battle can be played headlessly
7. Implement Duel System (src/gameplay/duel/)
8. Implement Officer Passive (src/gameplay/officers/passives/)
9. Implement Tactical HUD (src/ui/tactical/)
10. Implement Duel UI (src/ui/duel/)
11. Implement Portrait Display (src/ui/portraits/)
12. Implement Save/Load (src/core/save/)
→ At this point: Vertical Slice is playable
```

### Process Backlog

```bash
# Backfill ADRs for 3 implemented systems:
/architecture-decision officer-stats
/architecture-decision terrain-system
/architecture-decision combat-resolution

# Set up CI:
/test-setup
```
