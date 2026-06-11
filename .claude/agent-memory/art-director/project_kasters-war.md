---
name: project-kasters-war-context
description: Core context for the active game project — Kaster's War: The Unification War. Art bible location, locked decisions, asset roster, and technical constraints.
metadata:
  type: project
---

Active project: **Kaster's War: The Unification War**
Genre: Turn-based grand strategy + tactics
Engine: Godot 4.6 Forward+ renderer
Platform: PC (Steam)
Team size: Indie 1–5 people
Art bible location: `design/art/art-bible.md` (v0.1 in progress)

**Why:** Art bible is the visual source of truth; all AD decisions record there.
**How to apply:** Always read the current art bible before responding to any visual question — sections are approved and locked unless explicitly reopened.

## Art Bible Progress (as of 2026-06-11)

- Section 1: Visual Identity Statement — APPROVED
- Section 2: Mood & Atmosphere — APPROVED
- Section 3: Shape Language — APPROVED
- Section 4: Color System — APPROVED
- Section 5: Character Design Direction — APPROVED
- Section 6: Environment Design Language — APPROVED
- Section 7: UI/HUD Visual Direction — placeholder (not yet authored)
- Section 8: Asset Standards — drafted 2026-06-11, awaiting write approval
- Section 9: Reference Direction — placeholder (not yet authored)

## Key Locked Decisions

- **Texture approach**: Semi-realistic painterly with hand-authored normals (Section 6, locked)
- **Style reference**: RoTK13 semi-realistic painterly
- **Portrait canvas**: 512×640px for all named officers, bust-up three-quarter facing
- **LOD philosophy**: Design in reverse — hex sprite → icon → portrait (Section 5.4)
- **Shape for named officers**: One primary silhouette interruption only; never two competing features
- **SW-05 Sash Crimson**: Present on every player officer; absent on enemy officers
- **Heirloom Blade**: Zero visual events — no glow, no particle, no flash at any LOD
- **Portrait backgrounds**: SW-04 Pale Administrative, no gradient/vignette/backdrop

## Asset Roster

Named player officers (7): Kaster, Alexsen, Bon shi hai, Thane, Zhuge Jian, Jin Tao, Sander
Named enemy officers (2+): King Lycurse, Boreas (Traitor General)
Generic officer pool: ~25–30, 8–10 archetypes × 2–4 portrait variants each
Campaign map tiles: terrain types × 3 seasons × territory control states
Settlement props: ~30 objects × damage states (intact/damaged/destroyed/charred)

## Performance Budget

- ≤300 draw calls/frame
- 1.5 GB RAM ceiling
- 60fps target

## Flags Documented in Art Bible

- Flag A: Enemy vs. contested territory geometry distinction (Section 3.2)
- Flag B: Chamfer applies only to portrait-face frames (Section 3.3)
- Flag C: Settlement panels gain medium-rule weight when combat objective (Section 3.3)
- Flag D: Zhuge Jian hanfu sleeve fallback at hex sprite scale → guan cap (Section 3.1)
- Pattern overlay for colorblind faction read flagged for technical-artist feasibility (Section 4.5)
