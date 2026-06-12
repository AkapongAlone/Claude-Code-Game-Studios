# Victory/Defeat Conditions System

> **Status**: Designed
> **Author**: Game Designer + Systems Designer
> **Last Updated**: 2026-06-12
> **Implements Pillar**: P3 — Grounded, Barely Fantastic + P4 — Authored Peaks, Player Valleys
> **Review Mode**: Lean

## Overview

The Victory/Defeat Conditions System evaluates the tactical battlefield each turn to determine when a battle ends and whether the player won or lost. It reads squad morale states from the Morale System and hex occupancy from the Hex Movement System to calculate whether either side has achieved its goals. Victory is earned primarily by breaking the enemy army — routing enough enemy squads that they can no longer hold the field — with mission-specific secondary conditions layered on top: holding key hexes, protecting VIPs, eliminating named targets, or surviving a turn countdown. Defeat conditions are the mirror: the player's army breaks past a threshold, a key officer is incapacitated, an objective hex is lost, or time runs out. The system is fully data-driven — each battle loads a `BattleDefinition` specifying which conditions apply; the evaluation engine is generic and stateless. This system fires once per turn, after the Routing Resolution Phase, and immediately ends the battle when any condition triggers.

## Player Fantasy

The fantasy is **resolution that feels earned**. After a tense series of turns spent managing pressure, making sacrifices, and watching morale bars drain, the moment a battle ends should land with weight — either the satisfaction of watching the enemy line collapse and the last routing soldiers flee the field, or the sobering recognition that the cost was too high and retreat is the only honest answer.

The system serves P3 (Grounded, Barely Fantastic) directly: battles end the way real Napoleonic battles ended, not when the last soldier falls but when enough of one side breaks and the survivors see the writing on the wall. When the player crosses the rout threshold, the battle simply stops — there is no grinding down of the last three enemy squads to zero HP. The field is conceded. This creates the satisfying rhythm of escalating pressure → cascade collapse → sudden silence that defines the fantasy.

It also serves P4 (Authored Peaks): authored missions can stack secondary conditions that make specific battles feel unique — "hold the bridge until dawn" (SURVIVE\_TURNS), "protect Jin Tao's withdrawal" (LOSE\_VIP), "take the hill and hold it" (HOLD\_OBJECTIVE). Each condition changes what the player is optimizing for and therefore changes how the battle *feels*, even if the underlying hex combat is the same.

The failure fantasy is equally important: the player should never feel cheated by a defeat. The condition that triggered must be legible — "your army broke" (not "the game decided you lost"). Post-battle reporting shows both sides' route fractions so the player can see how close it actually was.

## Detailed Design

### Core Rules

**Battle Initialization:**

1. Each battle loads a `BattleDefinition` (JSON) specifying its victory conditions, defeat conditions, and optional overrides (route thresholds, turn limits, VIP IDs). See §Formulas for the format.
2. At battle start, `starting_squads(player)` and `starting_squads(enemy)` are recorded as fixed counts. These never change during the battle, even if reinforcements arrive in future scope — the denominator is locked at the moment of deployment.
3. All objective hex states are initialized (contested).

**Per-Turn Evaluation (fires after Routing Resolution Phase):**

The evaluation engine runs once per turn in this exact order:

1. **Hard Defeat Check** — evaluate all `LOSE_VIP` and `ENEMY_HOLDS_OBJECTIVE` conditions. If any trigger → `BattleResult: DEFEAT`. Stop.
2. **Victory Check** — evaluate all victory conditions (`ROUTE_ENEMY`, `HOLD_OBJECTIVE`, `SURVIVE_TURNS`, `ELIMINATE_TARGET`). If any trigger → `BattleResult: VICTORY`. Stop.
   - If `victory_mode = "all"` (mission override): all victory conditions must trigger simultaneously. If only some are met → skip to step 3.
3. **Soft Defeat Check** — evaluate `PLAYER_ROUTED`. If `route_fraction(player) >= route_defeat_threshold` → `BattleResult: DEFEAT`. Stop.
4. **Turn Limit Check** — if `current_turn > max_turns` → `BattleResult: DEFEAT`. Stop.
5. **Ongoing** — no condition triggered. Battle continues to the next turn.

**Condition Types — Victory:**

| Type | Trigger | Parameters |
|---|---|---|
| `ROUTE_ENEMY` | `route_fraction(enemy) >= route_victory_threshold` | `threshold` (default: `route_victory_threshold` knob) |
| `HOLD_OBJECTIVE` | Player has controlled objective hex for `hold_turns` consecutive turns | `hex_coord`, `hold_turns` |
| `SURVIVE_TURNS` | Battle reaches turn `target_turn` without any defeat condition triggering | `target_turn` |
| `ELIMINATE_TARGET` | Specified enemy squad is eliminated (HP = 0 or off-map) | `target_squad_id` |

