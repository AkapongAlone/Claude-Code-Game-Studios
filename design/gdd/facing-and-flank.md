# Facing & Flank System

> **Status**: In Design
> **Author**: Game Designer
> **Last Updated**: 2026-06-12
> **Implements Pillar**: P1 — Victory Through Preparation + P3 — Grounded, Barely Fantastic

## Overview

The Facing & Flank System assigns each squad a **facing direction** — one of the six hex sides — that persists from turn to turn until the squad moves or rotates. When an attacker strikes from a hex that falls outside the squad's forward arc, the attack is classified as a **flank attack**: Combat Resolution applies a +30% damage modifier (`flanking_mod = 1.3`) and the Morale System fires a flat 10-point morale pressure trigger. At the data level, the system is a position-state calculator: given an attacker's hex coordinate and a defender's facing direction, it answers `is_flanking() → bool`. At the player level, it is the engine of positional strategy — an attack from behind is meaningfully more dangerous than a frontal assault, and the player who outmaneuvers the enemy, wrapping flanks or forcing squads to divide attention, wins engagements that equal numbers should not. The **forest ambush** (defined in the Terrain System) is handled as a terrain-triggered flank-equivalent: it bypasses the facing-check and sets the flanking state directly when attackers strike units entering a forest hex. Beyond each squad's current facing direction, the system carries no persistent state — it produces a boolean output consumed by Combat Resolution and Morale and is otherwise stateless.

*(Provisional: hex coordinate representation assumed to follow cube coordinates with 6 direction vectors — pending Hex Movement GDD.)*

## Player Fantasy

The fantasy is **the trap that closes**. A player spots an enemy squad exposed on the left side — no friendly unit covering that flank. They spend a turn maneuvering a cavalry squad around the right side of the enemy formation, not to attack yet, but to *position*. Next turn, the cavalry is behind the enemy line. The attack lands with the +30% flank modifier. The enemy squad, taking both elevated damage and the morale pressure of being hit from the rear, shakes. The player felt the plan execute exactly as designed — and knew it two turns before the kill.

The inverse is equally felt: you notice an enemy unit has drifted around your left flank. You must choose between rotating your squad (sacrificing movement this turn) or attacking forward anyway and absorbing the flank hit. Neither choice is free. The Facing & Flank System creates this tension without asking the player to think abstractly — the geometry of the hex grid *shows* them where the danger is. The awareness gap between a player who tracks facing angles and one who doesn't is the gap between a general and a soldier.

This directly serves **P1 (Victory Through Preparation)**: the flank is never accidental — it is the outcome of two or three prior positioning moves, rewarding players who think ahead. It also expresses **P3 (Grounded, Barely Fantastic)**: flank attacks were the decisive tactic of Napoleonic-era infantry, and the +30% differential feels earned rather than arbitrary. A player who wins because they achieved a double-envelopment feels like Kaster — someone who studied the ground and acted on what they saw.

## Detailed Design

### Core Rules

**Facing Direction:**
Each squad has a facing direction — one of the six hex sides, stored as an integer [0–5] using cube coordinate direction conventions. Facing persists across turns and updates automatically:
- **After moving:** squad faces the direction of its last move step
- **After attacking without moving:** squad faces toward the target
- **If neither moved nor attacked:** facing is unchanged from the previous turn

No explicit rotation action exists — facing is entirely determined by the squad's movement and combat choices.

**Forward Arc and Flank Arc:**
- **Forward arc (3 hexes):** the facing direction and the two adjacent directions (±1 mod 6). Attacks from these hexes are frontal attacks.
- **Flank/rear arc (3 hexes):** the remaining three directions (±2 and the opposite direction). Attacks from these hexes are flank attacks.

```
  [F-1] [F] [F+1]    ← Forward arc — frontal attack
[F-2]  SQUAD  [F+2]  ← Flank arc sides
      [F+3]          ← Flank arc rear
```

**Flank Attack:**
An attack is classified as a flank attack when the attacker's hex falls within the defender's flank/rear arc (`is_flanking = true`):
- Combat Resolution applies `flanking_mod = 1.3` (+30% damage)
- Morale System applies `morale_damage_flank = 10` flat morale damage to the flanked squad this turn

