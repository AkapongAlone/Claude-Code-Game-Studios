# Officer Stats System

> **Status**: In Design
> **Author**: Game Designer + Systems Designer
> **Last Updated**: 2026-06-11
> **Implements Pillar**: P2 — Officers Are the Story + P1 — Victory Through Preparation
> **Review Mode**: Lean

---

## Overview

The Officer Stats System defines the five numeric attributes — WAR, LDR, INT, POL, CHR — that quantify every named officer's capabilities and role in the game world. Each stat is a numeric value (1–100) that remains nearly static across the campaign (growth limited to +1–3 per major deed); rather than progression through stat grinding, officer identity emerges from the unique *spread* of their five values and their Signature Passive Ability. This system is the foundational data layer: every other system in the game — Combat Resolution (for damage and defensive bonuses), Morale (for officer aura radius and recovery), Duel (for combat calculations), Diplomacy (for success chances), and Campaign Layer (for economic and governance output) — reads officer stats to compute their effects. Officer Stats owns the interface contract; dependent systems agree to accept these five values as the source of truth and to make no independent adjustments to them outside of the system's defined formulas.

---

## Player Fantasy

**The fantasy is clarity through numbers.** When a player sees Alexsen's WAR at 98 and Zhuge Jian's INT at 99, they immediately *understand* who this officer is without needing to be told. The stat spread becomes a visual signature — it's the game's way of saying "Alexsen is unstoppable in melee" and "Zhuge Jian sees what others miss." The player's fantasy is **reading the battlefield and the officers within it as a coherent system of numbers** — the sense that every combat advantage, every diplomatic success, every strategic decision flows from these five values. It's the feeling of being a general who has studied his officers so thoroughly that he can predict their behavior from a glance at their sheet. There's no hidden randomness obscuring who an officer is; stat spreads are the complete, truthful expression of capability.

---

## Detailed Design

### Core Rules

**Officer Stat Block Structure:**
Every officer (named and generic) has exactly five numeric stats:
- **WAR** (Warfare) — Combat prowess, melee/ranged damage, duel effectiveness
- **LDR** (Leadership) — Squad control capacity, morale influence, unit cohesion
- **INT** (Intelligence) — Strategic insight, intel cost reduction, stratagem effectiveness, misinformation resistance
- **POL** (Politics) — Governance output, economic management, diplomatic persuasion
- **CHR** (Charisma) — Officer recruitment, morale recovery, loyalty influence

**Value Range & Constraints:**
- Each stat is an integer in the range [1, 100]
- Values clamped at both ends: no stat may be assigned or modified below 1 or above 100
- Stat values are **persistent across campaign turns** — they do not reset or decay

**Named Officer Initialization (7 officers):**
| Officer | WAR | LDR | INT | POL | CHR |
|---|---|---|---|---|---|
| Kaster | 82 | 96 | 92 | 85 | 88 |
| Bon shi hai | 55 | 78 | 94 | 80 | 62 |
| Alexsen | 98 | 85 | 40 | 25 | 75 |
| Thane | 90 | 50 | 75 | 30 | 45 |
| Zhuge Jian | 30 | 70 | 99 | 90 | 80 |
| Jin Tao | 45 | 60 | 88 | 95 | 50 |
| Sander | 75 | 88 | 65 | 55 | 70 |

These values are the **Prologue baseline**. They may grow during the campaign (see Growth section below).

**Generic Officer Initialization:**
Generic officers (recruitable from settlements, ~25–30 available) are assigned stats at recruitment time:
1. **Archetype selection**: Player chooses (or system assigns) one of ~8–10 archetypes (e.g., "Warrior", "Scholar", "Administrator", "Scout")
2. **Stat distribution per archetype**: Each archetype has a defined stat template with a fixed high stat and low stats. Example:
   - Warrior: high WAR (75–88), low INT (30–45)
   - Scholar: high INT (80–95), low WAR (25–40)
   - Administrator: high POL (80–95), low CHR (40–55)
