# Systems Index: Kaster's War — The Unification War

> **Status**: Draft
> **Created**: 2026-06-11
> **Last Updated**: 2026-06-11
> **Source Concept**: `design/gdd/kasters-war-gdd.md`
> **Review mode**: Lean — TD-SYSTEM-BOUNDARY, PR-SCOPE, CD-SYSTEMS gates skipped

---

## Overview

Kaster's War is a three-layer strategy game (Campaign → Preparation Phase → Tactical) with a Duel system as a fourth context. The mechanical scope is large for an indie team: 35 systems spanning resource economics, intel-driven fog of war, hex tactical combat with realistic morale, per-officer signature passives, and an authored narrative that runs across all layers. The design order below is construction-ordered — Foundation first, then Core, then Feature — with MVP-tier systems prioritized within each layer so the Vertical Slice (Open Field battle + Duel) can be playable before the full campaign loop is designed. The game's signature mechanic — the Intel System — sits at the boundary of the Campaign and Preparation Phase layers and must be designed with both contexts in mind.

---

## Systems Enumeration

| # | System Name | Category | Priority | Status | Design Doc | Depends On |
|---|---|---|---|---|---|---|
| 1 | Officer Stats System | Foundation | MVP | Approved | design/gdd/officer-stats.md | — |
| 2 | Terrain System | Foundation | MVP | Approved | design/gdd/terrain-system.md | — |
| 3 | Resource System | Foundation | Campaign | Not Started | — | — |
| 4 | Settlement Data System | Foundation | Campaign | Not Started | — | — |
| 5 | Hex Movement System | Tactical | MVP | Not Started | — | Terrain |
| 6 | Combat Resolution System | Tactical | MVP | Not Started | — | Officer Stats, Terrain |
| 7 | Facing & Flank System | Tactical | MVP | Not Started | — | Terrain, Hex Movement |
| 8 | Morale System | Tactical | MVP | Not Started | — | Officer Stats, Combat Resolution |
| 9 | Fog of War / Vision System | Tactical | MVP | Not Started | — | Terrain, Hex Movement |
| 10 | Victory/Defeat Conditions System | Tactical | MVP | Not Started | — | Morale, Combat Resolution |
| 11 | Ranged & Artillery System | Tactical | Alpha | Not Started | — | Hex Movement, Combat Resolution, Fog of War |
| 12 | Fire System | Tactical | Alpha | Not Started | — | Terrain, Hex Movement, Campaign Map |
| 13 | Duel System | Character | MVP | Not Started | — | Officer Stats |
| 14 | Officer Passive Ability System | Character | MVP | Not Started | — | Officer Stats, Combat Resolution, Duel |
| 15 | Campaign Map System | Campaign | Campaign | Not Started | — | Resource, Settlement Data, Terrain |
| 16 | Intel System *(signature pillar)* | Campaign | Campaign | Not Started | — | Resource, Settlement Data |
| 17 | Army Composition System | Campaign | Campaign | Not Started | — | Campaign Map, Resource, Officer Stats |
| 18 | Settlement Management System | Campaign | Campaign | Not Started | — | Campaign Map, Officer Stats |
| 19 | Preparation Phase System | Campaign | Campaign | Not Started | — | Intel, Army Composition, Covert Ops, Story Events |
| 20 | Covert Operations System | Campaign | Campaign | Not Started | — | Intel, Officer Passive, Campaign Map |
| 21 | Diplomacy System | Campaign | Campaign | Not Started | — | Officer Stats, Duel, Campaign Map, Settlement Data |
| 22 | Story Event System | Campaign | Full Vision | Not Started | — | Settlement Data, Resource |
| 23 | Tactical AI System | AI | Alpha | Not Started | — | Hex Movement, Combat Resolution, Morale, Facing & Flank |
| 24 | Campaign AI System | AI | Campaign | Not Started | — | Campaign Map, Intel, Army Composition |
| 25 | French Drill / Upgrade System *(inferred)* | Progression | Full Vision | Not Started | — | Army Composition, Story Events |
| 26 | Tactical HUD | UI | MVP | Not Started | — | Combat Resolution, Morale, Officer Passive, Hex Movement |
| 27 | Duel UI | UI | MVP | Not Started | — | Duel |
| 28 | Portrait & Character Display System | UI | MVP | Not Started | — | Officer Stats |
| 29 | Campaign Map UI | UI | Campaign | Not Started | — | Campaign Map, Resource, Settlement Management, Intel |
| 30 | Preparation Phase UI | UI | Campaign | Not Started | — | Preparation Phase |
| 31 | Save/Load System *(inferred)* | Meta | MVP | Not Started | — | All gameplay systems |
| 32 | Difficulty Settings System *(inferred)* | Meta | Full Vision | Not Started | — | Intel, Campaign AI, Tactical AI |
| 33 | Audio System *(inferred)* | Meta | Full Vision | Not Started | — | All gameplay systems |
| 34 | Localization System *(inferred)* | Meta | Full Vision | Not Started | — | All UI systems |
| 35 | Tutorial / Mission Briefing System *(inferred)* | Meta | Full Vision | Not Started | — | Story Events |

