# Fog of War / Vision System

> **Status**: Designed
> **Author**: Game Designer
> **Last Updated**: 2026-06-12
> **Implements Pillar**: P1 — Victory Through Preparation + P3 — Grounded, Barely Fantastic

## Overview

The Fog of War / Vision System governs what the player can see on the tactical hex grid. At the data level it maintains a per-hex **visibility state** (VISIBLE, PREVIOUSLY_SEEN, or HIDDEN) for the enemy side of the battlefield, recalculating at the start of each player turn and updating in real-time as friendly squads move. The calculation has two inputs: each friendly squad's **vision range** (derived from unit type, current terrain, and passive bonuses) and the **line-of-sight primitive** from the Hex Movement System. Its outputs drive what enemy squad sprites are rendered, where the fog overlay is applied on the hex grid, and what tactical data (HP, unit type, officer name) is visible in the HUD. Terrain hexes are always visible; the fog only governs whether **enemy squad positions** are known. Enemy squads previously seen but currently out of vision are rendered as "last known" ghosts at their final observed position, giving the player a memory of where the enemy was — accurate or stale depending on whether the enemy moved since then.

At the player level, the system is the tactical intelligence layer: you see what your positioned squads can see, no more. A Light Infantry squad on a Hill sees 4 hexes; a Line Infantry squad in a valley sees 2. Preparing well — using Preparation Phase scout actions — lifts fog at battle start, rewarding the player who invested Intel resources on the campaign layer. The system directly implements **P1 (Victory Through Preparation)**: preparation pays out as vision, and vision pays out as decision quality. Without this system, tactical combat loses the intelligence-vs-uncertainty tension that makes positioning matter.

## Player Fantasy

The fantasy is the **intelligence advantage**. Not the comfort of knowing everything — the *edge* of knowing more than the enemy expects you to know. When the battle loads and half the enemy deployment is already visible because you sent Thane to scout, that is not a cheat; that is the payoff of a decision made three turns ago on the campaign map. The fog makes preparation valuable. Without it, the battle is a puzzle with all pieces face-up. With it, the player who prepared better has sharper information, and sharper information wins wars.

The inverse is equally important: the **anxiety of the dark hexes**. That forest in the southeast is silent. There is something in there — there has to be — but you cannot see it. You move your cavalry north instead of south because the south is blind. Every move made without vision is a bet. The fog is not an obstacle; it is a *player*, exerting pressure from everywhere you are not looking.

The third feeling is **discovery shock** — the moment a full enemy squad materializes from the grey at the edge of your vision, already moving toward a flank you left exposed. Fog of war makes enemy movement feel dangerous and surprising rather than telegraphed. In a game without fog, a clever flanking move is anticipated. In a game with it, the same move lands like an ambush.

Bon shi hai's Stratagem passive — "+1 hex vision to all squads" — has its full value here. With Bon in the army, every squad sees one hex farther. That sounds mechanical, but in practice it means certain hills that were blind become visible, certain flanks that felt unsafe become watched, and the player feels the difference immediately. The system creates the conditions where officer choice matters for reasons other than combat stats. This is P2 (Officers Are the Story) expressing itself through P1 (Victory Through Preparation).

## Detailed Design

### Core Rules

**What Fog Governs:**
Terrain hexes are always visible — the map is known (commanders survey the battlefield before battle). Fog governs **enemy squad positions only**. A player always sees the full terrain layout; they never know for certain where all enemy squads are.

All friendly squads are always visible to the player. No friendly information is hidden.

**Visibility States:**
Each enemy squad is tracked in one of three states:

| State | Condition | Rendering |
|---|---|---|
| VISIBLE | Within vision range AND unobstructed LOS from at least one friendly squad | Full brightness; unit type, officer name, health bar shown |
| PREVIOUSLY_SEEN | Was VISIBLE in a prior turn but no longer qualifies | Ghost sprite at last known position (greyed/dimmed); last known unit type shown; no HP or officer info |
| HIDDEN | Never seen | Nothing rendered at that squad's actual position |