3. **Randomization**: Within archetype, each stat is randomized ±2–3 from the archetype baseline (within the 1–100 range)
4. **Passive Ability (optional)**: ~20% of generic officers are assigned a random Passive Ability from a pool of ~12 generic passives (e.g., Forager, Drillmaster). Named officers are not subject to this randomization — their passives are individually designed.

**Growth Mechanism — Act-Based Stat Growth:**
- Officers grow stats at **act transitions** (Prologue→Act I, Act I→Act II, Act II→Act III, Act III→Act IV)
- At each transition, each **named officer** gains +1 to +3 to one or more of their stats (designer chooses which stat, which officer, and how much growth at each milestone)
- Generic officers **do not grow**; new recruits always start at their archetype baseline
- Growth is **permanent**: once a stat increases, it does not decrease
- Maximum stat value remains clamped at 100 — growth that would exceed 100 is clamped to 100

**Officer Stat Immutability (Within Acts):**
- During an act (campaign turns, battles, diplomacy), officer stats **do not change**
- Stats are read-only for all dependent systems during active gameplay
- Stats change only at act transitions (automatic system event, no player action required)

---

### States and Transitions

Officer Stats exist in a **single persistent state**: the current numeric values of the five stats. There are no transient states (buffed/debuffed), no state machine, no transitions between named states.

**The only state change**: a stat value increases from X to X+N during an act transition. This is not a "state transition" in the traditional sense; it is a **data mutation** (value assignment) that occurs outside gameplay.

Dependent systems read the current stat values; they do not trigger stat changes. Stat changes are driven solely by act milestone events (external to Officer Stats System).

---

### Interactions with Other Systems

Officer Stats System is the **data provider**. It exports the five stat values per officer to every dependent system. The dependency relationship is unidirectional: Officer Stats is read-only from the perspective of other systems.

**Dependent System Integrations:**

| Dependent System | Reads | Purpose | Interface |
|---|---|---|---|
| Combat Resolution | WAR, LDR | Compute damage bonus, defense modifier, hit chance | `officer.war()` → int, `officer.ldr()` → int |
| Morale System | LDR, CHR | Officer morale aura radius, morale recovery rate | `officer.ldr()`, `officer.chr()` |
| Duel System | WAR | Duel damage calculation, stamina recovery rate | `officer.war()` |
| Officer Passive Ability System | varies by passive | Some passives threshold on INT (Zhuge Jian +1 slot if INT ≥ 90) | Passive defines its own stat read |
| Diplomacy System | CHR, INT | Persuasion success chance, resistance to misinformation | `officer.chr()`, `officer.int()` |
| Settlement Management System | POL | Governor output multiplier, loyalty gain rate | `officer.pol()` |
| Campaign AI System | all five | AI decision-making heuristics (which officers to deploy where) | all five stats as inputs to scoring |
| Preparation Phase System | INT | Intel cost reduction, action slot availability (Zhuge Jian) | `officer.int()` |

**Data Contract:**
- Dependent systems must never modify officer stats directly
- Stat values are immutable from dependent system perspective; growth is owned by Officer Stats System only
- All reads are synchronous (no async/latency expected); stat values are always current in memory

**Error Handling:**
- If a stat is queried for an officer that does not exist: return null; dependent system must handle gracefully
- If a stat query receives an invalid stat type (e.g., "FEAR"): log error; return 0 (safe default)
- If act transition is triggered while a battle is in progress: defer stat growth until battle end, then apply growth

---

## Formulas

Officer Stats System has three numeric specifications:

### 1. Generic Officer Stat Randomization

The `randomize_generic_officer(archetype)` process is defined as:

For each stat S in {WAR, LDR, INT, POL, CHR}:
```
officer_stat[S] = clamp( archetype_baseline[S] + random(-variance, +variance), 1, 100 )
```

**Variables:**
| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| Archetype baseline | B_s | int | [1, 100] | The center stat value for this archetype's stat S |
| Randomization variance | Δ | int | [0, 5] | ±range applied to baseline; designer-configurable per archetype |
| Officer stat (output) | O_s | int | [1, 100] | Final assigned stat value, clamped to valid range |