*(inferred) = system not explicitly named in GDD but required for the explicit systems to function*

---

## Categories

| Category | Description |
|---|---|
| **Foundation** | No dependencies. Everything else builds on these. |
| **Tactical** | Hex-grid combat layer — movement, combat math, terrain interaction, morale. |
| **Character** | Officer-specific behaviors — passives and the duel mechanic. |
| **Campaign** | The strategic layer — map, economy, intel, preparation, covert ops, diplomacy. |
| **AI** | Enemy decision-making for both tactical and campaign layers. |
| **UI** | Player-facing display layers. Designed and built after their gameplay system counterpart. |
| **Meta** | Save/load, difficulty, audio, localization — wraps the complete game. |

---

## Priority Tiers

| Tier | GDD Milestone | Definition |
|---|---|---|
| **MVP (Vertical Slice)** | M0 | Open Field battle + Duel + 4 officer passives. Proves combat is fun before building the campaign layer. |
| **Alpha** | M1 Tactical Complete | All unit types, morale, terrain, fire, AI in tactical combat. Full tactical sandbox. |
| **Campaign** | M2 Campaign Loop | Map, economy, intel, preparation phase, campaign AI. Full game loop end-to-end. |
| **Full Vision** | M3–M4 | Story missions, events, upgrades, balance, localization, polish. Content-complete. |

---

## Dependency Map

### Foundation Layer (no dependencies)

1. **Officer Stats System** — 5-stat character sheets are the input for every combat modifier, passive ability, duel calculation, and economy decision. Nothing else can be designed without knowing what values exist.
2. **Terrain System** — tile types, movement costs, combat bonuses, visual categories. All spatial systems reference terrain.
3. **Resource System** — Gold, Supplies, Manpower, Intel are the currency of all campaign decisions. Design before any system that spends or earns them.
4. **Settlement Data System** — city properties (population, wealth, special resources, loyalty, owner faction). Required by campaign map, intel, and diplomacy systems.

### Core Tactical Layer (depends on Foundation)

5. **Hex Movement System** — depends on: Terrain
6. **Combat Resolution System** — depends on: Officer Stats, Terrain
7. **Facing & Flank System** — depends on: Terrain, Hex Movement
8. **Morale System** — depends on: Officer Stats, Combat Resolution
9. **Fog of War / Vision System** — depends on: Terrain, Hex Movement
10. **Victory/Defeat Conditions System** — depends on: Morale, Combat Resolution