**Vision Range:**
Each friendly squad's vision radius is:
```
vision_range(squad) = base_vision[unit_type] + terrain_vision_mod(squad.position) + squad.vision_bonus
```

Base vision by unit type:
| unit_type | base_vision |
|---|---|
| INF | 2 hexes |
| LI | 3 hexes — "far vision" (Light Infantry / Tirailleurs role) |
| CAV | 3 hexes — cavalry screening and reconnaissance role |
| ART | 2 hexes |

Terrain vision modifier: `+1` if the squad's current hex is a **Hill**; `0` otherwise. (Defined by Terrain GDD via `terrain.vision_modifier(hex)`.)

Vision bonus: sum of all active passive ability bonuses for this squad (see Passive Interface below).

**Visibility Check:**
Enemy squad E is VISIBLE this turn if at least one friendly squad F satisfies both:
1. `hex_distance(F.position, E.position) <= vision_range(F)`
2. `ray_cast_los(F.position, E.position) == true`

LOS blocking: Forest and Village hexes block LOS (defined by Hex Movement `ray_cast_los` — uses the same blocking rules as ranged attacks).

If neither condition is met and E was VISIBLE last turn → PREVIOUSLY_SEEN.
If neither condition is met and E was never VISIBLE → HIDDEN.

**Turn Timing:**
- Vision recalculates at the **START of the player's Movement Phase** each turn (captures AI-turn enemy movements).
- Vision also updates **immediately during the player's Movement Phase** when a friendly squad moves to a new hex (the squad's vision from its new position is calculated before the next action).
- During the AI's turn: the player sees only AI squads that fall within a friendly squad's vision at the moment of the AI's move. An AI squad that moves entirely within fog remains unseen until it enters a friendly squad's vision range.

**Ghost Position Rule:**
The ghost shows where the enemy was **last seen**, not where it currently is. If an enemy squad at hex A moves to hex B during the AI turn, and no friendly squad has LOS to hex B, the ghost persists at hex A. The player does not see the enemy's actual position update. This is intentional — stale intelligence is a gameplay mechanic, not a bug.

**Passive Vision Bonus Interface:**
Officer passive abilities that affect vision write to `squad.vision_bonus: int` at turn start. The Fog of War system reads this field per squad during vision_range calculation.

- **Bon's Stratagem passive**: sets `vision_bonus += 1` for ALL friendly squads on the battlefield at the start of each player turn.
- Other passive effects (if designed) follow the same write-to-`vision_bonus` pattern.

**Preparation Phase Integration:**
A Preparation Phase scout action (e.g., "Thane scouted deployment") populates a `battle_start_reveals` set containing the IDs of enemy squads that are VISIBLE from turn 1 regardless of vision range. This simulates pre-battle reconnaissance. The set is consumed by the Fog of War system at battle initialization and cleared after the first normal vision calculation.

**Revealed Information:**
When VISIBLE: squad position, unit type, officer name and portrait, health bar.
When PREVIOUSLY_SEEN: last known position, last known unit type. No HP or officer name (stale).
When HIDDEN: nothing shown.

**Ranged Attack Constraint:**
A ranged attack declaration requires the target squad to be currently VISIBLE. PREVIOUSLY_SEEN ghosts cannot be targeted. This is the primary tactical enforcement of fog.

**AI Fog Behavior (MVP):**
The enemy AI has perfect knowledge of all friendly squad positions — it does not operate under fog rules. Fog is a player-side experience only in MVP. Symmetric AI fog is a Difficulty Setting option (deferred to post-MVP).

---

### States and Transitions

Per-enemy-squad state tracked by this system:

| Field | Type | Persistence | Description |
|---|---|---|---|
| `visibility_state` | enum | Per-turn | VISIBLE \| PREVIOUSLY_SEEN \| HIDDEN |
| `last_known_position` | Vector3i or null | Persists until next sighting | Hex where enemy was last VISIBLE |
| `last_known_unit_type` | enum or null | Persists until next sighting | Unit type at last sighting |
| `last_seen_turn` | int | Persists | Turn number when last VISIBLE; -1 if never seen |