**Default variance**: Δ = 2 (±2 from baseline). Designers may adjust Δ per archetype (e.g., Warrior archetype uses Δ=3, Scholar uses Δ=2).

**Output range**: [1, 100] under all circumstances. If randomization would produce a value outside this range, clamp to nearest bound.

**Example**: Warrior archetype has baseline WAR=80. With variance=3, a generic warrior officer's WAR is randomly assigned in range [77, 83], then clamped to [1, 100] (no change in this example since 77–83 is within bounds).

### 2. Act-Based Stat Growth

When an act transition occurs (e.g., Act I starts), each named officer grows one or more stats. The growth amount per stat is:

```
stat_growth[S] = random(1, 3)
officer_stat[S] = clamp( officer_stat[S] + stat_growth[S], 1, 100 )
```

**Variables:**
| Variable | Symbol | Type | Range | Description |
|---|---|---|---|---|
| Current stat value | O_s | int | [1, 100] | Officer's stat before growth |
| Growth amount | G_s | int | [1, 3] | Random amount added; chosen independently per stat |
| Officer stat (output) | O_s' | int | [1, 100] | Final stat after growth, clamped |

**Growth selection rule**: Designer specifies *which* named officers grow *which* stats at each act transition. Example: "At Act II start, Kaster grows WAR by random [1-3], LDR by random [1-3], CHR by random [1-3]." The amounts are randomly determined; the *choice* of which officers and which stats is designer-authored.

**Output range**: Growth is clamped to [1, 100]. If Kaster's WAR is already 95 and grows +3, final value is 100 (clamped).

### 3. Stat Value Clamping (Safety Formula)

All stat operations must enforce:

```
stat_value = clamp(value, min=1, max=100)
```

This applies at:
- Officer initialization (named and generic)
- Growth application
- Any formula in a dependent system that modifies a stat (though Officer Stats System forbids modification by dependents)

**Output range**: [1, 100] always.

---

## Edge Cases

