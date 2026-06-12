# Duel System

> **Status**: Designed
> **Author**: Game Designer + Systems Designer
> **Last Updated**: 2026-06-12
> **Implements Pillar**: P2 — Officers Are the Story + P4 — Authored Peaks, Player Valleys
> **Review Mode**: Lean

## Overview

The Duel System governs personal combat between two officers — a turn-based simultaneous-stance sub-game that interrupts the calling context until one participant is defeated, exhausted, or the player voluntarily yields the killing blow. Duels occur in three distinct contexts: **field challenges** (voluntary, adjacent officers during tactical combat), **scripted story moments** (mandatory, authored with potential AI behavior overrides), and **diplomatic resolutions** (a city submits through personal combat instead of war). Each duel uses a three-way stance system — Attack, Defend, Feint — with rock-paper-scissors resolution (Attack beats Feint, Feint beats Defend, Defend beats Attack), a Stamina resource that depletes over turns to prevent indefinite stalling, and a "Read" mechanic that gives the higher-WAR officer a ~70%-accurate hint of their opponent's upcoming stance every three turns. Named officers carry an optional Signature Move — a powerful, high-cost action defined through a hook interface designed for extensibility across sequels. The system is fully data-driven: any officer can duel any other officer without code changes; scripted duels load a `ScriptedDuelDefinition` that can override AI behavior, force outcome flags, or trigger narrative events. Duel outcomes feed back to their calling context: field duels apply morale effects; scripted duels set story flags; diplomatic duels determine city submission.

## Player Fantasy

*Lean mode: `creative-director` not consulted — review against art bible and game pillars before production.*

The fantasy is **the read** — that one turn where you've been watching your opponent's pattern for three turns, the hint flickers up ("He seems to be readying an attack..."), and you call Defend. His Attack crashes against your parry. Maximum counter-damage. For one moment you're the general who understands the battle at the personal scale: not commanding hundreds, but inhabiting your best officer and winning through the same intelligence that wins campaigns. The WAR stat's "Read" mechanic makes this moment *legible* — it confirms what skilled play already suspects, and feels like justified reward rather than random luck.

The **Alexsen fantasy** is the freight train. When you drop Crushing Blow, your opponent sees the stamina cost tick down and knows it's coming. They have no good answer — defend and the blow breaks through anyway; feint and you still hit for reduced damage; attack and you both take the collision. The move's power isn't hidden. Its inevitability IS the fantasy. Alexsen hits like a force of nature and his stamina burns fast because of it — a player who learned his mechanics understands that Crushing Blow must land early or the window closes.

The **Thane-reveal fantasy** in Mission 6: the player controls Alexsen vs Thane and notices, over several turns, that Thane keeps missing moments where he clearly could have connected. The duel feels almost too easy. "Is the AI broken? Why is he pulling his strikes?" The end-scene explains: Thane chose to let Alexsen live. He was reading the whole duel, wanted to join Kaster's force, and spent the duel showing you his quality without injuring you. A system that felt defective becomes the most elegant character introduction in the game. The "intentional miss" must feel genuinely odd — not subtle, not polished into invisibility, but noticeably off — so that the reveal recasts everything retroactively.

The **diplomatic duel fantasy** is the unspoken argument. The city doesn't want to die, but their culture demands proof. Winning here feels like diplomacy through presence — you proved yourself worthy to this city's honor code without burning a single building. It's P1 (Victory Through Preparation) applied at the officer scale: you picked the right officer, with the right WAR stat, for the right city.

## Detailed Design

### Core Rules

**Duel Participants:**
Every duel involves exactly two `DuelParticipant` objects. A DuelParticipant wraps an `Officer` and derives three duel-specific stats from the officer's permanent stats:
- **Resolve** — duel HP (derived from CHR; see F-1)
- **Stamina** — available actions pool (derived from INT; see F-2)
- **Attack Damage** — damage output on a winning Attack stance (derived from WAR; see F-3)
- **Signature Move** — one optional special action loaded from data (may be `null` for officers with no duel-specific move)

**Turn Structure:**
Each duel turn executes these steps in order:

1. **Stance Selection** — both participants simultaneously choose from their available actions. Player sees their own selection UI; AI selects internally. Available actions depend on current Stamina (see Stamina Constraints table below).
2. **Signature Move Declaration** — if a participant selects their Signature Move, it is flagged. Signature Move resolution overrides normal RPS for that turn.
3. **Resolution** — stances are revealed simultaneously. If a Signature Move was declared, its `on_resolve()` hook fires first. Otherwise, the Stance Resolution Table (below) determines outcomes.
4. **Damage Application** — Resolve values are updated for both participants.
5. **Stamina Deduction** — Stamina costs for the chosen actions are deducted from both participants.
6. **Read Check** — if `current_turn mod 3 == 0` AND the higher-WAR participant has not yet received a Read hint this turn, the Read mechanic fires (see Read Mechanic rules below).
7. **Yield Check** — if the opponent's Resolve is ≤ `opponent.max_resolve × yield_threshold` AND the player has not already yielded, the Yield action becomes available in the player's UI.
8. **Termination Check** — evaluate termination conditions (see Termination Conditions below). If any condition is met, the duel ends.

**Stance Resolution Table:**

| P1 Stance | P2 Stance | RPS Winner | Damage to P2 | Damage to P1 |
|---|---|---|---|---|
| Attack | Attack | Tie | `floor(P1.attack_damage × 0.5)` | `floor(P2.attack_damage × 0.5)` |
| Attack | Defend | P2 wins | 0 | `ceil(P2.attack_damage × 0.4)` (counter) |
| Attack | Feint | P1 wins | `P1.attack_damage` | 0 |
| Defend | Attack | P1 wins | `ceil(P1.attack_damage × 0.4)` (counter) | 0 |
| Defend | Defend | Tie | 0 | 0 |
| Defend | Feint | P2 wins | 0 | `ceil(P2.attack_damage × 0.6)` (feint break) |
| Feint | Attack | P2 wins | 0 | `P2.attack_damage` |
| Feint | Defend | P1 wins | `ceil(P1.attack_damage × 0.6)` (feint break) | 0 |
| Feint | Feint | Tie | 0 | 0 |

*Counter damage (winning Defend): ~40% of the winning officer's attack_damage — the parry-and-riposte. Feint break damage (winning Feint): ~60% of the winning officer's attack_damage — breaks the guard but doesn't hit cleanly.*

**Stamina Constraints (available actions by current Stamina):**

| Stamina remaining (start of turn) | Available Stances | Signature Move |
|---|---|---|
| ≥ 4 | Attack, Defend, Feint | Available (if not spent) |
| 3 | Attack, Defend, Feint | Locked (most Sig Moves cost 3-4) |
| 2 | Attack, Defend, Feint | Locked |
| 1 | Defend, Feint only | Locked (Attack costs 2) |
| 0 | Defend only | Locked |