*Note: Combat Resolution and Morale have a turn-ordered circular reference (combat happens → morale updates → affects next turn's combat). Resolution: both are designed together in the same session; no live dependency.*

### Core Character Layer (depends on Foundation)

11. **Duel System** — depends on: Officer Stats
12. **Officer Passive Ability System** — depends on: Officer Stats, Combat Resolution, Duel

*Note: Duel System and Officer Passive Ability System have an overlap (Alexsen's Crushing Blow functions inside a duel). Resolution: Duel System owns the mechanic; Officer Passive hooks into it via a defined interface. Design both together.*

### Expanded Tactical Layer (depends on Core)

13. **Ranged & Artillery System** — depends on: Hex Movement, Combat Resolution, Fog of War
14. **Fire System** — depends on: Terrain, Hex Movement, and Campaign Map (for season state)
15. **Tactical AI System** — depends on: Hex Movement, Combat Resolution, Morale, Facing & Flank

### Core Campaign Layer (depends on Foundation)

16. **Campaign Map System** — depends on: Resource, Settlement Data, Terrain
17. **Intel System** — depends on: Resource, Settlement Data
18. **Army Composition System** — depends on: Campaign Map, Resource, Officer Stats
19. **Settlement Management System** — depends on: Campaign Map, Officer Stats (POL stat)

### Feature Campaign Layer (depends on Core Campaign)

20. **Preparation Phase System** — depends on: Intel, Army Composition, Covert Ops, Story Events
21. **Covert Operations System** — depends on: Intel, Officer Passive (Thane), Campaign Map
22. **Diplomacy System** — depends on: Officer Stats, Duel, Campaign Map, Settlement Data
23. **Campaign AI System** — depends on: Campaign Map, Intel, Army Composition

### Narrative Layer

24. **Story Event System** — depends on: Settlement Data, Resource (for trigger conditions)
25. **French Drill / Upgrade System** — depends on: Army Composition, Story Events

### Presentation Layer (depends on gameplay systems)

26. **Tactical HUD** — depends on: Combat Resolution, Morale, Officer Passive, Hex Movement
27. **Duel UI** — depends on: Duel System
28. **Portrait & Character Display System** — depends on: Officer Stats
29. **Campaign Map UI** — depends on: Campaign Map, Resource, Settlement Management, Intel
30. **Preparation Phase UI** — depends on: Preparation Phase System

### Polish / Meta Layer (depends on most systems)

31. **Save/Load System** — depends on: all gameplay systems (game state snapshot)
32. **Difficulty Settings System** — depends on: Intel, Campaign AI, Tactical AI
33. **Audio System** — depends on: all systems (audio events trigger from gameplay)
34. **Localization System** — depends on: all UI systems
35. **Tutorial / Mission Briefing System** — depends on: Story Events

---

## Recommended Design Order

*Dependency sort × priority tier. Independent systems at the same layer can be designed in parallel.*

| # | System | Priority | Layer | Suggested Agent(s) | Est. Effort |
|---|---|---|---|---|---|
| 1 | Officer Stats System | MVP | Foundation | game-designer | S | ✅ DESIGNED |
| 2 | Terrain System | MVP | Foundation | game-designer | S | ✅ DESIGNED |
| 3 | Combat Resolution System | MVP | Tactical Core | game-designer, systems-designer | M | ✅ DESIGNED |
| 4 | Morale System | MVP | Tactical Core | game-designer, systems-designer | M |
| 5 | Facing & Flank System | MVP | Tactical Core | game-designer | S |
| 6 | Hex Movement System | MVP | Tactical Core | game-designer | S |
| 7 | Fog of War / Vision System | MVP | Tactical Core | game-designer | S |
| 8 | Victory/Defeat Conditions System | MVP | Tactical Core | game-designer | S |
| 9 | Duel System ⚠️ | MVP | Character Core | game-designer, systems-designer | L |
| 10 | Officer Passive Ability System ⚠️ | MVP | Character Core | game-designer | M |
| 11 | Tactical HUD | MVP | UI | ux-designer | M |
| 12 | Duel UI | MVP | UI | ux-designer, art-director | S |
| 13 | Portrait & Character Display System | MVP | UI | art-director | S |
| 14 | Save/Load System | MVP | Meta | lead-programmer | M |
| 15 | Ranged & Artillery System | Alpha | Tactical Expanded | game-designer | M |
| 16 | Fire System | Alpha | Tactical Expanded | game-designer, systems-designer | M |
| 17 | Tactical AI System ⚠️ | Alpha | AI | ai-programmer, game-designer | L |
| 18 | Resource System | Campaign | Foundation | game-designer, economy-designer | M |
| 19 | Settlement Data System | Campaign | Foundation | game-designer | S |
| 20 | Campaign Map System | Campaign | Campaign Core | game-designer | L |
| 21 | Intel System ⚠️ | Campaign | Campaign Core | game-designer, systems-designer | L |
| 22 | Army Composition System | Campaign | Campaign Core | game-designer | M |
| 23 | Settlement Management System | Campaign | Campaign Core | game-designer | M |
| 24 | Preparation Phase System | Campaign | Campaign Feature | game-designer | M |
| 25 | Covert Operations System | Campaign | Campaign Feature | game-designer | M |
| 26 | Diplomacy System | Campaign | Campaign Feature | game-designer | S |
| 27 | Campaign AI System ⚠️ | Campaign | AI | ai-programmer, game-designer | L |
| 28 | Campaign Map UI | Campaign | UI | ux-designer | M |
| 29 | Preparation Phase UI | Campaign | UI | ux-designer | M |
| 30 | Story Event System | Full Vision | Narrative | game-designer, narrative-director | M |
| 31 | French Drill / Upgrade System | Full Vision | Progression | game-designer | S |
| 32 | Difficulty Settings System | Full Vision | Meta | game-designer | S |
| 33 | Audio System | Full Vision | Meta | audio-director | M |
| 34 | Localization System | Full Vision | Meta | localization-lead | M |
| 35 | Tutorial / Mission Briefing System | Full Vision | Meta | ux-designer | S |

*Effort: S = 1 session, M = 2–3 sessions, L = 4+ sessions. ⚠️ = high-risk system.*

---

## Circular Dependencies

| Systems | Relationship | Resolution |
|---|---|---|
| Combat Resolution ↔ Morale | Casualties reduce morale; morale state affects combat effectiveness | Turn-ordered: Combat calculates casualties first, Morale updates after. No live cycle. Design together. |
| Duel System ↔ Officer Passive Ability | Alexsen's Crushing Blow and other officer specials execute inside a Duel | Duel System owns the mechanic; Officer Passive defines a hook interface. Duel calls the hook, passive provides the behavior. Design both in the same session. |

---

## High-Risk Systems

| System | Risk Type | Risk Description | Mitigation |
|---|---|---|---|
| Duel System ⚠️ | Design + Scope | Must work in 3 contexts (field challenge, scripted battle, diplomatic), must be extensible for 2 planned sequels, and must make Mission 6's "intentional miss" feel earned rather than broken | Prototype before full GDD. Define the hook interface for future characters before locking the turn structure. |
| Intel System ⚠️ | Design | Intel decay, 4 levels, misinformation (Act IV), difficulty scaling via intel params, and Preparation Phase integration are all bound together — under-specifying any one creates gaps elsewhere | Design as a unified document covering campaign intel, fog state, and Prep Phase action availability together. |
| Officer Passive Ability System ⚠️ | Scope | 7 unique named passives, Heirloom Blade edge case (silent trigger, narrative ambiguity), 12+ generic passive pool — large surface area that touches every other tactical system | Design named passives first (7 is manageable); define the generic pool as categories, not individual abilities, until M3. |
| Tactical AI System ⚠️ | Technical | Must challenge the player credibly across 5 unit types, morale management, flanking opportunities, and artillery without feeling like it cheats — all within 16 squads per side | Constrain AI to rule-based behavior trees in MVP; defer learning or adaptive behavior to post-launch. |
| Campaign AI System ⚠️ | Design + Technical | Lycurse's 2-phase behavior (cautious → aggressive at Act IV) must feel like in-fiction underestimation, not game-difficulty rails. Misinformation layer adds state complexity | Design the fiction trigger (what in-world event unlocks phase 2) before implementing the behavior change. The AI reads better when the story reason is written first. |
| Preparation Phase System | Design | Acts as the bridge between campaign and tactical — the quality of player choices here depends on campaign play quality. Under-specifying action generation creates a flat experience | Design after Intel and Army Composition. Explicitly specify how each action card is generated (what campaign state condition enables it). |

---

## Progress Tracker

| Metric | Count |
|---|---|
| Total systems identified | 35 |
| Design docs started | 3 |
| Design docs reviewed | 0 |
| Design docs approved | 3 |
| MVP systems designed | 3 / 14 |
| Alpha systems designed | 0 / 3 |
| Campaign systems designed | 0 / 12 |
| Full Vision systems designed | 0 / 6 |

---

## Next Steps

- [ ] Run `/design-system officer-stats` — first in design order (foundation for all combat, character, and economy systems)
- [ ] Run `/design-system terrain` — can be done in parallel with officer stats
- [ ] Run `/map-systems next` to always pick the next undesigned system automatically
- [ ] Run `/design-review design/gdd/[system].md` after each GDD is authored
- [ ] Run `/gate-check pre-production` when all MVP-tier GDDs are complete