**Forest Ambush Override (Terrain-Triggered Flank):**
A squad in a forest hex that did NOT move this turn has the **ambush condition**. When it attacks an enemy squad that *did* move this turn, the attack is classified as `is_flanking = true` regardless of the actual facing relationship. This represents concealed forest units catching movement in the open.
- The override does not stack (result is still `is_flanking = true`, not doubled)
- Condition: attacker in forest + attacker did not move + target moved this turn
- Applies to all attack types (melee and ranged)

**Multiple Attackers:**
If multiple squads attack the same defender in one turn, `is_flanked_this_turn` is true for that entire turn if any single attack came from the flank arc or triggered the ambush override. The Morale trigger fires once per turn regardless of how many flank attacks landed.

---

### States and Transitions

The only persistent state per squad is `facing_direction`. Two ephemeral turn flags reset each turn:

| Field | Type | Range | Description |
|---|---|---|---|
| `facing_direction` | int | [0–5] | Current facing (cube coord direction index) — persists across turns |
| `moved_this_turn` | bool | — | True if the squad moved; resets at turn end |
| `is_flanked_this_turn` | bool | — | True if any attack this turn was a flank; resets at Morale Resolution Phase |

**Facing Update Triggers:**

| Trigger | New `facing_direction` |
|---|---|
| Squad moves to an adjacent hex | Direction from previous hex to new hex |
| Squad attacks without moving | Direction from squad's hex toward target's hex |
| Squad neither moves nor attacks | Unchanged from previous turn |

---

### Interactions with Other Systems

| System | This System Reads | This System Writes |
|---|---|---|
| **Hex Movement** *(provisional)* | Squad position (cube coord), `moved_this_turn` flag, move direction | `facing_direction` (updated post-move) |
| **Terrain** | Whether attacker hex is Forest; whether attacker `moved_this_turn` | — |
| **Combat Resolution** | — | `is_flanking(attacker_hex, defender_id)` → bool |
| **Morale System** | — | `is_flanked_this_turn(defender_id)` → bool (read during Morale Resolution Phase) |
| **Tactical AI** | — | `facing_direction(squad_id)`, `flank_arc_hexes(squad_id)` → set of hex coords |

*(Provisional: cube coordinate (q, r, s) representation and 6-direction vector convention assumed. Confirmed when Hex Movement GDD is authored.)*

## Formulas

### Formula 1: Facing Direction from Move Vector

```
move_delta = (qb - qa, rb - ra, sb - sa)
facing_direction = CUBE_DIR_INDEX[move_delta]
```

The six canonical cube direction vectors indexed 0–5 clockwise from East:

| Index | (dq, dr, ds) | Compass |
|---|---|---|
| 0 | (+1, −1, 0) | East |
| 1 | (+1, 0, −1) | South-East |
| 2 | (0, +1, −1) | South-West |
| 3 | (−1, +1, 0) | West |
| 4 | (−1, 0, +1) | North-West |
| 5 | (0, −1, +1) | North-East |

**Variables:**

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| Origin cube coords | (qa, ra, sa) | int × 3 | unbounded | Hex squad is moving from |
| Destination cube coords | (qb, rb, sb) | int × 3 | unbounded | Adjacent hex squad is moving to |
| Move delta | move_delta | (int, int, int) | one of 6 canonical vectors | Difference vector; must be exactly one cube step |
| Facing direction | facing | int | [0, 5] | Output direction index |

**Output range:** Exactly one of {0, 1, 2, 3, 4, 5}. Non-adjacent move_delta is an illegal call — Hex Movement gates this before facing is updated.

**Attack-without-move facing:**
```
facing_direction = CUBE_DIR_INDEX[(qt - qs, rt - rs, st - ss)]
```
where (qs, rs, ss) is the attacking squad's hex and (qt, rt, st) is the target's hex. Facing always updates on attack.

**Example:** Squad at (2, −1, −1) moves to (3, −1, −2). delta = (1, 0, −1) → index 1 (South-East). facing_direction = 1.

---

### Formula 2: Flank Arc Check (`is_flanking`)

```
relative_dir = (R - D + 6) mod 6
is_flanking  = (relative_dir >= 3)
```

**Variables:**

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| Defender facing | D | int | [0, 5] | Defender's current facing_direction |
| Attacker direction | R | int | [0, 5] | Direction index from defender's hex to attacker's hex (Formula 1 lookup) |
| Relative direction | relative_dir | int | [0, 5] | Attacker position expressed relative to defender's facing |
| Flank check | is_flanking | bool | {true, false} | True when attack comes from the flank/rear arc |

