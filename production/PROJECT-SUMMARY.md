# Kaster's War — Project Summary

**Date**: 2026-06-12  
**Stage**: Systems Design (3/35 systems designed)  
**Status**: Ready for next design phase

---

## 🎯 What's Done

### Design Documents
| Document | Status | Location | Purpose |
|----------|--------|----------|---------|
| Game Concept (Main GDD) | ✅ Complete | `design/gdd/kasters-war-gdd.md` | Full game vision + character profiles |
| Art Bible | ✅ Complete (9/9 sections) | `design/art/art-bible.md` | Visual direction + asset standards |
| Systems Index | ✅ Complete | `design/gdd/systems-index.md` | All 35 systems mapped + design order |
| **Officer Stats** | ✅ Complete (8/8) | `design/gdd/officer-stats.md` | 5-stat framework + 7 named officers |
| **Terrain System** | ✅ Complete (8/8) | `design/gdd/terrain-system.md` | Hex tiles + seasonal modifiers |
| **Combat Resolution** | ✅ Complete (8/8) | `design/gdd/combat-resolution.md` | Damage formulas + deterministic outcomes |

### Configuration
| Document | Status | Location | Purpose |
|----------|--------|----------|---------|
| Technical Preferences | ✅ Complete | `.claude/docs/technical-preferences.md` | Engine specs + naming conventions |
| CLAUDE.md | ✅ Complete | `CLAUDE.md` | Project master config |
| Entity Registry | ✅ Complete | `design/registry/entities.yaml` | Named officers + constants |

### Session State
| Document | Status | Location | Purpose |
|----------|--------|----------|---------|
| Active Session State | ✅ Updated | `production/session-state/active.md` | Current progress checkpoint |

---

## 📊 Key Numbers

**System Design Progress:**
- Total systems: 35
- MVP tier systems: 14 (Open Field battle + Duel)
  - Designed: 3/14 (Officer Stats, Terrain, Combat Resolution)
  - Remaining: 11/14
- Alpha tier: 3 systems (0/3 designed)
- Campaign tier: 12 systems (0/12 designed)
- Full Vision tier: 6 systems (0/6 designed)

**Named Officers:**
- Kaster (WAR 82, LDR 96, INT 92, POL 85, CHR 88)
- Bon shi hai (WAR 55, LDR 78, INT 94, POL 80, CHR 62)
- Alexsen (WAR 98, LDR 85, INT 40, POL 25, CHR 75)
- Thane (WAR 90, LDR 50, INT 75, POL 30, CHR 45)
- Zhuge Jian (WAR 30, LDR 70, INT 99, POL 90, CHR 80)
- Jin Tao (WAR 45, LDR 60, INT 88, POL 95, CHR 50)
- Sander (WAR 75, LDR 88, INT 65, POL 55, CHR 70)

**Terrain Types:**
- Road (1 AP), Open Field (1 AP), Hill (2 AP), Forest (2 AP), Village (1 AP), River (impassable)
- 3 seasonal states: Dry, Wet (×1.5 multiplier), Harvest

**Key Combat Constants:**
- Ranged WAR scaling: 1/100
- Melee WAR scaling: 1/200
- Flank bonus: +30%
- Broken morale damage penalty: -50%
- Defense cap: 90% max reduction

---

## 🗺️ System Design Order (Remaining 11 MVP)

**Next in order:**

| # | System | Priority | Dependencies | Est. Effort |
|---|--------|----------|--------------|------------|
| 4 | **Morale System** | MVP | Combat Resolution | Medium |
| 5 | Facing & Flank | MVP | Terrain, Hex Movement | Medium |
| 6 | Hex Movement | MVP | Terrain | Medium |
| 7 | Fog of War | MVP | Terrain, Hex Movement | Medium |
| 8 | Victory/Defeat | MVP | Morale, Combat | Small |
| 9 | Duel System ⚠️ | MVP | Officer Stats | Large |
| 10 | Officer Passive | MVP | Officer Stats, Combat, Duel | Medium |
| 11 | Tactical HUD | MVP | Combat, Morale, Officer Passive | Medium |
| 12 | Duel UI | MVP | Duel System | Small |
| 13 | Portrait Display | MVP | Officer Stats | Small |
| 14 | Save/Load | MVP | All gameplay | Large |

*⚠️ High-risk systems — require careful design*

---

## 📁 File Locations Quick Reference

### Design Docs (`design/gdd/`)
```
design/gdd/
├── kasters-war-gdd.md          ← Game concept (start here)
├── systems-index.md            ← All 35 systems mapped
├── officer-stats.md            ← Officer stat framework ✅
├── terrain-system.md           ← Hex grid + seasons ✅
├── combat-resolution.md        ← Damage formulas ✅
└── morale-system.md            ← [Next to design]
```

