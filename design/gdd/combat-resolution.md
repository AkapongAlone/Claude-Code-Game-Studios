# Combat Resolution System

> **Status**: In Design
> **Author**: Game Designer + Systems Designer
> **Last Updated**: 2026-06-12
> **Implements Pillar**: P2 — Officers Are the Story + P3 — Grounded, Barely Fantastic
> **Review Mode**: Lean

---

## Overview

Combat Resolution System calculates damage outcomes when two squads clash in tactical combat. It takes attacker stats (WAR via Officer Stats System), defender stats (LDR for defense), terrain modifiers (hill/forest via Terrain System), and positioning state (facing/flank via Facing & Flank System) and produces a numeric damage result applied to the defender's HP pool. Combat Resolution is the core of the tactical layer: officers' stat spreads matter *here*, terrain advantage matters *here*, and positioning strategy pays off *here*. The system is deterministic (no RNG in damage calculation) so outcomes are predictable and skill-driven.

---

## Player Fantasy

**Combat feels like a consequence of preparation.** The player chose this terrain (knowing the hill bonus exists), selected this officer (knowing Alexsen has WAR 98), positioned units to achieve a flank. When the attack resolves, the damage number that appears is *the result of all those prior decisions*. Low damage means "I didn't set this up well enough." High damage means "my preparation paid off." Officers are tactically distinct: Alexsen's damage is noticeably higher than Bon shi hai's on the same target, same terrain. The fantasy is: "This game keeps its promises — the stronger officer does more damage, the better position deals more damage, and I can predict outcomes before committing."

---

## Detailed Design

### Core Rules

**Attack Flow:**
1. Attacker selects defender target
2. System checks if attack is valid (in range, line of sight)
3. System calculates damage_dealt = base_damage(attacker) × terrain_modifier × position_modifier × morale_modifier
4. Damage is applied to defender's HP pool
5. If defender's HP drops to 0, squad is removed (death) or routed (morale break first)
6. Damage event is logged and triggers Morale System recalculation

