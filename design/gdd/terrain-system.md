# Terrain System

> **Status**: In Design
> **Author**: Game Designer
> **Last Updated**: 2026-06-12
> **Implements Pillar**: P1 — Victory Through Preparation + P3 — Grounded, Barely Fantastic
> **Review Mode**: Lean

---

## Overview

The Terrain System defines every explorable tile in the game world — its type (forest, hill, river, village, field, road), its movement cost, its combat modifiers, and its seasonal appearance. At the data level, Terrain is a spatial map: a hex grid populated with tile types, each type carrying numeric properties (movement cost, cover value, fire spread rate) that feed into Hex Movement, Combat Resolution, Fire System, and Campaign Map AI. At the player level, Terrain is the *first intelligence layer* — before any UI label, before any stat comparison, the player reads the battlefield's topology and anticipates advantages and risks. Terrain forces the core decision loop: "Do I have the right officer and squad composition to win *on this ground*?" Seasonal terrain variants (Dry/Wet/Harvest) are not cosmetic; they structurally change movement costs, unit capability, and tactical viability, requiring the player to adapt strategy between acts.

---

## Player Fantasy

**The fantasy is *reading the ground before committing*.** A player surveys a hex grid and instantly understands the battlefield topology: "that hill gives my archer advantage, the river bottleneck forces the enemy into a killzone, the forest is impassable this season." Terrain is not a hindrance to overcome; it is the *primary variable* the player reads to decide where to position units and which officers to deploy. The second layer is the *feeling of seasonal consequence* — when the Dry season arrives, the player feels the dry grass beneath their feet and knows fire will spread. When rains come, roads become rutted and movement slows. Terrain is not a static backdrop; it is a dynamic, readable, consequential *opponent* that shapes every tactical decision. The fantasy is: "I studied the ground, I chose correctly, and my understanding of this terrain is why I won."

---

## Detailed Design

### Core Rules

**Terrain Types and Movement Cost:**

The hex grid is populated with six terrain types. Each type has a **movement cost** (in action points per hex crossed) and **combat modifiers**:

| Terrain Type | Base Movement Cost | Seasonal Variant | Combat Effect | Flammable |
|---|---|---|---|---|
| Road | 1 AP | No change | None | No |
| Open Field | 1 AP | Dry/Wet/Harvest | None | Yes (Dry only) |
| Hill | 2 AP | +50% in Wet | Ranged +25%, Melee -10% | No |
| Forest | 2 AP | +50% in Wet | Cover (Ranged -25%), Ambush bonus | No |
| Village/Settlement | 1 AP | No change | Defense +15% (buildings) | No |
| River | Impassable* | Harder in Wet | — | No |

*River crossing available only at **Fords** (2 AP) or **Bridges** (1 AP). Attempting to cross elsewhere = impassable.

**Movement Mechanics:**
- A squad has a base movement pool (determined by LDR stat and unit type)
- Each hex crossed costs AP according to the terrain type
- A squad's turn ends when AP is exhausted or player chooses to stop
- Diagonal hexes count as single-hex movement (standard hex-grid rule)

**Seasonal Structure:**
- **Dry Season** (Act I–II): terrain movement costs normal; open fields are flammable (fire spreads 1 hex/turn with Wind direction modifier)
- **Wet Season** (Act II–III): all terrain +50% movement cost (muddy, rutted, waterlogged); river crossings require 3 AP at fords, 2 AP at bridges; fire does not spread (water quenches)
- **Harvest Season** (Act III–IV): movement costs normal; open fields provide supply storage bonus (settlements in harvest fields +25% supply faucet)

**Visibility and Cover:**
- **Hill**: increases vision range by 1 hex; ranged units on hills gain +25% damage vs. targets below
- **Forest**: provides **cover** — ranged attackers targeting units in forest suffer -25% damage; units in forest can **ambush** (gain +30% flanking bonus when attacking units entering the hex)
- **Village**: buildings provide **defense** — defenders in village gain +15% defense until they move out; ranged attackers at -15% damage when targeting village hexes

**River Ford and Bridge Rules:**
- **Fords** (shallow crossings): 2 AP to cross; unit is vulnerable mid-crossing (-20% defense while crossing); crossing takes 1 turn minimum
- **Bridges** (built structures): 1 AP to cross; no vulnerability penalty; can cross in a single action
- A squad occupying a bridge/ford hex cannot be dislodged by ranged attacks (bridges provide cover equivalent to village)

---

### States and Transitions