**State Machine:**

| From | Event | To |
|---|---|---|
| HIDDEN | Vision check returns VISIBLE | VISIBLE; update `last_known_position`, `last_known_unit_type`, `last_seen_turn` |
| VISIBLE | Vision check fails (out of range or LOS blocked) | PREVIOUSLY_SEEN; ghost stays at `last_known_position` |
| PREVIOUSLY_SEEN | Vision check returns VISIBLE again | VISIBLE; update `last_known_position` and `last_seen_turn` |
| PREVIOUSLY_SEEN | Enemy squad moves in fog (no friendly LOS) | Stays PREVIOUSLY_SEEN; ghost does NOT update (stale position) |
| Any | Enemy squad is eliminated | Remove from tracking |

**Battle Initialization Sequence:**

1. All enemy squads initialize to HIDDEN, `last_seen_turn = -1`
2. Apply `battle_start_reveals` set: each listed squad ID → force VISIBLE, update position/type, `last_seen_turn = 0`
3. Run full vision calculation for all friendly squads at starting positions
4. Any additionally VISIBLE enemy squads update state to VISIBLE

---

### Interactions with Other Systems

| System | This System Reads | This System Writes |
|---|---|---|
| **Hex Movement** | `hex_distance(a,b)` → int; `ray_cast_los(a,b)` → bool | — |
| **Terrain** | `terrain.vision_modifier(hex)` → int (Hill: +1, all others: 0) | — |
| **Officer Passives** | `squad.vision_bonus` → int per friendly squad | — |
| **Preparation Phase** | `battle_start_reveals` → set of enemy squad IDs (pre-scouted) | — |
| **Combat Resolution** | — | Enemy squad visibility state (ranged attacks require VISIBLE target) |
| **Ranged & Artillery** | — | Enemy VISIBLE state (targeting constraint) |
| **Tactical AI** | — | No fog applied to AI — AI reads all friendly squad positions directly |
| **Tactical HUD** | — | Per-squad visibility state; `last_known_position`, `last_known_unit_type` for ghost rendering |

## Formulas

### F-1: Vision Range per Squad

```
vision_range(squad) = base_vision[unit_type] + terrain.vision_modifier(squad.position) + squad.vision_bonus
```

| Symbol | Type | Range | Description |
|---|---|---|---|
| `base_vision[unit_type]` | int | {2, 3} | Base vision radius by unit type |
| `terrain.vision_modifier(hex)` | int | {0, 1} | Hill = +1; all others = 0 (locked by Terrain GDD) |
| `squad.vision_bonus` | int | 0+ | Sum of all active passive ability vision bonuses |
| `vision_range` | int | [2, 5+] | Hex radius within which the squad can detect enemies |

**Base vision by unit type:**
| unit_type | base_vision | Role rationale |
|---|---|---|
| INF | 2 | Standard line formation — eyes forward |
| LI | 3 | Skirmisher / screen role — far-vision per game concept |
| CAV | 3 | Scouting / screening role — historical cavalry reconnaissance |
| ART | 2 | Crew-served guns — focus downrange, not horizon |

**No hard cap.** Maximum without passives: LI or CAV on Hill = 4 hexes. With Bon present: 5 hexes. On a 20×15 map, this remains fog-meaningful because LOS blocking (Forest, Village) constrains practical vision in terrain-heavy maps.

**Output range:** [2, 5+]. Cannot be reduced below `base_vision` by passives.

**Worked examples:**
- INF on flat field (no Bon): `2 + 0 + 0 = 2 hexes`
- LI on Hill (Bon present): `3 + 1 + 1 = 5 hexes`
- CAV on flat field (Bon present): `3 + 0 + 1 = 4 hexes`
- ART on Hill (Bon present): `2 + 1 + 1 = 4 hexes`

---

### F-2: Collective Visibility Check

```
is_visible(enemy_squad E) → bool:
  for each friendly squad F:
    d = hex_distance(F.position, E.position)
    if d <= vision_range(F):                    # O(1) cheap gate
      if ray_cast_los(F.position, E.position):  # only called when in range
        return true
  return false
```

