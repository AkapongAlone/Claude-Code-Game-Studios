# Hex Movement System

> **Status**: Designed
> **Author**: Game Designer
> **Last Updated**: 2026-06-12
> **Implements Pillar**: P1 — Victory Through Preparation + P3 — Grounded, Barely Fantastic

## Overview

The Hex Movement System governs all spatial movement on the tactical hex grid. At the data level it serves three roles: a **movement executor** (routes squads from hex to hex, deducting Action Points per terrain cost), a **pathfinder** (calculates all reachable hexes within a squad's remaining AP and finds lowest-cost paths via weighted A*), and a **spatial utility layer** (hex distance and line-of-sight checks consumed by Combat Resolution, Facing & Flank, Fog of War, and Tactical AI). Each squad begins its turn with an AP budget derived from its officer's LDR stat and unit type; the player moves squads during the Movement Phase and attacks during the Combat Resolution Phase — movement and combat are separate phases so squads can both move and attack on the same turn. Beyond player-driven movement, this system owns **routing pathfinding** for BROKEN squads (auto-moved toward the nearest map edge during the Routing Resolution Phase). It also establishes the canonical **cube coordinate system** — the shared spatial language for the entire tactical layer. Without this system, no tactical system can answer "can that unit reach this hex?", "is that target in range?", or "is there line of sight?".

## Player Fantasy

The fantasy is **reading the map before committing**. The player selects a squad and the hex grid responds: reachable hexes light up, costs are visible, and the path calculates in real time as the cursor moves. Before clicking, the player knows exactly where this squad can go. The decision isn't "can I reach that?" — the system answers that — the decision is "should I go there?" That clarity is what makes positioning strategic: the player chooses positions with intent, not with uncertainty.

The inverse is also real: the feeling of *just barely out of reach*. An enemy squad sits one hex beyond the movement range. The player scans the map — is there a road that could save a step? Could the squad skip attacking this turn and push that extra hex now? The AP budget is always visible and legible, making these micro-decisions feel like genuine tactical choices rather than arbitrary constraints.

The second fantasy is **the march itself**: squads moving across seasonal terrain, tracing paths through forest and over hills, responding to terrain visually. Movement is not teleportation — the squad travels through intermediate hexes, and the path it takes is visible and meaningful. A squad that marched through a forest to reach a flanking position *arrived there from a direction the enemy couldn't fully anticipate*.

This directly serves **P1 (Victory Through Preparation)**: movement range is finite and terrain costs are known in advance, so the player who studied the map's topology before the battle begins arrives where they need to be. **P3 (Grounded, Barely Fantastic)**: armies marched; march speed was governed by road quality, weather, and terrain. That grounding makes the tactical layer believable.

## Detailed Design

### Core Rules

**Coordinate System (Canonical):**
All hex positions use cube coordinates (q, r, s) where q + r + s = 0. The 6 neighbor direction vectors [0–5] clockwise from East are defined in the Facing & Flank GDD and are the shared convention for all tactical systems. This GDD establishes those conventions as canonical.

**Turn Phase Integration:**
The system participates in two turn phases each round:
1. **Movement Phase** — player-controlled: select squad → choose destination → squad moves
2. **Routing Resolution Phase** — automated: BROKEN squads auto-move toward nearest map edge

**Action Point Budget:**
Each squad has an AP pool that resets at the start of the Movement Phase. AP is consumed by movement; unused AP is lost at turn end. The AP pool is derived from the officer's LDR stat and unit type (see Formulas). Movement and attacks are separate phases — a squad can both move and attack in the same turn.

**Movement Execution:**
1. Player selects a squad → system flood-fills from the squad's position and highlights all hexes reachable within remaining AP
2. Player hovers over a destination hex → system calculates and previews the least-cost path in real time
3. Player clicks the destination → squad moves along the path; AP is deducted per hex; `moved_this_turn = true`; `facing_direction` updates to the direction of the last step
4. Player may stop early (partial movement) — remaining AP is unused and lost at phase end
5. A squad may NOT move again after stopping (one move action per turn)

**Movement Costs:**
Per hex entered, AP cost = `terrain.movement_cost(hex, season)` from the Terrain System:
- Road / Village: 1 AP (all seasons)
- Open Field: 1 AP (Dry/Harvest), 2 AP (Wet)
- Hill / Forest: 2 AP (Dry/Harvest), 3 AP (Wet)
- Ford: 2 AP — squad acquires `crossed_ford_this_turn = true`
- Bridge: 1 AP — no penalty flag
- Direct river hex: impassable — excluded from pathfinding graph

**Ford Crossing:**
A squad crossing a ford pays 2 AP and acquires `crossed_ford_this_turn = true`. Combat Resolution reads this flag to apply a −20% defense penalty for the remainder of that turn. The flag clears at the start of the squad's next turn. A squad cannot begin a ford crossing unless it has ≥ 2 AP remaining.

**Hex Occupancy:**
At most one squad may occupy a hex at any time (friendly or enemy). Pathfinding treats all occupied hexes as impassable — a squad cannot stop at or pass through an occupied hex.

**Hex Distance:**
```
hex_distance(a, b) = max(|qa - qb|, |ra - rb|, |sa - sb|)
```
Chebyshev distance on cube coordinates. Used by ranged range checks, vision radius, and morale aura radius.

**Line of Sight (LOS):**
`has_line_of_sight(attacker_hex, target_hex) → bool` is computed via hex-grid ray from attacker center to target center. LOS is **blocked** by Forest and Village hexes on the ray path. LOS is **not blocked** by Open Field, Road, Hill, or River hexes. The attacker's own hex and the target hex are excluded from the blocking check. Ray-through-corner ambiguity resolves in favor of LOS. Used by Combat Resolution for ranged attack validation and by Fog of War for vision range.

**Routing Movement (BROKEN Squads):**
When a squad transitions to BROKEN state, Morale System signals routing intent. Hex Movement sets `routing_target` to the nearest map edge hex by `hex_distance`. Each Routing Resolution Phase, the routing squad moves toward its target using its full AP pool, respecting terrain costs and hex occupancy. Routing squads cannot receive player orders. See Morale GDD §Edge Cases for the 3-turn timeout fallback if routing is permanently blocked.

---

### States and Transitions

Per-squad state managed by this system:

| Field | Type | Persistence | Description |
|---|---|---|---|
| `position` | Vector3i (q, r, s) | Permanent | Current hex; updated on move |
| `ap_remaining` | int | Per-turn | AP left this turn; resets to `ap_pool` at Movement Phase start |
| `moved_this_turn` | bool | Per-turn | True if any movement occurred; read by Facing & Flank |
| `crossed_ford_this_turn` | bool | Per-turn | True if squad crossed a ford; drives Combat Resolution defense penalty |
| `routing_target` | Vector3i or null | While BROKEN | Nearest map edge hex; set on BROKEN, cleared on exit |

**Transitions:**

| Event | Effect |
|---|---|
| Movement Phase starts | `ap_remaining = ap_pool`, `moved_this_turn = false`, `crossed_ford_this_turn = false` |
| Squad moves N hexes | `ap_remaining -= sum(terrain costs)`, `moved_this_turn = true`, `facing_direction` updated |
| Ford crossed | `crossed_ford_this_turn = true` |
| Squad enters BROKEN | `routing_target` set to nearest map edge hex |
| Routing squad reaches map edge | Squad removed from map; `routing_target` cleared; campaign recovery begins |

---

### Interactions with Other Systems

| System | This System Reads | This System Writes |
|---|---|---|
| **Terrain** | `movement_cost(hex, season)` → int; impassable checks | — |
| **Officer Stats** | `officer.ldr()` for AP pool formula | — |
| **Facing & Flank** | — | `squad.moved_this_turn`, `squad.facing_direction` (per-move), squad `position` |
| **Combat Resolution** | — | `hex_distance(a, b)` → int; `has_line_of_sight(a, b)` → bool |
| **Morale System** | `squad.morale_state == BROKEN` (triggers routing setup) | Squad `position` (routing movement each Routing Phase) |
| **Fog of War** | — | `hex_distance(a, b)`, `ray_cast_los(a, b)` LOS primitive |
| **Tactical AI** | — | `reachable_hexes(squad)` → set; `pathfind(from, to)` → path |
| **Tactical HUD** | — | `reachable_hexes(squad)` (movement overlay); path preview on hover |

## Formulas

### F-1: AP Pool per Turn

```
ap_pool = min(base_ap[unit_type] + floor((ldr - 1) / 34), max_ap[unit_type])
```

| Symbol | Type | Range | Description |
|---|---|---|---|
| `unit_type` | enum | {INF, LI, CAV, ART} | Unit classification of the squad |
| `base_ap[unit_type]` | int | {INF=3, LI=4, CAV=5, ART=2} | Base AP before officer bonus |
| `ldr` | int | [1, 100] | Commanding officer's Leadership stat |
| `ap_bonus` | int | [0, 2] | `floor((ldr-1)/34)`: LDR 1–34 → 0, 35–67 → 1, 68–100 → 2 |
| `max_ap[unit_type]` | int | {INF=5, LI=6, CAV=7, ART=4} | Hard cap; prevents LDR growth from overflowing |
| `ap_pool` | int | [2, 7] | AP budget for this turn |

**Output range:** [2 (ART, LDR 1), 7 (CAV, LDR 68+)].

**Worked examples:**
- Kaster (LDR 96) commanding CAV: `floor(95/34) = 2`; `min(5+2, 7) = **7 AP**`
- Thane (LDR 50) commanding INF: `floor(49/34) = 1`; `min(3+1, 5) = **4 AP**`
- Generic recruit (LDR 20) commanding ART: `floor(19/34) = 0`; `min(2+0, 4) = **2 AP**`

**Balance note:** Dry Road: ART (max 4 AP) covers 4 hexes vs. CAV (max 7 AP) covers 7. Wet Forest (3 AP/hex): ART enters 1 hex; CAV enters 2. The gap is large enough to create distinct tactical roles without a separate move-order system.

---

### F-2: Per-Hex Movement Cost (Terrain Delegation)

```
hex_ap_cost = terrain.movement_cost(hex, season)
```

Fully delegated to the locked Terrain API. Returns a positive integer in [1, 3] — never 0 (no infinite-loop risk in flood fill) and never fractional.

| Terrain | Dry/Harvest | Wet |
|---|---|---|
| Road, Village | 1 | 1 |
| Open Field | 1 | 2 |
| Hill, Forest | 2 | 3 |
| Ford | 2 | 2 |
| Bridge | 1 | 1 |
| River (direct) | impassable | impassable |

---

### F-3: Hex Distance

```
hex_distance(a, b) = max(|qa - qb|, |ra - rb|, |sa - sb|)
```

| Symbol | Type | Description |
|---|---|---|
| `qa, ra, sa` | int | Cube coordinates of hex A (q+r+s = 0) |
| `qb, rb, sb` | int | Cube coordinates of hex B |
| result | int | Chebyshev distance in hexes |

**Output range:** [0, map_diameter]. Used by: ranged range checks, LOS, morale aura radius, routing target selection.

---

### F-4: Reachable Hexes (Dijkstra Flood Fill)

```
reachable_hexes(squad, ap_budget) → set<hex>:
  dist[source] = 0
  priority_queue.push(source, 0)
  while queue not empty:
    hex = queue.pop_min()
    for each neighbor of hex:
      if neighbor is occupied: skip          # cannot pass through OR stop at
      if terrain.is_impassable(neighbor): skip
      cost = dist[hex] + terrain.movement_cost(neighbor, season)
      if cost ≤ ap_budget AND cost < dist.get(neighbor, ∞):
        dist[neighbor] = cost
        queue.push(neighbor, cost)
  return { hex : dist[hex] ≤ ap_budget }
```

| Symbol | Type | Range | Description |
|---|---|---|---|
| `ap_budget` | int | [2, 7] | Squad's remaining AP this turn |
| `dist[hex]` | int | [0, ap_budget] | Minimum AP cost to reach this hex |
| result | set | [0, ~49 hexes] | All hexes reachable within budget |

**Critical rule:** Occupied hexes are excluded as both traversal nodes and destinations — a squad cannot route through any other unit's hex.

---

### F-5: Pathfinding (Weighted A*)

```
pathfind(from, to, ap_remaining) → list<hex>:
  h(n) = hex_distance(n, to)      # Chebyshev — admissible heuristic
  g(n) = cumulative terrain cost from source
  f(n) = g(n) + h(n)
  blocked: occupied hexes, impassable terrain
  if total_cost(path) ≤ ap_remaining: return path
  else: return []
```

| Symbol | Type | Range | Description |
|---|---|---|---|
| `g(n)` | int | [0, ap_remaining] | Actual cumulative AP cost to node n |
| `h(n)` | int | [0, hex_distance(from,to)] | Chebyshev heuristic; admissible because min terrain cost = 1 |
| result | list | length 0 or 1–N | Ordered hexes from `from` to `to`; empty if unreachable within budget |

**Admissibility:** `h(n) ≤ actual cost` always holds since min terrain cost is 1 AP/hex. **Note:** In wet heavy-terrain, `h(n)` may underestimate by up to 3×, increasing node expansions — correct and fast at 300-node map scale.

**Worked example:** CAV at (0,0,0), target at (4,−2,−2), `ap_remaining = 7`. Road path cost: `g(target) = 4 ≤ 7`. Path returned.

---

### F-6: Line of Sight (Cube Lerp)

```
has_line_of_sight(a, b) → bool:
  N = hex_distance(a, b)
  if N == 0: return true
  for i in 1 to N-1:              # excludes source and target hexes
    t = float(i) / float(N)
    mid = cube_round(lerp(a, b, t))
    if terrain.is_los_blocking(mid): return false
  return true
```

**Blocking terrain:** Forest, Village. **Non-blocking:** Open Field, Road, Hill, River.

| Symbol | Type | Range | Description |
|---|---|---|---|
| `N` | int | [0, map_diameter] | Hex distance; lerp step count |
| `t` | float | (0.0, 1.0) exclusive | Endpoints excluded — own hex and target hex are never blocking |
| result | bool | {true, false} | Whether unobstructed LOS exists |

**Corner ambiguity rule:** When `cube_round` is equidistant between two hexes, resolve in favor of LOS (neither hex treated as blocking). This is a deliberate player-friendly design choice — do not treat it as a bug in implementation.

---

### F-7: Routing Target Selection

```
routing_target(squad_position) → hex:
  candidates = all map-edge hexes
  return argmin_{h in candidates} hex_distance(squad_position, h)
  tiebreak: lowest q coordinate
```

| Symbol | Type | Description |
|---|---|---|
| `squad_position` | Vector3i | Current hex of the BROKEN squad |
| candidates | set | All hexes where q=q_min, q=q_max, r=r_min, or r=r_max |
| result | hex | Routing destination — nearest map edge by Chebyshev distance |

**Known behavior:** If the nearest edge hex is isolated behind an impassable river with no ford, the routing squad will approach it each turn until blocked, then be removed by the 3-turn routing timeout (see Morale GDD §Edge Cases). This is correct behavior — surface it in UI as "routing timeout" not "pathfinding error."

## Edge Cases

**E-1: Ford with insufficient AP.**
A squad with ≤ 1 AP remaining cannot begin a ford crossing (cost = 2 AP). The ford hex is excluded from the reachable-hexes flood fill at that AP level. The player cannot select it as a destination.

**E-2: ART in Wet Forest or Wet Hill.**
With base 2 AP and no LDR bonus, ART cannot enter a Wet Forest or Wet Hill hex (cost = 3 AP > 2). ART with a strong officer (LDR 68+, max_ap = 4) can enter but only if it starts adjacent (3 AP cost leaves 1 AP remaining, still a legal move). Artillery is effectively road-bound in rainy seasons with average officers — this is intentional and historically grounded.

**E-3: Destination path blocked by occupied hex.**
A* routes around occupied hexes. If no path exists within `ap_remaining` that avoids occupied hexes, the destination hex returns an empty path — the player cannot move there this turn. The reachable-hexes overlay correctly excludes these destinations.

**E-4: Two routing squads targeting the same edge hex.**
Each routing squad selects its routing_target independently. If two broken squads target the same edge hex and the first arrives, the second can no longer stop there (occupancy rule). The second pathfinds toward the same target hex but stops one hex short, then re-pathfinds next turn. If the first squad has exited the map, the second can enter freely. If neither can exit, both count toward the 3-turn routing timeout independently.

**E-5: Routing squad already on a map edge hex.**
`hex_distance` to the nearest edge = 0. Treat this as "routing target is current hex" and immediately remove the squad from the map at the start of the Routing Resolution Phase — no movement required.

**E-6: LOS at range 1 (adjacent hexes).**
`N = 1`. The loop `for i in 1 to N-1` iterates from 1 to 0 — zero iterations. LOS is always `true` at range 1 regardless of terrain. Adjacent squads always have LOS to each other; a squad in a Village or Forest can always be targeted by an adjacent attacker. This is intentional.

**E-7: LOS from inside a Forest hex.**
The source hex is excluded from the blocking check (`for i in 1 to N-1` excludes i=0). A squad inside a Forest can see out. The forest they occupy does not block their own sightlines. The Facing & Flank forest ambush rule is a separate mechanic — it does not interact with LOS.

**E-8: LOS ray through map boundary.**
If the ray path passes through a hex outside the map bounds, that hex is treated as non-blocking (it cannot be a Forest or Village — it doesn't exist). No out-of-bounds access.

**E-9: BROKEN squad with all neighbors blocked (stuck routing squad).**
If the routing squad cannot move on a given turn (all reachable neighbors are occupied or impassable), it stays in place and that turn counts toward the 3-turn routing timeout. On the 3rd such turn, the squad is removed from the map regardless of position (see Morale GDD §Edge Cases). This prevents permanent deadlock.

**E-10: Officer replaced mid-battle.**
If a commanding officer is wounded or killed and replaced during battle, `ap_pool` is recalculated at the start of the next Movement Phase (when `ap_remaining` resets). There is no mid-turn recalculation — the current turn's AP budget does not change.

**E-11: Squad attempts to move after already moving this turn.**
`moved_this_turn = true` once any movement occurs. The system rejects further move commands for that squad until the next turn's Movement Phase reset. The squad can still be selected (to show its stats) but the movement overlay is hidden and no destination is selectable.

**E-12: Zero-AP squad selected.**
If a squad's `ap_remaining = 0` at the start of the Movement Phase (extremely rare — possible only if a future system drains AP before movement), the flood fill returns an empty reachable set. The movement overlay is not displayed. The squad can be selected but cannot move.

## Dependencies

### Upstream (systems this GDD depends on)

| System | What This System Reads | Interface |
|---|---|---|
| **Terrain System** | Movement cost per hex per season; impassable flags; LOS-blocking flags | `terrain.movement_cost(hex, season)` → int; `terrain.is_impassable(hex)` → bool; `terrain.is_los_blocking(hex)` → bool |
| **Officer Stats System** | Officer LDR stat for F-1 AP pool formula | `officer.ldr()` → int [1, 100] |

> **Backfill note:** The Terrain GDD's Dependencies section was authored before this system existed — it does not list Hex Movement as a downstream consumer. Update `design/gdd/terrain-system.md §Dependencies` to add: "Hex Movement System reads `movement_cost(hex, season)`, `is_impassable(hex)`, and `is_los_blocking(hex)`." Similarly, the Officer Stats GDD should list this system as a consumer of `ldr()`.

### Downstream (systems that depend on this GDD)

| System | What It Reads From This System |
|---|---|
| **Facing & Flank System** | `squad.moved_this_turn` (bool, per-turn); `squad.facing_direction` (int [0–5], updated each move step); squad `position` (Vector3i) |
| **Combat Resolution System** | `hex_distance(a, b)` → int (ranged range check); `has_line_of_sight(a, b)` → bool (ranged attack validation) |
| **Morale System** | Squad `position` (updated during routing); routing ownership: Hex Movement executes BROKEN squad auto-movement when signaled by Morale |
| **Fog of War / Vision System** | `hex_distance(a, b)` → int (vision radius check); `ray_cast_los(a, b)` → bool (LOS primitive) |
| **Tactical AI System** | `reachable_hexes(squad)` → set (AI move planning); `pathfind(from, to)` → list (AI route execution) |
| **Tactical HUD** | `reachable_hexes(squad)` → set (movement overlay); `pathfind(from, to)` → list (cursor-hover path preview) |

### Cross-System State Ownership

| Field | Owned By | Read By |
|---|---|---|
| `squad.position` | Hex Movement | All spatial systems |
| `squad.ap_remaining` | Hex Movement | Tactical HUD (display only) |
| `squad.moved_this_turn` | Hex Movement | Facing & Flank |
| `squad.crossed_ford_this_turn` | Hex Movement | Combat Resolution |
| `squad.routing_target` | Hex Movement | Morale (routing status queries) |
| `squad.facing_direction` | Hex Movement writes on move; Facing & Flank owns the calculation | Combat Resolution (flank check) |

## Tuning Knobs

| Knob | Current Value | Safe Range | Gameplay Effect |
|---|---|---|---|
| `base_ap[INF]` | 3 | [2, 5] | Lower: infantry more positional, slower redeployment. Higher: more fluid lines, reduces positional commitment |
| `base_ap[LI]` | 4 | [3, 5] | Lower: closes gap with regular infantry. Higher: skirmishers dominate open-field repositioning |
| `base_ap[CAV]` | 5 | [4, 7] | Lower: cavalry less dominant as flanking threat. Higher: cavalry hard to contain once loose |
| `base_ap[ART]` | 2 | [1, 3] | Lower: artillery nearly immobile (accurate but situational). Higher: artillery repositions mid-battle |
| `max_ap[INF]` | 5 | [4, 6] | Hard cap; clamps officer LDR bonus |
| `max_ap[LI]` | 6 | [4, 7] | Hard cap; ensures LI stays faster than INF |
| `max_ap[CAV]` | 7 | [5, 9] | Hard cap; prevents cavalry from crossing the full map in one turn |
| `max_ap[ART]` | 4 | [2, 5] | Hard cap; at 4 ART remains road-dependent in Wet season |
| `ldr_ap_divisor` | 34 | [25, 50] | Controls how much officer LDR matters for movement speed. Lower = LDR matters more (high-LDR officers give bigger advantage). 34 yields a clean +0/+1/+2 breakpoint across LDR 1–100 |
| `los_blocking_terrain` | [Forest, Village] | — | Add Hill to reduce long-range ranged dominance. Remove Village to open urban sightlines. Affects ranged combat viability and fog of war |
| `los_corner_favor` | favor LOS (true) | [true, false] | `true` = attacker-friendly; marginal LOS resolves in attacker's favor. `false` = defender-friendly; corner ambiguity blocks LOS |

**Note:** Terrain movement costs (Road=1, Forest=2, Hill=2, wet multiplier=1.5) are owned by the Terrain System and locked in the entity registry. Any change to terrain costs must go through the Terrain GDD. The routing timeout (3 turns) is owned by the Morale GDD.

## Visual/Audio Requirements

### Visual

- **Movement overlay**: When a squad is selected, all reachable hexes within `ap_remaining` are highlighted with a team-color fill (semi-transparent) and a solid border. Hexes just out of range (reachable next turn if the squad doesn't attack) may be shown at reduced opacity as a secondary ring — optional, configurable.
- **Path preview**: As the cursor moves across the hex grid, a line traces the A* path from the squad to the hovered hex in real time. The destination hex shows the AP cost in a small label (e.g., "−3 AP"). Hexes along the path are highlighted in sequence.
- **Out-of-range indicator**: Hexes beyond AP budget are dimmed or greyed while a squad is selected, distinguishing them from the reachable set.
- **Squad movement animation**: The squad sprite travels hex by hex along the confirmed path — not a teleport. Speed is configurable; the march should feel deliberate, not instant.
- **Ford crossing visual**: A water-ripple or shimmer effect on the squad sprite while `crossed_ford_this_turn = true` (lasts the remainder of the turn to signal vulnerability).
- **Routing movement**: BROKEN squads move with a distinct animation (scattered, not ordered march) and a visible routing icon (e.g., downward arrow or white flag). Routing path is shown as a dashed line, not the normal solid preview.
- **AP counter on unit**: A small AP indicator (e.g., pip dots or a number) visible on the selected unit's sprite or info card showing `ap_remaining / ap_pool`.

### Audio

- **Movement confirmed**: A satisfying "step" or "march begins" sound cue when the player clicks to confirm a destination.
- **Footsteps/hoofbeats**: INF plays marching boots; LI plays lighter footsteps; CAV plays hoofbeats; ART plays rumbling wheels. Sounds play as the squad moves hex to hex.
- **Ford crossing**: Water splash sound as the squad enters the ford hex.
- **Invalid destination click**: A soft rejection sound (no move initiated) when the player clicks an impassable or out-of-range hex.
- **Routing movement**: A distinct "retreat" audio cue (shouted commands, panicked cadence) when a BROKEN squad auto-moves during the Routing Resolution Phase — clearly different from player-ordered movement.

## UI Requirements

- **Squad selection**: Clicking a friendly squad during the Movement Phase selects it, displays the movement overlay, and begins path preview mode. Clicking elsewhere or pressing ESC deselects.
- **Destination selection**: Clicking a highlighted (reachable) hex confirms the move. The squad begins moving immediately. No confirmation dialog — single click executes.
- **Invalid click handling**: Clicking an impassable or out-of-range hex does nothing (no error state, no deselection). Clicking an occupied hex deselects the current squad and selects the unit at that hex if friendly.
- **No take-back**: Once the squad begins moving, the action cannot be undone. The game does not offer an undo button for completed moves — this is intentional (P1: commitment is meaningful).
- **Path cost display**: The hovered destination hex shows the total AP cost of the path in a tooltip or small label. If the path costs more AP than available, the hex is not selectable.
- **AP display**: The selected squad's current `ap_remaining` and `ap_pool` are visible in the unit info panel at all times during the Movement Phase.
- **Terrain cost on hover**: Hovering over any hex during a squad's selection shows that hex's terrain movement cost for the current season (e.g., "Forest — 3 AP (Wet)").
- **Routing state display**: BROKEN squads display a routing indicator in the unit list and on-hex. The player cannot click a routing squad to command it; clicking it shows its current routing state and estimated turns until map exit.
- **Keyboard navigation**: All movement actions are accessible via keyboard (select squad via Tab/number key, confirm destination via Enter, cancel via ESC). Required per platform UX standards.

## Acceptance Criteria

### AP Pool Formula

1. **Base value, no bonus (LDR 1–34).** INF squad with LDR 20: `ap_pool = min(3 + floor(19/34), 5) = 3`.
2. **LDR bonus tier 1 (LDR 35–67).** INF squad with LDR 50: `ap_pool = min(3 + floor(49/34), 5) = 4`.
3. **LDR bonus tier 2 (LDR 68–100).** CAV squad with LDR 96: `ap_pool = min(5 + floor(95/34), 7) = 7`.
4. **Hard cap enforced at maximum LDR.** CAV squad with LDR 100: result is `min(5+2, 7) = 7`, not 8.
5. **ART at minimum LDR.** ART with LDR 1: `ap_pool = min(2 + floor(0/34), 4) = 2`.
6. **ART hard cap at LDR 80.** `min(2+2, 4) = 4` — cap holds.
7. **LDR boundary: 34 vs. 35.** LDR 34 → `ap_pool = 3` (bonus = 0). LDR 35 → `ap_pool = 4` (bonus = 1). Boundary is inclusive at 35.

### AP Reset and State Flags

8. **All per-turn fields reset at Movement Phase start.** A squad that ended the previous turn with `ap_remaining = 0`, `moved_this_turn = true`, and `crossed_ford_this_turn = true` has all three reset to `ap_pool`, `false`, `false` before any player action on the new turn.

### Reachable Hexes

9. **Flood fill boundary at exact AP budget.** INF with `ap_pool = 3` on uniform Open Field (Dry): every hex with minimum path cost = 3 is included; no hex costing > 3 is included.
10. **Occupied hex excluded from flood fill as both stop point and traversal node.** INF with `ap_pool = 4`, friendly squad one hex east, unoccupied hex two hexes east reachable only through the occupied hex: neither hex appears in the result set.
11. **Impassable river hex excluded regardless of AP.** River hex (no ford/bridge) is absent from reachable set regardless of remaining AP.

### Pathfinding (A*)

12. **Valid path returned with correct cost.** CAV at A, `ap_remaining = 7`, Road path to B 4 hexes away: `pathfind(A, B, 7)` returns 4-hex ordered path with cumulative cost 4.
13. **Returns empty when destination exceeds AP budget.** INF with `ap_remaining = 2`, destination requiring minimum 3 AP: `pathfind` returns `[]`.
14. **Routes around blocked hex.** Direct 1-hex path blocked by occupied unit; alternate 2-hex path costs 2 AP within budget: `pathfind` returns the 2-hex detour.

### Ford Crossing

15. **AP cost deducted and flag set.** Squad with `ap_remaining = 3` moves onto Ford: `ap_remaining` decreases to 1, `crossed_ford_this_turn = true`, position is the ford hex.
16. **Blocked at insufficient AP.** Squad with `ap_remaining = 1` adjacent to Ford: ford hex absent from reachable set.
17. **Flag clears on next turn start.** Squad with `crossed_ford_this_turn = true` at turn end: flag is `false` after Movement Phase reset, regardless of whether the squad moves again.

### Hex Occupancy

18. **Cannot stop at occupied hex.** Occupied destination hex absent from reachable set; player cannot select it.
19. **Cannot pass through occupied hex.** Only path to destination passes through an occupied hex; no alternate path within `ap_remaining`: `pathfind` returns `[]`.

### Move Execution State

20. **`moved_this_turn` set after any movement.** Squad moves one hex: `moved_this_turn = true` immediately after move completes.
21. **`facing_direction` set to direction of last step.** Multi-hex path ending North-East: `facing_direction = 5` (NE index) regardless of earlier steps.
22. **Cannot move twice in one turn.** Squad with `moved_this_turn = true`: movement overlay not displayed, no destination selectable until next turn reset.

### Hex Distance

23. **Adjacent hex returns 1.** A=(0,0,0), B=(1,−1,0): `hex_distance = 1`.
24. **Two-step path returns 2.** A=(0,0,0), C=(2,−1,−1): `hex_distance = max(2,1,1) = 2`.

### Line of Sight

25. **Blocked by Forest on intermediate hex.** A to B (distance 3), Forest at first intermediate lerp position: `has_line_of_sight = false`.
26. **Blocked by Village on intermediate hex.** A to B (distance 2), Village as sole intermediate hex: `has_line_of_sight = false`.
27. **Hill on intermediate hex does not block.** A to B (distance 3), only Hill on ray path: `has_line_of_sight = true`.
28. **Range 1 always passes.** A to adjacent Forest hex B (distance 1): `has_line_of_sight = true` — loop iterates zero times.
29. **Source hex terrain does not block.** Attacker inside Forest A, no Forest or Village on intermediate positions to B (distance 2): `has_line_of_sight = true`.

### Routing

30. **Nearest edge hex selected as routing target.** BROKEN squad at (3,−1,−2): `routing_target` is the map-edge hex with minimum Chebyshev distance; ties broken by lowest q coordinate.
31. **Squad auto-moves toward routing target each Routing Phase.** BROKEN squad moves along least-cost A* path toward `routing_target` using full `ap_pool`; player input has no effect.
32. **Squad removed from map on reaching edge hex.** BROKEN squad's path reaches `routing_target` within AP: squad removed from tactical map, campaign recovery data recorded, `routing_target` cleared.
33. **Three consecutive blocked Routing Phases trigger removal.** Squad unable to move for 3 Routing Phases in a row (all neighbors blocked): removed from map after third phase; campaign recovery data recorded.
34. **Squad already at map edge removed immediately.** `hex_distance` from current position to nearest edge = 0: squad removed at start of first Routing Resolution Phase, no movement occurs.

### ART Terrain Constraint

35. **ART recruit cannot enter Wet Forest.** ART with LDR 1–34 (`ap_pool = 2`) in Wet season: Forest hex cost = 3 AP > 2; Forest hex absent from reachable set.

## Open Questions

1. **Hex grid visual orientation (flat-top vs. pointy-top).** This GDD defines direction 0 = East = (+1,−1,0) but does not specify whether the screen renders hexes as flat-top or pointy-top. The choice affects the pixel-to-cube mapping function and the visual direction of the East vector. Confirm before implementing the pathfinding display layer. *Decision belongs to: Tactical HUD / Technical Director.*

2. **Vision range ownership.** This system provides `hex_distance` and `ray_cast_los` as spatial primitives. The actual vision range (how many hexes a squad can see) is not specified here — it depends on officer INT stat, terrain, and season. Should vision range be calculated inside this system's spatial utility layer, or owned entirely by the Fog of War system (using this system's primitives)? Current recommendation: Fog of War owns vision range parameters; Hex Movement provides primitives only. *Confirm when `fog-of-war.md` is authored (design order #7).*

3. **Routing movement and friendly pass-through.** Current rule: routing squads cannot pass through occupied hexes (same rule as player-controlled movement). An alternative is that routing squads can pass through — but not stop in — friendly-occupied hexes, representing a unit breaking through its own lines in panic. This would reduce routing-squad oscillation but change the spatial feel. *Flag for playtesting before finalizing.*

4. **Bridge vs. Ford as terrain subtypes.** The Terrain GDD was authored before this system. It specifies River as an impassable terrain with ford and bridge as crossing options, but does not clarify whether Bridge and Ford are separate terrain types or attributes of the River type. The movement cost formula depends on `terrain.movement_cost(hex, season)` returning 2 for ford and 1 for bridge. Confirm the Terrain API returns distinct values for these. *Review `design/gdd/terrain-system.md §Detailed Rules` and update if needed.*

5. **Partial movement visual affordance.** When a player stops a squad short of maximum AP range, unused AP is lost. Should the UI warn the player before confirming ("You have 2 AP remaining — are you sure?") or should the design stay silent? Warning reduces accidental AP waste but adds friction. *Decision belongs to: UX Designer.*