**If a stat is queried before officer initialization completes:** Return null. Dependent systems must handle null gracefully (treat as officer not yet available; do not proceed with calculations that depend on that officer's stats).

**If growth is applied to a stat already at 100:** The clamping formula enforces max=100. Growth of +1 to a stat at 100 results in 100 (clamped), not 101. No overflow, no error; silently cap at 100.

**If generic officer randomization produces a value outside [1, 100]:** The clamping formula handles all randomization. No edge case — output is always valid by construction. Example: archetype baseline 98 + random variance +5 = 103 → clamped to 100.

**If act transition occurs during an active battle:** Act transition is a system event fired *after* the preceding act's last battle concludes. Growth is applied only at the start of the next act, not during active gameplay. If a battle is somehow still running when an act transition is triggered (system error), defer the growth application until the battle ends, then apply growth before the first turn of the new act.

**If a dependent system attempts to modify an officer stat directly:** Officer Stats System forbids direct modification by dependent systems. Calls like `officer.set_war(100)` are invalid and must be rejected by the Officer Stats interface (return error, log warning). Dependent systems may read stats but never write them. All writes are reserved for Officer Stats System internally (initialization, growth, clamping).

**If an invalid archetype is selected during generic officer recruitment:** Invalid archetype → log error and return null. Recruitment fails. Player must select a valid archetype before the recruitment completes. Fallback behavior: do not auto-default to "Warrior" or any other archetype; require explicit valid selection.

---

## Dependencies

Officer Stats System has **no upstream dependencies** — it depends on nothing. It is a pure data layer.

Officer Stats System has **14 downstream dependencies** — systems that read officer stats to compute their effects:

| Dependent System | Dependency Type | What is read | Purpose | Hard/Soft |
|---|---|---|---|---|
| Combat Resolution | Read WAR, LDR | Damage formula, defense modifier | Tactical combat damage calculations | Hard |
| Morale System | Read LDR, CHR | Officer aura radius, morale recovery rate | Officer morale effects during battle | Hard |
| Duel System | Read WAR | Duel damage, stamina recovery | 1v1 combat mechanics | Hard |
| Officer Passive Ability System | Read varies | Different passives threshold on different stats (e.g., Zhuge Jian INT ≥ 90) | Passive ability gating and effects | Hard |
| Diplomacy System | Read CHR, INT | Persuasion success chance, misinformation resistance | Settlement persuasion and deception defense | Soft |
| Settlement Management System | Read POL | Governor output multiplier, settlement loyalty rate | Economic and governance output | Hard |
| Campaign AI System | Read all 5 | Officer scoring heuristics (which officers to deploy, where to govern) | AI decision-making | Soft |
| Preparation Phase System | Read INT | Intel cost reduction, Zhuge Jian +1 slot if INT ≥ 90 | Pre-battle planning options | Soft |
| Facing & Flank System | Read LDR | Leader aura protection from flank (passive) | Flank damage mitigation | Soft |
| Victory/Defeat Conditions | Read LDR | Squad rout threshold (higher LDR = harder to rout) | Battle end condition calculation | Soft |
| Tactical HUD | Read all 5 | Display officer stats in unit inspector | UI information only | Soft |
| Campaign Map UI | Read all 5 | Display officer stats in character detail panel | UI information only | Soft |
| Portrait & Character Display | Read varies | Display context (e.g., officer archetype determination) | Character presentation | Soft |
| Save/Load System | Read all 5 + growth history | Serialize officer stat state to save file, deserialize on load | Persistence | Hard |

**Hard dependencies** = system cannot function without Officer Stats System. **Soft dependencies** = system is enhanced by Officer Stats but can function with degraded behavior if Officer Stats is unavailable.

**Data Contract:**
- All dependent systems may *read* officer stat values at any time
- No dependent system may *write* or *modify* officer stat values
- Stat values are guaranteed immutable during an act (no changes mid-gameplay)
- Stat changes occur only at act transitions, outside active gameplay

---

## Tuning Knobs

All tuning knobs are designer-adjustable without code changes (ideally via configuration or spreadsheet; details of authoring tool belong in `/architecture-decision`).

**1. Generic Officer Archetype Baselines**

For each archetype (~8–10 archetypes), define baseline stat values:

| Archetype | WAR | LDR | INT | POL | CHR |
|---|---|---|---|---|---|
| Warrior | 78 | 60 | 35 | 40 | 55 |
| Scout | 62 | 55 | 70 | 45 | 60 |
| Scholar | 25 | 65 | 85 | 75 | 70 |
| Administrator | 35 | 72 | 75 | 90 | 60 |
| ... | ... | ... | ... | ... | ... |

**Impact on gameplay:** Archetype determines which officer types are available, which strengths/weaknesses players recruit. Lowering Warrior WAR makes generics less combat-effective; raising Scholar INT makes research-passive officers common.

**Extreme behaviors:** 
- If all archetypes have equally distributed stats (e.g., all 50/50/50/50/50), generic officers become homogenous and lack identity.
- If one archetype dominates (e.g., Warrior has 99 WAR), all recruitment skews toward that archetype.

---

**2. Randomization Variance (Δ) Per Archetype**

For each archetype, set the ±range applied during randomization (default: Δ=2, range [0, 5]):

| Archetype | Variance (Δ) |
|---|---|
| Warrior | 3 |
| Scout | 2 |
| Scholar | 2 |
| Administrator | 1 |

**Impact on gameplay:** Higher variance creates more diverse recruits within an archetype (Warrior can be 75–81 WAR instead of 76–80). Lower variance creates consistency (Administrator always has predictable POL).

**Extreme behaviors:** 
- If Δ=0 (no variance), all Warrior officers are identical clones; no recruitment variety.
- If Δ=5, even an Administrator can spawn with random 95 POL (outlier).

---

**3. Named Officer Growth Per Act**

For each named officer, at each act transition, specify growth:

| Officer | Act I→II | Act II→III | Act III→IV |
|---|---|---|---|
| Kaster | WAR +1–3, LDR +1–3, CHR +1–3 | WAR +1–3, INT +1–3 | LDR +1–3, CHR +1–3, POL +1–3 |
| Alexsen | WAR +1–3, LDR +1–3 | WAR +1–3 | LDR +1–3, CHR +1–3 |
| ... | ... | ... | ... |

(Exact amounts are random [1, 3], but *which* stats grow is designer-authored.)

**Impact on gameplay:** Growth shapes officer progression. Focusing Kaster's growth on WAR/LDR makes him a stronger combat leader. Focusing on INT/POL makes him more diplomatic/strategic.

**Extreme behaviors:** 
- If no growth is assigned, officers stagnate (could be intentional — "officers peak and don't grow").
- If all officers grow WAR every act, combat becomes dominant mechanic; non-combat officers fall behind.

---

**4. Archetype Stat Distribution Philosophy**

**Tuning parameter:** How "peaked" or "balanced" should archetypes be?

Example:
- **Peaked model** (current): Warrior high WAR (78), low INT (35). Each type has 1–2 standout stats.
- **Balanced model** (alternative): All archetypes average 55, with ±10 variance per stat. Everyone is generalist-ish.

**Impact on gameplay:** Peaked archetypes force specialization (recruit Warriors for combat, Scholars for intel). Balanced archetypes enable multi-role officers (Warrior can also govern decently).

---

**Safe Ranges:**

| Knob | Safe Min | Safe Max | Rationale |
|---|---|---|---|
| Archetype stat value | 20 | 90 | Below 20 or above 90 creates outlier officers; most at extremes feel broken |
| Randomization variance (Δ) | 0 | 5 | Above 5 creates such wild outliers that archetype identity becomes meaningless |
| Growth per stat per act | 0 | 5 | Above 5 grows officers too quickly (reach 100 by Act III); below 0 invalid |
| Officers with growth per act | 0 | 7 | All 7 named officers can grow; 0 means no growth mechanic used (intentional alternative) |

---

## Visual/Audio Requirements

[To be designed]

---

## UI Requirements

[To be designed]

---

## Acceptance Criteria

**GIVEN** a fresh campaign start at Prologue, **WHEN** Kaster is inspected, **THEN** his stat block reads exactly: WAR 82, LDR 96, INT 92, POL 85, CHR 88 (matching GDD table).

**GIVEN** a generic officer recruitment (Warrior archetype, baseline WAR 78, variance Δ=3), **WHEN** 100 Warrior officers are recruited, **THEN** at least 70 have WAR in range [75, 81] (within baseline ± variance) and all 100 have WAR in [1, 100] (clamped).

**GIVEN** Kaster at Act I with WAR 82, **WHEN** Act II begins and growth of +2 is specified for WAR, **THEN** Kaster's WAR becomes exactly 84 (no overflow, no randomness in application).

**GIVEN** Kaster's POL is 100, **WHEN** growth of +1 is applied, **THEN** Kaster's POL remains 100 (clamped, not 101).

**GIVEN** Combat Resolution System is running, **WHEN** it queries Alexsen's WAR stat, **THEN** it receives 98 (or current value post-growth) without error.

**GIVEN** Combat Resolution System attempts to set Alexsen's WAR to 50, **WHEN** the set operation is called, **THEN** the operation is rejected and an error is logged. Alexsen's WAR remains unchanged.

**GIVEN** a generic Warrior officer with baseline WAR 78, variance 3, **WHEN** 1000 randomizations are performed, **THEN** the distribution of WAR values is approximately uniform across [75, 81] (no clustering at edges, no bias toward any value). (Chi-square goodness-of-fit test p > 0.05.)

**GIVEN** an officer's stat is queried before the officer has been initialized, **WHEN** the query is executed, **THEN** the system returns null and the calling system handles gracefully (does not crash or produce undefined behavior).

**GIVEN** act transition occurs while a battle is active, **WHEN** the growth trigger fires, **THEN** growth is deferred and applied after the battle concludes. Existing battle stat calculations do not change mid-battle.

**GIVEN** all named officers have been recruited and grown through Act I→Act II, **WHEN** each officer's stats are examined, **THEN** each stat is within [1, 100] for every officer (no invalid values, all clamped correctly).

---

## Open Questions

[To be designed]
