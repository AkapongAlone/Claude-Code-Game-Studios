# Morale System

> **Status**: In Design
> **Author**: Game Designer + Systems Designer
> **Last Updated**: 2026-06-12
> **Implements Pillar**: P3 — Grounded, Barely Fantastic + P2 — Officers Are the Story
> **Review Mode**: Lean

## Overview

The Morale System tracks a per-squad willingness-to-fight value that degrades under pressure and recovers under strong leadership. Each squad carries a morale state that shifts as the battle unfolds: taking casualties, being flanked, losing an attached officer, or watching nearby allied squads break all push morale toward collapse. When morale reaches zero, the squad **routes** — it withdraws from the map. Routed squads are not destroyed; they return on the campaign layer with roughly half their manpower, meaning battles that end in routs are more survivable than battles that end in annihilation. An officer attached to a squad projects a leadership aura — proportional to their LDR stat — that shields nearby squads from morale degradation; squads with no officer are brittle and break more easily under any pressure. The officer's CHR stat governs recovery speed. The Morale System is the primary battle-ender in Kaster's War: most engagements conclude not when squads are killed to zero HP, but when enough squads have routed that one side can no longer hold a coherent line — expressing the game's grounded, human-cost vision of warfare.

## Player Fantasy

The fantasy is reading the cascade before it starts. When a squad routes in Kaster's War, it is not just a lost unit — it is a morale event that hits every squad that witnessed it. The gap it leaves exposes a neighbor's flank. That neighbor is now taking extra damage and bleeding morale simultaneously. A player who understands the Morale System sees these chain reactions forming two turns before they detonate and repositions to sever them. A player who doesn't watches their line unravel from one unlucky break. The feeling the system targets: *competence through spatial awareness* — the general who reads the shape of the battle and intervenes before the collapse, not after.

The inverse fantasy is the unbreakable anchor. A high-LDR officer at the center radiates stability to every squad in range; the line near him holds under pressure that would break the flanks. Alexsen, who is immune to morale damage entirely, feels like his fiction — a juggernaut crashing through enemy lines as the battle degrades around him, unaffected by chaos that staggers everyone else. Squads without an officer feel immediately different: brittle, prone to panic, the first to break under serious pressure. This gap between officer-led and unled squads makes **P2 (Officers Are the Story)** tactically legible — stat differences become spatial, felt through where the line holds and where it collapses.

Critically, morale loss is not pure punishment. A routed squad is not dead; it retreats and recovers half its manpower on campaign. The Morale System embodies **P3 (Grounded, Barely Fantastic)**: wars end when armies break, not when they are annihilated, and a player who holds enough of the field after a rout can still recover from it. Battles carry a rhythm of pressure and release — morale is the system that makes that rhythm visible and legible.

## Detailed Design

### Core Rules

**Morale Value:**
Each squad has an integer morale value in [0, 100]. Morale starts at 100 for officer-led squads and 70 for officer-less squads at battle start. Morale cannot be negative or exceed 100.

**Morale States (threshold-based):**
Morale state is derived from the current morale value each time it changes — there is no separate state variable to set manually.

| State | Condition | morale_mod (Combat) | Behavior |
|---|---|---|---|
| STEADY | morale ≥ 30 | 1.0 | Normal combat participation |
| SHAKEN | 10 ≤ morale < 30 | 0.75 | 25% damage penalty; routing imminent |
| BROKEN | morale < 10 | 0.5 | 50% damage penalty; routing sequence begins this turn |

When a squad enters BROKEN, its routing sequence is committed — the squad auto-moves toward the nearest map edge during the Routing Resolution Phase of that turn. If it reaches the map edge, it exits. If not, it continues automatically next turn until it exits. A routing squad cannot be given player orders.

**Morale Damage Triggers (applied during Morale Resolution Phase):**
Morale damage is processed once per turn after all attacks are resolved, in this order:

1. **Casualties** — morale damage proportional to the percentage of HP lost this turn.
2. **Flanking received** — flat morale damage per flank attack suffered this turn.
3. **Attached officer killed or incapacitated this turn** — significant flat morale damage.
4. **Adjacent allied squad entered BROKEN this turn** — moderate flat morale damage per squad observed routing within 2 hexes. Resolution order: (Pass 1) Process all BROKEN transitions from triggers 1–3 for all squads simultaneously. (Pass 2) For each squad that entered BROKEN in Pass 1, apply witnessing-rout morale damage to all friendly squads within 2 hexes; resolve any new BROKEN transitions. Maximum 2 cascade passes per Morale Resolution Phase — this allows one-deep domino collapses while preventing infinite chain loops.

**Officer Leadership Aura:**
An officer attached to a squad projects a morale protection aura to all friendly squads within a hex radius determined by the officer's LDR stat (see Formulas). Squads within an aura receive reduced morale damage from all triggers (see aura_protection_rate in Tuning Knobs). The aura applies to the officer's own squad and all friendly squads within radius.

- Multiple overlapping auras do NOT stack — only the highest LDR officer's aura applies to a given squad.
- An officer-less squad benefits from another officer's aura if within that officer's radius.