**Condition Types — Defeat:**

| Type | Trigger | Parameters |
|---|---|---|
| `PLAYER_ROUTED` | `route_fraction(player) >= route_defeat_threshold` | `threshold` (default: `route_defeat_threshold` knob) |
| `LOSE_VIP` | Named officer's squad is eliminated or officer is incapacitated | `vip_officer_id` |
| `ENEMY_HOLDS_OBJECTIVE` | Enemy has controlled objective hex for `enemy_hold_turns` consecutive turns | `hex_coord`, `enemy_hold_turns` |
| `EXCEED_TURN_LIMIT` | `current_turn > max_turns` without victory | `max_turns` |

**Hex Control (for objective conditions):**

- A hex is **player-controlled** if ≥ 1 non-BROKEN player squad occupies it and zero enemy squads occupy it.
- A hex is **enemy-controlled** if ≥ 1 non-BROKEN enemy squad occupies it and zero player squads occupy it.
- A hex is **contested** if both sides have non-BROKEN squads on it, or neither does. Contested hexes do not advance any objective counter.
- BROKEN (routing) squads do not count for hex control — a routing squad abandons the hex.

**Named Officer Incapacitation:**

Named officers are never killed in open-field tactical battles (fiction rule — they are incapacitated, captured, or retreat). The `LOSE_VIP` condition triggers when the VIP officer's **squad** is eliminated (all HP depleted or off-map via routing) — the officer is assumed incapacitated at that point. Generic officer death (squad HP = 0) does not trigger `LOSE_VIP` unless that officer's ID is explicitly listed in the `BattleDefinition`.

**BattleResult Report:**

When the battle ends, the system emits:
- `result`: VICTORY | DEFEAT | DRAW
- `trigger_condition`: which condition type fired and its parameters
- `end_turn`: the turn number the battle ended
- `route_fraction_player`: player's route fraction at battle end
- `route_fraction_enemy`: enemy's route fraction at battle end

The DRAW result is reserved for the mutual-rout edge case (see Edge Cases).

### States and Transitions

The Victory/Defeat Conditions System has no internal per-squad state — it reads state from other systems (Morale, Hex Movement). The only state it tracks internally is per-battle:

| State | Condition |
|---|---|
| ONGOING | No condition has triggered this battle |
| VICTORY | A victory condition triggered; battle ended |
| DEFEAT | A defeat condition triggered; battle ended |
| DRAW | Mutual-rout edge case; battle ended |

Objective hold counters are also tracked internally:

| Counter | Description |
|---|---|
| `objective_hold_player[hex]` | Consecutive turns player has controlled objective hex (resets on loss of control) |
| `objective_hold_enemy[hex]` | Consecutive turns enemy has controlled objective hex (resets on loss of control) |

Transitions:
```
ONGOING → VICTORY   (any victory condition triggers in step 2)
ONGOING → DEFEAT    (any defeat condition triggers in steps 1, 3, 4)
ONGOING → DRAW      (mutual-rout edge case — both route thresholds met simultaneously, no VIP/objective defeats active)
VICTORY, DEFEAT, DRAW → [battle ends — no further transitions]
```

### Interactions with Other Systems

| System | This System Reads | This System Writes |
|---|---|---|
| **Morale System** | `squad.morale_state` per squad (BROKEN = contributes to broken_squads); `squad.is_off_map` | — (read-only) |
| **Combat Resolution** | `squad.is_dead` (HP = 0, removed from map) | — (read-only) |
| **Hex Movement** | `squad.hex_position` and `squad.owner` for objective hex control evaluation | — (read-only) |
| **Officer Stats / Officer Passive** | `officer.id`, `officer.is_incapacitated` (for LOSE_VIP check) | — (read-only) |
| **Battle Flow Controller** | — | `BattleResult` (VICTORY / DEFEAT / DRAW + metadata); signals battle-end |
| **Campaign Layer** (future) | — | `BattleResult` (campaign receives manpower recovery data, territory outcome) |
| **Tactical HUD** | — | `BattleResult`, route fraction values for display |
| **Save/Load System** (future) | — | `BattleResult` record (stored in save data) |

**Interface contract this system exposes:**
- `VictoryChecker.evaluate(battle_state) -> BattleResult` — called by battle flow controller each turn after Routing Resolution Phase
- `VictoryChecker.get_route_fraction(side: String) -> float` — callable by HUD to display live route fraction
- `VictoryChecker.get_objective_progress(hex_coord) -> Dictionary` — callable by HUD to display hold counter

## Formulas

*Systems Designer reviewed: threshold corrected from 0.60 → 0.50; variable table expanded to distinguish the three broken-squad categories.*

---