Stamina costs per action:
- **Attack**: 2
- **Defend**: 1
- **Feint**: 1
- **Signature Move**: defined per move (Alexsen's Crushing Blow: 4)

**Termination Conditions (checked in order each turn):**

1. **Resolve Depleted** — if any participant's Resolve ≤ 0: duel ends. The participant at ≤ 0 is Defeated; the other is Victor. If both simultaneously reach ≤ 0 in the same turn: the participant with higher remaining Resolve (before this turn's damage) wins; if exactly equal, the one who dealt more total damage this duel wins (tiebreaker: P1 advantage if still tied).
2. **Stamina Exhaustion** — if any participant reaches Stamina 0 after deduction: they are Exhausted. An Exhausted participant can only Defend. If both participants are simultaneously Exhausted at turn end: one Final Exchange turn runs (both Defend → 0 damage → duel declared a draw by mutual exhaustion). Draw outcome is handled by context (field duels: no morale effect; scripted: check ScriptedDuelDefinition for override; diplomatic: a draw means the city does not submit).
3. **Yield Declared** — player selects Yield action (available when opponent Resolve ≤ yield threshold). Duel ends with result: YIELD\_WIN. Victor = player's officer; Opponent = survived.
4. **Scripted Override** — a `ScriptedDuelDefinition` turn trigger fires. Duel ends with the specified scripted outcome.

**The "Read" Mechanic:**
- Fires at the start of turn step 6 when `current_turn mod 3 == 0` (turn 3, 6, 9...)
- Only fires for the participant whose WAR stat is strictly higher than their opponent's
- If both participants have identical WAR: no Read hint fires
- Hint accuracy: 70% of the time, the hint correctly shows the opponent's selected stance for this turn (note: the hint fires AFTER both stances are selected in step 1, so the opponent's choice is already made; the hint reveals it with 70% accuracy before resolution in step 3)
- Hint display: flavor text, not a hard game-state reveal: *"[Opponent name] seems to be favoring [stance]..."* or *"[Opponent name]'s grip shifts — a feint? Perhaps."*
- 30% inaccuracy: shows a randomly selected incorrect stance
- The player can see both the hint AND their own selected stance; they cannot change their selection but the Read is informational going forward

