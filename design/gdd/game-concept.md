# Game Concept: Dominion of Ages

*Created: 2026-06-15*
*Status: Draft*

> **Pivot note:** This concept replaces the previous *Kaster's War* tactical-battle
> direction. The earlier tactical GDDs (combat-resolution, duel-system, facing-and-flank,
> fog-of-war, hex-movement, morale-system, tactical-hud, terrain-system, etc.) are
> **superseded** and should be archived. Existing officer-portrait assets are reusable
> as part of the leader roster.

---

## Elevator Pitch

> It's a **grand strategy game on a world map** where you build an empire not by
> drilling armies, but by **assembling a council of legendary leaders from every
> nation and every era** — slot Napoleon, Caesar, and Einstein into the same
> cabinet — and watch your nation's stats *top up* with every leader you add,
> until your build is strong enough to conquer the world.

---

## Core Identity

| Aspect | Detail |
| ---- | ---- |
| **Genre** | Grand strategy (4X-lite) + roster/build-crafting |
| **Platform** | PC (Steam) |
| **Target Audience** | Achievers & system-explorers — Civ + Brotato overlap (see Player Profile) |
| **Player Count** | Single-player |
| **Turn Structure** | Turn-based (discrete turns, end-turn button — Civ-style, not real-time-with-pause) |
| **Session Length** | 30–90 min; full campaign spans multiple sessions (save-supported) |
| **Monetization** | Premium (none decided yet) |
| **Estimated Scope** | Large (9–14 months, solo/small team) |
| **Comparable Titles** | Sid Meier's Civilization, Brotato, Wars of Napoleon |

---

## Core Fantasy

You are a kingmaker across all of history. You don't just rule a nation — you
**curate the greatest minds and conquerors who ever lived** and bend them to a
single banner. The thrill is the impossible dream team: Genghis Khan leading your
armies while Cleopatra runs your diplomacy and Tesla powers your research. Every
leader you recruit visibly makes your nation stronger, and the deepest satisfaction
is the *moment your council clicks* — when the synergies line up and the numbers
surge.

---

## Unique Hook

**It's like Civilization, AND ALSO like Brotato** — a transparent, stacking
build-crafting layer where every leader you slot into your council adds visible,
combinable modifiers to your national stat sheet. The empire's power is a *build*
you assemble, not a unit roster you babysit.

The hook works because it fuses two proven loops that normally live apart: the
"paint the map" satisfaction of 4X, and the "number-go-up, find-the-combo" dopamine
of roguelite build-crafting — unified by a roster of cross-era historical legends.

---

## Player Experience Analysis (MDA Framework)

### Target Aesthetics (What the player FEELS)

| Aesthetic | Priority | How We Deliver It |
| ---- | ---- | ---- |
| **Sensation** | 4 | Stat numbers visibly tick up; card units clash; satisfying UI feedback |
| **Fantasy** | 2 | Cross-era dream team — impossible-in-history council of legends |
| **Narrative** | 6 | Emergent "what-if history" stories, not scripted plot |
| **Challenge** | 3 | Optimizing council builds; reaching victory conditions |
| **Fellowship** | N/A | Single-player |
| **Discovery** | 3 | Finding leader synergies and Supreme Leader combos |
| **Expression** | 1 | Build diversity — many viable council compositions / playstyles |
| **Submission** | 5 | Low-micro, strategy-at-the-big-picture, relaxing turn pace |