| Symbol | Type | Range | Description |
|---|---|---|---|
| F | squad | — | Each friendly squad, iterated |
| E | squad | — | Enemy squad under test |
| `d` | int | 0+ | Chebyshev distance between F and E |
| `vision_range(F)` | int | 2–5+ | From F-1 |
| `ray_cast_los(F, E)` | bool | {true, false} | False if Forest or Village on the ray path |
| result | bool | {true, false} | True if any F can see E |

**OR logic:** if any single friendly squad can see E, E is VISIBLE. No confirmation-of-two required.

**Performance note:** The distance check is O(1) and acts as a cheap gate — `ray_cast_los` (more expensive) is only called when E is within range of F. On a 16×16 squad scenario (256 combinations), this yields ~50–80 ray cast calls in practice (most pairs are out of range). Acceptable for a turn-based game where this runs once per move action, not per frame.

**Boundary rule:** A squad at exactly `hex_distance = vision_range` is VISIBLE (`<=`, not `<`).

**Worked example:** CAV at (0,0,0) with vision_range=3, enemy at (3,−2,−1). `hex_distance = max(3,2,1) = 3`. 3 ≤ 3 → in range. `ray_cast_los` called. If no Forest/Village on path → VISIBLE.

---

### F-3: Ghost Staleness

```
staleness_turns = current_turn - last_seen_turn
```

| Symbol | Type | Range | Description |
|---|---|---|---|
| `current_turn` | int | 1+ | Current game turn |
| `last_seen_turn` | int | 1+ | Turn when enemy squad was last VISIBLE |
| `staleness_turns` | int | 0+ | Age of the ghost position in turns |
| `staleness_threshold` | int | default 3 | Turns after which a "?" indicator appears on ghost |

When `staleness_turns >= staleness_threshold`, a "?" badge is shown on the ghost sprite — indicating the player should treat the position as unconfirmed. The ghost itself remains rendered (the player knows the enemy existed there); only the confidence indicator changes. Display caps at "3+ turns" to avoid UI clutter.

**Threshold = 3** matches the Campaign layer Intel System's 3-turn intel decay — consistent cross-layer signaling.

**Worked example:** Enemy last seen turn 4, current turn 7. `staleness_turns = 3 >= 3`. "?" badge shown. Turn 8: `staleness = 4`, badge persists.

## Edge Cases

**E-1: Enemy squad eliminated while PREVIOUSLY_SEEN.**
If an enemy squad is destroyed (combat resolution) while its state is PREVIOUSLY_SEEN (not currently visible), the ghost is removed from the map at the moment of elimination. The player gets no visual confirmation of the kill — the ghost simply vanishes. A "squad eliminated" log entry still fires. This is intentional: you shouldn't get free confirmation kills on enemies you can't see.

**E-2: All friendly squads eliminated — no vision sources.**
If all friendly squads are dead, the visibility map collapses: all enemy squads transition to HIDDEN. This is an edge case since the battle ends when all squads are eliminated or routed — handle by checking battle-end conditions before recalculating vision.

**E-3: Bon is killed or routed mid-battle.**
When Bon's squad exits the map (routed or eliminated), `vision_bonus` for all friendly squads loses the Bon contribution at the start of the next turn's vision recalculation. Enemy squads that were visible only because of Bon's bonus transition to PREVIOUSLY_SEEN or HIDDEN. No mid-turn immediate recalculation — the change takes effect at the next vision update.

**E-4: Enemy squad enters a Forest mid-move during AI turn.**
If an enemy squad was VISIBLE at the start of the AI turn and then moves into a Forest during the AI turn, its visibility updates when vision recalculates at the start of the next player turn. The player MAY see the squad moving into the forest (if they currently have vision of that route) or may not (if the forest is out of LOS). In either case, at the next player turn start: if LOS to the forest hex is blocked for all friendly squads → the enemy transitions to PREVIOUSLY_SEEN with last known position being the forest hex.