**Officer Morale Recovery (CHR):**
At the end of each turn, after the Morale Resolution Phase, each non-BROKEN squad recovers morale **if and only if it took zero morale damage this turn** (recovery is suppressed during any turn where any morale trigger fired). This prevents morale from increasing under light pressure. Recovery amount is derived from the attached officer's CHR stat (see Formulas). When a squad benefits from another officer's aura (because it lacks an officer or is within range of a higher-LDR officer), recovery uses the aura officer's CHR stat. BROKEN squads do not recover — the routing sequence is committed.

**Officer-less Squads:**
A squad with no attached officer:
- Starts battle at morale 70 (brittle baseline).
- Has no personal LDR aura (cannot protect nearby squads).
- Has no CHR-based recovery unless within a friendly officer's aura radius.
- Takes morale damage at the full unprotected rate.

**Immunity Hooks (for Officer Passive System):**
The Morale System checks two passive flags before applying morale damage:

1. `morale_damage_immune` — if the squad's officer has this flag, all morale damage events are skipped for that squad. This is set by the Juggernaut passive (Alexsen). The squad's morale value never changes because all damage is skipped.
2. `flank_morale_immune_aura` — if the squad's officer has this flag, all friendly squads adjacent to that officer's squad are immune to the "flanking received" morale damage trigger. Set by the Old Guard passive (Sander). HP damage from flanking still applies normally; only the morale component is negated.