**Signature Move — Alexsen: Crushing Blow:**
- Availability: once per duel (cooldown: 0 uses after first use)
- Stamina cost: 4
- Resolution override (replaces normal RPS for this turn):
  - **vs Defend**: Crushing Blow bypasses the parry — opponent takes `P1.attack_damage` damage (not the counter outcome). Alexsen takes 0 damage.
  - **vs Feint**: Feint partially avoids the blow — opponent takes `ceil(P1.attack_damage × 0.75)`. Alexsen takes 0 damage.
  - **vs Attack**: Mutual collision — opponent takes `P1.attack_damage`. Alexsen takes `ceil(P2.attack_damage × 0.75)` (he's committed to the blow, absorbs a reduced counter hit).
- Signature Move is declared at step 2 (before stance resolution). The opponent cannot change their stance after Signature Move is declared — both choices are simultaneous.
- Signal to player UI when Crushing Blow is declared: Alexsen's portrait shifts and the opponent sees it coming (intentional — the unstoppable quality is part of the design).

**Signature Move Interface (for extensibility):**
All Signature Moves are defined as data entries in `assets/data/signature_moves.json`:
```json
{
  "move_id": "alexsen_crushing_blow",
  "officer_id": "alexsen",
  "stamina_cost": 4,
  "cooldown": 0,
  "on_resolve": "CrushingBlowResolver"
}
```
The `on_resolve` value names a resolver class that implements the interface:
```
SignatureMoveResolver:
  resolve(attacker, defender_stance) -> (damage_to_defender, damage_to_attacker)
```
New officers in sequels add only data entries + resolver classes — no changes to the core duel engine.

**Field Challenge Context:**
- A field challenge can be initiated during the player's Movement Phase when two opposing officers' squads are adjacent (hex distance = 1)
- Player initiates a challenge by targeting the enemy officer; AI may initiate a challenge against the player (governed by Tactical AI logic — not defined here)
- The challenged officer may **Accept** or **Refuse**:
  - Accept: duel begins; tactical battle pauses (no squad actions allowed until duel resolves)
  - Refuse: the challenging squad gains +10 morale; the refusing squad takes −15 morale penalty (cultural disrespect on Soliterra)
- Field duel outcome effects on the tactical battle:
  - **VICTORY** (player officer wins): enemy officer is incapacitated and withdraws; enemy squad becomes officer-less; enemy squad takes −25 morale (heavy blow)
  - **YIELD\_WIN** (player yields the killing blow): same morale effects as VICTORY + narrative flag `field_yield_[enemy_officer_id]` set
  - **DEFEAT** (player officer loses): player officer is incapacitated (not killed — consistent with Morale GDD named officer rule); player squad becomes officer-less; player squad takes −25 morale
  - **Draw** (mutual exhaustion): no morale effects; both officers resume their squads
- A squad (or its officer) cannot initiate or accept another field challenge for the remainder of the current battle after participating in one (once per battle per officer)
- The incapacitation of a named officer from a field duel does NOT trigger the `LOSE_VIP` defeat condition in the Victory/Defeat Conditions System — the duel is a voluntary engagement, not a tactical assassination

**Scripted Duel Context:**
- Defined by a `ScriptedDuelDefinition` data file in `assets/data/duels/[mission_id].json`
- Fields:
  - `player_officer_id`: officer the player controls
  - `opponent_officer_id`: AI-controlled opponent
  - `allow_player_loss`: if false, losing triggers a mission retry (cannot lose narratively)
  - `ai_behavior`: `"optimal"` | `"intentional_miss"` | `"scripted_sequence"`
    - `"optimal"`: AI always selects the statistically best stance given known state
    - `"intentional_miss"`: AI selects a losing or neutral stance with `miss_frequency` probability on turns it would normally win
    - `"scripted_sequence"`: AI follows a predetermined `ai_stance_list[]` (ignoring state)
  - `miss_frequency`: float [0.0, 1.0] — probability of AI "missing" when `ai_behavior = "intentional_miss"` (Mission 6 Thane: 0.40)
  - `ai_stance_list`: array of stance strings — used only with `"scripted_sequence"` behavior
  - `yield_forced_at_resolve_pct`: float [0.0, 1.0] — when opponent Resolve ≤ this % of max, Yield becomes the ONLY available player action (authored emotional beat; 0.0 = disabled)
  - `outcome_flag_victory`: story event flag set when player wins
  - `outcome_flag_defeat`: story event flag set when player loses (only meaningful when `allow_player_loss: true`)
  - `outcome_flag_yield`: story event flag set when player uses Yield
- Named officers' stats are used normally in scripted duels — the AI's behavior is scripted but the DuelParticipant stats are real
- After a scripted duel resolves, the tactical battle resumes with state intact (other squads have not moved; no turns have elapsed)

**Mission 6 specifics (The Challenge of the North):**
- Player controls Alexsen; AI controls Thane
- `ai_behavior: "intentional_miss"` with `miss_frequency: 0.40`
- Design intent: Thane is read as "strangely weak" or "making mistakes." End-scene reveal explains Thane chose to lose intentionally. The miss_frequency of 0.40 means Thane misses roughly 2 of every 5 turns he would normally win — enough to be noticeable, not enough to feel random or glitchy
- `allow_player_loss: false` (Alexsen must "win" for Thane to join)
- `outcome_flag_victory: "thane_yields"` — triggers Thane's join cutscene
- No yield mechanic in this duel (Alexsen is not in a position to yield to Thane in the narrative)

**Diplomatic Duel Context:**
- Triggered during Diplomacy interactions with specific independent cities
- Uses standard duel rules — no `ScriptedDuelDefinition` override (the contest is fair)
- Outcome:
  - **VICTORY or YIELD\_WIN**: city submits; diplomatic flag set; no military engagement required
  - **DEFEAT or Draw**: city does not submit; diplomatic path closed for this city for the current campaign turn; full military engagement is required if the player wants the city
- Named officers incapacitated by diplomatic duel loss are unavailable for campaign actions for 2 turns (injury recovery — not relevant to tactical combat)
- The city whose diplomatic duel is lost does not gain a morale or defensive bonus from winning — the duel result is purely political, not military

### States and Transitions

**Duel States:**

| State | Description |
|---|---|
| INACTIVE | No duel in progress |
| SELECTING | Current turn: both participants choosing their stance (player UI open) |
| RESOLVING | Stances revealed; damage being applied |
| READ\_PHASE | Read hint is being displayed before next SELECTING state |
| YIELD\_AVAILABLE | Opponent's Resolve is at or below yield\_threshold; Yield button visible |
| ENDED\_VICTORY | Duel resolved: player officer won |
| ENDED\_DEFEAT | Duel resolved: player officer lost |
| ENDED\_YIELD | Duel resolved: player officer yielded |
| ENDED\_DRAW | Duel resolved: mutual exhaustion |

**Transitions:**

```
INACTIVE
  → SELECTING         (duel initiated from any context)

SELECTING
  → RESOLVING         (both stances confirmed — simultaneous)

RESOLVING
  → ENDED_VICTORY     (any participant Resolve ≤ 0 and player wins)
  → ENDED_DEFEAT      (any participant Resolve ≤ 0 and player loses)
  → ENDED_DRAW        (both exhausted simultaneously, Final Exchange)
  → READ_PHASE        (turn mod 3 == 0 and Read fires)
  → YIELD_AVAILABLE   (opponent Resolve hits yield threshold)
  → SELECTING         (no termination — next turn begins)

READ_PHASE
  → YIELD_AVAILABLE   (opponent Resolve hits yield threshold during Read display)
  → SELECTING         (Read hint displayed; next turn begins)

YIELD_AVAILABLE
  → ENDED_YIELD       (player selects Yield)
  → SELECTING         (player selects a stance instead; Yield remains available)
  → ENDED_VICTORY     (opponent Resolve hits 0 — Yield was available but player chose a stance)

ENDED_* → INACTIVE    (after context handles outcome callbacks)
```

**Note:** `YIELD_AVAILABLE` is a persistent flag on the duel state, not a blocking state — the player can continue fighting past the yield threshold. Yield remains in the UI until the duel ends.

### Interactions with Other Systems

| System | This System Reads | This System Writes |
|---|---|---|
| **Officer Stats System** | `officer.war`, `officer.chr`, `officer.int` — inputs to F-1, F-2, F-3 | — (read-only) |
| **Officer Passive Ability System** | `officer.signature_move` — the move's resolver and cost loaded from data | — (Passive System defines the resolver; Duel System calls it) |
| **Morale System** (field context only) | — | Writes morale delta to both squads on field duel outcome (−25 to loser squad, +0 to winner — morale bonus is omitted to avoid double-reward with natural morale recovery) |
| **Victory/Defeat Conditions System** | — | Does NOT write to VDF — field duel incapacitation is not a VIP defeat trigger |
| **Hex Movement System** | `squad.hex_position`, `squad.owner` — to validate adjacency for field challenges | — |
| **Story Event System** | — | Writes `outcome_flag_victory/defeat/yield` strings from ScriptedDuelDefinition |
| **Campaign Layer** (diplomatic context) | — | Writes `diplomatic_submission` flag + officer incapacitation duration |
| **Tactical HUD** | — | Duel sub-game UI overlay (Resolve bars, Stamina, stance buttons, Read hint, Yield button) |
| **Duel UI** (#27 in systems index) | — | Owns all visual presentation of the duel sub-game |

**Context callback interface:**
When a duel ends, the DuelSystem calls `DuelContext.on_duel_ended(result: DuelResult)`. Each context (Field, Scripted, Diplomatic) implements this interface:
- Field: applies morale effects, sets officer incapacitation flag
- Scripted: sets story event flags, may trigger cutscene
- Diplomatic: sets city submission flag or marks diplomatic path closed

This pattern keeps the Duel System context-agnostic — it does not know which context called it.

## Formulas

*Systems Designer reviewed: resolved offset raised from +30 to +40 to prevent high-WAR/low-CHR officers (Thane) being too fragile; stamina budget role as implicit turn limiter confirmed and documented.*

---

### F-1: Duel Resolve (Duel HP from CHR)

```
duel_resolve = floor(CHR / 2) + 40
```

**Variables:**
| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| Officer CHR stat | chr | int | [1, 100] | Charisma/composure from Officer Stats System |
| Duel Resolve (output) | duel_resolve | int | [40, 90] | Officer's HP pool for this duel; depletes when taking stance damage |

**Output range:** 40 (CHR 1) to 90 (CHR 100). CHR represents composure and psychological endurance — the same stat that governs morale recovery in the Morale System is now the measure of how long an officer holds together under direct personal threat.

**Named officer resolve values:**
| Officer | CHR | Duel Resolve |
|---|---|---|
| Kaster | 88 | 84 |
| Zhuge Jian | 80 | 80 |
| Sander | 70 | 75 |
| Alexsen | 75 | 77 |
| Bon shi hai | 62 | 71 |
| Jin Tao | 50 | 65 |
| Thane | 45 | 62 |

*Thane at 62 resolve (revised from 52 with +30 offset): survives 4–5 hits from Alexsen's 14-damage attacks — a realistic 5–8 turn duel window for a high-WAR officer.*

---

### F-2: Stamina Pool (from INT)

```
stamina_pool = floor(INT / 10) + 5
```

**Variables:**
| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| Officer INT stat | int_stat | int | [1, 100] | Intelligence/tactical acuity from Officer Stats System |
| Stamina Pool (output) | stamina_pool | int | [5, 15] | Total stamina available for this duel; each action deducts from this pool |

**Output range:** 5 (INT 1) to 15 (INT 100). Stamina acts as an **implicit turn budget**: Alexsen (INT 40, stamina 9) can execute ~9 actions before exhaustion — if he spends 4 stamina on Crushing Blow, he has 5 remaining actions. A scholar archetype (INT 80–99, stamina 13–14) outlasts a warrior in a prolonged fight even if dealing less damage per turn.

**Named officer stamina values:**
| Officer | INT | Stamina Pool |
|---|---|---|
| Zhuge Jian | 99 | 14 |
| Kaster | 92 | 14 |
| Bon shi hai | 94 | 14 |
| Thane | 75 | 12 |
| Sander | 65 | 11 |
| Alexsen | 40 | 9 |

*Alexsen (9 stamina) + Crushing Blow (4 stamina) = 5 remaining actions. If he doesn't end the duel in those 5 turns post-Crushing Blow, he enters exhaustion and can only Defend.*

---

### F-3: Attack Damage (from WAR)

```
attack_damage = floor(WAR / 10) + 5
```

**Variables:**
| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| Officer WAR stat | war | int | [1, 100] | Warfare/martial prowess from Officer Stats System |
| Attack Damage (output) | attack_damage | int | [5, 15] | Damage dealt when officer wins an Attack stance match-up |

**Output range:** 5 (WAR 1) to 15 (WAR 100).

**Named officer attack_damage values:**
| Officer | WAR | Attack Damage |
|---|---|---|
| Alexsen | 98 | 14 |
| Lycurse | 92 | 14 |
| Thane | 90 | 14 |
| Kaster | 82 | 13 |
| Sander | 75 | 12 |
| Bon shi hai | 55 | 10 |
| Jin Tao | 45 | 9 |
| Zhuge Jian | 30 | 8 |

---

### F-4: Derived Damage Values

```
counter_damage   = ceil(attack_damage × 0.40)   [winning Defend]
feint_break_damage = ceil(attack_damage × 0.60)   [winning Feint]
tie_attack_damage = floor(attack_damage × 0.50)   [tied Attack vs Attack]
```

**Variables:**
| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| Winning officer's attack_damage | atk | int | [5, 15] | From F-3 for the stance winner |
| Counter damage (output) | counter_damage | int | [2, 6] | Defender's riposte on winning Defend — reward for correct read |
| Feint break damage (output) | feint_break_damage | int | [3, 9] | Feinter's penetrating hit on winning Feint — strong but not capping |
| Tie damage (output) | tie_attack_damage | int | [2, 7] | Each takes this when both choose Attack simultaneously |

**Example — Alexsen (attack 14):** counter = ceil(14×0.4) = 6; feint_break = ceil(14×0.6) = 9; tie = floor(14×0.5) = 7.

---

### F-5: Read Mechanic Accuracy

```
read_fires     = (current_turn mod 3 == 0) AND (participant_A.WAR > participant_B.WAR)
read_correct   = (random_float() < read_accuracy)   [read_accuracy default: 0.70]
```

**Variables:**
| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| Current duel turn | current_turn | int | [1, ∞] | Increments each full turn cycle |
| Read accuracy | read_accuracy | float | [0.0, 1.0] | Probability that the Read hint shows the correct stance; default 0.70 |
| Read fires (output) | read_fires | bool | true/false | true on turns 3, 6, 9... for the higher-WAR participant |
| Read correct (output) | read_correct | bool | true/false | 70% chance hint is accurate; 30% shows random incorrect stance |

**Note:** If `participant_A.WAR == participant_B.WAR` exactly: read\_fires = false for both. No tie-breaking on Read.

---

### Worked Example: Alexsen vs Kaster (revised +40 offset)

Setup:
- Alexsen: resolve 77, stamina 9, attack 14
- Kaster: resolve 84, stamina 14, attack 13

Turn 1 — Alexsen declares Crushing Blow (4 stamina); Kaster chooses Defend:
- Crushing Blow bypasses Defend → Kaster takes 14. Kaster resolve: 84 → 70.
- Alexsen stamina: 9 → 5. Kaster stamina: 14 → 13.

Turn 2 — Alexsen: Attack (2 stamina); Kaster: Feint (1 stamina):
- Attack beats Feint → Kaster takes 13. Kaster resolve: 70 → 57.
- Alexsen stamina: 5 → 3. Kaster stamina: 13 → 12.

Turn 3 — Read fires (Alexsen WAR 98 > Kaster WAR 82). Alexsen gets hint.
- Kaster chose Defend. Read correct (70%): hint says "Defend."
- Alexsen knows he should Feint. Alexsen: Feint (1 stamina); Kaster: Defend (1 stamina):
- Feint beats Defend → Kaster takes feint_break = ceil(14×0.6) = 9. Kaster resolve: 57 → 48.
- Alexsen stamina: 3 → 2. Kaster stamina: 12 → 11.

Turn 4 — Alexsen stamina 2 (Attack available, but borderline). Alexsen: Attack (2 stamina); Kaster: Attack (2 stamina):
- Tie: both take floor(13×0.5) = 6 (using Kaster's attack for Alexsen's damage) and floor(14×0.5) = 7 (Alexsen's attack for Kaster's damage).
- Kaster resolve: 48 → 41. Alexsen resolve: 77 → 71.
- Alexsen stamina: 2 → 0 (Exhausted). Kaster stamina: 11 → 9.

Turn 5 — Alexsen Exhausted (Defend only). Kaster: Attack; Alexsen: Defend:
- Defend beats Attack → Alexsen takes 0. Kaster takes counter = ceil(14×0.4) = 6.
- Wait, Defend beating Attack: the defending participant (Alexsen) deals counter_damage to the attacker (Kaster).
- Kaster resolve: 41 → 35. Alexsen still 71.
- Kaster stamina: 9 → 8.

Turn 6 — Alexsen Exhausted (Defend only). Kaster: Feint; Alexsen: Defend:
- Feint beats Defend → Alexsen takes feint_break = ceil(13×0.6) = 8. (Kaster's feint_break uses Kaster's attack_damage)
- Alexsen resolve: 71 → 63. Kaster resolve: 35.
- Kaster stamina: 8 → 7.

Turn 7 — Kaster: Attack; Alexsen: Defend:
- Defend beats Attack → Kaster takes 6 counter. Kaster resolve: 35 → 29. Alexsen 63.
- Kaster stamina: 7 → 6.

Turn 8 — Kaster: Attack; Alexsen: Defend:
- Kaster resolve: 29 → 23. Alexsen 63. Kaster stamina 5.

Turn 9 — Read fires again (turn 3, 6, 9 — turn 9). Kaster changes: Feint; Alexsen: Defend:
- Feint beats Defend → Alexsen takes 8. Alexsen: 63 → 55. Kaster: 23. Kaster stamina: 4.

Turn 10 — Kaster: Attack; Alexsen: Defend:
- Kaster: 23 → 17. Alexsen: 55. Kaster stamina 3.

Turn 11 — Kaster: Attack; Alexsen: Defend:
- Kaster: 17 → 11. Alexsen: 55. Kaster stamina 2.

Turn 12 — Kaster: Attack; Alexsen: Defend:
- Kaster: 11 → 5. Alexsen: 55. Kaster stamina 1.

Turn 13 — Kaster: Feint (stamina 1→0); Alexsen: Defend:
- Feint beats Defend → Alexsen: 55 → 47. Kaster: 5. Kaster Exhausted.

*At this point: Kaster resolve 5, Alexsen resolve 47. Both in exhaustion — only Defend available. Final Exchange: both Defend → 0 damage each. Winner = Alexsen (higher resolve remaining: 47 vs 5). Alexsen wins in 13 turns.*

**This duel is 13 turns long with the scenario described.** In practice, with mixed play (Kaster using Feint more aggressively to exploit Alexsen's forced Defend), the duel would end faster for Alexsen. The 8–13 turn range is appropriate for a narrative minigame.

## Edge Cases

| # | Situation | Rule |
|---|-----------|------|
| E-01 | **Equal WAR stats** | `read_fires = false` for both participants. No Read hint fires that turn. Neither side has the WAR advantage. |
| E-02 | **Both reach Resolve ≤ 0 on the same turn** | Mutual defeat. Field duel: no morale bonus to either squad. Scripted duel: check `outcome_flag_draw` — if defined, trigger it; if null, treat as player loss by default. |
| E-03 | **Stamina exactly equals Signature Move cost** | Signature Move is available. Officer legally spends their last stamina on it. After resolution, officer enters Exhaustion (Defend only). This is an intentional "all in" moment. |
| E-04 | **Both participants declare Signature Move simultaneously** | Both moves are declared. Higher-WAR participant's `on_resolve()` fires first. If P1's move defeats P2 (Resolve ≤ 0), P2's move does NOT fire — the defeated participant has no action. If P1's move does not defeat P2, P2's move fires second. |
| E-05 | **Scripted duel with `allow_player_loss: false` and player resolve drops to 0** | Duel is paused at player resolve = 1. The scripted intervention fires (escape route, reinforcement, lucky parry — written per mission). Duel ends with the scripted outcome, not the calculated defeat. |
| E-06 | **Field challenge is refused** | Refusing officer's squad takes −15 morale immediately. Challenging officer's squad takes no effect. The challenge cannot be re-issued to the same officer this battle. Once-per-battle limit is per-challenger, not per-target. |
| E-07 | **Challenged officer accepts but their squad is below STEADY** | Challenge proceeds normally. Duel mechanics are independent of squad morale state. Morale effects from the duel outcome (±25) apply after the duel ends, potentially routing an already-SHAKEN squad. |
| E-08 | **Officer incapacitated by an off-board event while dueling** | Off-board events queue until the duel ends. The Tactical Battle Controller freezes all external resolution while a duel is active. Incapacitation is applied post-duel, potentially skipping the winner's morale buff if they were incapacitated. |
| E-09 | **Yield action threshold: resolve at exactly `yield_threshold × max_resolve`** | Yield becomes available (rule uses ≤, inclusive). One point above the threshold: Yield is not available. |
| E-10 | **Player Yields but opponent refuse yield in a non-scripted duel** | Yield is always accepted in non-scripted duels — there is no refuse mechanic for the opponent. Yield is a unilateral player action that ends the duel immediately with the yield outcome. |
| E-11 | **Read hint fires on the turn the duel ends** | The hint displays for UI flavor but the duel resolves immediately. The player cannot act on the hint before termination. This is intentional — the Read is a "too late" moment if the duel ends the same turn. |
| E-12 | **Generic officer (no Signature Move data)** | Signature Move slot is `null`. The game does not render the Sig Move button in the action UI for this participant. Standard RPS only. No error — null Sig Move is a valid configuration. |
| E-13 | **DuelParticipant wraps an officer at INT 1 (minimum stamina 5)** | Stamina = `floor(1/10) + 5 = 5`. Officer can take 2 Attacks + 1 Defend, or 5 Defends. This is the valid floor — the officer has a very short duel window, which matches their character profile (not a combatant). |
| E-14 | **Diplomatic duel: player loses** | Diplomatic path for this city is closed for the current campaign turn. City does not submit. No field morale effect (diplomatic context has no tactical squads). The path may reopen next campaign turn if the Diplomacy System permits re-attempt (cross-system rule — deferred to Diplomacy GDD). |
| E-15 | **Field challenge issued to an officer whose stamina reached 0 from a prior duel this battle** | Stamina pool resets fresh at each duel start — it is a per-duel pool, not a persistent field resource. Officers can be challenged again in the same battle even if they previously exhausted their stamina. (Once-per-battle field challenge limit is on the *challenger*, not the *target*.) |
| E-16 | **Final Exchange tie (both participants at identical Resolve)** | Draw: field duel gives no morale bonus to either squad. Scripted duel triggers `outcome_flag_draw` if defined; otherwise treated as player loss. |
| E-17 | **Scripted duel `miss_frequency` = 1.0** | AI misses every Attack (Attack → no damage applied, stamina still deducted). Duel terminates when AI is Exhausted (stamina 0) or the player wins normally. `miss_frequency = 1.0` is a valid scripted config for a comedic or tragic scene — not only Mission 6. |
| E-18 | **Field challenge issued while a scripted duel is in progress** | Not possible — the Tactical Battle Controller marks the duel context as ACTIVE during scripted duels, blocking field challenge input. Field challenge input is re-enabled only after the scripted duel ends. |

## Dependencies

### Upstream Dependencies (this system reads from)

| System | Data Consumed | Interface | Notes |
|--------|--------------|-----------|-------|
| **Officer Stats System** | `officer.war`, `officer.chr`, `officer.int_stat` | Read via `Officer` resource object | Derives all three DuelParticipant stats (F-1, F-2, F-3). Officer stat values are immutable during a duel — no in-duel level-up or stat change. |
| **Officer Passive Ability System** | `officer.signature_move` (optional) | Read via `SignatureMove` data reference in officer data | Null if officer has no signature move. The Duel System calls `SignatureMove.on_resolve()` — it does not implement the move logic. |
| **Hex Movement System** | Adjacent hex check for field challenge eligibility | Query: `HexGrid.is_adjacent(challenger_pos, target_pos)` | Field challenge can only be issued when two officers occupy adjacent hexes. Adjacency uses the cube coordinate system (q, r, s). |
| **Story Event System** | Scripted duel configuration | `ScriptedDuelDefinition` loaded from data | The story system triggers scripted duels and provides the definition file. The Duel System does not know which mission it is in — it only reads the definition. |

### Downstream Dependents (this system writes to)

| System | Data Produced | Interface | Notes |
|--------|--------------|-----------|-------|
| **Morale System** | Morale delta for loser's squad, bonus for winner's squad | Writes to `Squad.morale_delta` field via `DuelContext.on_duel_ended(outcome)` | Field duels: −25 morale to loser's squad, +15 to winner's squad. Scripted duels: morale delta determined by `ScriptedDuelDefinition.morale_override` (or standard values if null). |
| **Story Event System** | Outcome flags written to story state | `StoryState.set_flag(outcome_flag_victory / outcome_flag_defeat / outcome_flag_draw)` | Flags are string keys from the ScriptedDuelDefinition. The Duel System writes the flag; Story Event System interprets it. Example: `"thane_yields"` triggers Thane join event. |
| **Diplomacy System** | Diplomatic path open/closed for this city this turn | `DiplomacyState.set_duel_result(city_id, won: bool)` | Diplomatic duel outcomes feed directly into whether the city submits. Implementation owned by the Diplomacy System — Duel System provides the boolean result. |
| **Tactical Battle Controller** | Duel-active lock (field event freeze) | `BattleController.set_duel_active(true/false)` | The controller must freeze all tactical turn processing while a duel is active. The Duel System signals start and end; the controller enforces the freeze. |

### Circular Dependency Note

The **Officer Passive Ability System** has a partial circular relationship with the Duel System: Alexsen's Crushing Blow and other duel-specific signature moves are defined in the Passive Ability GDD but *execute inside* the Duel System. Resolution: the Duel System owns the `on_resolve()` hook interface; the Passive Ability System provides the implementation. Design both GDDs in the same session to lock the interface contract before implementation begins.

## Tuning Knobs

All tuning knobs are defined in `assets/data/duel_config.json` unless noted.

| Knob | Default | Safe Range | Effect |
|------|---------|-----------|--------|
| `duel_resolve_base` | 40 | [30, 55] | Floor offset in F-1. Raising increases all officer resolve (longer duels). Lowering risks one-shot fragility for low-CHR officers. |
| `duel_stamina_base` | 5 | [3, 8] | Floor offset in F-2. Affects minimum duel length for INT-1 officers. |
| `duel_attack_base` | 5 | [3, 8] | Floor offset in F-3. Affects minimum damage for WAR-1 officers. |
| `counter_damage_ratio` | 0.40 | [0.25, 0.55] | Fraction of `attack_damage` dealt on a winning Defend. Lower = Defend is more passive; higher = defensive play becomes offensive threat. |
| `feint_break_ratio` | 0.60 | [0.45, 0.75] | Fraction of `attack_damage` dealt on a winning Feint. Must stay below 1.0 (Feint must never out-damage a clean Attack win). |
| `tie_attack_ratio` | 0.50 | [0.35, 0.65] | Each combatant's fraction of `attack_damage` taken on Attack-Attack tie. Values above 0.65 make Attack-Attack ties too punishing, discouraging Attack. |
| `read_accuracy` | 0.70 | [0.55, 0.85] | Probability the Read hint is correct. Above 0.85 feels deterministic; below 0.55 feels random. |
| `yield_threshold` | 0.30 | [0.20, 0.45] | Opponent's Resolve must be ≤ this fraction of their max before Yield is offered. Lower = Yield is only offered when opponent is very low; higher = Yield offered earlier, potentially trivializing mercy. |
| `field_challenge_refuse_penalty` | −15 | [−25, −5] | Morale applied to refusing officer's squad. More negative = refusing is more costly (encourages dueling culture); less negative = refusal is a tactical option. |
| `field_duel_loser_morale_delta` | −25 | [−35, −15] | Morale applied to losing squad after a field duel. Must exceed the `SHAKEN` → `BROKEN` threshold gap (which is 20 points) to reliably trigger routing on fragile squads. |
| `field_duel_winner_morale_delta` | +15 | [+5, +25] | Morale applied to winning squad after a field duel. |
| `crushing_blow_stamina_cost` | 4 | [3, 5] | Stamina cost for Alexsen's Crushing Blow signature move. Reduce to 3 to make it more usable; raise to 5 to make it a full commitment. |
| `exhaustion_stance` | Defend only | N/A (enum) | The only available action at Stamina = 0. Not numerically tunable — changing this would require design change review. |

**Scripted duel knobs** are per-mission in `ScriptedDuelDefinition` JSON files, not in the global config. See Core Rules → Scripted Duel Context for the full field list.

## Visual/Audio Requirements

### Visual

| Element | Description |
|---------|-------------|
| **Duel arena overlay** | Full-screen or near-full-screen overlay that suspends the tactical battle view. Styled as a close-up confrontation frame — portraits prominent, battlefield blurred in background. |
| **Stance selection UI** | Three-button layout (Attack / Defend / Feint) with Signature Move as a fourth button when available. Buttons show stance icon + stamina cost. Disabled stances (insufficient stamina) are grayed with no cost displayed. |
| **Simultaneous reveal animation** | Both stances "flip" to reveal at the same moment. Reveal animation: ~0.5 sec. Clear visual hierarchy: who won this exchange, how much damage. |
| **Resolve bar** | Two health-style bars (one per participant) that deplete visibly. Color: green → yellow → red gradient as resolve drops. Bar label shows current / max resolve. |
| **Stamina display** | Pip row (small icons, one per stamina point) rather than a numeric bar — communicates "running out" more viscerally than a number. Used up pips turn dark. |
| **Read hint display** | Subtle "flash" on the opponent's portrait side, accompanied by a brief text flavor line ("He shifts his weight forward…"). Correct hint: shows an icon matching the opponent's actual stance. Incorrect hint: shows a wrong stance icon — there is no visual distinction between a correct and incorrect hint (players must learn the 70% rate). |
| **Yield prompt** | Appears below stance buttons when active. Styled distinctly (different color / position) so it's not confused with an attack option. |
| **Signature Move button** | Visually prominent — slightly larger, distinct color/border from standard stances. Shows move name, stamina cost, and a brief tooltip describing its effect. Grayed when unavailable (insufficient stamina). |
| **Duel end overlay** | Win: brief triumph portrait flash, green/gold accent. Lose: defeat portrait, red accent. Transition back to battlefield within ~1 second. |

### Audio

| Element | Description |
|---------|-------------|
| **Duel theme music** | Distinct cue — lower tension than battle music, more intimate. A solo instrument (strings or horn) over sparse accompaniment. Scripted duels may override with a dedicated cue per scene. |
| **Stance reveal SFX** | Sword clash (Attack), defensive parry ring (Defend), whoosh deflect (Feint). Tie impacts: heavier, simultaneous collision sound. |
| **Damage SFX** | Short grunt/impact per damage hit. Volume scales with damage value (Crushing Blow is noticeably louder). |
| **Read hint SFX** | Subtle "insight" chime — distinct from UI button sounds. Should feel like an internal realization, not a HUD ping. |
| **Signature Move SFX** | Unique per move — Alexsen's Crushing Blow has a heavy two-handed wind-up and bone-crack impact. Each named officer's move has its own audio signature. |
| **Resolve depleting (low resolve warning)** | Optional: heartbeat or tension swell when a participant is at < 25% resolve. Avoid if it clutters the low-resolve moment. |
| **Yield SFX** | Sword lowered / surrender gesture sound. Brief, not triumphant — the yielder is defeated, not dishonored. |

## UI Requirements

### Duel Screen Layout

```
┌──────────────────────────────────────────────────────┐
│  [OPPONENT PORTRAIT]           [PLAYER PORTRAIT]     │
│  Resolve ████████░░   Name     Name   Resolve ████░░  │
│  Stamina ●●●●●○○○○               Stamina ●●●●●●●○○○○  │
│                                                      │
│       [Stance reveal area — center, prominent]       │
│                                                      │
│                  [Read hint text]                    │
│                                                      │
│  [ Attack ]  [ Defend ]  [ Feint ]  [Sig Move] (opt)  │
│                                                      │
│              [ Yield ] (conditionally visible)       │
└──────────────────────────────────────────────────────┘
```

| Component | Behavior |
|-----------|----------|
| **Opponent portrait** | Left side. Shows officer art, name, resolve bar, stamina pips. Opponent stance is hidden until reveal. |
| **Player portrait** | Right side. Shows officer art, name, resolve bar, stamina pips. Player's selected stance is privately committed but not shown to opponent. |
| **Resolve bar** | Horizontal, visible to both sides (no fog of war on resolve — both participants see each other's current health). |
| **Stamina pip row** | Shows remaining stamina. Pips fill right-to-left as stamina depletes. |
| **Stance buttons** | Always rendered in the same position. Disabled buttons are non-interactive (grayed) when stamina is insufficient. Keyboard shortcuts: Q/W/E for Attack/Defend/Feint, R for Signature Move. |
| **Signature Move button** | Only rendered when the player's officer has a non-null Signature Move. Shows `(Cost: N Stamina)` in tooltip. |
| **Yield button** | Hidden until yield condition is met. Appears below stance buttons. Not part of the normal stance layout — distinct vertical position. |
| **Read hint display** | Appears between portraits in center area. Flavor text only — one line, ~8 words. Shows on the turn Read fires; dismissed automatically next turn. |
| **Turn counter** | Small text, corner. Shows current turn number. |
| **Confirm button** | Not required — stance selection is final on button press (no "lock in and confirm" step). Reduces extra clicks in a time-pressured feel. |

### Keyboard Navigation

All duel actions must be accessible via keyboard without mouse:
- Q: Attack
- W: Defend
- E: Feint
- R: Signature Move (if available)
- Y: Yield (if available)
- Escape: Pause / Options (never exits duel — explicit player confirmation required to surrender a scripted duel)

### Gamepad Support

Partial — duel screen supports D-pad navigation across the 3-4 stance buttons. A to confirm. See technical preferences: gamepad is partial support, not core UX.

## Acceptance Criteria

*QA Lead reviewed. Canonical stat values corrected to match `assets/data/officers.json`.*

1. Given an officer with CHR 88 (Kaster), when Duel Resolve is calculated using F-1, then the result is `floor(88 / 2) + 40 = 84`.

2. Given an officer with the minimum possible CHR (1), when Duel Resolve is calculated using F-1, then the result is 40 (the formula floor).

3. Given an officer with the maximum possible CHR (100), when Duel Resolve is calculated using F-1, then the result is 90 (the formula ceiling).

4. Given named officers Alexsen (CHR 75), Thane (CHR 45), Sander (CHR 70), Bon (CHR 62), Jin Tao (CHR 50), and Zhuge Jian (CHR 80), when Duel Resolve is calculated for each, then the results are 77, 62, 75, 71, 65, and 80 respectively.

5. Given Zhuge Jian (INT 99), Kaster (INT 92), and Bon (INT 94), when Stamina Pool is calculated using F-2, then each result is 14. (All three INT values floor-divide to the same result at /10 + 5.)

6. Given an officer with the minimum possible INT (1), when Stamina Pool is calculated using F-2, then the result is 5 (the formula floor).

7. Given Alexsen (WAR 98) and Kaster (WAR 82), when Attack Damage is calculated using F-3, then Alexsen's result is 14 and Kaster's result is 13.

8. Given a winning Defend outcome where the defending officer's attack_damage (F-3) is 14 (e.g., Alexsen defending), when counter_damage is calculated using F-4, then the result is `ceil(14 × 0.40) = 6`.

9. Given a winning Feint outcome where the winning officer's attack_damage is 13 (Kaster), when feint_break_damage is calculated using F-4, then the result is `ceil(13 × 0.60) = 8`.

10. Given an Attack vs Attack tie where officer A's attack_damage is 14 and officer B's attack_damage is 13, when tie_attack_damage is applied using F-4, then officer A takes `floor(13 × 0.50) = 6` damage and officer B takes `floor(14 × 0.50) = 7` damage. Each participant takes damage based on the OTHER's attack_damage value, not their own.

11. Given all nine stance combinations, when each is resolved, then: (a) Attack vs Attack → tie, each takes `floor(other.attack_damage × 0.5)` damage; (b) Attack vs Defend → Defend wins, defender deals `counter_damage` to attacker; (c) Attack vs Feint → Attack wins, attacker deals `attack_damage` to feinter; (d) Defend vs Defend → tie, 0 damage each; (e) Defend vs Feint → Feint wins, feinter deals `feint_break_damage` to defender; (f) Feint vs Feint → tie, 0 damage each.

12. Given a participant with exactly 4 stamina and a Signature Move that costs 4, when the available actions are evaluated, then Attack, Defend, Feint, and Signature Move are all available.

13. Given a participant with exactly 3 stamina, when the available actions are evaluated, then Attack, Defend, and Feint are available but Signature Move (cost 4) is locked and cannot be selected.

14. Given a participant with exactly 1 stamina, when the available actions are evaluated, then only Defend and Feint are available — Attack (cost 2) is locked.

15. Given a participant with exactly 0 stamina (Exhaustion), when the available actions are evaluated, then only Defend is available; Attack and Feint are both locked.

16. Given a participant selects Attack, when the action resolves, then their stamina decreases by 2. Given they select Defend or Feint, their stamina decreases by 1. Given Alexsen selects Crushing Blow, his stamina decreases by 4.

17. Given it is turn 3 (`current_turn mod 3 == 0`) and participant A has higher WAR than participant B, when the Read mechanic fires for participant A, then there is a 70% probability the hint correctly shows participant B's chosen stance and a 30% probability it shows a randomly selected incorrect stance.

18. Given it is turn 3 and both participants have exactly equal WAR, when the Read mechanic is evaluated, then it does not fire for either participant — no hint is displayed.

19. Given it is turn 4 (`current_turn mod 3 != 0`), when the Read mechanic is evaluated, then it does not fire regardless of the WAR difference between participants.

20. Given Alexsen uses Crushing Blow (Signature Move) and the opponent chose Defend, when the stance is resolved, then Crushing Blow bypasses the Defend — Alexsen deals his full `attack_damage` (14) to the opponent and the opponent does NOT deal `counter_damage` back.

21. Given Alexsen uses Crushing Blow and the opponent chose Feint, when the stance is resolved, then Alexsen deals `ceil(14 × 0.75) = 11` damage to the opponent.

22. Given Alexsen and his opponent both select Crushing Blow / Attack in the same turn (head-on collision), when resolved, then both participants take their full respective `attack_damage` values simultaneously.

23. Given Alexsen has already used Crushing Blow once in the current duel, when he attempts to select it again in the same duel, then the Signature Move action is locked and unavailable.

24. Given a participant's Resolve drops to exactly 0 or below after damage is applied, when termination is checked, then that participant is defeated and the duel ends.

25. Given both participants' Resolve drops to 0 or below on the same turn, when termination is checked, then the outcome is a mutual defeat (draw) — neither participant is declared the winner.

26. Given both participants' Stamina simultaneously reaches 0 and neither Resolve has reached 0, when termination is checked, then a Final Exchange fires: both participants are forced to Defend (0 damage each), and the participant with higher current Resolve wins. If both Resolve values are exactly equal, the outcome is a draw.

27. Given the player's opponent has current Resolve at or below 30% of their maximum Resolve (`yield_threshold = 0.30`), when the player's available actions are evaluated, then the Yield action is available.

28. Given the player's opponent has current Resolve above 30% of their maximum Resolve, when the player attempts to access Yield, then the Yield action is unavailable and cannot be selected.

29. Given a scripted duel has `allow_player_loss: false`, when damage would reduce the player's Resolve to 0, then the duel pauses with the player's Resolve frozen at 1 — the player is not eliminated.

30. Given a scripted duel has `ai_behavior: "intentional_miss"` with `miss_frequency: 0.40`, when the AI selects Attack and a miss is triggered (40% probability), then 0 damage is applied to the player's Resolve but the AI's stamina still decreases by 2 (the stamina cost is paid regardless of the miss result).

31. Given a scripted duel has `miss_frequency: 1.0`, when the AI selects Attack every turn, then the attack always deals 0 damage while the AI's stamina depletes normally — this is a valid configuration and causes no errors or infinite loops.

32. Given a scripted duel completes with a player victory, when outcome flags are written to story state, then `outcome_flag_victory` is set. Given a player defeat, `outcome_flag_defeat` is set. Given a draw (mutual defeat or Final Exchange tie), `outcome_flag_draw` is set if defined; otherwise `outcome_flag_defeat` is used as the fallback.

33. Given a field challenge is initiated between two officers, when the adjacency check runs, then the challenge is only valid if both officers occupy adjacent hexes in the cube coordinate system. A challenge attempted from non-adjacent hexes is rejected.

34. Given a challenging officer has already issued one field challenge this battle, when they attempt a second field challenge against any opponent, then the challenge is blocked — once-per-battle limit is per-challenger.

35. Given a challenged officer refuses a field challenge, when the refusal is processed, then the refusing officer's squad receives −15 morale immediately; the challenging squad receives no morale change.

36. Given a field duel ends with a winner, when morale effects are applied, then the losing officer's squad receives −25 morale and the winning officer's squad receives +15 morale.

37. Given a diplomatic duel concludes with the player winning, when the diplomatic outcome is applied, then the contested city submits (diplomatic path succeeds).

38. Given a diplomatic duel concludes with the player losing, when the diplomatic outcome is applied, then the diplomatic path to that city is closed for the current campaign turn. No field morale effects are applied (no tactical squads present in diplomatic context).

39. Given edge case E-04 (both participants select Signature Move simultaneously), when resolution order is determined, then the participant with higher WAR fires their move first. If the higher-WAR participant's move reduces the opponent's Resolve to 0 or below, the opponent's Signature Move does not fire.

40. Given a new duel begins for an officer who previously exhausted their stamina in an earlier field duel this battle, when the duel is initialized, then the officer's stamina pool is reset to their full F-2 value — stamina is per-duel, not persistent across duels.

## Open Questions

1. **Simultaneous tie-break in Final Exchange**: When both participants finish at exactly equal Resolve after the Final Exchange, the GDD specifies "draw." For field duels this is fine. For scripted duels without a `outcome_flag_draw` entry, should the fallback be player-loss or context-dependent? Confirm with narrative director before implementing the scripted duel controller.

2. **Diplomatic duel re-attempt**: If a diplomatic duel ends in player defeat, the GDD states "diplomatic path closed this campaign turn." Can the player attempt the same city's diplomatic duel again next campaign turn with a different officer, or is it one attempt per game? Deferred to Diplomacy System GDD — the Duel System has no opinion, it only writes the result flag.

3. **Read mechanic in scripted duels with `intentional_miss`**: If the AI is set to `intentional_miss`, the Read hint (if it fires) will suggest the AI is choosing Attack — but the miss means it deals no damage. Should Read be suppressed in scripted duels with behavior overrides, or should the hint still fire as a potential misdirection/narrative element? The Thane encounter may specifically benefit from the hint being accurate while the miss makes it confusing.

4. **Signature Move extensibility for Part 3**: Kaster vs Alexsen (planned for Part 3) implies both officers will have developed duel signature moves by then. The current interface supports this. Confirm that the JSON-based resolver class pattern is sufficient for sequel implementation without engine-version lock-in (Part 3 timeline unknown).

5. **Morale effect on BROKEN squads**: If the losing squad is already at BROKEN state before the field duel ends, and the −25 morale delta would push them further negative, does this trigger any secondary effects (additional routing, surrender)? Deferred to Morale System GDD — the Duel System only writes the delta, not its downstream consequences.