**E-5: Two enemy squads in the same hex (impossible by movement rules, but...).**
The Hex Movement system prevents two squads from occupying the same hex. This edge case cannot occur. No special handling needed.

**E-6: `battle_start_reveals` contains a squad ID that doesn't exist on this map.**
If a Preparation Phase scout action generated reveals for squad IDs that are not in the current battle (e.g., different battle from a cached prep), silently ignore those IDs. The `battle_start_reveals` set is filtered against the current battle's enemy squad list at initialization.

**E-7: Vision range would be negative from a future passive that reduces vision.**
No currently designed passive reduces vision. If a future mechanic introduces vision reduction (e.g., "blinded" status effect), clamp vision_range at `max(1, computed_value)` — a squad always sees at least 1 hex (its immediate neighbors). Never 0 or negative.

**E-8: Staleness threshold reached for a ghost that was scouted via Preparation Phase.**
A `battle_start_reveals` ghost starts with `last_seen_turn = 0` (before turn 1). If the enemy squad was never subsequently re-sighted, at turn 4 its `staleness_turns = 4 >= 3`. The "?" badge appears even for prep-phase-revealed squads. This is correct: pre-battle scouting intelligence also grows stale.

**E-9: LOS from one friendly squad is blocked, but another has clear LOS.**
The `is_visible` check iterates ALL friendly squads. If friendly squad A has LOS blocked (Forest in the way) but friendly squad B at a different position has clear LOS, enemy squad E is VISIBLE. Vision coverage is the union of all friendly squad visions, not the intersection.

## Dependencies

### Upstream (systems this GDD depends on)

| System | What This System Reads | Interface |
|---|---|---|
| **Hex Movement System** | Hex distance; LOS ray cast | `hex_distance(a, b)` → int; `ray_cast_los(a, b)` → bool |
| **Terrain System** | Vision range modifier per hex | `terrain.vision_modifier(hex)` → int (+1 for Hill, 0 others) |
| **Officer Passive Ability System** | Per-squad vision bonus from passive effects | `squad.vision_bonus` → int (written by passives, read by this system) |
| **Preparation Phase System** | Pre-battle scout reveals | `battle_start_reveals` → set of enemy squad IDs |

> **Backfill note:** The Terrain GDD declares `terrain.vision_modifier()` as an interface but was authored before this system. Its Dependencies section should list Fog of War as a downstream consumer. Update `design/gdd/terrain-system.md §Dependencies` to add Fog of War.
>
> The Hex Movement GDD was authored with FoW as a downstream consumer — no backfill needed there.

### Downstream (systems that depend on this GDD)

| System | What It Reads From This System |
|---|---|
| **Combat Resolution** | `enemy.visibility_state == VISIBLE` check before allowing ranged attack declaration |
| **Ranged & Artillery System** | Enemy must be VISIBLE to be targeted |
| **Tactical AI System** | AI does not use fog (has perfect information in MVP) — no dependency |
| **Tactical HUD** | `visibility_state`, `last_known_position`, `last_known_unit_type`, `staleness_turns` per enemy squad (drives ghost rendering, info display) |

### Cross-System State Ownership

| Field | Owned By | Read By |
|---|---|---|
| `squad.visibility_state` | Fog of War | Combat Resolution, Ranged & Artillery, Tactical HUD |
| `squad.last_known_position` | Fog of War | Tactical HUD (ghost rendering) |
| `squad.last_known_unit_type` | Fog of War | Tactical HUD |
| `squad.last_seen_turn` | Fog of War | Fog of War (F-3 staleness), Tactical HUD (badge) |
| `squad.vision_bonus` | Officer Passive Ability System (writes) | Fog of War (reads) |
| `battle_start_reveals` | Preparation Phase System (writes) | Fog of War (reads at battle init, then clears) |

## Tuning Knobs