### F-1: Route Fraction

The `route_fraction` formula measures what portion of a side's original force is no longer capable of fighting:

```
route_fraction(side) = broken_squads(side) / starting_squads(side)

broken_squads = broken_on_map + routed_off_map + dead_squads
```

**Variables:**
| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| Squads in BROKEN state on map | broken_on_map | int | [0, 16] | Squads with `morale_state == BROKEN` still physically present; routing has begun but not completed |
| Squads that exited via routing | routed_off_map | int | [0, 16] | Squads that entered BROKEN and reached a map edge; removed from map |
| Squads eliminated at HP = 0 | dead_squads | int | [0, 16] | Squads killed by HP exhaustion and removed immediately; tracked by a separate accumulator because their removal trigger differs from routing |
| Combined broken count | broken_squads | int | [0, 16] | Sum of the three categories above |
| Starting squads (fixed) | starting_squads | int | [1, 16] | Total squads on this side at battle start; set once and never updated, even if reinforcements arrive |
| Route fraction (output) | route_fraction | float | [0.0, 1.0] | Proportion of original force no longer fighting |

**Output range:** 0.0 (no losses) to 1.0 (entire original force broken or dead).

**Why three separate buckets:** `dead_squads` removal fires no morale event for adjacent squads (Morale GDD edge case 5 — HP-death is distinct from rout). The Victory system must accumulate deaths separately to avoid missing them in the route fraction count.

**Example:** Battle starts with 10 enemy squads (`starting_squads = 10`). After 5 turns: 2 squads are BROKEN and still on-map, 2 have routed off-map, 1 was killed at HP = 0.
`route_fraction = (2 + 2 + 1) / 10 = 0.50` → equals `route_victory_threshold` → ROUTE_ENEMY victory triggers.

---

### F-2: Route Victory and Defeat Checks

```
route_victory = (route_fraction(enemy) >= route_victory_threshold)
route_defeat  = (route_fraction(player) >= route_defeat_threshold)
```

**Variables:**
| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| Enemy route fraction | route_fraction(enemy) | float | [0.0, 1.0] | From F-1 applied to enemy side |
| Player route fraction | route_fraction(player) | float | [0.0, 1.0] | From F-1 applied to player side |
| Victory threshold | route_victory_threshold | float | [0.40, 0.80] | Default 0.50; tunable per battle |
| Defeat threshold | route_defeat_threshold | float | [0.40, 0.80] | Default 0.50; tunable per battle; typically mirrors victory threshold |
| Route victory (output) | route_victory | bool | true/false | true → ROUTE_ENEMY victory condition met |
| Route defeat (output) | route_defeat | bool | true/false | true → PLAYER_ROUTED defeat condition met |

**Output:** Boolean. At default thresholds of 0.50: a side of 16 squads triggers the check when 8 squads are broken/dead.

**Threshold rationale:** 0.50 is chosen over 0.60 because the broken_squads count includes dead units (which are permanent losses, not temporary routs). Historically, Napoleonic armies broke at 25–50% effective casualties; with dead + routing combined, 50% is the appropriate level at which a side visibly cannot hold a coherent line.

---

### F-3: Turn Limit Check

```
battle_timed_out = (current_turn > max_turns)
```

**Variables:**
| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| Current turn | current_turn | int | [1, ∞] | Battle turn counter, increments at end of each full IGOUGO cycle |
| Maximum turns | max_turns | int | [5, 30] | Defined in BattleDefinition; applies only if `EXCEED_TURN_LIMIT` defeat condition is present |
| Timed out (output) | battle_timed_out | bool | true/false | true → player failed to achieve victory within the time limit |

**Output:** Boolean. When `battle_timed_out = true` and the `EXCEED_TURN_LIMIT` condition is in the BattleDefinition, the result is DEFEAT. If no turn limit condition is defined, this check never fires — the battle continues until route or objective conditions resolve it.

**Design note:** Turn limit defeat is always a player defeat in MVP — there is no "timed-out tie-goes-to-most-objectives" resolution. Scenario authors must set `max_turns` high enough that a skilled player can realistically win within the limit. Tutorial/playtest feedback should calibrate `max_turns` per mission.

---

### BattleDefinition Format Reference

```json
{
  "battle_id": "act1_open_field",
  "victory_conditions": [
    { "type": "ROUTE_ENEMY", "threshold": 0.50 }
  ],
  "defeat_conditions": [
    { "type": "PLAYER_ROUTED", "threshold": 0.50 },
    { "type": "LOSE_VIP", "vip_officer_id": "kaster" }
  ],
  "victory_mode": "any"
}
```