**Damage Calculation Order:**
1. Base damage (attacker's WAR-derived stat)
2. Terrain modifier (hill/forest/village from Terrain System)
3. Flanking modifier (if attacker is flanking, bonus applied)
4. Morale modifier (attacker morale state reduces damage if low; defender morale state reduces defense if low)

**Ranged vs. Melee:**
- **Ranged** (archer, musketeer): base damage = unit_type_base × (1 + attacker.WAR / 100). Range: 2–4 hexes. Requires line of sight (blocked by forest, building corners). Cannot attack adjacent hexes.
- **Melee** (sword, spear): base damage = unit_type_base × (1 + attacker.WAR / 200). Range: 1 hex adjacent only. No line of sight required. Can attack through corners.

The WAR scaling is different (1/100 vs. 1/200) because melee officers naturally deal more damage at base level, so WAR scaling is dampened to prevent melee domination.

**Defender Defense:**
- base_defense = defender_officer.LDR × 0.5 (if officer present). If no officer, base_defense = 0.
- defense = base_defense × terrain_modifier
- effective_damage = damage_dealt × (1 - min(defense / 100, 0.9)) — caps defense at 90% reduction max

Example: Defender with LDR 80 in a village (+15% defense): effective_defense = 40 × 1.15 = 46. Incoming damage 100: 100 × (1 - 46/100) = 100 × 0.54 = 54 damage dealt.

### States and Transitions

Combat Resolution has no states. It is a stateless calculation function: given inputs (attacker, defender, terrain, position), it produces damage output. The output may trigger state changes in other systems (Morale, Death, Rout) but Combat Resolution itself does not track state.

### Interactions with Other Systems

| System | Reads | Writes |
|---|---|---|
| Officer Stats | attacker.WAR, defender.LDR | — |
| Terrain | terrain_type, terrain_damage_mod | — |
| Facing & Flank | is_flanking(attacker position) | — |
| Morale | attacker_morale_state, defender_morale_state | — (Morale System reads combat results) |
| Tactical HUD | — | damage_dealt (displayed as floating number) |
| Victory Conditions | — | casualty_count (triggers rout checks) |

---

## Formulas

### 1. Base Damage (Ranged)

```
base_damage_ranged = unit_base × (1 + attacker.WAR / 100)
```

| Variable | Type | Range | Description |
|---|---|---|---|
| unit_base | int | [15, 40] | Squad type base damage (archer 20, musketeer 35) |
| attacker.WAR | int | [1, 100] | Officer WAR stat |
| base_damage_ranged | float | [15, 50] | Damage before modifiers |

**Example:** Archer (unit_base 20) with WAR 80 officer: 20 × (1 + 80/100) = 20 × 1.8 = 36 damage

### 2. Base Damage (Melee)

```
base_damage_melee = unit_base × (1 + attacker.WAR / 200)
```

| Variable | Type | Range | Description |
|---|---|---|---|
| unit_base | int | [25, 50] | Squad type base damage (swordsman 40, spear 35) |
| attacker.WAR | int | [1, 100] | Officer WAR stat |
| base_damage_melee | float | [25, 50] | Damage before modifiers |

**Example:** Swordsman (unit_base 40) with WAR 80 officer: 40 × (1 + 80/200) = 40 × 1.4 = 56 damage

### 3. Total Damage (All Modifiers Combined)

```
damage_dealt = base_damage × terrain_mod × flanking_mod × morale_mod
```

| Variable | Type | Range | Description |
|---|---|---|---|
| base_damage | float | [15, 56] | From formulas 1 or 2 |
| terrain_mod | float | [0.75, 1.25] | From Terrain System (hill +25%, forest -25%) |
| flanking_mod | float | [1.0, 1.3] | 1.0 if not flanking, 1.3 if flanking (+30%) |
| morale_mod | float | [0.5, 1.0] | Attacker morale state (low morale = 0.5 damage; normal = 1.0) |
| damage_dealt | float | [5, 90] | Final damage after all modifiers |

**Example:** Swordsman 56 base damage, on hill (+25%), flanking (+30%), attacker morale normal (1.0):
56 × 1.25 × 1.3 × 1.0 = 91.2 damage (clamped to 90 max)

### 4. Effective Defense (Damage Reduction)

```
effective_damage = damage_dealt × (1 - min(defense / 100, 0.9))
```

| Variable | Type | Range | Description |
|---|---|---|---|
| damage_dealt | float | [5, 90] | From formula 3 |
| defense | float | [0, 46] | LDR × 0.5 × terrain_mod; capped at 46 |
| damage_reduction_rate | float | [0, 0.9] | Defense as percentage reduction; capped at 90% |
| effective_damage | float | [0.5, 90] | Damage after defense reduction |

---

## Edge Cases

**If attacker or defender has 0 morale (broken):** Attacker deals 50% damage. Defender takes 100% damage (morale already broken, can't reduce further). Unit may rout before taking damage (Morale System decides).

**If a squad's HP reaches exactly 0:** Squad is killed (removed from map). Casualties count toward Morale System checks for adjacent officers.

**If a squad's HP is reduced below 0:** Clamp to 0 (no negative HP). Treat as killed.

**If attacker and defender are the same squad (edge case: self-attack bug):** Reject the attack as invalid. Log error.

**If terrain modifier is 0 (no terrain type assigned to hex):** Use 1.0 (no modifier). Treat as safe fallback.

**If flanking_mod is calculated incorrectly (bug in Facing & Flank System):** Fall back to 1.0 (no flank bonus). Damage is reduced, but combat continues (safety fallback).

---

## Dependencies

**Upstream dependencies:**
- Officer Stats (reads WAR, LDR)
- Terrain (reads damage modifier)
- Facing & Flank (reads flank status)
- Morale (reads morale state)

**Downstream dependencies:**
- Morale System (reads casualty count, triggers morale checks)
- Tactical HUD (displays damage numbers)
- Victory Conditions (reads casualty count for rout checks)
- Duel System (may use simplified damage formula — TBD in Duel GDD)

---

## Tuning Knobs

| Knob | Default | Safe Range | Impact |
|---|---|---|---|
| Ranged WAR scaling | 1/100 | [1/50, 1/150] | Higher = ranged more WAR-dependent |
| Melee WAR scaling | 1/200 | [1/100, 1/300] | Higher = melee more WAR-dependent |
| Flank bonus | +30% | [+20%, +50%] | Higher = positioning more important |
| Morale damage penalty (broken) | -50% | [-30%, -70%] | Higher = broken units are more useless |
| Defense cap | 90% | [75%, 100%] | Higher = defense becomes stronger |
| LDR-to-defense scaling | 0.5 | [0.3, 0.7] | Higher = LDR stat grants more defense |

---

## Visual/Audio Requirements

**Hit feedback:**
- Damage number appears above defender squad, color-coded: white (normal), green (low damage), red (high damage)
- If critical hit (high flank bonus): number pulses slightly
- SFX: melee impact sound (sword/spear clash), ranged impact sound (arrow/musket hit)

**Miss feedback (if damage < 5% of defender's max HP):**
- "Ineffective!" text appears
- SFX: deflection/parry sound

**Death feedback:**
- Squad disappears with death animation (fade-out, collapse, or visual appropriate to unit type)
- SFX: death cry (brief, not gratuitous)

---

## Acceptance Criteria

**GIVEN** a ranged archer (base 20) with WAR 80 officer attacking on flat terrain, **WHEN** damage is calculated, **THEN** damage = 20 × 1.8 × 1.0 × 1.0 × 1.0 = 36.

**GIVEN** the same archer attacking from a hill (+25%), **THEN** damage = 20 × 1.8 × 1.25 × 1.0 × 1.0 = 45.

**GIVEN** the same archer attacking a defender in forest (attacker -25% damage), **THEN** damage = 20 × 1.8 × 0.75 × 1.0 × 1.0 = 27.

**GIVEN** the archer is flanking (+30% damage), **THEN** damage = 20 × 1.8 × 1.0 × 1.3 × 1.0 = 46.8.

**GIVEN** a defender with LDR 80 in a village (+15% defense), **WHEN** defending against 100 damage, **THEN** effective_defense = 40 × 1.15 = 46; damage taken = 100 × (1 - 0.46) = 54.

**GIVEN** attacker's morale is broken (state: broken), **WHEN** damage is calculated, **THEN** damage_dealt is reduced by 50% (morale_mod = 0.5).

**GIVEN** a squad's HP reaches 0, **WHEN** the turn ends, **THEN** the squad is removed from the map and casualty count increments.

**GIVEN** a flanking bonus is triggered but Facing & Flank System fails to recognize it (bug), **WHEN** damage falls back to 1.0× (no flank), **THEN** combat continues with reduced damage (safety mechanism active).