| Knob | Current Value | Safe Range | Gameplay Effect |
|---|---|---|---|
| `base_vision[INF]` | 2 | [1, 3] | Lower: fog is thick even for main infantry; higher: fog is minimal |
| `base_vision[LI]` | 3 | [2, 4] | Lower: closes gap with INF; higher: LI become the dominant scout unit |
| `base_vision[CAV]` | 3 | [2, 4] | Lower: cavalry lose scouting identity; higher: cavalry dominate early intel |
| `base_vision[ART]` | 2 | [1, 3] | Usually keep at 2; reducing to 1 forces artillery to rely on spotter units |
| `staleness_threshold` | 3 | [1, 5] | Lower: ghost positions feel stale quickly (more uncertainty); higher: ghosts remain "trusted" longer (less anxiety) |
| LOS blocking terrain | Forest, Village | — | Add Hill to limit ranged dominance from elevation. Remove Village to open urban sightlines. Changes significantly affect ranged attack viability. |
| AI vision mode | Perfect (MVP) | [Perfect, FoW-symmetric] | Symmetric FoW (AI also limited by vision) adds challenge and realism but requires AI pathfinding rework — post-MVP option |

**Note:** Hill vision bonus (+1) and LOS blocking rules (Forest, Village) are owned by the Terrain GDD and locked in the entity registry. Changes require a Terrain GDD update.

## Visual/Audio Requirements

### Visual

- **Fog overlay**: Hexes that contain HIDDEN or PREVIOUSLY_SEEN enemy squads have no visual indicator on the hex itself — terrain is always shown fully. The fog is communicated exclusively through the absence of enemy squad sprites, not through a darkening overlay on terrain. This keeps the map readable and avoids the "black shroud" look that conflicts with the art direction (painted terrain, war-table aesthetic).
- **Ghost sprite**: A PREVIOUSLY_SEEN enemy squad is rendered as a dimmed (40–50% opacity), desaturated version of its normal unit token at `last_known_position`. No animated elements — static, clearly "uncertain."
- **Staleness badge**: When `staleness_turns >= staleness_threshold`, a small "?" badge appears on the ghost token's corner. Styled as a wax seal or worn parchment stamp to match the art direction.
- **VISIBLE enemy unit**: Rendered at full opacity, full color. A subtle "eye" or "awareness" indicator may appear (optional) — but enemy units should render normally when visible; over-annotating discovered enemies reduces the "reading the map" feel.
- **Transition from HIDDEN to VISIBLE**: A subtle "materialize" or "unfog" animation when an enemy squad is first sighted — a brief fade-in from ghost to full. Should not be jarring or alarming; matches the tense intelligence-discovery feel of the game.
- **Preparation Phase reveal**: At battle start, pre-scouted enemy squads appear at full opacity with a brief golden highlight (the "intel" payoff). Distinct from normal sighting — signals "you prepared for this."

### Audio

- **Squad spotted**: A subtle sound cue when an enemy squad transitions from HIDDEN → VISIBLE (first ever sighting). Low-key — a murmur of concern, not an alarm. Does not repeat for PREVIOUSLY_SEEN → VISIBLE transitions (re-sighting a known squad is not a new discovery).
- **Ghost staleness**: No audio cue for staleness threshold — visual badge is sufficient.
- **Preparation Phase reveal**: A distinct "intel confirmation" sound at battle start for pre-revealed squads — reinforces the payoff of the preparation investment.

## UI Requirements

- **No terrain darkening**: Do not apply fog overlay to terrain hexes. Terrain is always shown at full brightness. The fog is visible only through absent/ghost enemy sprites.
- **Ghost interaction**: Clicking on a ghost token shows a tooltip: "Last known position — [unit type] — [staleness_turns] turn(s) ago." Ghosts are not selectable for attack. Attempting to right-click a ghost shows "Target not visible — no ranged attack available."
- **Vision radius indicator (debug/optional)**: In the unit info panel for a selected friendly squad, optionally display the squad's current `vision_range` value: "Vision: 4 hexes." Not shown on the hex grid — does not draw a visible radius circle (that would feel too gamey and undermine the intelligence-reading feel).
- **Battle start reveal animation**: At battle start, pre-scouted enemy squads appear with a brief golden highlight and a "Thane's report: [N] squads located." notification bar — communicates that the Preparation Phase investment had a concrete effect.
- **Squad info panel**: When an enemy squad is VISIBLE, clicking it shows: unit type, health bar (approximate — shown as a bar, not exact number), officer name and portrait. When PREVIOUSLY_SEEN, clicking the ghost shows: last known unit type, "Information may be stale — [N] turns ago." No HP or officer info.
- **Turn log**: The turn log records "Enemy squad spotted at [hex]" on first sighting. Does not repeat on re-sightings or ghost state changes.
- **Keyboard navigation**: Ghost tokens are not keyboard-selectable (cannot be Tab-targeted for action). Vision indicator is accessible via the squad info panel via keyboard (Tab to selected squad, then F for "Focus" panel showing vision value).
- **Preparation Phase summary screen**: After a scout action is taken in Prep Phase, show a preview: "Thane's report will reveal [N] enemy squads at battle start." Players see what their prep investment buys before committing.