### Art & Visual (`design/art/`)
```
design/art/
├── art-bible.md                ← Visual direction ✅
└── characters/README.md        ← Portrait specs
```

### Configuration (`docs/` & `.claude/`)
```
docs/
├── engine-reference/godot/     ← Godot 4.6 reference
└── technical-preferences.md    ← Engine + naming rules

.claude/docs/
├── technical-preferences.md    ← Full tech stack
├── directory-structure.md      ← Project layout
├── coordination-rules.md       ← Agent workflow
└── coding-standards.md         ← Code quality rules
```

### Game Data (`design/registry/`)
```
design/registry/
└── entities.yaml               ← Officers + constants
```

---

## 🎮 Core Game Loop (from GDD)

```
Campaign Layer (Strategic)
├─ Map Navigation
├─ Intel Gathering
├─ Army Composition
└─ Covert Operations
    ↓
Preparation Phase (Tactical Setup)
├─ Officer Selection
├─ Squad Composition
└─ Battle Scenario
    ↓
Tactical Layer (Real-time Combat)
├─ Hex Movement
├─ Combat Resolution
├─ Morale Management
└─ Victory Conditions
    ↓
Duel System (Officer 1v1)
├─ Challenge Mechanic
└─ Officer Passives
```

---

## 📋 Combat Formula Reference

### Ranged Damage
```
base = unit_base × (1 + attacker.WAR / 100)
total = base × terrain_mod × flank_mod × morale_mod
```
Example: Archer base 20, WAR 80 → 20 × 1.8 = 36 base damage

### Melee Damage
```
base = unit_base × (1 + attacker.WAR / 200)
total = base × terrain_mod × flank_mod × morale_mod
```
Example: Swordsman base 40, WAR 80 → 40 × 1.4 = 56 base damage

### Defense Reduction
```
effective_damage = damage × (1 - min(defense / 100, 0.9))
```
Example: LDR 80 defender, village +15% → defense = 40 × 1.15 = 46 → 100 damage becomes 54

---

## 🛠️ Tools & Skills

**Available commands to continue design:**

```bash
# Design the next system in order
/design-system morale-system

# Or auto-pick the next system
/map-systems next

# Review what's been written
/design-review design/gdd/officer-stats.md

# Cross-GDD consistency check (when multiple GDDs exist)
/consistency-check
```

---

## 📌 Open Questions (to resolve later)

From game concept Appendix B:
1. Fire Plan outcome: GDD assumes success — confirm with novel canon
2. Zhuge Jian join timing: Act II (treatise) → Act III (physical) — confirm
3. Mission 8 duel: allow loss without game-over?
4. Post-unification island name: Kasteria or Kastera?
5. Loyalty system depth: single value per city sufficient?

---

## 🚀 Next Steps

### Immediate (this session or next)
1. **Design Morale System** (design order #4)
   - Depends on: Combat Resolution ✅
   - Command: `/design-system morale-system`

2. Continue remaining MVP systems in order
   - Facing & Flank, Hex Movement, Fog of War, etc.

### After MVP systems are designed (11 more)
1. Run `/design-review` on all GDDs
2. Run `/consistency-check` for cross-system conflicts
3. Run `/gate-check pre-production` for formal review

### Later (Alpha tier)
- Ranged & Artillery System
- Fire System
- Tactical AI System

### Even later (Campaign & Full Vision)
- 18 more systems for campaign loop, story events, polish

---

## 💡 Key Decisions Made

✅ **Officer Stats Framework**: Named officers with fixed stat blocks; generics use archetypes with ±2–3 variance; growth only at act transitions

✅ **Terrain as Intelligence Layer**: 6 types with seasonal modifiers; player reads ground before committing

✅ **Deterministic Combat**: No RNG in damage calculation — only positioning, officer choice, and terrain matter

✅ **Art Style**: RoTK13-inspired semi-realistic painterly; faction tinting via CanvasLayer; Godot Forward+ renderer

✅ **Engine**: Godot 4.6 + GDScript + Jolt physics

---

## 📖 How to Use This Document

- **"What's done?"** → See "🎯 What's Done" section
- **"Where's X?"** → See "📁 File Locations" section
- **"What's next?"** → See "🚀 Next Steps" section
- **"How do I implement Y?"** → See "📋 Combat Formula Reference" or read the specific GDD file
- **"What's the design order?"** → See "🗺️ System Design Order" section

---

**Last Updated**: 2026-06-12  
**Session**: Systems Design (3/35 complete)  
**Ready to**: Design Morale System or review existing work
