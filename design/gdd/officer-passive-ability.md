# Officer Passive Ability System

> **Status**: Designed
> **Author**: Game Designer + Systems Designer
> **Last Updated**: 2026-06-12
> **Implements Pillar**: P2 — Officers Are the Story
> **Review Mode**: Lean

## Overview

The Officer Passive Ability System defines the unique mechanical behaviors that make each named officer feel irreplaceable beyond their stat spread. Every named officer carries one or two named passive abilities — persistent effects that activate automatically during battle, the campaign layer, or the Preparation Phase, requiring no direct player action to trigger. These passives are the primary expression of **P2 (Officers Are the Story)**: Alexsen's morale immunity makes him feel like an unstoppable force; Thane's forest ambush passive makes every forest hex a tactical resource; Bon's vision bonus reshapes how the player reads the fog of war. Without passives, officers are indistinguishable except by degree — with passives, each officer creates a distinct spatial and tactical identity that changes how battles are approached. Generic recruitable officers have a 20% chance of carrying one passive from a pool of approximately twelve generic passive categories (weaker, single-purpose effects vs. named officer passives). The system operates entirely as passive hooks registered at battle or campaign start: no player UI is needed to activate them. The Officer Passive Ability System owns the definitions and registration of all passives; other systems (Morale, Combat Resolution, Fog of War, Duel, Campaign) each expose a hook interface that passives call into.

## Player Fantasy

*Lean mode: `creative-director` not consulted — review against art bible and game pillars before production.*

The fantasy is **roster composition as playstyle identity**. When you deploy Thane, you have a specific plan — forests are your weapon, ambush is your doctrine. When you bring Bon instead of Thane, you know more, see farther, but you've sacrificed the sudden flanking threat. The officer roster is not a collection of increasingly powerful cards; it is a set of *lenses through which the same battle looks different*. Choosing your officers before a battle is the last move of the Preparation Phase — the moment where the abstract plan ("I'll control the forest flank") becomes concrete ("Thane's squad enters from the western tree line on turn 1").

The Heirloom Blade is a separate fantasy entirely: the blade is a question mark with teeth. Over the course of a playthrough, players who pay close attention will notice unusually high damage numbers appear from Kaster's squad without explanation — not often, not reliably, just *occasionally* and without announcement. The players who notice will argue about it. "Is that a bug? Is that a feature? Is it really the blade?" The fantasy here is narrative uncertainty packaged as a mechanical whisper: *P3 (Grounded, Barely Fantastic)* at the level of a floating combat number.

The **Vital Strike** fantasy — Thane's killing blow that radiates morale damage to adjacent enemies — is the tactical punctuation mark. The player sets up a flanking ambush, Thane's Shadow Work forces the flanking bonus from forest, the squad deals killing damage, and the cascade morale hits arrive like aftershocks. Victory through choreography, not luck.

Sander's **Old Guard** aura makes the player think about formation geometry rather than raw numbers. A high-LDR officer with a 3-hex aura is an anchor point — but his specific value (flank immunity for adjacent squads) means his best position is the corner of a line, not the center, because flanks are most vulnerable at the edges. That spatial reasoning — "where does Sander go to block the most dangerous morale source" — is P1 (Victory Through Preparation) applied at the squad-placement level.

## Detailed Design

### Core Rules

**Passive Registration:**
At the start of every tactical battle or campaign phase where passives apply, the Officer Passive Ability System initializes a `PassiveRegistry`. Each officer present in the battle has their passive(s) registered as active hooks. Passives are deregistered when their officer is incapacitated, killed, or absent from the current phase. Passives cannot be manually toggled by the player — they are always-on conditions.

**Passive Scope Categories:**
| Scope | When Active | Examples |
|-------|------------|---------|
| **Tactical** | During tactical battles only | Juggernaut, Old Guard, Shadow Work, Vital Strike, Stratagem, Read the Field |
| **Campaign** | Between battles, on campaign map | Quartermaster, The Treatises, Read the Field (partial) |
| **Hidden** | Same as scope but no UI disclosure | Heirloom Blade |

**Generic Officer Passives:**
Generic officers have a 20% probability at recruitment of receiving one passive from the generic pool. Generic passives are weaker, single-purpose versions of named passives — they never replicate a named officer's unique mechanic. The generic pool is defined as categories, not individual named abilities, for MVP (full list in M3).

---

### Named Officer Passives

#### Kaster — Read the Field

**Scope**: Tactical (and partial Campaign — see Campaign interaction)

**Mechanic**: Once per battle turn, Kaster may use the **Inspect** action during the Movement Phase to reveal the full stats of any single enemy officer whose squad is within Kaster's LDR aura radius (same radius used by Morale System). Revealed stats include: officer name, WAR, LDR, INT, CHR, morale value, and current HP percentage. The reveal is persistent for the rest of the battle — the revealed information remains visible even after Kaster's squad moves away.

**Passive Condition**: The Inspect action is available if and only if:
1. Kaster's squad is on the map and not BROKEN
2. The target enemy squad is within `floor(Kaster.LDR / 25)` hexes (the aura radius formula from the Morale System)
3. The target enemy squad has not already been inspected this battle

**Campaign Interaction**: When Kaster is the designated battle commander (the highest-LDR officer in the force at battle start), the player begins the battle with enemy officer identities revealed (names only, not stats) for all enemy squads in range of Kaster's starting hex.

**Design note:** "Read the Field" connects to the Duel System's WAR-based Read mechanic thematically — both are about Kaster's pattern-recognition. In the duel, it fires mechanically; in the tactical layer, it is a deliberate action. These are intentionally different because the tactical-scale read requires patient observation (spend an action), while the duel read is reflexive (it fires automatically at WAR advantage).

---

#### Kaster — Heirloom Blade

**Scope**: Tactical (Hidden)

**Mechanic**: On each attack resolved by Kaster's squad, there is a `blade_proc_rate` (default: 0.03 — 3%) probability that the damage calculation uses the **ceiling** of its possible range instead of the computed value. The ceiling for any attack is defined as: `damage_ceiling = unit_base × (1 + 100/WAR_divisor) × max_terrain_mod × max_flank_mod × 1.0` (using the formula maximums in place of actual values). In practice, a Blade proc on a swordsman with Kaster (WAR 82): ceiling ≈ 40 × 1.5 × 1.25 × 1.3 × 1.0 ≈ 97.5 → floored to 97 damage.

**No UI disclosure**: The Heirloom Blade proc produces no special combat log entry, no animation, no icon. It appears as a large damage number with no explanation. Players may notice unusually high numbers over many playthroughs but the game never confirms the cause. This is an **intentional design constraint** — the blade is ambiguous by narrative decree (P3). Adding even a subtle icon would undermine the ambiguity.

**Implementation constraint**: The `damage_ceiling` calculation must never exceed the Combat Resolution formula's physical maximum — it uses formula maximums, not a hardcoded constant, so that the proc cannot be exploited or detected by comparing to an "impossible" number.

