---
name: project-art-bible-ux-constraints
description: Art bible visual direction rules that have UX implications — shape grammar, color, density, accessibility commitments
metadata:
  type: project
---

Art bible Sections 1–6 are locked. These are the rules that directly constrain UX design.

**Shape grammar (Section 3.3):**
- Pure angular, no organic curves in UI
- Chamfer (45° corner cut) used ONLY for portrait frames containing an officer face — this is an identifier, not an honor
- Rule weight = hierarchy: portrait frame (heaviest, chamfered) > officer stat panels (medium) > unit cards (light) > supporting panels (lightest)
- Settlement panels gain medium rule weight when combat objective — ONLY dynamic shape change at runtime
- No rounded corners, no pill buttons

**Color for UI (Section 4.4):**
- Muted, low-saturation world palette
- UI colors derived from world palette via value increase / saturation reduction — no new hues introduced
- Active/selected: Warm Amber #C4872A (only full-saturation element outside semantic signals)
- Hover: SW-04 at 20% opacity overlay (value lift only, no hue shift)
- Disabled: SW-01 at 60% opacity
- Body text: SW-04 (#D4C9B0) on dark panels

**Semantic signals (Section 4.2):**
- Danger: #7A2020 + downward filled chevron
- Reward/Opportunity: Warm Amber #C4872A + upward chevron/diamond
- Intel/Uncertain: Cool Pale Blue #A8BDD4 + circle icon (reserved exclusively)
- Depletion/Warning: Muted Amber-Green #7A8A3A + segmented bar
- All semantics have mandatory shape backup (colorblind requirement)

**Colorblind safety (Section 4.5):**
- Shape backup mandatory for all semantic pairs
- Pattern overlay for faction territory: horizontal = player, diagonal = enemy, none = neutral
- Simulation testing required: deuteranopia, protanopia, greyscale before production-ready

**Density by game state (Section 3.3):**
- Campaign Map: large panels, sparse, wide margins
- Preparation Phase: dense information grid, consistent inset rules
- Tactical HUD: minimal, thin rules, small panels, panels enter/exit (never persist)

**Aesthetic commitments that constrain UX:**
- No glow, no particle effects, no screen flash, no chromatic aberration (banned in all states)
- Heirloom Blade trigger: no visual event — single-frame portrait expression OR plain HUD text only
- Portrait lighting always neutral (4800–5200K) — Duel is the only exception

**Why:** These locked art direction rules are the boundaries within which UX must operate. Any UX requirement that conflicts with these rules must be surfaced as a formal conflict.

**How to apply:** Cross-reference before proposing any interaction feedback, state indicator, or panel design. Flag conflicts explicitly rather than working around them silently.