```json
{
  "battle_id": "act2_bridge_defense",
  "victory_conditions": [
    { "type": "SURVIVE_TURNS", "target_turn": 8 }
  ],
  "defeat_conditions": [
    { "type": "PLAYER_ROUTED", "threshold": 0.50 },
    { "type": "ENEMY_HOLDS_OBJECTIVE", "hex_coord": "q0r-3s3", "enemy_hold_turns": 3 }
  ],
  "victory_mode": "any"
}
```

```json
{
  "battle_id": "prologue_keras",
  "victory_conditions": [
    { "type": "ROUTE_ENEMY", "threshold": 0.50 },
    { "type": "HOLD_OBJECTIVE", "hex_coord": "q1r0s-1", "hold_turns": 3 }
  ],
  "defeat_conditions": [
    { "type": "PLAYER_ROUTED", "threshold": 0.50 },
    { "type": "EXCEED_TURN_LIMIT", "max_turns": 12 }
  ],
  "victory_mode": "any"
}
```

## Edge Cases

- **If both route thresholds are met simultaneously (mutual rout):** Hard defeat conditions (LOSE_VIP, ENEMY_HOLDS_OBJECTIVE) are checked first and cannot coexist with this case if they haven't triggered by now. With no hard defeats active, the evaluation order checks victory before soft defeat — so if `route_fraction(enemy) >= 0.50` AND `route_fraction(player) >= 0.50` on the same turn, the victory check runs first and returns VICTORY. This represents a Pyrrhic win: the player holds the field but at severe cost. If the game concept later requires DRAW as an outcome (campaign tie state), a separate check `route_victory AND route_defeat` → DRAW can be added as a BattleDefinition flag (`allow_draw: true`). In MVP, Pyrrhic wins remain wins.

- **If LOSE_VIP and ROUTE_ENEMY both trigger on the same turn:** LOSE_VIP is a hard defeat condition checked in step 1, before the victory check in step 2. Result is DEFEAT. Protecting the VIP is a non-negotiable mission parameter when it appears in the BattleDefinition. Authors should not include LOSE_VIP in battles where losing the officer is narratively acceptable.

- **If `starting_squads = 0` for either side (empty force):** Division by zero in F-1. Handled defensively: if `starting_squads = 0`, that side's route_fraction is defined as 1.0 (fully broken before the battle began). This immediately triggers the relevant condition at turn 1. In practice, scenario validation in the editor should reject any BattleDefinition with 0 squads on either side.

- **If a BROKEN squad occupies an objective hex:** BROKEN (routing) squads do not count for hex control. A routing squad abandons the hex even if it physically passes through it on the way to the map edge. The hex reverts to contested on the same turn the squad enters BROKEN.

- **If `victory_mode = "all"` and only some victory conditions are met:** The system skips step 2 and proceeds to step 3 (soft defeat check). All victory conditions must trigger on the same evaluation pass for victory to be declared. This means a player who routes the enemy but hasn't held the objective yet does not win; but if they are also route-defeated, the defeat still fires before another turn can be played.

- **If `HOLD_OBJECTIVE` hold counter reaches `hold_turns - 1` and the player is pushed off next turn:** Counter resets to 0 (full reset, not pause). There is no partial progress. This is intentional — tension from near-completion is part of the HOLD_OBJECTIVE fantasy.

- **If an officer listed in LOSE_VIP is not present in the battle (scenario authoring error):** The condition never triggers (no squad to check). The battle proceeds without the VIP defeat condition active. An authoring-time warning should be raised if the VIP officer ID is not found among deployed squads.

- **If a squad is eliminated at HP = 0 on the same turn its morale would have entered BROKEN:** HP death takes precedence — the squad is removed immediately as a dead squad (no routing sequence). It counts toward `dead_squads`, not `broken_on_map`. The morale event (officer_loss_penalty for adjacent squads) still fires per Morale GDD.

- **If `ELIMINATE_TARGET` specifies a squad that routed off-map rather than dying at HP = 0:** Routing off-map counts as elimination for this condition — the target is no longer on the battlefield and cannot fight. `squad.is_off_map = true` satisfies the condition.

- **If the battle has no conditions in either VictoryConditions or DefeatConditions:** Undefined behavior — the battle will never end. Scenario validation must treat a BattleDefinition with zero conditions as an authoring error and refuse to start the battle.

- **If a named officer is incapacitated mid-turn (during Combat Resolution Phase) before the VictoryChecker runs:** The incapacitation is recorded immediately on the squad when it happens. When VictoryChecker evaluates at end-of-turn (after Routing Resolution Phase), it reads `officer.is_incapacitated = true` and triggers LOSE_VIP if applicable. The battle does not end mid-turn; evaluation is always deferred to the end-of-turn check point.

## Dependencies

**Upstream dependencies** (systems this GDD depends on):