### Key Dynamics (Emergent player behaviors)
- Players experiment with leader combinations to discover synergies ("if I run
  3 Military leaders + Sun Tzu...").
- Players commit to a playstyle lane (Military / Economy / Diplomacy / ...) and
  chase its matching victory condition.
- Players gamble on a Supreme Leader for a build-defining power spike, weighing
  its downside.
- Players expand territory specifically to unlock more council slots and new leaders.

### Core Mechanics (Systems we build)
1. **Council & Stacking Modifiers** — leaders slot into category lanes and add
   transparent flat + % bonuses to national stats (the Brotato heart).
2. **World Map Conquest** — province-based map; mobilize armies, auto-resolve, take territory.
3. **Card Units** — mobilized armies appear as cards (Wars of Napoleon style) with stat-driven resolution.
4. **Leader Acquisition & Ranks** — recruit leaders via gacha/purchase/condition-unlock; leaders have ranks.
5. **Supreme Leader** — optional capstone slot: large council-wide buff + exclusive skill, at a cost/debuff.

---

## Player Motivation Profile

### Primary Psychological Needs Served

| Need | How This Game Satisfies It | Strength |
| ---- | ---- | ---- |
| **Autonomy** | Many viable playstyle lanes and council builds; choose your path to victory | Core |
| **Competence** | Visible stat growth, synergy discovery, optimizing the perfect council | Core |
| **Relatedness** | Connection to legendary historical figures you collect and command | Supporting |

### Player Type Appeal (Bartle Taxonomy)
- [x] **Achievers** — collect leaders, max out stat lanes, reach victory conditions, number-go-up.
- [x] **Explorers** — discover leader synergies, Supreme Leader combos, optimal build orders.
- [ ] **Socializers** — N/A (single-player).
- [ ] **Killers/Competitors** — Minimal (conquest AI opponents, no PvP at launch).

### Flow State Design
- **Onboarding curve**: First 10 min — start with 3 slots, fill them, see stats jump, take one province. Teach by doing.
- **Difficulty scaling**: AI nations grow alongside the player; bigger empires unlock stronger leaders for both sides.
- **Feedback clarity**: The national stat sheet is always visible; every action shows its numeric delta.
- **Recovery from failure**: Losing a battle costs units, not the run; campaign continues — failure is a setback, not a wall.

---

## Core Loop

### Moment-to-Moment (30 seconds)
View the national stat sheet, drag a leader into/out of a council slot, and watch
the numbers *top up* instantly (the Brotato feel). Decide whether this composition
is the build you want.

### Short-Term (5–15 minutes)
Per turn: mobilize an army (spawn card units), send it to take a province,
auto-resolve the battle, recruit a newly available leader, or invest in a stat lane.
"One more turn" lives in *seeing the council get better and the map get bigger.*

### Session-Level (30–90 minutes)
Expand territory → unlock new council slots → recruit and re-arrange leaders →
push your chosen lane harder. A session ends at a natural breakpoint (campaign saves).

### Long-Term Progression
Advance toward a **victory condition matching your playstyle lane** (conquest,
economic, diplomatic, tech). Grow from 3 slots to a full council of legends across
a long campaign.

### Retention Hooks
- **Curiosity**: Which leaders unlock next? What synergies are out there? What does this Supreme Leader's exclusive skill do?
- **Investment**: A campaign empire and a carefully tuned council you don't want to abandon.
- **Social**: N/A at launch.
- **Mastery**: Discovering and refining the strongest council builds per lane.

---

## Game Pillars

### Pillar 1: Every Choice Tops Up
Every leader and action must produce a visible, immediate numeric change to the
player's stats.

*Design test*: If we're debating between two implementations, choose the one where
the player sees clearer, faster feedback on the effect.

### Pillar 2: Dream Team Across Time
The charm is assembling legends that could never have coexisted in real history.

*Design test*: If we're debating a rule, choose the one that keeps cross-era,
cross-nation mixing free and open rather than historically constrained.

### Pillar 3: Many Roads to Glory
Every lane (Military / Civilian / Economy / Diplomacy / Science) must be able to
win the game.

*Design test*: If a change would make one lane or one leader dominant, reject it —
preserve lane parity.

### Pillar 4: Strategy, Not Micromanagement
Simpler than EU4 — combat auto-resolves; decisions happen at the big-picture level.

*Design test*: If a feature adds moment-to-moment micro-management, cut it.

### Anti-Pillars (What This Game Is NOT)
- **NOT a real-time tactical battle game** — would compromise Pillar 4 (Strategy, not micro). Battles auto-resolve.
- **NOT a game with one "best" leader** — would compromise Pillar 3 (Many Roads). No single dominant pick.
- **NOT a game that hides its math** — would compromise Pillar 1 (Every Choice Tops Up). Stats and odds stay transparent.

---

## Council System (Signature System Detail)

### Category Lanes
Leaders belong to a category that buffs its corresponding national stat lane. Players
invest in lanes to shape a playstyle, and each lane connects to a victory path:

| Lane | Example Leaders | Primary Buffs | Victory Path |
| ---- | ---- | ---- | ---- |
| ⚔️ Military | Napoleon, Genghis Khan, Caesar | Combat power, special units | Conquest |
| 🏛️ Civilian | Hammurabi, Solon | Happiness, population, extra slots | Tall / internal growth |
| 💰 Economy | Medici, Adam Smith | Income, trade, resources | Economic |
| 🕊️ Diplomacy | Bismarck, Cleopatra | Alliances, vassals, influence | Diplomatic |
| 🔬 Science | Einstein, Tesla, da Vinci | Research, tech unlocks | Tech |

> Category → playstyle → victory condition is intentionally a single chain, so that
> Civ-style victory variety and Brotato-style build-crafting are the same decision.

### Stacking Modifiers (Brotato DNA)
- Leaders contribute **flat + percentage** bonuses that combine into a transparent stat pool.
- Some leaders **scale off nation state or other leaders** (e.g., "+5% military power per conquered province"; "if ≥3 Military leaders, armies always strike first").
- The national stat sheet always shows the running total; slotting a leader animates the delta.

### Leader Acquisition & Ranks
- Leaders have a **rank** (tiered rarity/power).
- Acquired through multiple channels: **random draw / purchase with resources / unlock by meeting conditions** (e.g., conquer a leader's home region).
- Slot count starts at **3** and expands as the nation grows.

### Supreme Leader (Capstone Slot)
- Every nation has **one optional Supreme Leader slot**, separate from the council.
- **Upside**: large buff to the entire council + an **exclusive skill** available only in this position.
- **Downside (tradeoff)**: a cost to install, and/or a debuff to certain stats once installed.
- Effect: defines the identity of the campaign — *commit to this leader and accept the weakness?*
- Example: Napoleon as Supreme Leader → all Military leaders +50%, unlocks "Coup d'État," but Diplomacy −30%.

---

## Inspiration and References

| Reference | What We Take From It | What We Do Differently | Why It Matters |
| ---- | ---- | ---- | ---- |
| Sid Meier's Civilization | World map, province expansion, multiple victory paths | Power comes from a council build, not unit micro | Validates 4X + multi-path appeal |
| Brotato | Transparent stacking stats, build-crafting, number-go-up | Applied to a nation/council instead of a character | Validates the satisfying core feel |
| Wars of Napoleon | Card-based unit presentation | Cards are auto-resolved abstractions, not tactical pieces | Validates the visual unit language |

**Non-game inspirations**: Alternate-history "what if" thought experiments; the
fantasy-football idea of drafting all-time greats onto one team.

---

## Target Player Profile

| Attribute | Detail |
| ---- | ---- |
| **Age range** | 18–40 |
| **Gaming experience** | Mid-core |
| **Time availability** | 30–90 min sessions, several times a week |
| **Platform preference** | PC / Steam |
| **Current games they play** | Civilization VI, Brotato, Old World / Humankind |
| **What they're looking for** | Strategy depth without heavy micromanagement; satisfying build optimization |
| **What would turn them away** | Tedious unit micro, opaque math, a single dominant strategy |

---

## Technical Considerations

| Consideration | Assessment |
| ---- | ---- |
| **Recommended Engine** | Godot 4.6 (already configured; GDScript, Forward+, Jolt) |
| **Key Technical Challenges** | Transparent stacking-modifier system; large leader/synergy data model; readable world-map UI |
| **Art Style** | 2D stylized — card-based units + stylized world map (UI-heavy) |
| **Art Pipeline Complexity** | Medium–High (many leader portraits — mitigate with consistent simple style for MVP) |
| **Audio Needs** | Moderate (ambient, UI feedback, event stings) |
| **Networking** | None |
| **Content Volume** | MVP ~20 leaders / ~15 provinces; Full vision: full world map, 5 lanes, large leader roster |
| **Procedural Systems** | None planned (authored map + data-driven leaders) |

---

## Risks and Open Questions

### Design Risks
- If stacked numbers don't *feel* like they move, the Brotato heart fails. **Prototype stat feedback first.**
- Long campaign + collection chase could drag if pacing of slot/leader unlocks is off.

### Technical Risks
- Stacking-modifier engine (flat + % + conditional scaling) must stay consistent and debuggable across many leaders.

### Market Risks
- 4X is crowded; the build-crafting hook must read clearly in marketing or it looks like "another Civ-like."

### Scope Risks
- Leader-portrait art volume could balloon — needs a disciplined art style and MVP roster cap.
- Balancing 5 lanes + Supreme Leader + synergies is a wide balance space.

### Open Questions
- Exact leader-acquisition mix (random vs purchase vs condition-unlock) — resolve via prototype.
- How many starting lanes/victory paths in MVP vs full? (MVP proposes 3 lanes, 1 victory path.)
- Supreme Leader downside model: flat debuff vs install cost vs both — prototype to find what feels fair.

---

## MVP Definition

**Core hypothesis**: *Assembling a council whose stats visibly top up is satisfying
enough to sustain 30+ minute sessions.*

**Required for MVP**:
1. National stat sheet with live stacking modifiers (flat + %).
2. Council with 3 starting slots across 3 lanes (Military / Economy / Diplomacy), expandable by territory.
3. ~20 leaders with ranks and at least a few scaling synergies.
4. Supreme Leader slot with one working upside/downside example.
5. Small world map (~15 provinces), mobilize → card units → auto-resolve combat.
6. One victory condition (conquest).

**Explicitly NOT in MVP** (defer to later):
- Full world map and all 5 lanes.
- Non-conquest victory conditions.
- Full gacha/acquisition economy.
- Deep diplomacy/AI personalities.

### Scope Tiers (if budget/time shrinks)

| Tier | Content | Features | Timeline |
| ---- | ---- | ---- | ---- |
| **MVP** | ~15 provinces, ~20 leaders, 3 lanes | Council + stacking stats + auto-resolve + conquest win | ~6–8 weeks |
| **Vertical Slice** | One full region, ~40 leaders | + Supreme Leader polish, 2 victory paths, acquisition v1 | ~8–10 weeks |
| **Alpha** | Full world map, all 5 lanes (rough) | All victory paths, full acquisition, AI nations | ~3–4 months |
| **Full Vision** | Complete roster, polished UI/art | All systems, balanced, content-complete | ~9–14 months |

---

## Visual Identity Anchor

*(Lean mode — art-director gate skipped; this is a provisional anchor to be confirmed in `/art-bible`.)*

- **Direction (provisional)**: Clean, readable "strategist's table" — stylized 2D map + collectible leader cards, numbers always legible.
- **One-line visual rule**: *The number must always be the hero of the frame* — every UI choice serves stat readability and the satisfying "tick up."
- **Supporting principles**:
  - *Card as artifact* — leader cards feel like collectible, ranked objects.
  - *Map as canvas* — provinces read at a glance by owner color.
- **Color philosophy**: Restrained map palette so faction colors and stat-change highlights pop.

> Confirm and expand this in `/art-bible` before asset production.

---

## Next Steps

- [ ] Archive/supersede the old *Kaster's War* tactical GDDs (move to `design/gdd/archive/` or mark superseded).
- [ ] Update `CLAUDE.md` project description to reflect the new concept (engine stays Godot 4.6).
- [ ] **Prototype the core idea** (`/prototype council-stacking`) — validate the stat-top-up feel before writing GDDs.
- [ ] Run `/art-bible` to confirm the Visual Identity Anchor.
- [ ] Validate concept completeness (`/design-review design/gdd/game-concept.md`).
- [ ] If prototype PROCEEDS: decompose into systems (`/map-systems`).
- [ ] Author per-system GDDs (`/design-system [system]`) — Council, World Map, Card Units, Leader Acquisition, Supreme Leader.
- [ ] Build vertical slice in Pre-Production (`/vertical-slice`) before committing to Production.