**Output range:** Boolean. relative_dir values 0, 1, 2 = forward arc (frontal). Values 3, 4, 5 = flank/rear arc.

**Example (flank):** Defender facing D = 1 (SE). Attacker at direction R = 4 (NW) from defender. relative_dir = (4 − 1 + 6) mod 6 = 3. 3 ≥ 3 → is_flanking = true.

**Example (frontal):** D = 1, R = 2 (SW). relative_dir = 1. 1 ≥ 3 → false. No flank bonus.

---

### Formula 3: Forest Ambush Condition

```
is_flanking = attacker_in_forest AND (NOT attacker_moved_this_turn) AND target_moved_this_turn
```

**Variables:**

| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| Attacker in forest | attacker_in_forest | bool | {true, false} | Attacker's hex terrain type is FOREST |
| Attacker stationary | NOT attacker_moved_this_turn | bool | {true, false} | Attacker spent zero movement points this turn |
| Target moved | target_moved_this_turn | bool | {true, false} | Defender spent any movement points this turn |
| Ambush flag | is_flanking | bool | {true, false} | Overrides facing-based check to true when all three hold |

**Output range:** Boolean. OR override — if Formula 2 already returns true, this check is redundant. If Formula 2 returns false, Ambush can still set is_flanking = true.

**Example:** Attacker stationary in forest; defender moved adjacent this turn. All three conditions hold → is_flanking = true. flanking_mod = 1.3 applies; 10 morale damage triggers.

---

**Design note:** The 3/3 equal arc split (3 frontal, 3 flank/rear) is intentional — it produces the 2–3 turn positioning tempo required by P1. Post-MVP tuning candidate: if playtesting shows the pure-rear hex (relative_dir = 3) deserves stronger punishment than side hexes (4, 5), a second constant rear_bonus = 0.5 (flanking_mod = 1.5 for relative_dir == 3 only) can be added without restructuring the formula.

## Edge Cases

- **If a squad does not move or attack this turn:** Facing is unchanged. A static squad maintains its orientation from the previous turn — enemies who have been maneuvering around it will find the flank arc exposed. No special handling; facing simply carries over.

- **If multiple attackers strike the same defender from both frontal and flank arcs in the same turn:** `is_flanked_this_turn = true` (any flank attack sets the flag). Both attacks resolve with their respective modifiers (frontal attack uses flanking_mod = 1.0; flank attack uses 1.3). The Morale trigger fires once for the turn, not once per flank attack.

- **If a squad moves AND attacks in the same turn:** Facing updates first from the move direction, then updates again toward the attack target. Final `facing_direction` is the direction toward the last attacked target.

- **If the forest ambush condition fires but the facing-based check already returns true:** Both conditions independently produce `is_flanking = true`. The result is the same bonus (flanking_mod = 1.3) — no doubling. The forest ambush is an OR override, not a stacking multiplier.

- **If the forest attacker moved into the forest on the same turn it attacks:** `attacker_moved_this_turn = true` — ambush condition fails. The attacker must have been stationary in the forest to qualify. Moving into position and immediately ambushing is not valid.

- **If both the attacker and the defender are stationary this turn:** Forest ambush requires `target_moved_this_turn = true`. If the defender did not move, ambush does not trigger. Only the facing-based Formula 2 check applies.

- **If a squad's flank arc includes hexes outside the map boundary:** Out-of-bounds hexes cannot contain squads. No attack originates from them. The `is_flanking` check is only invoked per actual attack; unmanned hex directions are never triggered. No special handling needed.

- **If facing_direction is not set at battle start:** All squads must have a valid `facing_direction` assigned before the first turn. Default at scenario setup: squad faces toward the nearest enemy cluster (or map center from starting position if no enemies visible). A fallback of direction 0 (East) is acceptable for scenario editor defaults; authored scenarios should set facing explicitly.

- **If a routing BROKEN squad is flanked while retreating:** Routing squads continue to have a `facing_direction` (updated as they auto-move toward the map edge). Attacks against routing squads can still trigger `is_flanking = true` and apply flanking_mod. Since BROKEN squads receive no further morale recovery and the rout is already committed, the morale damage trigger fires but has no meaningful effect.

- **If relative_dir is exactly 3 (pure-rear hex) vs. 4 or 5 (side hexes):** Under the current design, all three flank/rear values (3, 4, 5) produce the same flanking_mod = 1.3. No mechanical distinction between side and rear attacks in MVP. See Formulas design note for the post-MVP rear_bonus candidate.

