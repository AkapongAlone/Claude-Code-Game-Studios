---
name: project-kasters-war
description: Core project context for Kaster's War — game structure, layers, platform, input, and UX-relevant mechanics
metadata:
  type: project
---

Turn-based grand strategy + tactics PC game (Godot 4.6, Steam).

**Three gameplay layers:**
1. Campaign Map — sparse, administrative, survey-mode
2. Preparation Phase — dense information grid, pre-battle planning
3. Tactical Hex Combat — minimal HUD, hex grid primary, panels enter/exit
4. Duel System — 1v1 embedded in tactical layer, ceremonial register

**Platform and Input:**
- PC (Steam) only
- Primary input: Keyboard/Mouse
- Partial gamepad support
- No touch, no mobile

**Information systems requiring UX attention:**
- Intel system: 3 certainty levels (rumors / confirmed / deep intel) — must be readable at a glance and degrade gracefully
- Seasonal system: affects movement and terrain — must be ambient but legible
- Named officer stat blocks: WAR/LDR/INT/POL/CHR (5 stats) + passive ability — dense info per card
- Preparation Phase: stratagem slots (2 of 4-6 options), officer card selection — most information-dense state
- Duel: stance-based (Attack/Defend/Feint) + stamina, WAR read hint every 3 turns

**Named officers (7 player, 2+ enemy):**
Kaster, Bon shi hai, Alexsen, Thane, Zhuge Jian, Jin Tao, Sander (player); King Lycurse, Traitor General (enemy)

**Why:** Understanding the game's three-layer structure and information density per state is foundational to all UX review work.

**How to apply:** Reference these layers and their distinct density requirements when reviewing any UI proposal, panel design, or interaction pattern.