| System | Dependency Type | What is read | Hard/Soft |
|---|---|---|---|
| Morale System | Read morale_state per squad | `morale_state == BROKEN` → squad contributes to `broken_on_map`; `is_off_map` flag → contributes to `routed_off_map` | Hard |
| Combat Resolution System | Read squad elimination events | `squad.is_dead` (HP = 0) → squad contributes to `dead_squads` | Hard |
| Hex Movement System | Read squad positions | `squad.hex_position` + `squad.owner` → hex control evaluation for HOLD_OBJECTIVE and ENEMY_HOLDS_OBJECTIVE | Hard (only for battles with objective conditions) |
| Officer Stats / Officer Passive System | Read officer state | `officer.is_incapacitated` → triggers LOSE_VIP condition | Hard (only for battles with LOSE_VIP condition) |

**Downstream dependencies** (systems that depend on this GDD):

| System | What it reads | Hard/Soft |
|---|---|---|
| Battle Flow Controller | `BattleResult` (VICTORY / DEFEAT / DRAW + trigger condition) | Hard — this system signals battle termination |
| Campaign Layer | `BattleResult` (manpower recovery, territory changes, story event triggers) | Hard |
| Tactical HUD (#26) | `route_fraction(player)`, `route_fraction(enemy)`, `objective_hold_player[hex]` for live display | Soft |
| Save/Load System (#31) | `BattleResult` record for campaign persistence | Soft |
| Tactical AI System (#23) | `route_fraction(player)`, `route_fraction(enemy)` for surrender heuristics | Soft |

**Bidirectional consistency check:**
- Morale GDD (§Dependencies) lists Victory/Defeat Conditions as downstream: ✓ (reads morale_state)
- Combat Resolution GDD (§Dependencies) lists Victory Conditions as downstream and notes it reads casualty_count: ✓ (reads squad.is_dead)
- Hex Movement GDD must list Victory/Defeat Conditions as downstream when it is authored (hex position read for objectives): flag for authoring time
- Tactical HUD, Campaign Layer, Save/Load, Tactical AI: must list Victory/Defeat Conditions as upstream when those GDDs are authored

## Tuning Knobs

All values are data-driven via `assets/data/victory_conditions.json` (global defaults) and overridable per-battle in `assets/data/battles/[battle_id].json`.

| Knob | Default | Safe Range | What breaks at extremes |
|---|---|---|---|
| `route_victory_threshold` | 0.50 | [0.40, 0.80] | Below 0.40: battles end very fast — 6 of 16 squads lost triggers win, feeling premature. Above 0.70: battles drag past the point of felt tension; players grind down the last squads after the outcome is obvious. |
| `route_defeat_threshold` | 0.50 | [0.40, 0.80] | Should typically mirror `route_victory_threshold` for symmetry. Diverging the two (e.g., defeat threshold 0.70 while victory threshold 0.40) creates asymmetric battles where the player wins easily but cannot be defeated — use only for explicitly easy tutorial missions. |
| `default_victory_mode` | "any" | ["any", "all"] | "all" should only be used in authored missions with ≤ 2 victory conditions; with 3+ conditions it becomes nearly impossible to meet all simultaneously. |
| `max_turns_default` | 20 | [8, 40] | Applied only to missions that use `EXCEED_TURN_LIMIT`. Below 8: even a fast player cannot win most open-field battles. Above 40: the turn limit becomes meaningless (no pressure). Tune per mission — 20 is the starting point for open-field battles. |

**Knob interaction warnings:**
- Lowering `route_victory_threshold` below 0.40 while keeping a high `max_turns_default` means most battles end before the turn limit is ever relevant. If using SURVIVE_TURNS missions, ensure the victory threshold is NOT also in the BattleDefinition (or set it very high), otherwise the two conditions compete and the player wins by routing the enemy before surviving is tested.
- `route_defeat_threshold` at 0.40 combined with aggressive AI targeting (Tactical AI system) can create frustrating early defeats before the player has learned morale management. For Acts I–II (early campaign), consider 0.60 as the defeat threshold while keeping victory at 0.50 (player wins easier, loses harder — scaffolded difficulty).

## Visual/Audio Requirements

*Lean mode: `art-director` not consulted — review against art bible before production.*

**Victory state:**
- Fade or dissolve over the tactical map with a clean full-screen overlay; the battlefield remains visible in the background at reduced saturation (the battle is *over*, not erased)
- Title text: "VICTORY" in the game's primary display font; subtitle: the condition that triggered (e.g., "The enemy line has broken." or "The bridge was held.")
- SFX: triumphant but measured — not a fanfare. Drums, a horn call, then silence. P3 tone — this is relief and exhaustion, not celebration.

**Defeat state:**
- Slower fade than victory; darker overlay
- Title text: "DEFEAT"; subtitle: the trigger condition (e.g., "Your army has broken." or "Kaster has fallen.")
- SFX: low drum, muted. No dramatic sting. The absence of music after battle-end SFX conveys the weight.

**Route fraction progress (in-battle, HUD):**
- Enemy route fraction shown as a subtle progress indicator in the Tactical HUD (see UI Requirements). No explicit "enemy morale meter" — the player reads the battlefield; this indicator is context, not a target reticle.
- Player route fraction is NOT shown by default — the player should read their own squad states. An accessibility option may add a numeric display.

**Objective hex visual:**
- Objective hexes are marked at battle start with a distinct overlay (flag icon or colored ring — art bible aesthetic). The HOLD counter (X/N turns) appears on-hover.
- When the player gains control of an objective hex, a subtle pulse effect on the hex ring signals "now holding."
- When control is lost, the ring dims or changes color.

**SFX requirements:**
- Victory and defeat SFX must be clearly distinct from mid-battle SFX (routing sounds, combat impacts). They are endpoint signals, not battle sounds.
- Volume: defeat SFX should be quieter than victory SFX — emphasizing the "silence after the storm" rather than a loud failure sting.

## UI Requirements

**Battle End Screen (post-battle summary):**
- Displayed after the victory/defeat overlay before returning to the campaign layer
- Shows: VICTORY / DEFEAT / DRAW; trigger condition text; end turn number; player route fraction (X of Y squads lost); enemy route fraction (X of Y squads lost)
- If LOSE_VIP triggered: officer name and status ("Kaster — Incapacitated. He will recover after this battle.")
- "Continue" button to return to campaign

**In-battle condition tracker (HUD element):**
- For ROUTE_ENEMY condition: an enemy force indicator (e.g., a small colored bar or squad-count fraction "Enemy: 3/10") visible in HUD. Updates each turn after evaluation.
- For HOLD_OBJECTIVE condition: objective hex label shows hold progress (e.g., "Bridge: 2 / 5 turns held"). Displayed on hover over the objective hex, and optionally as a permanent HUD element if the objective is the primary win condition.
- For SURVIVE_TURNS condition: turn countdown displayed in HUD ("Hold until turn 8 — 3 turns remaining").
- For EXCEED_TURN_LIMIT defeat: same turn display with urgency color shift as deadline approaches (amber at ≤ 3 turns remaining, red at ≤ 1 turn).

**Route fraction display:**
- Enemy route fraction (progress toward player victory) is displayed as a squad count indicator. Example: "Enemy: 5 / 10 squads broken" — precise enough to be legible, not so abstract it requires interpretation.
- Player route fraction is NOT displayed numerically by default (player reads their own squads). An accessibility option (`show_player_route_fraction: true`) adds numeric display for players who want it.

📌 **UX Flag — Victory/Defeat Conditions System**: This system has UI requirements. In Phase 4 (Pre-Production), run `/ux-design` to create a UX spec for the battle end screen and condition tracker HUD elements before writing epics. Stories that reference victory/defeat display should cite `design/ux/battle-end.md` and `design/ux/tactical-hud.md`, not this GDD directly.

## Acceptance Criteria

*Unit test evidence is BLOCKING for this Logic-category system. All criteria are independently verifiable by a QA tester without reading the GDD. QA Lead reviewed for completeness — 28 criteria covering all 13 core rules.*

---

**Formula Correctness — F-1 (route_fraction)**

**AC-01**
**GIVEN** a side had 10 starting squads, has 2 broken-on-map, 1 routed-off-map, and 2 dead squads, **WHEN** route_fraction is evaluated, **THEN** the result equals 0.50 (5/10).

**AC-02**
**GIVEN** a side had 8 starting squads, has 0 broken-on-map, 0 routed-off-map, and 3 dead squads, **WHEN** route_fraction is evaluated, **THEN** the result equals 0.375 (3/8) — below the 0.50 threshold, no rout condition fires.

**AC-03**
**GIVEN** a side had 6 starting squads and every squad is dead (HP = 0), **WHEN** route_fraction is evaluated, **THEN** the result equals 1.0 — dead squads count toward the numerator identically to broken or routed squads.

---

**Boundary Conditions — F-2 (threshold edges)**

**AC-04**
**GIVEN** the enemy's route_fraction is exactly 0.50, **WHEN** victory conditions are evaluated, **THEN** ROUTE_ENEMY fires and the result is VICTORY — the threshold is inclusive (>= 0.50).

**AC-05**
**GIVEN** the enemy's route_fraction is 0.49 (e.g., 4 of 9 starting squads lost → 4/9 ≈ 0.444), **WHEN** victory conditions are evaluated, **THEN** ROUTE_ENEMY does NOT fire.

**AC-06**
**GIVEN** the player's route_fraction is exactly 0.50, **WHEN** defeat conditions are evaluated, **THEN** PLAYER_ROUTED fires and the result is DEFEAT — the threshold is inclusive.

**AC-07**
**GIVEN** the player's route_fraction is 0.49, **WHEN** defeat conditions are evaluated, **THEN** PLAYER_ROUTED does NOT fire.

---

**Formula F-3 — EXCEED_TURN_LIMIT boundary**

**AC-15**
**GIVEN** current_turn equals max_turns exactly, **WHEN** the turn-limit condition is evaluated, **THEN** EXCEED_TURN_LIMIT does NOT fire — the condition requires current_turn > max_turns (strictly greater than).

**AC-16**
**GIVEN** current_turn equals max_turns + 1, **WHEN** the turn-limit condition is evaluated, **THEN** EXCEED_TURN_LIMIT fires and the result is DEFEAT.

---

**Evaluation Order — Hard defeats checked first**

**AC-08**
**GIVEN** the player's named VIP officer's squad is eliminated this turn AND the enemy's route_fraction is >= 0.50 simultaneously, **WHEN** end-of-turn conditions are evaluated, **THEN** LOSE_VIP fires and the result is DEFEAT — hard defeat takes precedence; ROUTE_ENEMY is never evaluated.

**AC-09**
**GIVEN** ENEMY_HOLDS_OBJECTIVE is active (enemy has held the objective hex for the required consecutive turns) AND the enemy's route_fraction is >= 0.50 simultaneously, **WHEN** conditions are evaluated, **THEN** ENEMY_HOLDS_OBJECTIVE fires and the result is DEFEAT — hard defeat checked before victory.

**AC-10**
**GIVEN** LOSE_VIP fires this turn AND PLAYER_ROUTED would also fire this turn, **WHEN** conditions are evaluated, **THEN** the result is DEFEAT (LOSE_VIP) — hard defeat fires before soft defeat; only one result is returned.

---

**Evaluation Order — Victory checked before soft defeat**

**AC-11**
**GIVEN** the enemy's route_fraction is >= 0.50 AND the player's route_fraction is >= 0.50 on the same turn (mutual rout), AND no hard defeat conditions are active, **WHEN** conditions are evaluated, **THEN** the result is VICTORY — victory conditions are checked before PLAYER_ROUTED (soft defeat), so mutual rout resolves as a Pyrrhic win.

**AC-12**
**GIVEN** the enemy's route_fraction is >= 0.50 AND current_turn > max_turns on the same evaluation pass, **WHEN** conditions are evaluated, **THEN** the result is VICTORY — victory is checked before EXCEED_TURN_LIMIT.

---

**Evaluation Order — Soft defeats relative to turn limit**

**AC-13**
**GIVEN** the player's route_fraction is >= 0.50 AND current_turn > max_turns on the same evaluation pass, **WHEN** conditions are evaluated, **THEN** the result is DEFEAT (PLAYER_ROUTED) — PLAYER_ROUTED is checked before EXCEED_TURN_LIMIT per evaluation order.

**AC-14**
**GIVEN** current_turn > max_turns AND no other condition has fired, **WHEN** conditions are evaluated, **THEN** the result is DEFEAT (EXCEED_TURN_LIMIT).

---

**Hex Control — HOLD_OBJECTIVE and ENEMY_HOLDS_OBJECTIVE**

**AC-17**
**GIVEN** a player squad in BROKEN state is the only player unit on the objective hex and no enemy squads are present, **WHEN** hex control is evaluated, **THEN** the player does NOT control the hex — BROKEN squads do not count for control.

**AC-18**
**GIVEN** a player squad in STEADY state and an enemy squad both occupy the objective hex, **WHEN** hex control is evaluated, **THEN** neither side controls the hex — control requires >= 1 non-BROKEN friendly squad AND 0 enemy squads present.

**AC-19**
**GIVEN** the player has controlled the objective hex for N-1 consecutive turns, then loses control for exactly 1 turn, then regains control, **WHEN** HOLD_OBJECTIVE is evaluated, **THEN** the consecutive-turn counter resets to 0 on loss of control and begins counting again from 1 on regain — N consecutive turns must be uninterrupted.

**AC-20**
**GIVEN** the player has controlled the objective hex for exactly N consecutive turns (matching `hold_turns` in the BattleDefinition), **WHEN** HOLD_OBJECTIVE is evaluated at the end of that turn, **THEN** HOLD_OBJECTIVE fires and the result is VICTORY.

**AC-21**
**GIVEN** the enemy has held the objective hex for exactly N consecutive turns with no interruption (matching `enemy_hold_turns` in the BattleDefinition), **WHEN** ENEMY_HOLDS_OBJECTIVE is evaluated, **THEN** it fires and the result is DEFEAT.

---

**SURVIVE_TURNS**

**AC-22**
**GIVEN** a scenario has SURVIVE_TURNS with `target_turn = 10`, the battle reaches turn 10, and no defeat condition has fired this turn, **WHEN** conditions are evaluated at the end of turn 10, **THEN** SURVIVE_TURNS fires and the result is VICTORY.

**AC-23**
**GIVEN** a scenario has SURVIVE_TURNS with `target_turn = 10` and PLAYER_ROUTED fires on turn 9, **WHEN** conditions are evaluated, **THEN** the result is DEFEAT — PLAYER_ROUTED fires before SURVIVE_TURNS would be checked.

---

**ELIMINATE_TARGET**

**AC-24**
**GIVEN** a scenario has ELIMINATE_TARGET for Squad X, and Squad X's HP reaches 0 this turn, **WHEN** conditions are evaluated, **THEN** ELIMINATE_TARGET fires and the result is VICTORY.

**AC-25**
**GIVEN** a scenario has ELIMINATE_TARGET for Squad X, and Squad X routes off-map (enters BROKEN and exits the map edge) without reaching HP = 0, **WHEN** conditions are evaluated, **THEN** ELIMINATE_TARGET fires and the result is VICTORY — off-map via routing counts as eliminated for this condition.

---

**LOSE_VIP**

**AC-26**
**GIVEN** a scenario has LOSE_VIP for Officer Y, and Officer Y is incapacitated (named characters are never killed in field battles — they are incapacitated), **WHEN** conditions are evaluated at end of turn, **THEN** LOSE_VIP fires and the result is DEFEAT.

**AC-27**
**GIVEN** a scenario has LOSE_VIP for Officer Y, and Officer Y's squad's HP reaches 0 (squad eliminated), **WHEN** conditions are evaluated, **THEN** LOSE_VIP fires — squad elimination triggers LOSE_VIP regardless of the officer's personal survival state.

---

**Complete Evaluation Order Integration**

**AC-28**
**GIVEN** on the same turn: ENEMY_HOLDS_OBJECTIVE is met, ROUTE_ENEMY is met, PLAYER_ROUTED is met, and EXCEED_TURN_LIMIT is met, **WHEN** the evaluator runs its full pass, **THEN** the result is DEFEAT (ENEMY_HOLDS_OBJECTIVE) — hard defeat checked first, wins over all subsequent checks regardless of order of other triggers.

---

*Coverage map: F-1 formula (AC-01–03) · F-2 thresholds (AC-04–07) · F-3 turn limit (AC-15–16) · Evaluation order all 4 tiers (AC-08–14, AC-28) · Hex control (AC-17–21) · SURVIVE_TURNS (AC-22–23) · ELIMINATE_TARGET (AC-24–25) · LOSE_VIP (AC-26–27).*

## Open Questions

1. **DRAW as a campaign outcome** — The mutual rout edge case currently resolves as VICTORY (Pyrrhic win). If campaign design later requires a DRAW state (no territory gained, both sides take losses but neither "won"), the BattleDefinition flag `allow_draw: true` is reserved for this purpose. Confirm with campaign layer design whether DRAW has distinct consequences from DEFEAT (territory retention, manpower recovery differences) before implementing.

2. **LOSE_VIP and incapacitation vs. squad elimination** — AC-27 specifies that squad elimination triggers LOSE_VIP even if the officer personally survived. But in later campaign scope, officers can detach from their squad before it's destroyed (e.g., scripted retreat event). Does the LOSE_VIP trigger check squad elimination OR officer incapacitation OR either? For MVP, squad elimination is sufficient. Revisit when Officer Passive Ability System (design #14) defines officer detach mechanics.

3. **Difficulty scaling via thresholds** — The tuning knobs section suggests Acts I–II could use asymmetric thresholds (player defeat threshold 0.60, victory threshold 0.50) for scaffolded difficulty. Confirm with Difficulty Settings System (design #32, Full Vision) whether per-act threshold overrides are the right mechanism or whether a single difficulty setting modifies all BattleDefinitions at load time.

4. **Starting squads with mid-battle reinforcements** — This GDD fixes `starting_squads` at battle start for the denominator. If campaign events add reinforcements mid-battle (explicitly future scope), the current formula means reinforcements don't affect the threshold denominator and have no "rout protection" value — they can die without pulling closer to the rout threshold. Whether this is the desired design (reinforcements feel purely additive) or whether they should re-denominate should be decided when reinforcement mechanics are designed.

5. **Post-battle summary routing fractions** — The BattleResult report includes `route_fraction_player` and `route_fraction_enemy` for the post-battle screen. Confirm with Campaign Layer design whether these values also need to be stored in save data for narrative callbacks (e.g., a story event that references "the devastating losses at the Open Field battle" based on the player's actual route fraction from that specific battle).