## Acceptance Criteria

### F-1: Vision Range Formula

1. **INF base vision.** INF on a flat hex with no bonus: `vision_range = 2`.
2. **LI base vision.** LI on a flat hex with no bonus: `vision_range = 3`.
3. **CAV base vision.** CAV on a flat hex with no bonus: `vision_range = 3`.
4. **ART base vision.** ART on a flat hex with no bonus: `vision_range = 2`.
5. **Hill bonus.** INF on a Hill hex: `vision_range = 3` (base 2 + terrain +1).
6. **Forest no vision bonus.** INF on a Forest hex: `vision_range = 2` (Forest does not add to vision).
7. **Bon's Stratagem active.** Any friendly squad with Bon present: `squad.vision_bonus` includes +1. Applies to all unit types.
8. **Stacked bonuses.** INF on Hill with Bon active: `vision_range = 4` (base 2 + Hill 1 + Bon 1).

### F-2: Visibility Check — Distance Gate

9. **Exactly at range boundary — VISIBLE.** LI (vision_range=3) and enemy at hex_distance=3, clear LOS: `is_visible = true`. Range check is `<=`, not `<`.
10. **One hex beyond range — NOT VISIBLE.** LI (vision_range=3) and enemy at hex_distance=4: `is_visible = false` regardless of LOS.
11. **Within range, clear LOS.** INF (vision_range=2) and enemy at hex_distance=2, clear LOS: `is_visible = true`.

### F-2: Visibility Check — LOS Blocking

12. **Forest intermediate blocks.** Enemy in range; Forest hex lies between friendly and enemy (not at either endpoint): `is_visible = false`.
13. **Village intermediate blocks.** Enemy in range; Village hex lies between friendly and enemy (not at either endpoint): `is_visible = false`.
14. **Clear path — visible.** Enemy in range; no Forest or Village hexes on the intermediate ray path: `is_visible = true`.
15. **Target's own hex does not block.** Enemy occupies a Forest hex at the terminal position; intermediate hexes are clear: `is_visible` is determined by intermediate hexes only — terminal Forest does not block its own detection.

### F-2: Vision Union Across Multiple Squads

16. **Union — one blocked, one clear.** Friendly Squad A has LOS blocked to enemy E; Friendly Squad B has clear LOS within range: `is_visible(E) = true`. One squad seeing is sufficient.
17. **All out of range — HIDDEN.** No friendly squad has enemy E within vision_range: `is_visible(E) = false` regardless of LOS state.

### State Transitions

18. **VISIBLE → PREVIOUSLY_SEEN.** Enemy that was VISIBLE and then moves beyond all friendly vision ranges: state transitions to PREVIOUSLY_SEEN; ghost appears at last_known_position.
19. **Ghost does not follow enemy in fog.** Enemy in PREVIOUSLY_SEEN state moves during AI turn outside all friendly vision: ghost token stays at old last_known_position; it does NOT update to the enemy's new position.
20. **PREVIOUSLY_SEEN → VISIBLE.** Friendly squad moves into LOS of an enemy squad's actual current position: enemy transitions to VISIBLE; ghost removed.
21. **HIDDEN state.** Enemy never sighted by any friendly squad: state is HIDDEN; no ghost token exists.