**Naming note**: The passive entry in `officer_passives.json` is stored under the internal ID `"heirloom_blade"` but this ID must never appear in any player-facing string in the UI.

---

#### Alexsen — Juggernaut

**Scope**: Tactical

**Mechanic**: Alexsen's squad is immune to all morale damage. The flag `morale_damage_immune = true` is registered on Alexsen's DuelParticipant and squad entry. The Morale System checks this flag before applying any morale damage trigger (casualties, flank, officer loss, witnessing rout) and skips all morale damage for this squad when the flag is true. Alexsen's squad morale value is initialized normally (100) but never decreases in battle.

**Note**: Juggernaut does not make Alexsen's squad immune to HP damage, routing by HP exhaustion, or combat results. Only morale damage is blocked.

**Duel relation**: Alexsen's Crushing Blow Signature Move is defined in the **Duel System GDD** (Section C: Core Rules → Signature Move Interface) and executed via the `SignatureMoveResolver` hook. Crushing Blow is not owned by this GDD. This GDD owns Juggernaut (tactical morale immunity). These are distinct abilities that happen to share an officer.

---

#### Thane — Shadow Work

**Scope**: Tactical

**Mechanic**: When Thane's squad initiates a melee attack from a Forest hex, the attack is treated as a **flanking attack** regardless of the target's facing direction. The `flanking_mod` from the Combat Resolution formula is set to 1.3 (flanking value) for this attack even if `is_flanking()` from the Facing & Flank System returns false. Standard flanking bonuses from Facing & Flank System still apply additionally if the true facing position would also give a flank — but since the condition is already met, Shadow Work is redundant in that case (no double-stacking).

**Condition**: Thane's squad must be in a Forest hex at the moment of attack initiation (hex under Thane's squad's current position). Moving out of the forest and then attacking does not trigger Shadow Work.

**Ranged attacks**: Shadow Work applies only to melee attacks. Ranged attacks from forest hexes follow standard Combat Resolution (Shadow Work does not grant ranged flank bonus).

**Interaction with Vital Strike**: Shadow Work and Vital Strike are independent — Shadow Work fires at attack initiation (modifying the damage calculation), Vital Strike fires at kill resolution (triggering morale damage cascade). Both may fire on the same attack if the forest-ambush attack also kills the target.

---

#### Thane — Vital Strike

**Scope**: Tactical

**Mechanic**: When Thane's squad delivers the killing blow on an enemy squad (reducing their HP to 0 or below), all enemy squads within 2 hexes of the killed squad receive a flat `vital_strike_morale_damage` (default: −15 morale) immediately, outside the normal Morale Resolution Phase. This is a special out-of-phase morale trigger that fires synchronously with the kill event.

**Condition**: The kill must be the final damage event (HP drops to ≤ 0). Kills by non-HP-means (e.g., a morale-only route) do NOT trigger Vital Strike. Vital Strike triggers once per kill, not per target hit.

**Cascade note**: The −15 morale damage from Vital Strike can push squads into SHAKEN or BROKEN. BROKEN transitions from Vital Strike are processed in the same Morale Resolution Phase as the triggering turn's normal morale events — they do not get a special cascade pass. The 2-pass cascade cap still applies.

**Stacking**: If Thane kills two squads in one turn (via multi-hex attacks or a turn with two attacks), Vital Strike fires separately for each kill.

---

#### Zhuge Jian — The Treatises

**Scope**: Campaign / Preparation Phase

**Mechanic**: Zhuge Jian adds **+1 Preparation Phase action slot** to the player's available slots when he is present and active in the force entering a battle. The extra slot is available only if `Zhuge_Jian.INT ≥ 90` — this condition is true at his starting stats (INT 99) and remains true unless stats are dramatically altered.

**Threshold note**: The INT ≥ 90 threshold was referenced in the Officer Stats GDD as the gating condition. The threshold is a soft guard in case his INT stat is somehow reduced (an edge case in game design, but the gate must exist). Under normal campaign conditions, Zhuge Jian will always meet the threshold.

**Interaction**: The Preparation Phase System (undesigned as of this GDD) must read `passive_registry.has_flag("treatises_active")` to determine if the extra slot is available. This GDD defines the flag; the Preparation Phase System owns the slot count and consumes the flag.

**Campaign exclusion**: Zhuge Jian joining late (novel canon: treatise Acts I–II, physical Act III) means this passive is unavailable for the entire early campaign. The player has access to fewer Preparation Phase options until Zhuge Jian joins — this is an intentional P4 (Authored Peaks) constraint, not a gap to be patched.

---

#### Jin Tao — Quartermaster

**Scope**: Campaign

**Mechanic**: While Jin Tao is assigned as a **settlement governor**, all friendly armies within a 2-settlement-hop radius of his location receive a `quartermaster_supply_reduction` (default: 20%) reduction in supply costs per campaign turn. Supply cost reduction is multiplicative with other modifiers: `effective_supply_cost = base_supply_cost × (1 − 0.20)`. The radius is measured by the settlement graph (point-to-point adjacency), not distance.

**Stacking**: The Quartermaster bonus does not stack with itself if Jin Tao governs two settlements simultaneously (impossible — one governor per settlement), but it does not stack with a second officer carrying a generic "Forager" passive. If both apply to the same army, only the larger reduction applies (highest value wins, no additive stacking).

**Campaign AI interaction**: The Campaign AI System will consider the Quartermaster radius when deciding where to prioritize supply lines. This system defines the mechanic; the Campaign AI GDD will define how to factor it into decision-making.

---

#### Bon shi hai — Stratagem

**Scope**: Tactical

**Mechanic**: All friendly squads in the tactical battle gain **+1 vision range** to their base vision. This applies to the `vision_range` formula as an additive bonus to the `squad_vision_bonus` term: `vision_range = base_vision[unit_type] + terrain.vision_modifier(hex) + 1` (when Bon is present). The +1 applies globally to all friendly squads; it is not limited to squads in Bon's aura.

**Condition**: Bon's squad must be present and not BROKEN. If Bon is incapacitated, the bonus is removed immediately.

**Stacking**: Stratagem does not stack with a second copy of itself (impossible — Bon is unique). It does stack additively with terrain vision bonuses (hill +1, etc.).

---

#### Sander — Old Guard

**Scope**: Tactical

**Mechanic**: All friendly squads adjacent to Sander's squad (hex distance ≤ 1) are immune to the **"flanking received" morale damage trigger**. The flag `flank_morale_immune_aura = true` is applied to each adjacent squad at the start of each Morale Resolution Phase. The Morale System checks this flag before applying the flanking morale trigger.

**Radius**: Unlike the general LDR aura (which uses the LDR-based hex radius formula), Old Guard's immunity radius is fixed at 1 hex — immediately adjacent squads only. Sander's LDR stat still determines his general morale aura radius for other morale protection effects (the 25% morale damage reduction from the aura).

