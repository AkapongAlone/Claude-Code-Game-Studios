# Council Stacking — Concept Prototype

**Game:** Dominion of Ages (pivot of Kaster's War)
**Date:** 2026-06-15
**Status:** in-progress (awaiting playtest verdict)

## Hypothesis

> "If the player slots a leader into the council and sees the national stats
> animate/top up immediately, they'll feel Brotato-style satisfaction — confirmed
> if they voluntarily swap leaders ≥3 times within 5 minutes."

Riskiest assumption: that numbers ticking up on a strategy UI gives Brotato-style
dopamine rather than feeling like a spreadsheet.

## How to Run

Open `prototype.html` in any browser (double-click). No server needed.

> If the Kaster portrait doesn't load over `file://`, it can be embedded as base64.

## What It Tests

- **Council**: 4 category slots (Military / Economy / Diplomacy / Science) + 👑 Supreme Leader + 🪶 Advisor slot
- **Stacking stats**: flat + % bonuses combine into a transparent stat sheet; deltas animate on each change
- **Derived resources**: Income, Research, Manpower, War Drive, Order — all computed from the 4 main stats
- **Relationships**: same-nation bond (+12%), allies (+10%), disliked-nation rivalry (−15%)
- **Off-specialty penalty**: a leader in the wrong category slot keeps only 20% of their bonuses (MISMATCH_PENALTY)
- **Supreme Leader**: large council-wide buff + exclusive skill, with a downside debuff
- **Advisor**: +10% all stats and halves the Supreme's downside (requires a Supreme present) — the "Zhuge Liang to Liu Bei" mechanic
- **Roster**: ~24 leaders incl. the 5 Kaster's War cast (Kaster uses the real portrait); click-to-place or drag-and-drop
- **Auto-battle**: Military stat vs escalating enemies, to prove stats matter

## Known Deferred Ideas

- Skills that override/offset the off-specialty penalty (noted, not yet built)
- Leader acquisition economy (gacha / purchase / condition-unlock)
- World map, turn loop, save/load — out of prototype scope

## Findings

_(To be filled in after playtest — PROCEED / PIVOT / KILL.)_