### F-3: Ghost Staleness

22. **Below threshold — no badge.** Ghost with `staleness_turns = 2` (threshold is 3): no "?" badge displayed.
23. **At threshold — badge shown.** Ghost with `staleness_turns = 3`: "?" badge displayed on ghost token.
24. **Badge clears on re-sighting.** Enemy ghost with "?" badge transitions to VISIBLE: badge removed; `last_seen_turn` updated to current turn.

### Turn Timing

25. **Vision recalculates at Movement Phase start.** At the start of the player's Movement Phase, vision state for all enemy squads recalculates before any friendly squad moves — prior turn's stale state is replaced.
26. **Real-time update during movement.** A friendly squad moves to a new hex during the player's Movement Phase; an enemy newly within range is VISIBLE immediately — before any further player action this turn.
27. **AI turn partial visibility.** During the AI turn, enemy squads moving through hexes entirely outside any friendly squad's vision range are not shown moving to the player; movement only visible when the enemy squad passes through or ends in a currently-visible hex.

### Battle Initialization

28. **All enemies start HIDDEN.** At battle start with no battle_start_reveals entries for this scenario, all enemy squads are HIDDEN — no enemy positions visible.
29. **battle_start_reveals forces VISIBLE.** Enemy Squad X is in the battle_start_reveals set; at battle start, Squad X is VISIBLE and its position shown.
30. **Bon bonus at turn 1.** Bon's Stratagem active at battle start; all friendly squads include `+1` in `squad.vision_bonus` from the first vision recalculation.

### Ranged Attack Constraint

31. **VISIBLE target — attack permitted.** Ranged attack against VISIBLE enemy squad: attack declaration accepted.
32. **PREVIOUSLY_SEEN ghost — attack rejected.** Ranged attack targeting a ghost token: attack declaration rejected; ghost is not selectable as a ranged target.
33. **HIDDEN enemy — attack rejected.** Ranged attack against HIDDEN enemy: attack declaration rejected.

### Bon Eliminated

34. **Bon eliminated removes vision bonus.** Bon's squad eliminated before the current turn's vision recalculation; when vision recalculates, all friendly squads have `squad.vision_bonus` without the Bon +1.

### AI Information

35. **AI has perfect information in MVP.** Enemy AI evaluates friendly squad positions for targeting and movement without consulting the fog system — all friendly positions are accessible to the AI regardless of fog state.

## Open Questions

1. **Symmetric AI fog (post-MVP).** The MVP AI has perfect information. For Hard difficulty, should the AI also be limited by fog (only targeting friendly squads it "knows about")? This would require AI pathfinding and targeting to consult the visibility state — significant implementation work. *Flag for Difficulty Settings System design.*

2. **LI forest transparency.** Should Light Infantry have a special rule where Forest intermediate hexes don't block their own outgoing LOS (since they operate within forests)? This would make LI-in-Forest a dominant scouting position. Kept simple in MVP (Forest blocks LOS for all unit types). *Revisit when Officer Passive Ability System is designed — could be a generic LI passive rather than a core FoW rule.*

3. **Vision during enemy turn — full watch or partial?** Current rule: player sees AI squad moves only within current friendly vision range. An alternative is that the enemy turn is fully animated (player watches all enemy moves) and fog only applies to the snapshot at the player's turn start. Full animation is friendlier for the player but reduces tactical fog tension. *Decision belongs to: UX Designer, target resolution before Tactical HUD design.*

4. **Ghost token click behavior — should it trigger anything?** Currently: clicking a ghost shows a stale info tooltip. Alternative: clicking a ghost highlights "last known position" and shows which turn it was seen, enabling the player to reason about where the squad might be now. *Decision belongs to: UX Designer.*

5. **Preparation Phase "Thane scouted" — how many squads revealed?** The `battle_start_reveals` mechanism is defined but the number of enemy squads revealed depends on the Preparation Phase action design. This GDD declares the interface; the Preparation Phase System GDD must specify the action cost and reveal count. *Resolve when Preparation Phase System is designed (design order #19).*