## Dependencies

**Upstream dependencies (systems this GDD depends on):**

| System | Dependency Type | What Is Read | Hard/Soft |
|---|---|---|---|
| Terrain System | Reads terrain type of attacker's hex | Forest check for ambush condition (Formula 3) | Hard |
| Hex Movement System *(provisional)* | Reads squad position (cube coordinate), move direction vector, `moved_this_turn` flag | All three formulas require position data; facing_direction is updated after every move | Hard |

**Downstream dependencies (systems that depend on this GDD):**

| System | What It Reads | Hard/Soft |
|---|---|---|
| Combat Resolution System | `is_flanking(attacker_hex, defender_id)` → bool → used as `flanking_mod` (1.0 or 1.3) | Hard |
| Morale System | `is_flanked_this_turn(defender_id)` → bool → triggers `morale_damage_flank = 10` in Morale Resolution Phase | Hard |
| Tactical AI System | `facing_direction(squad_id)`, `flank_arc_hexes(squad_id)` → identifies flanking opportunities for enemy maneuvering | Soft |

**Bidirectional consistency check:**
- Combat Resolution GDD §Interactions lists "Facing & Flank — reads `is_flanking(attacker position)`" ✓
- Combat Resolution GDD §Dependencies lists Facing & Flank as upstream ✓
- Morale System GDD §Dependencies lists "Facing & Flank | Read is_flanked per squad | Hard" ✓
- Terrain System GDD §Dependencies: does NOT yet list Facing & Flank as downstream — **flag for correction when Terrain GDD is updated.**
- Hex Movement GDD: not yet authored — must list Facing & Flank as downstream when designed.

## Tuning Knobs

| Knob | Default | Safe Range | Owner | Impact |
|---|---|---|---|---|
| `flank_bonus` | 0.3 (flanking_mod = 1.3) | [0.2, 0.5] | `combat-resolution.md` (registered constant) | Higher = flanking more decisive; above 0.5 makes flanking ~2× frontal, trivializing head-on engagements |
| Arc split | 3 frontal / 3 flank | — | Hardcoded in Formula 2 (threshold `>= 3`) | Changing requires a code change and GDD revision — not a data tuning knob |
| `flank_morale_penalty` | 10 | [5, 20] | `morale-system.md` (tuning knob) | Higher = flanking applies stronger morale pressure per turn; above 15 stacks with damage bonus to make flanking very threatening |
| Starting `facing_direction` | Toward nearest enemy cluster | [0–5] | Scenario config | Per-scenario override; computed at battle setup by default. Authored scenarios should set facing explicitly for each squad |

**Post-MVP tuning candidates (not active in MVP):**
- `rear_bonus` = 0.5 (flanking_mod = 1.5 for relative_dir == 3 only) — differentiates pure-rear attacks from side attacks. Requires a new registered constant and Formula 2 update.
- `ambush_bonus` — currently forest ambush applies the same `flank_bonus`. A separate constant could make forest ambush stronger or weaker if playtesting shows they should differ.

**Note:** `flank_bonus` is owned by the Combat Resolution GDD and registered in `design/registry/entities.yaml`. Changing its value requires updating Combat Resolution first and propagating here.

## Visual/Audio Requirements

**Squad Facing Indicator:**
Each squad token must display its current facing direction visually. A directional arrow or chevron overlaid on the token (or the token itself rotated toward its facing direction) must be readable at a glance without hovering. This is a persistent element, not a tooltip. Final approach to be confirmed by art-director before production.

**Flank Arc Visualization (Hover/Selection):**
When a squad is hovered or selected, highlight the 3 forward-arc hexes and 3 flank/rear-arc hexes:
- Forward arc: subtle green/neutral tint
- Flank/rear arc: subtle red/amber tint
- Hover-only to reduce visual noise (consistent with Morale System aura visualization)

**Flank Attack Feedback:**
When an attack resolves as a flank attack (is_flanking = true):
- Damage number uses a distinct color (recommended: orange) or a "FLANK" label to differentiate from frontal attacks
- The existing pulse effect (Combat Resolution GDD) already covers high-damage hits; color is the primary differentiator
- Optional brief token shake on the defender to reinforce "caught from the side"