Terrain does not have states in the traditional sense. Each hex maintains a persistent **terrain type** and **seasonal state** (determined by the Campaign Layer's current season). 

**State change**: Only the **seasonal state** changes, at act transitions. When a new act begins, all terrain types remain the same; only their **movement costs and flammability** change per the seasonal modifier table above. This is a data mutation (seasonal_state = "Wet"), not a state machine transition.

Example: A Forest hex remains Forest across Dry→Wet→Harvest. Its movement cost shifts 2 AP → 3 AP (2 × 1.5) during Wet season, then reverts to 2 AP in Harvest.

---

### Interactions with Other Systems

| Dependent System | Reads | Purpose | Data Flow |
|---|---|---|---|
| Hex Movement | Terrain type, movement cost, seasonal modifier | Calculate movement pool consumption per hex | `terrain.movement_cost(season)` → int |
| Combat Resolution | Terrain type (hill, forest, village) | Modifier to ranged/melee damage, defender defense bonus | `terrain.ranged_modifier()`, `terrain.defense_bonus()` |
| Fire System | Terrain type, season state | Identify flammable hexes (fields in Dry season); spread fire to adjacent flammable hexes | `terrain.is_flammable(season)` → bool |
| Fog of War / Vision | Terrain type (hill raises vision) | Hill hexes increase vision range; forests and villages block vision | `terrain.vision_modifier()` → int |
| Campaign Map UI | Terrain type, season state | Display map tiles with seasonal visual variants; show movement costs | `terrain.display_asset(season)` → asset_path |
| Campaign Map AI | Terrain type, movement cost | Factor terrain difficulty into march route calculation and position scoring | `terrain.movement_cost()` |
| Morale System | Terrain type (village, forest) | Forest ambush (morale penalty for surprised units); village defense (morale bonus) | Indirect via Combat Resolution modifiers |

**Data Contract:**
- All dependent systems read terrain properties by hex coordinate
- No system modifies terrain state (except Campaign Layer applying seasonal transitions)
- Terrain is immutable during active gameplay within an act

---

## Formulas

### 1. Movement Cost Formula (with Seasonal Modifier)

```
movement_cost_for_hex = terrain_base_cost × season_multiplier
```

**Variables:**
| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| Terrain base cost | C_t | int | [1, 2] | Cost per hex (Road=1, Forest/Hill=2) |
| Season multiplier | M_s | float | [1.0, 1.5] | Seasonal modifier (Wet=1.5, others=1.0) |
| Final movement cost | C | int | [1, 3] | AP consumed per hex |

**Season multipliers:** Dry: 1.0, Wet: 1.5, Harvest: 1.0

**Output range:** [1, 3] AP per hex

### 2. Ranged Damage Modifier (Terrain-Based)

```
ranged_damage = base_damage × (1.0 + terrain_ranged_mod)
```

**Variables:**
| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| Base damage | D_b | float | [1, 100] | Damage before terrain |
| Terrain modifier | M_r | float | [-0.25, +0.25] | Hill +25%, Forest -25%, Village -15% |
| Final damage | D | float | [0.75×D_b, 1.25×D_b] | Damage after modifier |

**Output range:** [0.75×D_b, 1.25×D_b]

### 3. Fire Spread (Flammable Terrain Only)

Fire spreads on Open Fields during Dry season only, 1 hex per turn in wind direction. Fire does NOT spread in Wet season. Burned hexes persist for battle duration (charred, blocks movement).

### 4. Defense/Cover Modifier (Terrain-Based)

```
effective_defense = base_defense × (1.0 + terrain_defense_mod)
```

**Variables:**
| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| Base defense | D_b | float | [1, 100] | Defense before terrain |
| Terrain modifier | M_d | float | [-0.20, +0.15] | Village +15%, Ford -20% |
| Final defense | D | float | [0.8×D_b, 1.15×D_b] | Defense after modifier |

**Output range:** [0.8×D_b, 1.15×D_b]

---

## Edge Cases

**If a squad tries to cross a river without a ford/bridge:** The move is invalid and rejected. No partial crossing, no swimming. Must reroute to a ford or bridge.

**If fire spreads to a hex occupied by a squad:** The squad takes damage (fire damage = 20% of squad's current HP) and the hex becomes charred. Repeated fire on the same hex does not deal additional damage.

**If a squad moves from a hill to a non-hill hex:** The +25% ranged damage bonus is lost immediately on the next turn (hill only provides bonus while occupying the hill).

**If Wet season begins during an active battle:** Movement costs are recalculated immediately. Squads that moved 3 hexes in Dry may have exhausted their AP; they cannot move further since next hex would cost 3 AP in Wet.

**If all bridges/fords are destroyed or blocked:** River becomes completely impassable; units cannot cross. Affects tactical routing.

**If a forest hex burns (edge case in scenarios with fire in non-field terrain):** Forest becomes charred but fire does NOT spread to adjacent forests. Fire only spreads on fields. Charred forest retains +cover for remaining units in it.

---

## Dependencies

**Upstream dependencies:** None — Terrain System is foundational.

**Downstream dependencies:** 7 systems depend on Terrain:

| Dependent System | Reads | Type |
|---|---|---|
| Hex Movement | Movement cost per terrain type, seasonal modifier | Hard |
| Combat Resolution | Ranged/melee modifiers, terrain type | Hard |
| Fire System | Flammability state, spread rules | Hard |
| Fog of War / Vision | Terrain type for vision blocking/boosting | Hard |
| Campaign Map UI | Terrain display assets, seasonal variants | Hard |
| Campaign Map AI | Movement costs for pathfinding | Hard |
| Morale System | Terrain-based morale effects (ambush, defense) | Soft |

**Data contract:** All reads are read-only. No system modifies terrain state except Campaign Layer (seasonal transitions).

---

## Tuning Knobs

| Knob | Default | Safe Range | Impact |
|---|---|---|---|
| Movement cost: Hill | 2 AP | [1, 3] | Higher = hillier terrain harder to traverse |
| Movement cost: Forest | 2 AP | [1, 3] | Higher = forests become bottlenecks |
| Wet season multiplier | 1.5× | [1.2, 2.0] | Higher = mud/flooding more severe |
| Ranged damage on hill | +25% | [+10%, +40%] | Higher = ranged dominance on hills |
| Forest cover penalty | -25% | [-15%, -40%] | Higher = forests become safe havens |
| Village defense bonus | +15% | [+10%, +25%] | Higher = villages become fortifications |
| Fire spread rate | 1 hex/turn | [1, 3] hex/turn | Higher = fire moves faster across dry fields |
| Ford crossing cost | 2 AP | [1, 3] | Higher = rivers become major barriers |

---

## Visual/Audio Requirements

**Terrain Asset Requirements:**

Each of the 6 terrain types must have **3 seasonal variants** (Dry/Wet/Harvest) for a total of 18 unique tile visual assets:

| Terrain Type | Dry Visual | Wet Visual | Harvest Visual |
|---|---|---|---|
| Road | Hard-packed, dust | Rutted, muddy | Worn, traffic-marked |
| Open Field | Sparse grass, cracked ground | Waterlogged, dense vegetation | Full grain, harvested sections |
| Hill | Bare earth, rocky | Vegetation-heavy, wet | Golden grass, autumn tones |
| Forest | Sparse underbrush, visible canopy | Dense fog, wet undergrowth | Autumn colors, damp floor |
| Village | Dust clouds, dry conditions | Muddy streets, wet roofs | Organized fields, harvest stacks |
| River | Flowing water, exposed banks | Swollen, fast-flowing | Normal flow, supply activity |

**SFX requirements:** None explicit. Audio Director defers to atmosphere (bird ambient in forest, wind on hills, rushing water at river) — handled by audio-director.

---

## UI Requirements

**Campaign Map UI:**
- Display terrain type via tile visual asset (already specified above)
- Display seasonal state via color filter (Dry=warmer, Wet=cooler, Harvest=golden) at 5-10% opacity overlay
- Show movement cost on hover: "Forest (Wet): 3 AP" 
- Highlight impassable hexes in red when player hovers over a squad (show unreachable areas due to river/terrain cost)

**Tactical HUD:**
- Display terrain type name on unit inspector panel when unit is selected: "Unit on: Forest (Wet)"
- Show hill vision bonus indicator: "+1 vision" if unit on hill
- Show fire status: "Charred" for burned hexes (prevents movement through them)

---

## Acceptance Criteria

**GIVEN** a squad on a Road in Dry season with 5 AP, **WHEN** it moves 5 hexes, **THEN** all 5 AP are consumed (1 AP/hex × 5 = 5).

**GIVEN** a squad on a Forest in Wet season with 5 AP, **WHEN** it attempts to move into a Forest hex (cost 3 AP), **THEN** the move succeeds (3 AP consumed, 2 AP remaining).

**GIVEN** a ranged attacker on a Hill targeting a squad 2 hexes below on flat ground, **WHEN** the attack is resolved, **THEN** damage = base_damage × 1.25 (hill +25% modifier).

**GIVEN** an Open Field in Dry season adjacent to a fire source, **WHEN** a turn ends and fire spreads, **THEN** the Open Field becomes charred and fire spreads to adjacent flammable fields in wind direction.

**GIVEN** an Open Field in Wet season with an adjacent fire hex, **WHEN** the turn ends, **THEN** fire does NOT spread (water quenches fire).

**GIVEN** a river hex without a bridge/ford, **WHEN** a squad attempts to cross it, **THEN** the move is rejected and the squad remains on its original hex.

**GIVEN** a squad defending in a Village with base defense 50, **WHEN** it is attacked, **THEN** effective defense = 50 × 1.15 = 57.5.

**GIVEN** a squad mid-crossing a Ford (crossing_state = "in_progress"), **WHEN** it is attacked, **THEN** its defense = base_defense × 0.8 (-20% penalty).

**GIVEN** Wet season begins during active battle, **WHEN** the season transition is applied, **THEN** all movement costs recalculate immediately (squads' remaining AP are not retroactively adjusted, but future moves cost more).

**GIVEN** all 18 seasonal terrain variants exist, **WHEN** the campaign transitions to a new season, **THEN** the Campaign Map UI displays the correct variant for each hex (no visual pop-in or missing assets).