**HP damage**: Old Guard does NOT prevent HP damage from flanking attacks. Flanking via Shadow Work or actual facing/flank position still deals the full flanking_mod combat damage. Only the morale component of flanking is negated for adjacent squads.

**Coverage**: Old Guard's 1-hex immunity applies to the squads immediately adjacent, not to Sander's own squad (Sander's squad still has normal morale — he has no personal morale immunity, only the aura effect).

---

### Generic Passive Pool

Generic officers have a 20% chance at recruitment to receive one passive from the following category pool. These are defined as categories for MVP; specific balance values are authored per category during M3 content pass:

| Category | Scope | Effect sketch |
|----------|-------|--------------|
| **Forager** | Campaign | Reduces army supply consumption by a small amount |
| **Drillmaster** | Tactical | Adjacent friendly squads start battle with +10 morale |
| **Skirmisher** | Tactical | +1 movement range for LI unit type squads under this officer |
| **Logistics Expert** | Campaign | Reduces the time cost of one Preparation Phase action |
| **Inspiring Presence** | Tactical | Morale recovery rate +1 for squads within 1 hex |
| **Marksmanship** | Tactical | Ranged squads under this officer gain small ranged damage bonus |
| **Iron Will** | Tactical | This officer's squad takes reduced HP damage when morale is SHAKEN |
| **Investigator** | Campaign | Slightly reduces intel gathering cost in assigned settlement |
| **Fortifier** | Tactical | +5 base defense bonus when this officer's squad is in a village hex |
| **Veteran Instincts** | Tactical | This officer's squad is not surprised (no flanking_mod) on the first combat turn only |
| **Negotiator** | Campaign | Small POL bonus when governing a settlement |
| **River Guide** | Tactical | No AP penalty for river crossing hexes |

*Full stat values for each generic passive are deferred to M3 content pass. MVP requires only that the category names exist as data entries and the hook registrations work.*

---

### States and Transitions

The Officer Passive Ability System has no state machine. Passives are either **registered** (officer present and not incapacitated) or **deregistered** (officer absent or incapacitated). This is a binary flag per passive, not a state with transitions.

**PassiveRegistry lifecycle:**

| Event | Result |
|-------|--------|
| Battle/phase starts | All present officers' passives are registered |
| Officer becomes incapacitated | That officer's passives are deregistered immediately |
| Officer recovers (post-duel return, not death) | Passives re-register for remaining battle duration |
| Battle/phase ends | All passives deregistered; registry cleared |

**No mid-battle passive switching**: The player cannot add or remove officer passives during a battle. Roster changes (officer reassignment, recruitment) only take effect at campaign turn start.

**Hidden passive (Heirloom Blade) state**: No state tracking required — the proc is stateless (each attack rolls independently). The PassiveRegistry tracks only the flag `heirloom_blade_active = true` while Kaster's squad is present.

### Interactions with Other Systems

| System | Direction | Interface | What changes |
|--------|-----------|-----------|-------------|
| **Officer Stats** | Read | `officer.war()`, `officer.ldr()`, `officer.int()` | Passive eligibility thresholds (Treatises: INT ≥ 90); Read the Field: aura radius uses LDR |
| **Combat Resolution** | Write (hook) | `passive_registry.get_flank_mod_override(attacker)` | Shadow Work: override `flanking_mod = 1.3` when condition met |
| **Combat Resolution** | Write (hook) | `passive_registry.get_damage_ceiling(attacker, base_damage)` | Heirloom Blade: replace computed damage with ceiling value on proc |
| **Morale System** | Write (flags) | `squad.morale_damage_immune`, `squad.flank_morale_immune_aura` | Juggernaut sets immune flag; Old Guard sets aura flag per-squad each phase |
| **Morale System** | Write (trigger) | `passive_registry.on_kill(killer_squad, killed_squad)` | Vital Strike: fires out-of-phase morale damage on adjacent squads |
| **Fog of War / Vision** | Write (formula term) | `passive_registry.get_vision_bonus(squad)` → int | Stratagem: returns +1 for all friendly squads when Bon is active |
| **Duel System** | Hook interface | `SignatureMove.on_resolve()` | Alexsen's Crushing Blow registered in Duel System; this GDD does not own it |
| **Tactical Battle Controller** | Read | `battle_controller.add_action(squad, "inspect", target)` | Read the Field: registers the Inspect action for Kaster's squad during Movement Phase |
| **Preparation Phase System** | Write (flag) | `passive_registry.has_flag("treatises_active")` | Treatises: Prep Phase reads this flag to determine available action slot count |
| **Campaign Map System** | Write (modifier) | `passive_registry.get_supply_modifier(army)` | Quartermaster: returns 0.80 multiplier for armies in range of Jin Tao's settlement |

**Hook registration pattern:** All passives register their hooks via `PassiveRegistry.register(officer_id, passive_id, hook_type, condition_fn, effect_fn)`. Dependent systems call into the registry at the appropriate phase; the registry resolves conditions and fires effects. This ensures the Passive Ability System owns all passive logic — other systems call the hooks but never implement the passive behavior directly.

## Formulas

*Systems Designer reviewed: F-1 corrected (use Morale bracket table, not LDR/25 formula); F-3 corrected (proc rate 3%→5%, ceiling uses officer.WAR not 100); F-4 corrected (damage −15→−10, must route through cascade pass).*

---

### F-1: Read the Field — Inspect Range

```
inspect_range = aura_radius(officer.LDR)
```

Where `aura_radius()` is the same bracket table used by the Morale System (not a separate formula):

| LDR | Inspect range (hexes) |
|-----|----------------------|
| < 50 | 1 |
| 50–74 | 2 |
| 75–89 | 3 |
| ≥ 90 | 4 |

**Variables:**
| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| Officer LDR stat | ldr | int | [1, 100] | From Officer Stats System |
| Inspect range (output) | inspect_range | int | [1, 4] | Maximum hex distance at which Kaster can inspect an enemy squad |

**Kaster (LDR 96):** inspect_range = 4 hexes.

**Rationale for bracket table (not division formula):** Using the same bracket table as the Morale System ensures that any LDR value producing a 4-hex morale aura also produces a 4-hex inspect range. Diverging formulas would create confusion when players expect the aura and the inspect to behave consistently. The bracket is the cross-system standard.

---

### F-2: Shadow Work — Flanking Override

```
shadow_work_active = (attacker_squad.officer == Thane)
                   AND (attacker_squad.terrain == FOREST)
                   AND (attack_type == MELEE)

IF shadow_work_active:
    flanking_mod = max(flanking_mod, 1.3)
```

**Variables:**
| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| Current flanking_mod | flanking_mod | float | [1.0, 1.3] | From Combat Resolution / Facing & Flank System |
| Shadow Work output | flanking_mod | float | [1.3, 1.3] | Guaranteed 1.3 when condition met |

**Design intent (critical):** Shadow Work guarantees flanking_mod = 1.3 on any qualifying attack, **even when the Facing & Flank System's `is_flanking()` check returns false**. The `max(flanking_mod, 1.3)` ensures that if `is_flanking()` already returned 1.3 (from real geometry), it is not doubled. Shadow Work only adds value when Thane is in forest but NOT in a true flank position — this is the passive's entire purpose: making forest hexes unconditionally threatening for Thane regardless of facing geometry.

---

### F-3: Heirloom Blade — Proc Rate and Damage Ceiling

```
blade_proc = (random_float() < blade_proc_rate)   [default: 0.05]

IF blade_proc:
    damage_dealt = damage_ceiling(unit_type, officer)

damage_ceiling = floor(unit_base_max[unit_type] × scaling(officer.WAR, unit_type) × max_terrain_mod × max_flank_mod × 1.0)

scaling(war, RANGED) = (1 + war / 100)
scaling(war, MELEE)  = (1 + war / 200)
max_terrain_mod = 1.25   [hill bonus — locked constant]
max_flank_mod   = 1.3    [flanking — locked constant]
```

**Variables:**
| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| Proc rate | blade_proc_rate | float | [0.0, 1.0] | Default 0.05 (5%). See tuning knobs |
| Officer WAR | war | int | [1, 100] | Kaster's actual WAR at time of attack |
| Unit base max | unit_base_max | int | [20, 50] | Largest unit_base for this unit type |
| Damage ceiling (output) | damage_ceiling | int | [~45, ~110] | Theoretical max output for this officer + unit type |

**Named values (Kaster WAR 82):**
- Melee swordsman (unit_base_max = 40): `floor(40 × 1.41 × 1.25 × 1.3) = floor(91.65) = 91`
- Ranged musketeer (unit_base_max = 35): `floor(35 × 1.82 × 1.25 × 1.3) = floor(103.2) = 103`

**Proc rate rationale:** At 5%, a single Kaster melee squad over a 20-turn battle (1 attack/turn) expects 1 proc. With 2 melee squads, expect 2 procs. This is the minimum threshold for "the player sees it happen at least once per battle most runs" while maintaining uncertainty about whether it was intentional. At 3%, the proc is nearly invisible and attribution to chance is near-certain. At 8%+, procs become regular enough to feel deliberate.

**Implementation constraint:** The ceiling uses `officer.WAR` (not 100), so the proc does not produce "impossible" numbers that players could detect as a hardcoded special case. The output is always within the range that a higher-WAR officer could theoretically produce through normal combat — maintaining the ambiguity.

**Hidden constraint**: The proc must not be logged in any combat log, floating text, or sound effect that differs from a normal hit. The large number should be indistinguishable in presentation from a lucky high roll.

---

### F-4: Vital Strike — Adjacent Morale Damage

```
vital_strike_fires = (kill_event AND squad.officer == Thane)

IF vital_strike_fires:
    FOR each enemy_squad WHERE hex_distance(enemy_squad, killed_squad) <= 2:
        queue: enemy_squad.pending_morale_damage += vital_strike_morale_damage

[Queued damage is processed during the Morale Resolution Phase as a witnessing-category event,
subject to the 2-pass cascade cap defined in the Morale System GDD]
```

**Variables:**
| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| Kill event | kill_event | bool | true/false | Fires when Thane's squad reduces target to HP ≤ 0 |
| Blast radius | vital_strike_radius | int | [1, 4] | Default: 2 hexes. Matches witnessing-rout radius from Morale System |
| Morale damage (output) | vital_strike_morale_damage | int | [5, 20] | Default: −10. Applied to each enemy squad in radius |

**Rationale for −10 (not −15):** The Morale System registers `witnessing_penalty = 10` per routing squad observed within 2 hexes. Vital Strike at −10 matches this ceiling, keeping a kill event proportionally consistent with a routing event. At −15, Vital Strike was 50% stronger per trigger than witnessing, and since kills are manufactured more cheaply than routs, −15 created a degenerate Thane strategy of hunting kills specifically to cascade-route neighboring SHAKEN squads.

**Cascade pass constraint:** Vital Strike damage is processed in the Morale Resolution Phase's standard cascade passes, not as immediate out-of-phase damage. This ensures the 2-pass cascade cap applies: Vital Strike morale damage cannot trigger unlimited routing chains in a single turn.

---

### F-5: Stratagem — Vision Bonus

```
squad_vision_bonus += 1   [when Bon shi hai is active and not BROKEN]

vision_range = base_vision[unit_type] + terrain.vision_modifier(hex) + squad_vision_bonus
```

The +1 is additive to the existing `vision_range` formula (registered in `entities.yaml`). No new formula — this GDD only defines the condition under which the bonus is applied.

**Output range note:** The `vision_range` formula is documented with output range [2, 5]. Stratagem can push vision to 6 when terrain also gives a +1 bonus (hill) and base_vision is already 5. This exceeds the documented range. The [2, 5] ceiling is a **soft maximum under normal conditions**, not a hard clamp. Vision 6 is legal and intentional when Bon is present.

---

### F-6: Quartermaster — Supply Cost Modifier

```
effective_supply_cost = base_supply_cost × (1 - quartermaster_supply_reduction)
  WHERE quartermaster_supply_reduction = 0.20   [default: 20%]
  
CONDITION: army is within 2 settlement-hops of Jin Tao's assigned governor settlement
           (settlement-hops = graph distance on the campaign settlement network)
```

**Variables:**
| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| Base supply cost | base_supply_cost | float | TBD | Defined in Resource System GDD (not yet authored) |
| Reduction fraction | quartermaster_supply_reduction | float | [0.0, 0.5] | Default 0.20. Safe max: 0.40 before logistics becomes trivial |
| Output | effective_supply_cost | float | ≥ 0 | Reduced supply cost |

**Provisional flag:** "2 settlement-hops" is an informal term until the Resource System GDD defines the settlement graph structure and graph distance calculation. This formula is a placeholder that requires the Resource System GDD to formalize the condition before it is implementable.

---

### F-7: Generic Passive Assignment Probability

```
generic_passive_assigned = (random_float() < generic_passive_chance)   [default: 0.20]

IF generic_passive_assigned:
    passive = random_choice(generic_passive_pool)   [uniform distribution, 1 passive max]
```

**Variables:**
| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| Passive chance | generic_passive_chance | float | [0.0, 1.0] | Default 0.20 (20%) |
| Passive pool | generic_passive_pool | list | 12 categories (MVP) | List of available generic passive categories |
| Output | passive or null | passive/null | — | One passive assigned, or null if check fails |

**Expected distribution:** At 20% with 25–30 generic officers, ~5–6 officers will carry a passive. This is intended to create occasional "interesting recruits" without making passives ubiquitous. No generic officer may carry more than 1 passive.

## Edge Cases

| # | Situation | Rule |
|---|-----------|------|
| E-01 | **Kaster is incapacitated mid-battle** | Read the Field passive deregisters immediately. Any already-revealed enemy officer stats remain visible for the rest of the battle (the information was gained — it does not expire). Inspect action is no longer available. |
| E-02 | **Read the Field: enemy squad has no officer** | Inspect action on an officer-less squad reveals morale and HP only (no officer stats). The action is still valid and expends the once-per-turn use. |
| E-03 | **Read the Field: Kaster inspects same squad twice** | Second Inspect is blocked — per Core Rules, each enemy squad may only be inspected once per battle. The action UI should grey out already-inspected squads. |
| E-04 | **Heirloom Blade procs on the killing blow** | Proc fires normally. The ceiling damage is applied; the kill resolves. No special interaction — the kill event proceeds with proc-level damage. |
| E-05 | **Heirloom Blade proc rate tuned to 0.0** | No procs ever fire. The passive is effectively disabled. This is a valid configuration for testing (allows isolation). |
| E-06 | **Shadow Work: Thane's squad moves out of forest before attacking** | Shadow Work requires Thane's squad to be in a Forest hex at the moment of attack initiation — not at the moment of movement. If Thane's squad moves from forest to open terrain in the same turn and then attacks, Shadow Work does NOT apply. Terrain is checked at attack resolution, not at movement start. |
| E-07 | **Shadow Work + real flanking simultaneously** | Both conditions are true. `max(flanking_mod, 1.3)` means flanking_mod = 1.3 either way — no double-stacking. The damage output is identical whether Shadow Work or real flanking produces the 1.3 value. |
| E-08 | **Vital Strike: Thane kills two squads in one turn** | Vital Strike fires separately for each kill. Adjacent morale damage from kill #1 is queued; adjacent morale damage from kill #2 is queued separately. Both are processed in the Morale Resolution Phase. If the blast radii overlap (both kills affect the same enemy squad), the squad receives Vital Strike damage twice (−10 × 2 = −20 total), but this is processed in the same cascade pass — not as two separate cascade waves. |
| E-09 | **Vital Strike kill puts target below 0 HP** | Kill event fires normally at 0 or below. The exact HP value does not affect Vital Strike behavior. |
| E-10 | **Vital Strike fires on a HP-zero squad that was already routing** | Vital Strike's condition is "kill event" (HP drops to ≤ 0). A squad already in BROKEN/routing state that takes a killing blow still triggers Vital Strike if Thane is the attacker. The already-routing squad's position is still valid for the 2-hex radius check. |
| E-11 | **Juggernaut: squad takes HP damage that would normally also trigger flanking morale damage** | HP damage applies normally (Juggernaut only blocks morale damage). The flanking morale trigger is skipped due to `morale_damage_immune`. The squad's morale never decreases. Its HP does. |
| E-12 | **Juggernaut + Old Guard overlap** | If Alexsen and Sander are adjacent, Old Guard's flank immunity applies to Alexsen's squad (it's within 1 hex). Since Alexsen is already fully morale-immune, Old Guard is redundant for his squad specifically. No conflict. |
| E-13 | **Old Guard: Sander is incapacitated** | Old Guard deregisters immediately. Adjacent squads lose the flank morale immunity. This change takes effect at the next Morale Resolution Phase — not retroactively for the current turn's damage that was already calculated. |
| E-14 | **Stratagem: Bon is BROKEN (routing)** | Bon's passive deregisters when he enters BROKEN state. Vision bonus is removed. Enemy squads become harder to see immediately. If Bon recovers (he cannot — BROKEN is terminal in-battle), the bonus would reactivate, but since BROKEN is terminal, this is moot. |
| E-15 | **Treatises: Zhuge Jian is present but not in the battle roster** | "Present" is defined as being in the force that enters the battle, even if not attached to a squad. If Zhuge Jian is in the army list but not a squad officer, Treatises still applies. The Preparation Phase System must determine "presence" by checking the army roster, not squad attachment. |
| E-16 | **Treatises: Zhuge Jian's INT drops below 90 via future system** | The threshold check (`int_stat >= 90`) must be re-evaluated at each Preparation Phase start. If growth or a future mechanic somehow drops INT below 90, the extra slot is removed. Under current stat rules (no debuffs; growth only increases stats), this cannot happen, but the guard must exist. |
| E-17 | **Quartermaster: Jin Tao's settlement is captured mid-campaign turn** | Quartermaster's supply reduction applies at campaign turn resolution, not real-time. If Jin Tao's settlement is captured before the turn resolves, the bonus does not apply for that turn. Transition timing owned by Campaign Map System. |
| E-18 | **Generic officer passive duplicates a named passive category** | Generic passives are defined as a separate pool with weaker values. The pool must not contain any passive that uses the same hook as a named passive (e.g., no generic `morale_damage_immune` — that is exclusively Juggernaut). If a generic passive and a named passive would both write to the same flag, the named passive takes priority and the generic passive is considered redundant (does not stack). This constraint is enforced by the generic pool design in M3. |
| E-19 | **Heirloom Blade: proc fires but the attack would have missed (future system)** | No miss mechanic is defined in the current system. If a future system adds miss probability, the proc check occurs after hit confirmation — a missed attack does not proc the Blade. Deferred until the miss mechanic exists. |

## Dependencies

### Upstream Dependencies (this system reads from)

| System | Data Consumed | Interface | Notes |
|--------|--------------|-----------|-------|
| **Officer Stats System** | `officer.war`, `officer.ldr`, `officer.int_stat`, `officer.chr` | Read via Officer resource at passive registration | Passive eligibility thresholds and aura radius depend on officer stats. Stats are immutable during a battle. |

### Downstream Systems (this system writes to)

| System | What changes | Interface | Notes |
|--------|-------------|-----------|-------|
| **Morale System** | `morale_damage_immune` flag (Juggernaut), `flank_morale_immune_aura` flag (Old Guard), Vital Strike morale damage queue | Flags registered at battle start; Vital Strike fires `on_kill()` callback | Morale System defines and checks these hooks (see Morale GDD §Immunity Hooks). This GDD defines the passives that set them. |
| **Combat Resolution** | `flanking_mod` override (Shadow Work), `damage_ceiling` proc (Heirloom Blade) | `passive_registry.get_flank_mod_override(attacker)`, `passive_registry.get_damage_ceiling(attacker)` | Combat Resolution calls into the registry at damage calculation time. Registry returns overrides only when conditions are met. |
| **Fog of War / Vision System** | `squad_vision_bonus` additive term (Stratagem) | `passive_registry.get_vision_bonus(squad)` → +1 when Bon active | Vision formula adds this term per squad. Registry returns 0 when Bon is inactive. |
| **Tactical Battle Controller** | Inspect action availability (Read the Field) | `battle_controller.register_special_action("inspect", kaster_squad, inspect_fn)` | The controller must expose a hook for passive-registered special actions. Inspect is player-initiated, once-per-turn. |
| **Preparation Phase System** | Extra action slot flag (The Treatises) | `passive_registry.has_flag("treatises_active")` → bool | Prep Phase reads this flag at phase start to determine available slot count. |
| **Campaign Map System** | Supply cost modifier (Quartermaster) | `passive_registry.get_supply_modifier(army, jin_tao_location)` → float | Campaign map queries the registry during supply resolution. Returns 0.80 when condition met, 1.0 otherwise. |

### Circular Dependency Note

The **Duel System** and this system have an interface overlap: Alexsen's Crushing Blow Signature Move is *executed* inside the Duel System but conceptually belongs to Alexsen's character design. Resolution: the Duel System owns the `SignatureMoveResolver` interface and the Crushing Blow execution. This GDD owns Juggernaut (tactical morale immunity) and acknowledges Crushing Blow exists without defining it — the Duel GDD is the authoritative source for Crushing Blow behavior.

## Tuning Knobs

All tuning knobs stored in `assets/data/passive_config.json` unless noted per-passive.

| Knob | Default | Safe Range | Effect |
|------|---------|-----------|--------|
| `blade_proc_rate` | 0.05 | [0.02, 0.08] | Heirloom Blade proc probability per attack. Below 0.02: nearly invisible over a full run. Above 0.08: procs become frequent enough to feel deliberate and break ambiguity. |
| `inspect_uses_per_turn` | 1 | [1, 2] | How many times Kaster can use Read the Field per turn. Raising to 2 gives much more intel per battle; lower is more strategic. Not recommended above 2. |
| `shadow_work_flank_mod` | 1.3 | [1.2, 1.4] | The flanking_mod value Shadow Work guarantees. Must not exceed 1.3 (the standard flanking cap) without also updating the `flank_bonus` constant in the registry. Currently pegged to the same value. |
| `vital_strike_morale_damage` | −10 | [−5, −15] | Morale damage applied to each enemy squad within 2 hexes on Vital Strike kill. At −5 it barely matters; at −15 it risks cascade-routing a full SHAKEN line (original concern from systems-designer). |
| `vital_strike_radius` | 2 | [1, 3] | Hex radius from killed squad for Vital Strike morale blast. Matches witnessing-rout radius (2) by default for consistency. |
| `quartermaster_supply_reduction` | 0.20 | [0.10, 0.40] | Fraction of supply costs saved by Jin Tao's Quartermaster. Below 0.10 is imperceptible; above 0.40 trivializes campaign-layer supply management. |
| `quartermaster_radius_hops` | 2 | [1, 3] | Settlement-graph distance within which Quartermaster applies. Requires Resource GDD to formalize. |
| `generic_passive_chance` | 0.20 | [0.10, 0.35] | Probability a generic officer receives a passive at recruitment. Below 0.10: passives are rare treats. Above 0.35: most generics have passives, diluting named officer uniqueness. |

**Per-passive per-named-officer knobs** (in `assets/data/officer_passives.json`):
- `treatises_int_threshold`: default 90. The INT value at which Zhuge Jian's extra Prep Phase slot activates. Not recommended to change without reviewing the Preparation Phase GDD slot count design.
- `read_field_cooldown_per_squad`: default "once per battle per squad" (boolean). Not a numeric knob — changing would require design review.

## Visual/Audio Requirements

*Lean mode: `art-director` not consulted — review visual treatment against art bible before production.*

### Per-Passive Visual/Audio Notes

| Passive | Visual | Audio |
|---------|--------|-------|
| **Read the Field** | "Inspect" cursor highlight on targeted squad. Revealed stats appear in an officer profile panel (same design as normal inspection UI). Inspected squads get a small "seen" icon persistent on the tactical map. | Subtle "reading" sound — paper or quill scratch. Quiet, intellectual, not triumphant. |
| **Heirloom Blade** | **No unique visual.** The proc produces no glow, no particle effect, no icon. The only signal is the larger damage number in the standard combat log. If a damage number color system exists, the blade proc must use the same color as a normal hit. | **No unique audio.** Standard melee hit sound, same as any other attack. |
| **Juggernaut** | No per-turn visual. Optional: a subtle passive icon on Alexsen's squad portrait indicating morale immunity. Should be understated — not a glowing shield. In the morale bar UI, Alexsen's bar simply never moves. | No morale break sound ever plays for Alexsen's squad (this is incidentally the audio signal — the silence where other squads would have wavering voice lines). |
| **Shadow Work** | When Shadow Work triggers (forest melee attack), the combat resolution animation shows the standard flanking hit effect — NOT a special ambush effect. The passive does not get its own announcement. Players infer the passive from noticing Thane always gets flanking numbers from forest. | Standard flanking hit audio — no special SFX for Shadow Work proc. |
| **Vital Strike** | When Vital Strike fires, affected enemy squads display a brief morale hit indicator (same as witnessing-rout indicator). No unique Vital Strike visual — consistent with the game's pattern of not announcing passives. | A brief "shockwave of fear" audio beat — the same sound used for witnessing-rout morale damage, applied to each affected squad. Subtle, not an announcement. |
| **The Treatises** | In the Preparation Phase UI, the extra action slot has a small scroll icon or visual tag indicating Zhuge Jian's contribution. This is the ONE case where a passive is somewhat visible — because the player needs to understand why they have an extra slot. | Campaign UI notification chime when the Prep Phase UI opens with the extra slot. |
| **Quartermaster** | In the campaign supply summary panel, affected armies display a "Jin Tao (−20%)" note next to their supply cost. This is deliberate — campaign passives are disclosed because the player needs to make governor assignment decisions. | No audio; campaign layer UI. |
| **Stratagem** | Vision-range change is visible through the fog of war update (more hexes revealed). No icon or announcement. A subtle visual expansion of each squad's visible area is the only signal. | No SFX. |
| **Old Guard** | Adjacent squad morale bars do not react to flank morale events (the bar simply doesn't drop on flanking hits). This is a perceptible absence, not an announcement. Optional: a small "shield" icon on adjacent squad portraits when within Old Guard's 1-hex radius. | No special audio for passive; the absence of the "morale hit" sound when flanked near Sander is the implicit signal. |

## UI Requirements

### Passive Disclosure Philosophy

Named officer passives are **partially disclosed** — the player can see that an officer HAS a passive (the passive name appears in the officer detail panel), but the mechanical specifics are not front-loaded. Players learn what passives do by observing effects. Exception: campaign passives (Quartermaster, The Treatises) are disclosed numerically in the relevant UI because they require the player to make active resource/slot decisions based on them.

Heirloom Blade is **never disclosed** — it does not appear in Kaster's officer detail panel, officer tooltip, or any game UI.

| UI Element | What is shown | Notes |
|-----------|---------------|-------|
| **Officer Detail Panel (tactical)** | Passive name only (e.g., "Juggernaut", "Shadow Work + Vital Strike") | No mechanical description on first encounter. Glossary unlocked after first observation. |
| **Officer Tooltip (hover)** | Passive name only | Same policy as detail panel. |
| **Passive Glossary** | Full mechanical description, unlocked after first observation | Once the player has seen Juggernaut in action, the glossary entry unlocks explaining "immune to morale damage." |
| **Tactical map squad portrait** | Optional passive icon (category-level: shield for defensive, sword for offensive, eye for intel). No text. | Icons available but art direction may choose to omit for visual cleanliness. |
| **Preparation Phase UI** | "Zhuge Jian — The Treatises: +1 action slot" label on the extra slot | Campaign passives must be disclosed because they require player decision-making. |
| **Campaign supply summary** | "Jin Tao's Quartermaster: −20% supply" note next to affected army costs | Same reason as above. |
| **Heirloom Blade** | Not shown anywhere | Not in officer detail, not in glossary, not as an icon. If a player discovers it, it's through pattern recognition. |

### Keyboard/Gamepad Access
- Read the Field Inspect action: mapped to the same key/button as other special squad actions in the movement phase. Navigation hint appears in the squad action bar when Kaster's squad is selected and a valid target is in range.
- Passive glossary: accessible from the officer detail panel via [G] or equivalent menu navigation. Available during battle pause.

## Acceptance Criteria

*QA Lead reviewed. 44 criteria.*

### PassiveRegistry — Registration and Deregistration

1. GIVEN a tactical battle starts with Kaster present in the battle roster, WHEN the PassiveRegistry initializes, THEN both the `read_field` and `heirloom_blade_active` flags are registered as active for Kaster's officer ID.

2. GIVEN Kaster's squad is incapacitated mid-battle, WHEN the PassiveRegistry processes the incapacitation event, THEN both `read_field` and `heirloom_blade_active` are deregistered immediately and the Inspect action is no longer available for the remainder of the battle.

3. GIVEN a battle ends, WHEN the PassiveRegistry clears, THEN all registered passive flags are deregistered and the registry is empty.

4. GIVEN a generic officer with no passive assigned is in the battle, WHEN the PassiveRegistry initializes, THEN no passive flag is registered for that officer ID.

### Read the Field (Kaster)

5. GIVEN Kaster's squad is active (not BROKEN, not incapacitated) and an enemy squad is exactly 4 hexes away, WHEN the Inspect action is triggered, THEN the Inspect succeeds and reveals the enemy officer's name, WAR, LDR, INT, CHR, current morale value, and current HP% — Kaster's LDR 96 gives a 4-hex inspect range via the bracket table.

6. GIVEN Kaster's squad is active and an enemy squad is exactly 5 hexes away, WHEN the player attempts to Inspect that squad, THEN the Inspect action is unavailable and no stats are revealed.

7. GIVEN Kaster successfully inspects Enemy Squad A on turn 2, WHEN Kaster's squad moves 6 hexes away from Enemy Squad A on turn 3, THEN Enemy Squad A's previously revealed stats remain visible for the rest of the battle — revealed information does not expire.

8. GIVEN Kaster successfully inspects Enemy Squad A on turn 2, WHEN the player attempts to inspect Enemy Squad A again on turn 3, THEN the Inspect action is blocked for that squad — each enemy squad may be inspected at most once per battle.

9. GIVEN Kaster's squad is BROKEN (routing), WHEN the next Movement Phase begins, THEN the Inspect action is not available — the action requires Kaster's squad to be active and non-BROKEN.

10. GIVEN the player uses Inspect once on turn 1, WHEN turn 2 begins, THEN the Inspect action is available again — the once-per-turn use resets each turn.

11. GIVEN the player Inspects an officer-less enemy squad, WHEN the reveal result is displayed, THEN only morale value and HP% are shown (no officer stats), and the once-per-turn use is still expended.

### Heirloom Blade (Kaster — Hidden)

12. GIVEN Kaster's squad performs a melee swordsman attack and the proc check fires (`random_float() < 0.05`), WHEN the damage is resolved, THEN the damage equals `floor(40 × (1 + 82/200) × 1.25 × 1.3) = 91`.

13. GIVEN Kaster's squad performs a ranged musketeer attack and the proc check fires, WHEN the damage is resolved, THEN the damage equals `floor(35 × (1 + 82/100) × 1.25 × 1.3) = 103`.

14. GIVEN a Heirloom Blade proc fires, WHEN the combat result is displayed to the player, THEN no unique animation, no unique audio, no icon, and no distinctive combat log entry appears — the output is visually and aurally identical to a normal attack.

15. GIVEN the officer detail panel is opened for Kaster, WHEN the player inspects the passive list, THEN no entry named "Heirloom Blade" or any equivalent label appears anywhere in the panel, tooltip, or glossary.

16. GIVEN `blade_proc_rate` is set to 0.0, WHEN Kaster's squad attacks 100 times, THEN zero procs fire — the 0.0 rate fully disables the passive.

### Juggernaut (Alexsen)

17. GIVEN Alexsen's squad is active with `morale_damage_immune = true`, WHEN the Morale Resolution Phase processes casualties morale damage against Alexsen's squad, THEN Alexsen's squad's morale value is unchanged.

18. GIVEN Alexsen's squad is active with `morale_damage_immune = true`, WHEN Alexsen's squad is flanked and the flank morale trigger would fire, THEN Alexsen's squad's morale value is unchanged.

19. GIVEN Alexsen's squad is active with `morale_damage_immune = true`, WHEN a friendly squad within 2 hexes enters BROKEN (witnessing trigger), THEN Alexsen's squad's morale value is unchanged.

20. GIVEN Alexsen's squad is active with `morale_damage_immune = true`, WHEN Alexsen's own squad officer is killed (officer loss trigger), THEN Alexsen's squad's morale value is unchanged.

21. GIVEN Alexsen's squad is active with `morale_damage_immune = true`, WHEN Alexsen's squad takes 25 HP damage from a melee attack, THEN HP decreases by 25 and morale remains at 100 — HP damage is unaffected by Juggernaut.

22. GIVEN Alexsen's squad starts at morale 100 and battles for 20 turns with Juggernaut active, WHEN the battle ends, THEN Alexsen's squad's morale is still 100.

### Shadow Work (Thane)

23. GIVEN Thane's squad is in a Forest hex and initiates a melee attack, and `is_flanking()` returns false, WHEN Combat Resolution calculates `flanking_mod`, THEN `flanking_mod = max(1.0, 1.3) = 1.3` — Shadow Work guarantees the flanking bonus regardless of geometry.

24. GIVEN Thane's squad is in a Forest hex, initiates a melee attack, and `is_flanking()` also returns true (1.3), WHEN `flanking_mod` is resolved, THEN `flanking_mod = max(1.3, 1.3) = 1.3` — no double-stacking.

25. GIVEN Thane's squad moves from a Forest hex to an open-terrain hex during the Movement Phase and then attacks from the open hex, WHEN Combat Resolution resolves the attack, THEN Shadow Work does NOT apply — terrain is checked at attack initiation, not movement start.

26. GIVEN Thane's squad is in a Forest hex and initiates a ranged attack, WHEN Combat Resolution resolves the attack, THEN Shadow Work does NOT apply — `flanking_mod` is not forced to 1.3 for ranged attacks.

### Vital Strike (Thane)

27. GIVEN Thane's squad kills Enemy Squad X (reduces HP to 0), and Enemy Squad Y and Enemy Squad Z are each within 2 hexes of Enemy Squad X, WHEN the Morale Resolution Phase resolves this turn, THEN Enemy Squad Y and Enemy Squad Z each receive −10 morale damage from the Vital Strike queue.

28. GIVEN Thane kills two separate enemy squads in one turn with overlapping 2-hex blast radii on Enemy Squad Z, WHEN Vital Strike processes in the Morale Resolution Phase, THEN Enemy Squad Z receives −20 total morale damage (−10 × 2), processed as two events within the same cascade pass.

29. GIVEN a morale route occurs (enemy squad reaches 0 morale without Thane's squad delivering an HP kill), WHEN Vital Strike's kill condition is evaluated, THEN Vital Strike does NOT fire — HP kills only.

30. GIVEN Vital Strike's −10 damage would push Enemy Squad Y from morale 15 to morale 5 (BROKEN) during Pass 1 of the Morale Resolution Phase, WHEN the Morale Resolution Phase completes, THEN Enemy Squad Y enters BROKEN state but does NOT generate a Pass 3 — the 2-pass cascade cap applies to Vital Strike events.

### The Treatises (Zhuge Jian)

31. GIVEN Zhuge Jian is in the battle force roster (not necessarily squad-attached) with INT 99 (≥ 90), WHEN the Preparation Phase initializes, THEN `passive_registry.has_flag("treatises_active")` returns true and one additional action slot is available.

32. GIVEN Zhuge Jian is in the army roster but NOT attached to any squad as a squad officer, WHEN `passive_registry.has_flag("treatises_active")` is evaluated, THEN the flag returns true — army roster presence is the qualifying condition, not squad attachment.

33. GIVEN Zhuge Jian's INT stat is 89 (below threshold), WHEN the Preparation Phase initializes, THEN `passive_registry.has_flag("treatises_active")` returns false and no extra slot is provided.

### Quartermaster (Jin Tao)

34. GIVEN Jin Tao is assigned as governor of Settlement A, and a friendly army is exactly 2 settlement-hops from Settlement A, WHEN campaign supply costs are resolved, THEN `effective_supply_cost = base_supply_cost × 0.80` (20% reduction).

35. GIVEN Jin Tao is assigned as governor of Settlement A, and a friendly army is exactly 3 settlement-hops away, WHEN campaign supply costs are resolved, THEN no Quartermaster reduction applies — full `base_supply_cost` is charged.

36. GIVEN Jin Tao's Quartermaster (−20%) and a generic Forager passive (−10%) both apply to the same army, WHEN supply costs are resolved, THEN the effective reduction is 20% (Quartermaster only) — no additive stacking; largest single reduction wins.

### Stratagem (Bon shi hai)

37. GIVEN Bon's squad is present and NOT BROKEN, WHEN the vision formula is evaluated for any friendly squad, THEN each friendly squad's `vision_range` includes +1 from Stratagem — a squad on a hill hex (terrain +1) with base_vision 3 reaches vision 5; a squad with base_vision 5 and terrain +1 reaches vision 7, exceeding the documented [2,5] soft maximum.

38. GIVEN Bon's squad enters BROKEN state, WHEN the PassiveRegistry deregisters Bon's passives, THEN all friendly squads immediately lose the +1 Stratagem vision bonus at the next vision evaluation.

### Old Guard (Sander)

39. GIVEN Sander's squad is active, and Friendly Squad F is at distance 1 (adjacent), and Friendly Squad F is flanked this turn, WHEN the Morale Resolution Phase evaluates the flank morale trigger for Friendly Squad F, THEN Friendly Squad F takes 0 morale damage from the flank trigger.

40. GIVEN Sander's squad is active, and Friendly Squad F is adjacent and is flanked, WHEN Combat Resolution resolves the flanking attack against Friendly Squad F, THEN Friendly Squad F takes full flanking HP damage (flanking_mod = 1.3 applied) — Old Guard does not reduce HP damage.

41. GIVEN Sander's squad is active and Friendly Squad G is at distance 2 from Sander (not adjacent), WHEN Friendly Squad G is flanked, THEN Friendly Squad G takes the full flank morale damage (10 by default) — Old Guard radius is fixed at 1 hex.

42. GIVEN Sander's own squad is flanked this turn, WHEN the Morale Resolution Phase fires, THEN Sander's own squad takes the normal flank morale damage (10) — Old Guard applies to adjacent squads only, not to Sander himself.

### Generic Passive Pool

43. GIVEN 1,000 generic officers are recruited in a deterministic test (fixed random seed) with `generic_passive_chance = 0.20`, WHEN recruitment completes, THEN approximately 200 officers carry a passive (within statistically expected variance) and no recruited officer carries more than 1 passive.

44. GIVEN the generic passive pool is evaluated for assignment at recruitment, WHEN a passive category is selected, THEN the assigned category is not `morale_damage_immune` or any other category that uses the same hook registration as a named officer passive — generic passives must not replicate named passive hooks.

## Open Questions

1. **Quartermaster "settlement-hops" definition**: The term "2 settlement-hops" is informal until the Resource System GDD defines the campaign settlement graph structure and graph distance calculation. This formula is a placeholder — the Quartermaster mechanic cannot be fully implemented until that GDD is authored.

2. **Stratagem vision floor**: The `vision_range` formula's documented output range is [2, 5]. Stratagem pushes this to 6 on hill hexes. Should the vision system hard-clamp at 5 regardless of bonuses, or is 6+ intentionally allowed? The systems-designer flagged this ambiguity. Decision required before Fog of War system implementation.

3. **Generic passive balance pass**: The 12 generic passive categories are defined as a category list for MVP; specific values (e.g., how much "Forager" reduces supply) are deferred to M3. This is an intentional scope boundary — confirm with the producer that the M3 content pass will cover generic passive stat values before M3 begins.

4. **Read the Field and Diplomacy**: When Kaster uses Read the Field during a battle against a faction, should the revealed officer stats affect diplomatic options in the campaign layer after the battle? This could be a Diplomacy GDD mechanic ("you know his INT, so you can target his weakness in negotiation"). Deferred to Diplomacy System GDD.

5. **Heirloom Blade Part 3**: The blade's narrative role is ambiguous by design, but does it have a mechanical revelation in Part 3? If Part 3 includes a story beat where the blade's power is acknowledged narratively (even vaguely), the system must be able to trigger or mark an event flag. The current implementation has no such hook. Confirm with narrative director whether a "blade event" flag should be added before the Officer Passive System is finalized.