**Forest Ambush Feedback:**
When forest ambush triggers:
- Same flank attack visual (orange damage number or "AMBUSH" label)
- Brief particle effect at the forest hex (leaves, shadow burst) to signal origin
- Audio: distinct "reveal" sound before impact (branch snap, sudden movement) followed by normal impact SFX

**SFX:**
- Flank attack: normal impact SFX plus a short distinct audio cue (surprised-impact sound differing from frontal clash)
- Forest ambush: ambient "reveal" sound preceding the impact SFX

*Lean mode: `art-director` not consulted — review against art bible before production.*

📌 **Asset Spec** — Visual/Audio requirements are defined. After the art bible is approved, run `/asset-spec system:facing-and-flank` to produce per-asset visual descriptions, dimensions, and generation prompts from this section.

---

## UI Requirements

**Facing Direction Display (Tactical HUD):**
- Squad token always shows facing direction without player interaction
- On squad selection: facing direction stated in the unit inspector panel (e.g., "Facing: South-East")

**Flank Arc Overlay (Hover/Selection):**
- Forward arc hexes highlighted green; flank/rear arc hexes highlighted red/amber
- Persists while squad is selected; dismissed on deselect
- Consistent with Morale aura overlay pattern (hover-triggered, same visual layer)

**Attack Initiation Preview:**
When the player has a target selected (attack cursor active), display whether the attack angle is a flank:
- If the attack path strikes the defender's flank arc, show a "FLANK" indicator in the targeting UI
- Allows pre-attack confirmation of flanking benefit — core to P1 "study the ground" fantasy

**Ambush Condition Indicator:**
- Player's own squads in forest that have not moved: optional icon (leaf/camouflage marker) on the token indicating ambush-ready status
- Enemy squads' ambush condition is NOT displayed — player must read terrain, not a UI flag

📌 **UX Flag — Facing & Flank System**: This system has UI requirements. In Phase 4 (Pre-Production), run `/ux-design` to create a UX spec for the Tactical HUD before writing epics. Stories referencing facing indicators or flank arc overlays should cite `design/ux/tactical-hud.md`, not this GDD directly.

## Acceptance Criteria

*Unit test evidence is BLOCKING for this Logic-category system. Integration tests for cross-system boundary criteria are ADVISORY. All criteria below are independently verifiable by a QA tester without reading the GDD.*

**Facing update — move:**
GIVEN a squad at hex A, WHEN it moves to adjacent hex B where move_delta = (+1, −1, 0) (direction 0 = East), THEN facing_direction = 0.

**Facing update — second canonical vector:**
GIVEN a squad at hex A, WHEN it moves to adjacent hex B where move_delta = (0, −1, +1) (direction 5 = North-East), THEN facing_direction = 5. (Validates the CUBE_DIR_INDEX table is complete, not hardcoded to a single case.)

**Facing update — attack without move:**
GIVEN a squad facing direction 3 attacks a target at direction 2 from the squad's position without first moving, WHEN the attack resolves, THEN facing_direction = 2.

**Facing update — no action:**
GIVEN a squad facing direction 0 neither moves nor attacks this turn, WHEN the turn ends, THEN facing_direction is still 0.

**Facing update — move AND attack same turn:**
GIVEN a squad facing direction 1 moves in direction 0 (East) then attacks a target at direction 2 from its new position, WHEN the attack resolves, THEN facing_direction = 2 (attack target direction overrides move direction).

**Formula 2 — frontal attack:**
GIVEN defender facing D = 0, attacker at direction R = 0, WHEN is_flanking is evaluated, THEN relative_dir = 0; is_flanking = false.

**Formula 2 — forward arc, adjacent direction (R = 1):**
GIVEN defender facing D = 0, attacker at direction R = 1, WHEN is_flanking is evaluated, THEN relative_dir = 1; is_flanking = false.

**Formula 2 — forward arc boundary (R = 2, last safe direction):**
GIVEN defender facing D = 0, attacker at direction R = 2, WHEN is_flanking is evaluated, THEN relative_dir = 2; is_flanking = false. (A bug setting threshold `>= 2` instead of `>= 3` would fail here.)

**Formula 2 — flank arc (R = 3, first flank direction):**
GIVEN defender facing D = 0, attacker at direction R = 3 (directly opposite), WHEN is_flanking is evaluated, THEN relative_dir = 3; is_flanking = true.

**Formula 2 — wrap-around arithmetic:**
GIVEN defender facing D = 5, attacker at direction R = 2, WHEN is_flanking is evaluated, THEN relative_dir = (2 − 5 + 6) mod 6 = 3; is_flanking = true.