These flags are defined and set by the Officer Passive Ability System (design #14). The Morale System reads them but never writes them.

**Turn Structure Integration:**
1. Movement phase (player/enemy control)
2. Combat Resolution phase (all attacks, HP damage)
3. **Morale Resolution phase** — process all four triggers for all squads
4. **Routing Resolution phase** — BROKEN squads auto-move toward nearest map edge; remove if reached
5. **Recovery phase** — CHR-based morale recovery for non-BROKEN squads
6. Next turn begins

**Campaign Recovery:**
When a squad exits the map via routing, it is removed from the tactical layer. After the battle concludes, that squad is restored to the campaign roster with manpower equal to 50% of the HP value it had when it entered BROKEN state (not its max HP). This represents soldiers who scattered but were not killed.

---

### States and Transitions

```
         [morale < 30]            [morale < 10]
STEADY ─────────────→ SHAKEN ─────────────→ BROKEN → ROUTING → [exits map]
  ↑         [morale ≥ 30]
  └──────────────────←
```

| From | To | Condition |
|---|---|---|
| STEADY | SHAKEN | morale drops below 30 |
| SHAKEN | STEADY | morale recovers to ≥ 30 |
| SHAKEN | BROKEN | morale drops below 10 |
| BROKEN | Routing | Automatic — committed this turn, no recovery possible |
| Routing | Exits map | Squad reaches map edge (1–2 turns) |

No transition out of BROKEN back to SHAKEN or STEADY — once a squad enters BROKEN, the rout is committed regardless of subsequent morale changes.

---

### Interactions with Other Systems

| System | This System Reads | This System Writes |
|---|---|---|
| **Officer Stats** | `officer.ldr()` → aura radius; `officer.chr()` → recovery amount | — (read-only) |
| **Combat Resolution** | — | `squad.morale_state` (Combat Resolution reads this for `morale_mod`) |
| **Facing & Flank** | `is_flanked(squad)` this turn → triggers flank morale damage | — |
| **Victory/Defeat Conditions** | — | `morale_state` per squad (Victory Conditions tracks BROKEN count for rout-based win/loss) |
| **Tactical HUD** | — | `squad.morale` (numeric value), `squad.morale_state` (state indicator display) |
| **Officer Passive Ability System** | `officer.passive_flags`: `morale_damage_immune`, `flank_morale_immune_aura` | — (read-only) |

**Cross-reference with Combat Resolution:**
Combat Resolution's existing formula maps `morale_state` to `morale_mod`. The Combat Resolution GDD was authored with a binary (NORMAL → 1.0, BROKEN → 0.5). The addition of SHAKEN → 0.75 requires updating `combat_resolver.gd`'s match statement and the associated tests. The existing constant `morale_broken_damage_penalty` (−0.5) remains correct for BROKEN; a new constant `morale_shaken_damage_penalty` (−0.25) must be registered in the entity registry.

## Formulas

### 1. Aura Radius from LDR

The `aura_radius` formula maps an officer's LDR stat to a hex radius using a bracket table:

```
aura_radius = bracket(ldr):
  ldr < 50    → 1 hex
  50 ≤ ldr < 75  → 2 hexes
  75 ≤ ldr < 90  → 3 hexes
  ldr ≥ 90    → 4 hexes
```

**Variables:**
| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| Officer LDR stat | ldr | int | [1, 100] | Leadership stat from Officer Stats System |
| Aura radius (output) | aura_radius | int | [1, 4] | Hex radius of morale protection |

**Output range:** 1 to 4 hexes. No officer has a 0-hex aura; all officers project at least 1 hex.

**Example:** Kaster (LDR 96): 4 hex aura. Thane (LDR 50): 2 hex aura. A generic Scout officer (LDR ~45): 1 hex aura.

**Named officer aura radii:**
| Officer | LDR | Aura Radius |
|---------|-----|-------------|
| Kaster | 96 | 4 hexes |
| Sander | 88 | 3 hexes |
| Alexsen | 85 | 3 hexes |
| Bon shi hai | 78 | 3 hexes |
| Zhuge Jian | 70 | 2 hexes |
| Jin Tao | 60 | 2 hexes |
| Thane | 50 | 2 hexes |

---

### 2. Morale Recovery from CHR

The `recovery_per_turn` formula defines how many morale points a non-BROKEN squad recovers at end of turn (suppressed on turns where any morale damage was taken):

```
recovery_per_turn = floor(chr / 25)
```

**Variables:**
| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| Officer CHR stat | chr | int | [1, 100] | Charisma stat from Officer Stats System |
| Recovery per turn (output) | recovery_per_turn | int | [0, 4] | Morale points restored at end of a quiet turn |

**Output range:** 0 to 4 per turn. CHR 25–49 → 1/turn; CHR 50–74 → 2/turn; CHR 75–99 → 3/turn; CHR 100 → 4/turn.

**Example:** Kaster (CHR 88): 3 morale/turn recovered. Thane (CHR 45): 1 morale/turn. A generic officer (CHR 30): 1 morale/turn.

---

### 3. Morale Damage from Casualties

The `morale_damage_casualties` formula converts HP% lost this turn into morale damage:

```
morale_damage_casualties = floor(hp_lost_pct × casualty_sensitivity)
```

where `hp_lost_pct = hp_lost_this_turn / squad_max_hp`.

**Variables:**
| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| HP lost this turn | hp_lost | float | [0, max_hp] | Effective HP damage taken in Combat Resolution this turn |
| Squad max HP | max_hp | float | [1, ∞] | Unit type's HP pool (defined in combat.json per unit type) |
| HP fraction lost | hp_lost_pct | float | [0.0, 1.0] | Fraction of max HP lost this turn |
| Casualty sensitivity | casualty_sensitivity | int | [30, 70] | Tuning multiplier; default 50 |
| Morale damage (output) | morale_damage_casualties | int | [0, 50] | Morale damage from casualties this turn |

**Output range:** 0 to 50, floored. A squad cannot take more than 50 morale damage from casualties in a single turn regardless of HP loss.

**Example:** A squad with max_hp = 100 takes 25 effective HP damage (25% loss): floor(0.25 × 50) = 12 morale damage. Catastrophic hit of 80 HP: floor(0.80 × 50) = 40 morale damage.

---

### 4. Morale Damage from Flanking

```
morale_damage_flank = flank_morale_penalty    (flat per flank attack received this turn)
```

**Variables:**
| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| Flank morale penalty | flank_morale_penalty | int | [5, 20] | Tuning constant; default 10 |
| Morale damage (output) | morale_damage_flank | int | [0, 20] | Morale damage from being flanked this turn |

**Output range:** 0 (not flanked) or 10 (flanked, default). Suppressed if the squad's officer has `flank_morale_immune_aura` and the squad is adjacent to that officer.

**Example:** Squad is flanked once this turn: 10 morale damage in addition to the flanking HP damage bonus.

---

### 5. Morale Damage from Officer Loss

```
morale_damage_officer_loss = officer_loss_penalty    (flat, fires once per officer lost)
```

**Variables:**
| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| Officer loss penalty | officer_loss_penalty | int | [15, 50] | Tuning constant; default 30 |
| Morale damage (output) | morale_damage_officer_loss | int | 0 or 30 | 0 if no officer lost this turn; 30 if officer killed or incapacitated |

**Output range:** 0 or `officer_loss_penalty`. Fires once regardless of how the officer left (death for generics; incapacitation for named characters).

**Example:** A squad's officer is killed: immediate 30 morale damage, applied in the Morale Resolution Phase of that turn.

---

### 6. Morale Damage from Witnessing Rout

```
morale_damage_witnessing = witnessed_rout_count × witnessing_penalty
```

**Variables:**
| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| Routing squads in range | witnessed_rout_count | int | [0, ∞] | Number of friendly squads that entered BROKEN within 2 hexes this Morale Resolution Phase |
| Witnessing penalty | witnessing_penalty | int | [5, 20] | Tuning constant per routing squad; default 10 |
| Morale damage (output) | morale_damage_witnessing | int | [0, 80] | Morale damage from observed routs; uncapped |

**Output range:** 0 to theoretically uncapped, but in practice bounded by the 2-pass cascade rule (maximum two cascade passes per turn). Practical maximum: ~40 damage (4 routs witnessed across both passes).

**Example:** Two adjacent friendly squads entered BROKEN in Pass 1: 2 × 10 = 20 morale damage from witnessing.

---

### 7. Total Morale Damage per Turn

```
total_morale_damage = morale_damage_casualties + morale_damage_flank + morale_damage_officer_loss + morale_damage_witnessing
total_morale_damage = floor(total_morale_damage × (1 − aura_protection_rate))    [if in aura]
```

**Variables:**
| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| Raw total morale damage | raw_dmg | int | [0, ~120] | Sum of all four damage components before aura |
| Aura protection rate | aura_protection_rate | float | [0.0, 1.0] | Fraction of damage negated; default 0.25 if in aura, 0.0 if not |
| Final morale damage (output) | total_morale_damage | int | [0, ~90] | Morale subtracted from squad this turn |

**Output range:** 0 to ~90 in extreme scenarios (80% HP loss + flank + officer death). Aura reduces this to ~67 maximum.

**Worked examples (corrected formula values):**

Sander's squad (LDR 88, CHR 70, 3-hex aura, recovery 2/turn). Attacker applies 25% HP loss/turn. Flank added at turn 4.

| Turn | Morale | Events | Raw Dmg | Aura (−25%) | Recovery | End | State |
|------|--------|--------|---------|-------------|----------|-----|-------|
| 1 | 100 | 25% HP | 12 | 9 | 0* | 91 | STEADY |
| 2 | 91 | 25% HP | 12 | 9 | 0* | 82 | STEADY |
| 3 | 82 | 25% HP | 12 | 9 | 0* | 73 | STEADY |
| 4 | 73 | 25% HP + flank | 22 | 16 | 0* | 57 | STEADY |
| 5 | 57 | 25% HP | 12 | 9 | 0* | 48 | STEADY |
| 6 | 48 | 25% HP | 12 | 9 | 0* | 39 | STEADY |

*Recovery suppressed because morale damage occurred each turn. Sander's squad reaches SHAKEN around turn 10–11 under continued equal pressure. A high-LDR/CHR officer's squad is intended to hold the line.

Officer-less squad (morale starts 70, no aura, no recovery). Same attack pattern.

| Turn | Morale | Events | Damage | End | State |
|------|--------|--------|--------|-----|-------|
| 1 | 70 | 25% HP | 12 | 58 | STEADY |
| 2 | 58 | 25% HP | 12 | 46 | STEADY |
| 3 | 46 | 25% HP | 12 | 34 | STEADY |
| 4 | 34 | 25% HP + flank | 22 | 12 | SHAKEN |
| 5 | 12 | 25% HP | 12 | 0 | BROKEN |

Officer-less squad reaches BROKEN at turn 5 under sustained medium pressure with a flank event. Without the flank: BROKEN at turn 7. The flank is the decisive accelerant — correct design.

## Edge Cases

- **If morale drops to exactly 10:** State transitions to SHAKEN (boundary is inclusive at 10 — `morale < 30` triggers at 29; SHAKEN is `10 ≤ morale < 30`; reaching exactly 10 is SHAKEN, not BROKEN).

- **If morale drops to exactly 0:** Morale is clamped to 0; state is BROKEN. The squad is in routing sequence. Morale value stays at 0 until the squad exits the map — there is no morale meaning below 0.

- **If a squad takes morale damage this turn and also has CHR-based recovery:** Recovery is fully suppressed. The squad does not recover any morale on turns where it took morale damage from any trigger.

- **If a squad takes zero HP damage in a turn:** No morale_damage_casualties fires. Recovery may apply at end of turn (provided no other trigger fired).

- **If a squad's HP reaches 0 before its morale reaches 0 (killed before routing):** The squad is removed from the map immediately as a death event, not a rout event. No morale event fires for adjacent squads from the death. The squad does NOT return to the campaign roster (death, not rout — no manpower recovery).

- **If Alexsen's squad (morale_damage_immune) would take any morale damage:** All morale damage from all triggers is skipped. Alexsen's squad's morale value never changes (stays at 100 throughout the battle under normal conditions). Alexsen's squad cannot enter SHAKEN or BROKEN through morale damage — though if a scripted event forces a morale value change directly (e.g., scenario setup), the immunity does not protect against direct value assignments.

- **If a squad's officer is killed while the squad is already in BROKEN routing:** The officer_loss_penalty of 30 does not apply — the squad is already routing and no morale calculation is meaningful. The penalty fires only if the squad's state is STEADY or SHAKEN at the time the officer is lost.

- **If multiple auras overlap on the same squad:** Only the highest-LDR officer's aura applies (no stacking). The same officer's CHR governs recovery for squads in their aura. If two officers have equal LDR, the one assigned first to the field (lower squad ID) takes precedence — consistent tiebreak.

- **If an officer-less squad is within a friendly aura:** The aura officer's LDR-based protection and CHR-based recovery apply to that officer-less squad as if it were that officer's own squad. The officer-less squad's base morale start (70) is not changed by the aura.

- **If a cascade results in 3+ routing squads in Pass 1:** Pass 2 processes witnessing events from all Pass 1 routs simultaneously. Any squads that enter BROKEN in Pass 2 do NOT trigger a Pass 3 — the cascade is capped at 2 passes per Morale Resolution Phase. Squads that would have broken in Pass 3 simply keep their reduced morale value (potentially deep into SHAKEN) and may route next turn.

- **If witnessing rout events from Pass 1 push a squad from STEADY to SHAKEN but not to BROKEN:** That squad does not trigger further cascade in Pass 2 (only squads that reach BROKEN generate witnessing events).

- **If an enemy squad routs:** Enemy routs do not trigger morale damage for friendly squads. Witnessing rout trigger applies only to allied squad routs. (Enemy routing is the desired outcome — it should not demoralize your own troops.)

- **If a routing squad is blocked from reaching the map edge (e.g., terrain or enemy squads block all paths):** The routing squad continues to auto-move each turn toward the nearest unobstructed path to the map edge. If it remains on the map for more than 3 turns after entering BROKEN, it is removed from the map automatically (timeout fallback) to prevent edge cases where routing squads are permanently trapped. The campaign manpower recovery still applies.

- **If a scenario starts a squad at a non-default morale (e.g., Preparation Phase "rest troops fully" action):** The starting morale value is set by the scenario/Preparation Phase system override. The Morale System does not reset starting morale — it accepts whatever value is provided at battle start. The `officerless_morale_start` (70) and `officer_morale_start` (100) defaults apply only when no override is provided.

- **If a squad's HP is at 5% but morale is STEADY (zombie squad scenario):** No special handling in MVP — a squad with near-zero HP but STEADY morale continues to fight normally. The squad will likely die from the next hit rather than rout. This is intentional: a morale-iron squad that's physically destroyed is rare but valid. Monitor via playtesting whether the disconnect between HP exhaustion and morale state creates confusing gameplay; if so, add a passive HP-below-threshold morale drain in a post-MVP patch.

## Dependencies

**Upstream dependencies** (systems this GDD depends on):

| System | Dependency Type | What is read | Hard/Soft |
|---|---|---|---|
| Officer Stats System | Read LDR, CHR | Aura radius formula input; recovery formula input | Hard |
| Combat Resolution System | Read HP damage this turn | hp_lost_pct for casualties formula; turn-ordered (Combat resolves first, then Morale) | Hard |
| Facing & Flank System | Read is_flanked per squad | Flank morale damage trigger | Hard |
| Officer Passive Ability System | Read passive_flags | `morale_damage_immune` (Alexsen), `flank_morale_immune_aura` (Sander) | Soft (system functions without passives; passive system not designed until #14) |

**Turn-order note on Combat Resolution ↔ Morale circular reference:** Systems index §Circular Dependencies confirms: Combat calculates HP casualties first → Morale updates after → Morale state feeds next turn's combat. No live cycle. Both systems use the previous turn's morale state as input to the current turn's combat; morale state updates are not mid-turn.

**Downstream dependencies** (systems that depend on this GDD):

| System | What it reads | Hard/Soft |
|---|---|---|
| Combat Resolution System | `squad.morale_state` → `morale_mod` (1.0 / 0.75 / 0.5 for STEADY/SHAKEN/BROKEN) | Hard |
| Victory/Defeat Conditions System | `morale_state` per squad (tracks BROKEN/routing count for rout-based win/loss conditions) | Hard |
| Tactical AI System | `squad.morale` (numeric), `squad.morale_state` (target selection: prefer SHAKEN/BROKEN squads; retreat logic) | Soft |
| Tactical HUD | `squad.morale` (display bar), `squad.morale_state` (state indicator icon) | Soft |
| Campaign Layer | Routing squad data (squad ID, HP when BROKEN) → manpower recovery calculation | Hard |

**Bidirectional consistency check:**
- Combat Resolution GDD (§Dependencies) lists Morale as upstream: ✓ (Combat reads `morale_state`)
- Combat Resolution GDD (§Dependencies) lists Morale as downstream: ✓ (Morale reads `morale_state` output and casualties)
- Officer Stats GDD (§Dependencies) lists Morale as downstream: ✓ (Morale reads LDR, CHR)
- Victory/Defeat Conditions GDD: Not yet authored — flag that it must list Morale as upstream when designed.

## Tuning Knobs

All values are data-driven via `assets/data/morale.json` — no hardcoded constants in code.

| Knob | Default | Safe Range | What breaks at extremes |
|---|---|---|---|
| `casualty_sensitivity` | 50 | [30, 70] | Below 30: morale barely responds to HP loss (morale irrelevant). Above 70: a single heavy hit may instantly BREAK a squad. |
| `flank_morale_penalty` | 10 | [5, 20] | Below 5: flanking has negligible morale effect. Above 20: a single flank attack combined with casualties can near-instantly BREAK a squad. |
| `officer_loss_penalty` | 30 | [15, 50] | Below 15: officer death has little tactical weight. Above 50: losing one officer can cascade-break the entire line. |
| `witnessing_penalty` | 10 | [5, 20] | Below 5: cascades barely propagate. Above 20: one break immediately cascades across the entire line (2-pass cap helps, but individual hits are still severe). |
| `aura_protection_rate` | 0.25 | [0.10, 0.50] | Below 0.10: aura protection is imperceptible over a battle. Above 0.50: officer aura trivially prevents all morale degradation. |
| `steady_threshold` | 30 | [20, 40] | Lower: squads spend more time SHAKEN. Higher: squads enter SHAKEN sooner, shortening effective battle time. |
| `broken_threshold` | 10 | [5, 15] | Lower: squads hold on longer before routing. Higher: SHAKEN window is very narrow and squads snap directly to routing. |
| `officerless_morale_start` | 70 | [50, 90] | Below 50: officer-less squads route almost immediately. Above 90: officer-less squads feel nearly as durable as officer-led. |
| `officer_morale_start` | 100 | fixed (100) | Lowering this below 80 makes all squads start fragile (use Preparation Phase "rest" action to restore to 100 instead). |
| `campaign_recovery_pct` | 0.50 | [0.30, 0.70] | Below 0.30: routing is economically catastrophic; players avoid all risk. Above 0.70: routing is nearly free; morale system has no campaign cost. |
| `cascade_pass_limit` | 2 | [1, 3] | 1 pass: no chain collapses possible. 3 passes: deeper domino chains (risky for multiplayer-tuned maps). |

**Knob interaction warnings:**
- Increasing `casualty_sensitivity` + `flank_morale_penalty` together without also increasing `aura_protection_rate` makes aura-less squads fragile to the point of uselessness.
- Lowering `broken_threshold` below 5 makes SHAKEN → BROKEN transitions nearly instantaneous once SHAKEN is reached — the SHAKEN state loses its warning function.
- `campaign_recovery_pct` should be tuned alongside `officerless_morale_start` — if routing is cheap to recover AND officer-less squads rout fast, players are incentivized to use officer-less squads as expendable chaff, which undermines P2.

## Visual/Audio Requirements

*Lean mode: `art-director` not consulted — review against art bible before production.*

**Squad token state display:**
- STEADY: normal squad token appearance
- SHAKEN: token border or base glow shifts to amber/orange; subtle wavering idle animation on the token sprite
- BROKEN/routing: token border shifts to red; token moves automatically; small "retreat arrow" indicator overlays the token

**Morale damage feedback (per-turn):**
- Morale damage numbers appear above the squad token (distinct color from HP damage — recommend a different color, e.g., blue or purple, to distinguish from white HP damage numbers)
- Morale numbers appear after Combat Resolution damage numbers, in the Morale Resolution Phase

**State transition feedback:**
- STEADY → SHAKEN: brief amber flash on token + short audio cue (wavering drum or discordant horn)
- SHAKEN → BROKEN: red flash + distinct audio cue (routing sound — shouting, breaking formation)
- BROKEN: routing auto-movement should read as panicked, not controlled — token moves without player-issued orders; consider a slight jitter/shake on the token as it routes

**Officer aura visualization (optional, lower priority):**
- When hovering over or selecting a squad, display the officer's aura radius as a subtle hex highlight (e.g., semi-transparent teal ring around the officer's squad hex, extending to aura_radius hexes)
- Permanent aura visualization is NOT recommended — too much visual noise during active play; hover-only is sufficient

**SFX requirements:**
- Morale trigger events should be audibly distinct from HP damage SFX to prevent confusion
- SHAKEN state: ambient morale-low audio cue (optional, low volume, looped during SHAKEN state) — requires performance review before inclusion
- Rout: clear audio feedback distinguishing from death (death = brief, quiet; rout = louder, more chaotic, signals ongoing action)

📌 **Asset Spec** — Visual/Audio requirements are defined. After the art bible is approved, run `/asset-spec system:morale-system` to produce per-asset visual descriptions and generation prompts from this section.

## UI Requirements

**Per-squad morale display (Tactical HUD):**
- Morale bar displayed in squad inspector panel (shown on hover or selection)
- Bar shows numeric morale value (0–100) and current state (STEADY / SHAKEN / BROKEN) as a text label or icon
- Bar color matches state: green (STEADY), amber (SHAKEN), red (BROKEN)
- Recovery rate tooltip: on hover over morale bar, display "Recovery: +N/turn (from Officer CHR)" or "No recovery" if officer-less and outside aura

**Aura radius visualization:**
- Officer aura radius shown as hex highlight on squad hover/selection (see Visual/Audio section)
- Indicator distinguishes own-squad aura from borrowed aura (officer-less squad in someone else's aura)

📌 **UX Flag — Morale System**: This system has UI requirements. In Phase 4 (Pre-Production), run `/ux-design` to create a UX spec for the Tactical HUD before writing epics. Stories that reference morale bar display should cite `design/ux/tactical-hud.md`, not this GDD directly. Note this in the systems index for the Tactical HUD system (#26).

## Acceptance Criteria

*Unit test evidence is BLOCKING for this Logic-category system. Integration tests for routing movement (AC-16) are ADVISORY. All criteria below are independently verifiable by a QA tester without reading the GDD.*

**Initialization**

**GIVEN** a battle starts with a squad with any officer attached, **WHEN** the battle begins, **THEN** the squad's morale value equals 100.

**GIVEN** a battle starts with a squad with no officer attached, **WHEN** the battle begins, **THEN** the squad's morale value equals 70.

**State Boundaries**

**GIVEN** a squad's morale value is exactly 30, **WHEN** its state is evaluated, **THEN** the state is STEADY (morale ≥ 30 is STEADY, not SHAKEN).

**GIVEN** a squad's morale value is exactly 10, **WHEN** its state is evaluated, **THEN** the state is SHAKEN (morale exactly 10 is SHAKEN, not BROKEN; BROKEN requires morale < 10).

**State Transitions**

**GIVEN** a squad with morale 35 (state: STEADY) receives 6 morale damage from the casualty trigger, **WHEN** the Morale Resolution Phase applies the damage, **THEN** the squad's morale equals 29 and its state is SHAKEN.

**GIVEN** a squad with morale 15 (state: SHAKEN) receives 6 morale damage from the casualty trigger, **WHEN** the Morale Resolution Phase applies the damage, **THEN** the squad's morale equals 9, its state is BROKEN, and the Routing Resolution Phase begins auto-moving the squad toward the nearest map edge this turn.

**GIVEN** a SHAKEN squad with morale 28 takes zero morale damage this turn and its officer has CHR 75, **WHEN** the Recovery Phase runs, **THEN** morale increases by floor(75/25) = 3 (final morale = 31) and the squad's state transitions to STEADY.

**Morale Clamp**

**GIVEN** a squad at morale 5 receives 20 morale damage, **WHEN** the damage is applied, **THEN** morale is clamped to 0 (not −15).

**GIVEN** a squad at morale 98 with a CHR-based recovery of 4 takes zero morale damage this turn, **WHEN** the Recovery Phase runs, **THEN** morale is clamped to 100 (not 102).

**Recovery**

**GIVEN** a SHAKEN squad with morale 25 has an attached officer with CHR 50 and took zero morale damage this turn, **WHEN** the Recovery Phase runs, **THEN** the squad's morale increases by floor(50/25) = 2, ending at 27.

**GIVEN** a squad with morale 25 took 6 morale damage from the casualty trigger this turn, **WHEN** the Recovery Phase runs, **THEN** the squad's morale does NOT increase — recovery is suppressed on any turn where morale damage occurred.

**GIVEN** an officer-less squad with morale 60 took zero morale damage this turn and is NOT within any friendly officer's aura, **WHEN** the Recovery Phase runs, **THEN** the squad's morale does NOT increase.

**GIVEN** an officer-less squad with morale 60 is within the aura of a friendly officer with CHR 50, and the squad took zero morale damage this turn, **WHEN** the Recovery Phase runs, **THEN** the squad's morale increases by floor(50/25) = 2, ending at 62.

**GIVEN** a squad's officer has CHR 24, **WHEN** the Recovery Phase runs on a zero-damage turn, **THEN** the squad's morale does NOT increase — floor(24/25) = 0 (CHR below threshold = no recovery).

**GIVEN** a BROKEN squad is within a friendly officer's aura, **WHEN** the Recovery Phase runs, **THEN** the squad's morale does NOT increase — BROKEN squads never recover.

**Aura Radius Formula (F1)**

**GIVEN** an officer has LDR 96, **WHEN** the aura radius is calculated, **THEN** the result equals 4 hexes.

**GIVEN** an officer has LDR 70, **WHEN** the aura radius is calculated, **THEN** the result equals 2 hexes.

**GIVEN** an officer has LDR exactly 50, **WHEN** the aura radius is calculated, **THEN** the result equals 2 hexes (not 1 — lower boundary of the 50–74 bracket).

**GIVEN** an officer has LDR exactly 75, **WHEN** the aura radius is calculated, **THEN** the result equals 3 hexes (not 2 — lower boundary of the 75–89 bracket).

**GIVEN** an officer has LDR exactly 90, **WHEN** the aura radius is calculated, **THEN** the result equals 4 hexes (not 3 — lower boundary of the ≥90 bracket).

**Aura Protection Formula (F7)**

**GIVEN** a squad is within a friendly officer's aura (aura_protection_rate = 0.25) and receives a combined raw morale damage total of 20 from all triggers this turn, **WHEN** F7 is applied, **THEN** the squad takes floor(20 × 0.75) = 15 morale damage.

**GIVEN** a squad is within a friendly aura and receives 12 morale damage from casualties AND 10 from the flank trigger (raw total = 22), **WHEN** F7 is applied, **THEN** the squad takes floor(22 × 0.75) = 16 morale damage — floor is applied once to the combined total, not per-trigger.

**Aura Priority (Multiple Overlaps)**

**GIVEN** a squad is within range of two friendly officers (Officer A: LDR 70, Officer B: LDR 88), **WHEN** morale damage is applied to that squad, **THEN** protection is calculated using LDR 88 only — the two auras do not stack, and only the highest-LDR aura applies.

**Damage Triggers (without aura)**

**GIVEN** a squad takes HP loss equal to 25% of its max HP this turn, **WHEN** F3 is applied, **THEN** morale_damage_casualties = floor(0.25 × 50) = 12.

**GIVEN** a squad is flanked this turn and is NOT within any friendly officer's aura, **WHEN** the flank morale trigger fires, **THEN** the squad takes 10 morale damage.

**GIVEN** a squad's officer is killed this turn, the squad's state is STEADY or SHAKEN, and the squad is NOT within any friendly aura, **WHEN** the Morale Resolution Phase runs, **THEN** the squad takes 30 morale damage.

**GIVEN** a BROKEN routing squad's attached officer is killed this turn, **WHEN** the Morale Resolution Phase runs, **THEN** no additional morale damage is applied to the routing squad.

**Witnessing Rout (F6)**

**GIVEN** two friendly squads within 2 hexes of Squad C (morale 40, state STEADY) each enter BROKEN during Pass 1 of the Morale Resolution Phase, **WHEN** Pass 2 fires witnessing events, **THEN** Squad C takes 2 × 10 = 20 morale damage.

**GIVEN** an enemy squad enters BROKEN within 2 hexes of a friendly squad, **WHEN** the Morale Resolution Phase runs, **THEN** the friendly squad takes zero witnessing morale damage — witnessing events apply to allied routs only.

**Cascade Cap**

**GIVEN** three squads (each with morale 11) are within 2 hexes of each other, WHEN Pass 1 morale damage pushes two into BROKEN simultaneously and Pass 2 witnessing damage pushes the third into BROKEN, **THEN** no Pass 3 executes — squads that would have broken in a hypothetical Pass 3 remain with their reduced morale value.

**GIVEN** a squad enters BROKEN in Pass 2 of a cascade, **WHEN** the Morale Resolution Phase concludes, **THEN** that squad's BROKEN entry does NOT generate new witnessing events for surrounding squads in the same Phase.

**Immunity Flags**

**GIVEN** a squad's officer has the `morale_damage_immune` flag set, **WHEN** the Morale Resolution Phase applies damage from any trigger (casualties, flank, officer loss, witnessing), **THEN** the squad's morale value is unchanged.

**GIVEN** a squad's officer has the `flank_morale_immune_aura` flag set, **WHEN** an adjacent friendly squad is flanked this turn, **THEN** that adjacent squad takes 0 morale damage from the flank trigger.

**morale_mod Output (cross-system boundary)**

**GIVEN** a squad is in STEADY state (morale ≥ 30), **WHEN** Combat Resolution reads `morale_mod`, **THEN** `morale_mod` equals 1.0.

**GIVEN** a squad is in SHAKEN state (10 ≤ morale < 30), **WHEN** Combat Resolution reads `morale_mod`, **THEN** `morale_mod` equals 0.75.

**GIVEN** a squad is in BROKEN state (morale < 10), **WHEN** Combat Resolution reads `morale_mod`, **THEN** `morale_mod` equals 0.5.

**Routing and Campaign Recovery**

**GIVEN** a squad enters BROKEN (morale < 10), **WHEN** the Routing Resolution Phase runs, **THEN** the squad auto-moves toward the nearest map edge without requiring player input. *(Integration test — requires movement system)*

**GIVEN** a squad had a current HP value of 60 when it transitioned to BROKEN, **WHEN** the battle ends and campaign recovery processes, **THEN** the squad is restored to the campaign roster with manpower = 30 (floor(60 × 0.50)). Note: 1 HP = 1 manpower unit for campaign recovery purposes.

## Open Questions

1. **Routing movement ownership** — The routing auto-move behavior (BROKEN squad moves toward map edge over 1–2 turns) requires pathfinding. Does the Hex Movement System (design #5) own routing pathfinding, or does the Morale System own it? Decision needed before Hex Movement GDD is authored. Tentative answer: Hex Movement owns all pathfinding including routing; Morale System signals the routing intent and Hex Movement executes it.

2. **Zombie squad HP-below-threshold passive drain** — A squad with < 10% HP but STEADY morale can fight normally until it takes one more hit. Systems designer flagged this as a potential immersion issue (HP-exhausted squad holding the line psychologically). Deferred to post-MVP playtesting; a passive morale drain at HP < 10% threshold can be added as a tuning knob if needed.

3. **Aura visualization scope** — Hover-only aura display was specified. Is there a scenario where persistent aura visualization would be preferable (e.g., for new players learning the system)? Consider a difficulty/accessibility toggle for persistent aura rings vs. hover-only. Defer to UX design phase.

4. **Alexsen's Juggernaut passive and morale** — The Morale System exposes a `morale_damage_immune` hook that Alexsen's passive sets. The Officer Passive Ability System (design #14) owns the implementation. Before that GDD is authored: confirm whether Alexsen's immunity means his squad's morale NEVER changes (frozen at 100), or just can't be damaged (could theoretically increase via recovery). The intent is frozen at start value — no need to even run recovery for immune squads.

5. **Starting morale for Preparation Phase "rest troops" action** — If the Preparation Phase allows a "rest troops fully" action that starts all squads at 100 morale (including officer-less squads), this overrides the `officerless_morale_start` = 70 default. The Morale System accepts whatever starting morale is passed in. Confirm that the Preparation Phase GDD (design #19) explicitly documents this override.

6. **Campaign recovery unit mapping** — This GDD resolves "1 HP = 1 manpower" for recovery purposes. Confirm when the Army Composition GDD (design #17) is authored that manpower and HP share the same unit scale. If they don't, a conversion factor must be added to the campaign recovery formula.