**Multiple attackers — one frontal, one flank:**
GIVEN a defender attacked by two squads this turn (one from forward arc, one from flank arc), WHEN attacks resolve, THEN is_flanked_this_turn = true; Morale fires 10 morale damage once, not twice.

**Multiple attackers — all flanking, morale fires once:**
GIVEN a defender attacked by two squads both from the flank arc this turn, WHEN the Morale Resolution Phase runs, THEN the flank morale trigger fires once (10 morale damage total, not 20).

**Formula 3 — forest ambush overrides frontal facing check:**
GIVEN an attacker in a Forest hex that did not move this turn attacks a defender that did move this turn, AND the attack angle (Formula 2) would return is_flanking = false, WHEN is_flanking is evaluated, THEN is_flanking = true — the forest ambush overrides the facing-based result.

**Formula 3 — attacker moved, ambush fails:**
GIVEN an attacker in a Forest hex that DID move this turn attacks a defender that moved this turn, WHEN Formula 3 is evaluated, THEN the forest ambush condition does NOT trigger; only Formula 2 applies.

**Formula 3 — defender stationary, ambush fails:**
GIVEN an attacker in Forest that did not move, but the defender also did NOT move this turn, WHEN Formula 3 is evaluated, THEN the forest ambush condition does NOT trigger.

**Cross-system — Combat Resolution (flank):**
GIVEN is_flanking = true, WHEN Combat Resolution reads the flanking modifier, THEN flanking_mod = 1.3.

**Cross-system — Combat Resolution (frontal):**
GIVEN is_flanking = false, WHEN Combat Resolution reads the flanking modifier, THEN flanking_mod = 1.0.

**Cross-system — Morale (flanked):**
GIVEN is_flanked_this_turn = true, WHEN the Morale Resolution Phase runs, THEN the squad takes 10 morale damage from the flank trigger.

**Cross-system — Morale (not flanked):**
GIVEN is_flanked_this_turn = false, WHEN the Morale Resolution Phase runs, THEN the squad takes 0 morale damage from the flank trigger.

**Routing squad — flank registers, morale suppressed:**
GIVEN a BROKEN routing squad is attacked from its flank arc, WHEN is_flanking is evaluated, THEN is_flanking = true. AND WHEN the Morale System processes the flank trigger, THEN no morale damage is applied — BROKEN squads do not receive morale damage. (Integration test — requires Morale System.)

**Battle start initialization:**
GIVEN a battle begins and squads are initialized, WHEN all squads' facing_direction values are inspected, THEN every squad has a facing_direction that is an integer in [0, 5]. For scenarios using the default (no explicit override): each squad faces toward the nearest enemy cluster from its starting position.

## Open Questions

1. **Hex coordinate convention** — This GDD assumes cube coordinates (q, r, s) with the 6-direction table defined in Formula 1. Confirm with the Hex Movement GDD (design #6) that both systems use the same convention. If Hex Movement uses axial or offset coordinates, Formula 1 must be updated.

2. **Routing pathfinding ownership** — When a BROKEN squad auto-routes (Morale System), does Hex Movement own that pathfinding and update `facing_direction` as a side effect? Or does Facing & Flank expose a `target_direction_for_routing()` function? Tentative: Hex Movement owns all movement including routing; Facing & Flank updates facing passively. Confirm when Hex Movement GDD is authored (same question as Morale System Open Questions #1).

3. **Default starting facing policy** — Squads default to facing the nearest enemy cluster if no explicit override is set. Needs a clear implementation rule: is this computed at scenario-setup time or at battle-start frame? For player-placed deployments, the default should face map center unless the player sets it explicitly. Confirm in Tactical HUD design.

4. **Post-MVP rear bonus** — Should `relative_dir == 3` (pure-rear hex) carry a stronger bonus than side hexes (4, 5)? MVP holds all three at +30%. Candidate addition: `rear_bonus = 0.5` (flanking_mod = 1.5 for relative_dir == 3 only). Track via playtesting; add as a registered constant and update Formula 2 if adopted.

5. **Flank vs. ambush HUD distinction** — Both a facing-based flank and a forest ambush produce the same `is_flanking = true` flag. If the Tactical HUD should distinguish them ("FLANK +30%" vs "AMBUSH +30%"), a separate `is_ambush` flag is needed. Currently out of scope — flag for UX design phase if desired.
