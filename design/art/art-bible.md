# Kaster's War: The Unification War — Art Bible
> **Version**: 0.1
> **Last Updated**: 2026-06-11
> **AD Sign-Off**: Skipped — Lean mode
> **Status**: Complete (9/9 sections)

---

## Section 1: Visual Identity Statement ✅

### One-Line Visual Rule

> "Every visual decision earns its place by making the world more legible or the stakes more real — never both at once, and never neither."

**How to use this rule:**
- "More legible" = does this help the player read the battlefield, identify a character at a glance, or understand a system state? If yes, the detail is justified.
- "More real" = does this deepen the sense that Soliterra obeys physical and historical logic — mud, smoke, fatigue, season? If yes, it earns its place.
- "Never both at once" = prevents over-designed assets that try to be dramatic and informative simultaneously and achieve neither.
- "Never neither" = kills decoration for decoration's sake.

---

### Supporting Principle 1 — Contrast Is Earned by Hierarchy
*Anchors to: P2 — Officers Are the Story*

Named officers must be visually legible at three distances: portrait close-up, campaign-map mid-zoom, and tactical hex full-zoom. At each zoom level they must be distinguishable from generic units and from each other within one second of viewing.

Generic units establish a visual baseline of muted, uniform mass. Named officers deviate from that baseline in **exactly one primary dimension** — silhouette, dominant color, or posture angle — so the deviation reads instantly. The deviation must be grounded in character, not fantasy:

| Officer | Primary Differentiator | Grounding |
|---|---|---|
| **Alexsen** | Silhouette — larger frame, battered uniform | Physical presence, years of front-line combat |
| **Bon shi hai** | Posture — oblique stance, reading terrain not enemy | Tactician's habit, always measuring the ground |
| **Thane** | Posture — compressed, ready, never at rest | Assassin's trained stillness |
| **Zhuge Jian** | Costume — Chinese scholar robes (hanfu), not military uniform | Civilian intellectual, not a soldier |
| **Jin Tao** | Dominant color — administrative insignia, cleaner uniform | Quartermaster who never reaches the front |
| **Sander** | Silhouette — older, heavier stance, shield-forward bearing | Old Guard discipline, protective instinct |

> **Design test**: When deciding whether to add a second distinguishing color or accessory to a named officer's battle sprite, choose silhouette clarity over additional detail. One strong silhouette read outweighs two competing color notes.

> **Note (Flag 2)**: At small tactical-hex sprite sizes, silhouette may be harder to control than color. If sprite work precedes portrait integration, this principle may require a size-dependent variant. Revisit when tactical sprite production begins.

---

### Supporting Principle 2 — Restraint Is the Supernatural's Only Costume
*Anchors to: P3 — Grounded, Barely Fantastic*

The Heirloom Blade must never produce a visual event. No particle, no glow, no screen flash, no chromatic aberration, no slow-motion effect. When the passive triggers — the single moment in a battle where Kaster survives a killing blow — the visual response is: **nothing happens visually**.

If a signal to the player is required, only two options are permitted:
1. A single-frame portrait expression shift (braced → composed)
2. Plain text in the HUD — no icon pulse, no animation

The ambiguity of the moment — luck or blade — is the narrative payload. Visual noise destroys it.

This principle extends to all system-state changes: a supply shortage is an amber number, not wilting crop art. Low morale is a stat indicator, not dramatic soldier portraits. Restraint is not poverty of craft — it is the correct delivery mechanism for a world governed by logic, not spectacle.

> **Design test**: When uncertain whether a system-state change (low morale, weather shift, Heirloom Blade trigger) warrants a visual effect, choose text or a single static indicator over any animated or particle-based effect.

---

### Supporting Principle 3 — Texture Signals Season and Time, Not Decoration
*Anchors to: P1 — Victory Through Preparation + P4 — Authored Peaks, Player Valleys*

Campaign map and tactical terrain must change **structurally** with season — not just in color palette. The game's core intelligence loop requires the player to read environmental conditions and act on them before clicking a single order.

| Season | Structural Change | Intelligence Signal |
|---|---|---|
| Dry | Ochre cracked ground, sparse dry grass, hard road surface | Fire plan is visually available as a possibility before it is mechanically confirmed |
| Wet | Waterlogged ground, dense vegetation, visibly rutted roads | Artillery movement problem is communicated before the player issues a movement order |
| Harvest | Full fields, supply-route roads trafficked | Enemy supply burn timing is readable from terrain |

Authored-peak battles (Open Field, Fire Plan, Arctos siege) are distinguished from sandbox battles not by adding new visual effects, but by the **density and composition of existing elements** — more units on screen, a more dramatically composed deployment line, a specific weather state. The peak feels different because the world-state is heightened, not because a new visual layer was added.

> **Design test**: When designing a seasonal terrain variant and uncertain whether to change the terrain's structure (road texture, vegetation placement, ground surface) or only its color palette — choose structural change. The player must be able to read season from tile silhouette alone, without relying on color.

---

## Section 2: Mood & Atmosphere ✅

### How to Read This Section

Each game state has five properties. The lighting artist reads these five rows to set up a scene from scratch. The **one visual element that carries the mood** is the primary production constraint — if that element reads correctly, the state reads correctly even if the others are approximate.

Campaign Map and Preparation Phase share a contemplative, deliberate quality — intentional, as they are consecutive in the player's mental workflow. Their distinction is delivered by scale and density, not emotional opposition: Campaign Map is wide and sparse, Preparation Phase is compressed and detail-saturated.

---

### State 1: Campaign Map

| Property | Specification |
|---|---|
| **Primary emotion target** | Measured ownership — the player surveys what they control and calculates what it costs them, neither triumphant nor anxious |
| **Lighting character** | Midday, slightly overcast diffusion — cool neutral (4800–5200 K), low directional shadow, medium contrast. No golden hour. The world is not flattering itself. |
| **Atmospheric descriptors** | Spare, administrative, exposed, deliberate, patient |
| **Energy level** | Contemplative |
| **One element that carries the mood** | Sky: flat cloud cover, no sun disk visible, horizon line dominant — the island reads like a map someone is reading, not a landscape someone is standing in |

**Lighting artist note**: The overcast sky is not gloomy — it is neutral-functional. Avoid pushing it toward dramatic storm. Settlements in player control are slightly warmer than contested or enemy territory via local material color of built structures (not light). Seasonal structural changes must be readable on this sky condition from terrain silhouette and vegetation mass alone — not from sky color or light temperature.

---

### State 2: Preparation Phase

| Property | Specification |
|---|---|
| **Primary emotion target** | Focused tension — the player is reading the last intelligence they will have before irreversible commitment |
| **Lighting character** | Late afternoon, low directional light from screen-left — warm-neutral (5500 K), raking shadows that reveal terrain relief. Medium-high contrast on terrain features; portrait UI at neutral light. |
| **Atmospheric descriptors** | Close, weighty, scrutinous, committed, quiet |
| **Energy level** | Tense |
| **One element that carries the mood** | Shadow angle: the low raking light casts long shadows across the tactical preview, making every terrain fold legible — the player is literally reading the ground before their troops walk it |

**Lighting artist note**: The shift from Campaign Map (overcast, diffuse) to Preparation Phase (directional, raking) signals that something specific is at stake. Do not apply raking light to the Campaign Map under any circumstance — it is reserved exclusively for Preparation Phase and the tactical layer.

---

### State 3: Tactical Combat

| Property | Specification |
|---|---|
| **Primary emotion target** | Controlled urgency — the plan is in motion; the player is executing under pressure, not re-examining premises |
| **Lighting character** | Inherits light state from its Preparation Phase. **Auto-battle fallback: late afternoon directional, warm-neutral (5500 K).** Night battles: cool blue-grey ambient (3800 K), high shadow density. |
| **Atmospheric descriptors** | Active, pressured, readable, physical, committed |
| **Energy level** | Measured (default); morale-broken units increase animation tempo — not lighting |
| **One element that carries the mood** | Unit density on the hex grid: the visible mass of squads creating and breaking lines communicates battle state without UI annotation |

**Lighting artist note**: Lighting continuity between Preparation Phase and Tactical Combat is a production rule — light does not reset between phases. Time passes within a battle via ambient temperature shift only (very slow, noticeable only across 8+ turns). No atmospheric fog/haze for dramatic effect; fog on map tiles is a mechanical terrain element (visibility reduction), not a mood layer.

---

### State 4: Duel

| Property | Specification |
|---|---|
| **Primary emotion target** | Ceremonial dread — not excitement; the moment where everything that cannot be prepared for is tested |
| **Lighting character** | Tight high-contrast directional, warm-cool split: key light warm (6000 K) above-left, fill light cool (4000 K) below-right. Most dramatically lit state in the game. |
| **Atmospheric descriptors** | Isolated, formal, still, high-stakes, stripped |
| **Energy level** | Ceremonial |
| **One element that carries the mood** | Background desaturation: everything outside the two combatants drops to near-monochrome, forcing the figures to carry all chromatic information. The battle continues in sound — but visually the world narrows to two people. |

**Lighting artist note**: The warm-cool split is used **only** in Duel state — players will learn to associate it with life-or-death stakes. Background desaturation is an art-pass material decision, not a real-time screen effect. Portrait lighting breaks the neutral-portrait rule here deliberately — Duel portrait warm key is the visual signature of the state.

---

### State 5: Authored Peak Battles

| Property | Specification |
|---|---|
| **Primary emotion target** | Epic weight without spectacle — the player recognizes a hinge point of the war; scale communicates this, not added effects |
| **Lighting character** | Each peak has a fixed, non-advancing light state. **Open Field**: harsh midday overcast, grey-flat, cold (4500 K). **Fire Plan**: late afternoon into dusk (6500 K), slow pre-timed ambient shift amber→red-orange over battle duration. **Arctos Siege**: morning mist, diffuse cool (4200 K), detail lost in foreground depth. |
| **Atmospheric descriptors** | Dense, consequential, world-state-saturated, large, definitive |
| **Energy level** | Frenetic (Fire Plan); measured-heavy (Open Field, Arctos Siege) |
| **One element that carries the mood** | Deployment line density: authored peaks have significantly more units visible on screen than sandbox battles — density itself is the signal, not new effects |

**Lighting artist note**: Authored peak light states are locked. Only the Fire Plan has a controlled progression — the amber→red-orange shift is a slow, pre-timed ambient temperature shift (not a reactive particle system). This communicates the fire's momentum without depicting it at scale (P3: no particle magic). No other authored peak advances time during battle.

---

### State 6: Victory / Defeat Screens

| Property | Specification |
|---|---|
| **Primary emotion target** | Victory: grave satisfaction — the player won, but the cost is visible. Defeat: recognition without despair — this is information, not punishment. Neither state is a pop screen. |
| **Lighting character** | Victory: warm evening (6800 K), long shadows, battlefield visible in background — soft, not triumphant. Defeat: cool desaturated afternoon (4200 K), flat, battlefield empty. Both at low contrast. |
| **Atmospheric descriptors** | Victory: earned, still, heavy, honest, resolved. Defeat: clear, spare, accountable, open, quiet. |
| **Energy level** | Contemplative (both) |
| **One element that carries the mood** | A still background image of the battlefield — not a celebration portrait but the ground the battle was fought on, now quiet. Victory: field quiet. Defeat: field empty of player units. The field is the subject, not the character. |

**Lighting artist note**: Victory and Defeat are intentionally close in visual register — separated only by color temperature (warm vs. cool), not by energy or composition. This is a deliberate statement aligned with P3: winning a battle is not a party, losing one is not a catastrophe — both are facts to be absorbed and acted upon. If the UI team requests a more celebratory Victory state, escalate to creative director. The quiet register is load-bearing for the game's tone.

---

### Cross-State Consistency Rules

1. **Portrait lighting is always neutral** (4800–5200 K, low contrast, front-lit) regardless of game state. Duel breaks this rule deliberately — that violation is the Duel's visual signature.
2. **Seasonal terrain structural changes carry into all states** — the same Dry/Wet/Harvest read that applies on the Campaign Map applies in Tactical Combat and Preparation Phase.
3. **Banned effects hold in all states without exception**: glow, particle magic, chromatic aberration, screen flash. The Duel's background desaturation is an art-pass material decision, not a real-time screen effect.
4. **Authored peak light states are locked.** Only the Fire Plan has a controlled progression.

---

## Section 3: Shape Language ✅

### How to Read This Section

Shape language is the grammar of recognition. Before color resolves at a distance, before text is readable, before lighting registers as mood — shape reads. This section defines the geometric vocabulary that structures every visual layer of Kaster's War: what shapes mean, which shapes lead the eye, and what the world looks like when shapes are doing their job correctly.

---

### 3.1 Character Silhouette Philosophy
*Anchors to: P2 — Officers Are the Story*

The visual baseline is **undifferentiated mass**: infantry columns, artillery crews, and cavalry units that read as uniform, compacted rectangles. The mass is the ground — it exists so that named officers can deviate from it.

Named officers deviate through **asymmetry and extension**. Where generic units are compact and symmetric, named officers carry one deliberate interruption — a wider hat brim, a cloak at an angle, a weapon at oblique rest, a civilian garment breaking the military silhouette. The interruption is singular, not a collection of features — one thing that reads at thumbnail scale.

**Hero shapes: irregular-vertical** — tall (reads above mass at small size), with one horizontal break. Generic units: **compact-horizontal** — ranked, wide, regular. The opposition reads at 64×64 pixels without color.

| Officer | Silhouette Interruption | Shape Geometry |
|---|---|---|
| **Alexsen** | Oversized battered frame — armor and weather accumulated | Wide-base irregular-vertical; no clean edges |
| **Bon shi hai** | Oblique posture, turned at angle to viewer's axis | Diagonal-dominant — body axis not perpendicular |
| **Thane** | Compressed, no wasted limbs, head low | Compact-vertical; compression IS the silhouette read |
| **Zhuge Jian** | Flowing hanfu sleeves — only officer with fabric volume below the waist | Vertical with soft horizontal extension at sleeve height |
| **Jin Tao** | Formal upright, insignia-dominant — no silhouette break | Clean-vertical; distinguished by what's ABSENT |
| **Sander** | Shield-forward, weight back, hunched chin | Wedge — wide at front, receding toward viewer |

**Zhuge Jian note**: The hanfu silhouette is the only officer shape derived from non-military garment volume. Do not add flowing fabric to any uniformed officer — the shape reads "scholar" specifically because no soldier wears it.

**Fallback rule for hex-scale sprites (Flag D)**: If hanfu sleeve volume collapses to visual noise at tactical-hex sprite size (≤32px height), the fallback distinguishing feature for Zhuge Jian is head gear — a scholar's guan (冠 cap) whose height silhouette reads vertically where the sleeve cannot. Never substitute military headgear. Document the fallback decision in the sprite production notes.

> **Design test**: When designing a named officer's battle sprite and uncertain whether to add a second costume feature or strengthen the primary silhouette — choose the single stronger silhouette. An officer who reads as "the one with the big hat" outperforms one who reads as "the one with the hat, cloak, and sash."

---

### 3.2 Environment Geometry
*Anchors to: P1 — Victory Through Preparation + P3 — Grounded, Barely Fantastic*

Soliterra's world is built from two competing shape families in deliberate tension.

**Nature dominates in curves**: coastlines irregular, hills rounded, forests with soft broken canopy silhouettes, rivers arcing. The island's organic geography is the reference state — what exists before human organization asserts itself.

**Human construction dominates in angles**: fortifications rectilinear, roads straight between settlements, palisades vertical stakes, cannon emplacements geometric earthworks. Napoleonic-era military aesthetic = imposition of right angles onto organic world. The sharper and more geometric the construction, the more controlled — and more fragile under pressure — it reads.

**Territory read through geometry**:

| Feature Type | Shape Character | Player Read |
|---|---|---|
| Natural terrain (hills, coast, forest) | Irregular curve, soft silhouette | Unpredictable; cover; slow movement |
| Roads | Straight, hard-edged, regular interval | Supply line; speed; vulnerability |
| Player settlements | Dense angular built structures + organic surrounds | Organized, controlled |
| Enemy settlements | Angular but in a foreign pattern — their geometric order, not the player's | Controlled by someone else; readable as organized threat |
| Contested territory | Reduced built geometry on all sides; fractured rectangles, degraded road lines, organic mass expanding | Least legible; least controlled; most dangerous to read |

**Enemy vs. contested distinction (Flag A)**: Enemy territory retains intact angular geometry (their forts, their roads, their organized fields) but the *pattern* is the identifier — their fortification geometry is positioned to face inward toward the player's approach, not distributed for local governance. Contested territory has the least angular imposition of any type: fields fallow (soft organic), roads degraded (interrupted lines), settlements fractured. The distinction: organized-but-hostile vs. disorganized.

**Seasonal shape variation**: Wet season — organic shapes expand (vegetation, waterlogged ground); road geometry becomes interrupted (ruts, degraded edges). Dry season — organic shapes contract; angular structures read more cleanly against bare ground.

> **Design test**: When designing a contested-territory tile and uncertain whether to reduce built geometry or shift it to a degraded palette — reduce the geometry first. A contested settlement must read as less organized structurally from tile silhouette before color is applied.

---

### 3.3 UI Shape Grammar
*Anchors to: P1 — Victory Through Preparation + P4 — Authored Peaks, Player Valleys*

The UI is a layer of organized information in front of the world — it does not pretend to be part of it. Its shape grammar echoes Napoleonic military document design (regimental orders, staff map annotations) — not fantasy HUD ornament.

**Base vocabulary: the ruled edge** — straight lines, clean corners, consistent stroke weight, minimal decoration. Panels are rectangles. Buttons are rectangles. Nothing in the UI uses organic curves (no pill buttons, no rounded corners as default). Curves belong to nature and terrain; the UI's right angles signal "information organized by a human for a purpose."

**One permitted decorative exception**: Officer portrait frames use a shallow **chamfer** — a 45° corner cut — at all four frame corners. This echoes period military insignia frames and distinguishes portrait frames from generic data panels without fantasy ornament. The chamfer is an identifier for officer portraits only (Flag B: chamfer applies only to frames containing a portrait face — not to officer stat cards, decision cards, or any other officer-adjacent panel).

**UI shape grammar by density layer**:

| Layer | Shape Grammar | Rationale |
|---|---|---|
| **Campaign Map** | Large panels, thick border rules, sparse interior divisions, wide margins | World is the content; UI is minimal annotation. Panels feel like map overlays. |
| **Preparation Phase** | Dense grid of cards with consistent inset rules; chamfered portrait frame prominent; stat panels tightly packed | Information density is the mechanic; shape consistency creates visual rhythm for fast eye parsing |
| **Tactical HUD** | Minimal — thin rules, small panels, maximum map visibility; panels enter and exit, never persist | During combat the player must read the hex grid; HUD must not compete for foreground |

**Rule weight as hierarchy signal**:
1. Portrait frames — heaviest rule weight (chamfered)
2. Named officer stat panels — medium rule weight
3. Generic unit counters — lightest rule weight or no border
4. Supporting panels (supply count, weather, turn counter) — thin rule, no figure interruption

**Dynamic rule weight exception (Flag C)**: Settlement panels gain medium-rule weight when they become a combat objective — the only runtime shape rule change in the UI. This is the signal that a settlement has entered the decision space. All other shape grammar is static.

> **Design test**: When a new UI panel needs to be designed and its rule weight is uncertain — ask: does this panel contain a named officer's portrait face? If yes: chamfered frame, heaviest rule. If the panel is adjacent to an officer but doesn't contain their face: medium rule, standard 90° rectangle. All other panels: thin rule, standard rectangle.

---

### 3.4 Hero Shapes vs. Supporting Shapes
*Anchors to: P2 — Officers Are the Story + P4 — Authored Peaks, Player Valleys*

Visual hierarchy is achieved through figure-ground contrast at every layer. The game presents one of two things: a named officer's decision space, or the mass context in which that decision is made. Shape language reinforces which mode is active.

**Hero shapes**: singular, irregular, prominent — interrupt their context at every zoom level.
**Supporting shapes**: regular, repeated, receding — exist to make the interruption legible.

**Gaze hierarchy stack** (highest to lowest visual priority):

1. Named officer portrait frame (heaviest rule, chamfered corner, largest face element)
2. Named officer battle sprite (asymmetric silhouette, isolated from unit mass)
3. Terrain feature relevant to current decision (geometry deviating from tile baseline)
4. Unit mass (regular, repeated, background-weight)
5. Supporting UI panels (thin rule, no figure interruption)

The player does not need a highlight ring or glow to identify officers. Shape grammar delivers it.

**Panel type comparison**:

| Panel Type | Corner | Rule Weight | Ratio |
|---|---|---|---|
| Portrait frame | Chamfered (45°) | Heaviest | Tall, face-filling |
| Unit card | 90° | Medium | Square thumbnail + 2 stat lines |
| Settlement panel | 90° | Thin (medium when objective) | Wider than tall; infrastructure read |

> **Design test**: When a new information type needs a UI panel — if it does not anchor to a named officer's portrait face, it is thin-rule, standard 90° rectangle. No exceptions. The chamfer is not an honor; it is an identifier.

---

## Section 4: Color System ✅

### Core Rule
**Warm colors are earned, not ambient.** The default temperature of Soliterra is cool-neutral. Warmth enters only when something has changed — a faction has acted, a moment has peaked, a resource has depleted.

---

### 4.1 Primary Palette

Two tiers: **World Colors** (terrain, environment, atmosphere) and **Signal Colors** (semantic meaning, UI only). A color cannot serve both tiers simultaneously.

| Swatch | Name | Hex | Role | Emotional Register |
|---|---|---|---|---|
| SW-01 | Campaign Slate | `#4A5568` | Visual baseline — neutral ground state | Administrative, patient |
| SW-02 | Kaster Navy | `#1E2D45` | Player faction anchor | Ownership, gravity, discipline |
| SW-03 | Weathered Ochre | `#8B7355` | Terrain detail — dry conditions | Physical, factual, mundane |
| SW-04 | Pale Administrative | `#D4C9B0` | Document surface, portrait background | Legible, formal, period-appropriate |
| SW-05 | Sash Crimson | `#8B2635` | Earned warmth — only warm note in player army | Sacrifice, distinction, danger earned |
| SW-06 | Enemy Burnt Sienna | `#6B3D2E` | Enemy faction anchor — foreign military, not threat | Opaque, organized, present |
| SW-07 | Mist Lead | `#8FA3B1` | Atmospheric distance, fog of war, contested ambient | Uncertain, receding, unreliable |

> **Design test**: Place all seven swatches on mid-grey. Without labels, identify two warm (SW-05, SW-06), two near-neutral (SW-03, SW-04), three cool (SW-01, SW-02, SW-07). If this read fails, the palette relationship needs adjustment.

---

### 4.2 Semantic Color Vocabulary

Semantic colors appear in UI and state indicators only — **not** in terrain, costumes, or environment (exceptions: SW-05 bridges world/semantic as a narrative object; Fire Plan ambient shift uses the warm-progression family as a world-state event).

| Semantic Role | Color | Hex | Value | Icon/Shape Backup |
|---|---|---|---|---|
| Danger / Threat | Reduced Crimson | `#7A2020` | Dark | Downward filled chevron |
| Reward / Opportunity | Warm Amber | `#C4872A` | Mid | Upward chevron / diamond |
| Player Ownership | (structural — no hue assigned) | — | — | Faction temp + shape language |
| Intel / Uncertain | Cool Pale Blue | `#A8BDD4` | High | Circle icon (reserved exclusively) |
| Depletion / Warning | Muted Amber-Green | `#7A8A3A` | Mid | Horizontal segmented bar |

**Why no color for Player Ownership**: A "safe green" would violate the warm-earned rule by making safety a chromatic event. Player territory should feel default — the baseline. Absence of threat signals is itself the safety signal.

> **Design test**: Print the semantic matrix in greyscale. Each row's value level (dark / mid / high / mid) must be distinguishable from its neighbors by at least 2 Munsell value steps.

---

### 4.3 Per-Area / Per-Faction Color Temperature Rules

**Rule**: No faction inherits another faction's temperature register. The read must be unambiguous at mid-zoom without labels.

| Territory | Temperature Direction | Expression | Why |
|---|---|---|---|
| Player (Kaster) | Cool-neutral 4800–5000K | SW-02 undertone on territory; slightly warmer built-structure material | Player territory = default/administrative register |
| Enemy (Notos/Lycurse) | Warm-neutral 5800–6200K | SW-06 undertone on territory; warmer than player even in wet season | Foreign military establishment, different tradition |
| Neutral / Unaligned | Neutral 5000–5500K | SW-01 ground, SW-04 built surfaces | No faction overprint — "unclaimed" |
| Contested | Desaturated — neither dominant | SW-07 ambient; SW-02 + SW-06 at reduced saturation, cancellation not blend | Least organized read; strategic uncertainty |

**Seasonal overlay conflict resolution**: Terrain structural shift takes priority over faction temperature tint, **but** faction tint is preserved in built-structure material color. Players read season from ground/vegetation; faction identity from built structures. Channels do not compete.

> **Design test**: Render four territory tiles in wet season. Without labels, player vs. enemy must be identifiable within 3 seconds from built-structure material color alone.

---

### 4.4 UI Palette

**Chromatic strategy**: Muted world + anchored UI. Every UI color is derived from a world palette color via value increase, saturation reduction, or opacity reduction. The UI never introduces a new hue not present in the world palette.

| UI Element | Source | Operation | Rationale |
|---|---|---|---|
| Panel background | SW-02 | Lightness +40%, opacity 85% | Tactical overlay feel |
| Panel border / rule | SW-01 | Lightness +15%, opacity 100% | Military document ruled line |
| Body text | SW-04 | Full value, full opacity | Maximum legibility on dark panels |
| Portrait frame border | SW-02 | Saturation +10%, lightness −10% | Heaviest rule, slight blue presence |
| Active / selected state | Warm Amber `#C4872A` | Native saturation | Only full-saturation element outside semantic signals |
| Hover state | SW-04 | 20% opacity overlay | Value lift only — no hue shift |
| Disabled / inactive | SW-01 | Lightness +10%, opacity 60% | Present but inert |

**Two hard rules**:
1. SW-05 (Sash Crimson) is never used as a UI convention — it belongs to characters and world. The danger semantic uses `#7A2020`, which is darker and distinct.
2. SW-06 (Enemy Burnt Sienna) never appears in player-facing panels. Enemy information displayed in player UI uses neutral colors + faction icon.

> **Design test**: Open the Preparation Phase screen. Cover all semantic signal indicators. The screen should read as value-only — dark panels, off-white text, mid-grey rules, no visible hue. Uncover semantic indicators. They must immediately read as the most chromatically saturated elements on screen.

---

### 4.5 Colorblind Safety

This is an information-dense game. Colorblind accommodation is a core design requirement, not an add-on.

**Risk pairs and mandatory backup cues (blocking)**:

| Pair | Risk | Backup Cue — MANDATORY |
|---|---|---|
| Danger Crimson vs. Depletion Amber-Green | Deuteranopia / Protanopia (most likely failure) | Danger = downward chevron + darkest value; Depletion = segmented bar + mid value. Shapes must never be used for other roles. |
| Reward Amber vs. Depletion Amber-Green | Deuteranopia | Reward = upward chevron/diamond; Depletion = segmented bar. Shape grammar is primary channel. |
| Intel Blue vs. Panel Background Navy | Tritanopia | Intel indicators require min 3:1 contrast ratio (WCAG AA) against any panel. Circle icon reserved exclusively for intel. |
| Player Faction vs. Enemy Faction on Campaign Map | Deuteranopia | **Pattern overlay**: player territory = fine horizontal-rule texture (15–20% opacity); enemy territory = fine diagonal-rule texture; neutral = no texture. Non-color channel for spatial faction read. *(Flag for technical-artist feasibility before production.)* |

**Simulation testing requirement**: Before any UI screen is marked production-ready, test under: (1) Deuteranopia simulation, (2) Protanopia simulation, (3) Full greyscale. All named information must be identifiable from shape or value alone under deuteranopia.

> **Design test**: Export Preparation Phase at full density. Apply deuteranopia simulation. Every distinct information type must be identifiable from shape or value alone. If any two types become visually indistinguishable, redesign the backup cue before the screen enters production.

---

## Section 5: Character Design Direction ✅

### 5.1 Player Character Visual Archetype — What All Named Officers Share

The class signal: **one deliberate interruption to the military baseline.**

Generic units read as mass — uniform, ranked, compacted. A named officer is recognized not by being "more elaborate" but by carrying a single feature that the mass cannot contain: one thing that makes them identifiably one person, not a type. The feature is grounded in that person's history or role — not aesthetic choice, not decoration.

**What all named player officers share at the class level:**

- **SW-05 Sash Crimson (`#8B2635`) appears somewhere on every player officer.** Placement varies (sash, sword-knot, trim, binding) but the color is present. Not a spotlight — a class signal that reads only when the full roster is seen together. An officer without any crimson present is either incomplete or has defected.
- **Portraits are bust-up, three-quarter facing.** The officer attends to something off-screen — the world, not the viewer.
- **Portrait backgrounds: SW-04 Pale Administrative at consistent low contrast.** Document surface — holds the figure without asserting itself. No gradient, no vignette, no environmental backdrop.
- **Faces are present and specific.** Not idealized. Each officer has visible specific features that do not resolve to a generic type.
- **Paint style: RoTK13 semi-realistic painterly.** Textured brushwork with legible form — not photorealistic, not cartoon. Edges soft where receding, hard where competing for read.

> **Design test**: Line up all seven named player officers at portrait scale. Cover names. Each must be identifiable from face alone. Cover faces; each must be identifiable from silhouette alone. Both reads must hold independently.

---

### 5.2 Distinguishing Feature Rules Per Character Type

**Player Officers (7 named)**

Distinguished in exactly one primary dimension. The feature must be legible at all three scales — portrait, campaign icon (~48px), tactical sprite (~32px).

| Officer | Primary Differentiator | SW-05 Placement | Note |
|---|---|---|---|
| Kaster | Silhouette — irregular-vertical, hat + sword break | Sword-knot or sash | Sword visually ordinary in all states |
| Alexsen | Silhouette — oversized battered frame | Buried in coat trim or binding | Age of garment is the read, not detail amount |
| Bon shi hai | Posture — oblique, terrain-reading body axis | Sash | Diagonal body axis is the distinguishing read |
| Thane | Posture — compressed, suppressed | Hidden — interior lining or grip-wrap | Absence of visible crimson is consistent with his nature |
| Zhuge Jian | Costume — hanfu, civilian garment | Robe accent | Only officer where garment TYPE is the identifier |
| Jin Tao | Color — cleaner, more formal, administrative insignia | Insignia or trim | Absence of wear is the signal |
| Sander | Silhouette — shield-forward wedge | Strap binding or shield-edge trim | Old Guard bearing is the read |

**Enemy Named Characters**

King Lycurse and Boreas warrant full portrait treatment equivalent to player officers. They do not carry SW-05. Their anchor is SW-06 (`#6B3D2E`) — present as a structural note in costume, not a spotlight. Lycurse reads as warrior king (physical authority, not administrative rank). Boreas's portrait contains a visual trace of his prior player-faction allegiance — a specific costume element removed, covered, or replaced. The material fact is visible; no editorializing. *(Specific prop to be determined with narrative team.)*

**Generic Officers (~25–30 recruitable)**

Same portrait format (bust-up, three-quarter, SW-04 background). Not silhouette-distinguished — their work is done by RoTK-style archetype reads: ~8–10 visual archetypes, 2–4 portrait variants each. SW-05 present once they join player faction. **Generic officers must not use any silhouette feature locked to a named officer** — no oblique axis (Bon), no hanfu (Zhuge), no shield-forward wedge (Sander).

> **Design test**: Generic officer portrait next to any named officer. Generic must not be mistakable for named. Cue is not quality — it is silhouette singularity: named has one interruption, generic reads as a military type.

---

### 5.3 Expression and Pose Style Targets

**Philosophy: high information, low affect.** Officers do not emote at the player. They are operating — thinking, measuring, waiting — and their expression is the residue of that activity. Reference register: Napoleonic-era military portraiture, 1800–1815. Composed, slightly guarded, occasionally weary. Decision made; outcome uncertain.

**Base portrait state (campaign / preparation phase):** Resting-specific to psychological nature, not reacting to game events. Kaster is composed and carrying weight he does not show. Thane's expression is held, not given. Zhuge Jian looks like he is *thinking* rather than *deciding* — a legible distinction at portrait scale.

**Pre-battle state:** Same portrait as base. No separate state. Players work with what they know — not emotional signals from officers.

**Duel state:** Same expression register in heightened lighting (Section 2). Officers must not look afraid — duel is chosen confrontation in this world's military code. Expression: formal recognition of stakes. Slightly set jaw, eyes leveled. Controlled effort, not suppressed.

**Defeat state:** One additional portrait per named officer (same composition, same lighting). Expression: post-action recognition — processing a loss, not performing it. Eyes not focused on viewer; focused on the fact.

**Framing by archetype:**
- Combat officers (Alexsen, Sander, Kaster, Thane): tighter crop, less air above — their world is close
- Strategic officers (Bon shi hai, Zhuge Jian): more air above — thinking at a different scale
- Administrative officers (Jin Tao): centered, formal, more visible torso — institutional presence

Same canvas dimensions for all; framing adjustments only.

> **Design test**: Three portraits without names — combat, strategic, administrative. From framing and expression alone (no color, no costume), each archetype orientation must be readable.

---

### 5.4 LOD Philosophy

Design in reverse: start with what works at 32px, confirm at icon scale, add portrait resolution to the already-functional shape.

**Level 1 — Portrait (512×640 canvas, recommended):**
All channels available: silhouette, color, posture, expression, costume specificity, paint texture. Minimum readable: individual identity, faction (SW-05 or SW-06 present), role (civilian/military/scholar/warrior).

**Level 2 — Campaign Icon (~48–64px):**
Face drops to impression. Silhouette primary, color secondary. Costume texture gone; garment outline remains. Minimum readable: faction (warm note presence), silhouette class (seven distinct shapes), role archetype. Zhuge Jian fallback activates here if hanfu sleeve collapses: use guan cap (冠) height silhouette.

**Level 3 — Tactical Hex Sprite (~24×32 to 32×40px):**
Silhouette only. Color reads as faction temperature blob. Minimum readable: faction (color temperature), named vs. generic (one silhouette interruption vs. compact regular mass), scholar-vs-military impression for Zhuge Jian.

**What drops first in simplification:**
1. Facial feature specificity → 2. Fabric/armor surface texture → 3. Small accessory detail → 4. SW-05 precise placement (warm note preserved) → 5. Pose articulation precision

**Never dropped at any LOD:** The single primary silhouette interruption, faction color temperature, named-vs-generic distinction.

**Cross-LOD consistency rule**: The silhouette interruption must be the same feature across all three LOD levels. If a feature cannot survive to hex sprite scale, it is not the right primary feature — redesign the portrait, not the sprite.

> **Design test**: Produce the campaign icon and hex sprite before committing to the final portrait. If the portrait's primary distinguishing feature does not survive to hex sprite scale, revise the portrait. Test direction: portrait ← icon ← sprite, not portrait → icon → sprite.

---

### 5.5 Kaster's Blade — Visual Silence Rule

**The blade is ordinary. That is the rule.**

In portrait: a standard military sword of the period, appropriate to rank. It does not glow, does not have unusual coloration, does not bear visible inscriptions, does not occupy the composition's focal zone. If a SW-05 accent appears on the sword-knot or scabbard, it is identical to the same accent on any other officer's weapon — not unique to this blade.

**At each LOD:**
- Portrait: sheathed or resting position, outside focal zone, period-appropriate hardware, no unusual materials
- Campaign Icon: contributes to irregular-vertical silhouette as a line — reads as part of a soldier's shape
- Tactical Sprite: a line extending from the figure. No color distinction.

**During gameplay (Heirloom Blade trigger):** No visual event on the blade. No flash, pulse, edge highlight, or particle. This is absolute.

**Commissioning note for character artists:** If an artist instinctively adds visual interest to the blade — edge sheen, engraving, unusual color in the pommel — brief them explicitly: the blade is a deliberate non-object. The craft here is the discipline to make it thoroughly ordinary while everything else in the portrait has been carefully considered. The contrast between Kaster's fully-realized portrait and his utterly plain weapon is itself a moment of careful authorship.

> **Design test**: Show Kaster's portrait to someone unfamiliar with the game. Ask them to identify the most visually interesting element. The blade must not appear in their answer. If it does, remove the detail that drew the eye and test again.

---

## Section 6: Environment Design Language ✅

*The environment is not a backdrop — it is the first intelligence report the player receives before any UI data loads.*

---

### 6.1 Architectural Style — Hybrid Colonial-Indigenous

Soliterra's architecture reflects a culture that pre-dates Napoleonic contact by centuries. The visual rule: **European military geometry was imposed on top of an older built tradition that never fully yielded.** The tension between these two layers is the island's architectural identity.

**The Older Layer — Island Vernacular**
Grey coastal limestone, timber from interior forests, clay-fired low-pitch roof tiles, compact irregular clustering. Rooflines echo the island's terrain silhouette. Single arched gateways as the primary transitional element. Materials register: grey limestone, weathered timber, pale ochre clay tile.

**The Napoleonic Overlay — Military Geometry**
Star fort geometry for major fortifications, earthwork bastions, gabion field emplacements, straight road cuts through hill contours. Completeness of the overlay correlates with strategic value — communicating military priority before any UI label confirms it. Materials register: raw earth (recently dug), weathered timber, iron hardware.

**Hybrid Forms (what makes Soliterra visually distinct):**
- Settlement walls: limestone construction + Napoleonic buttress piers (piers visibly newer — clean-cut vs. weathered)
- Fortified gateways: older arched form survives inside newer angular gate-frame with portcullis groove — two centuries visible at one element
- Military roads: arrive at organic settlement edge and dissolve — the last 40m negotiates between military axis and older path network
- Supply warehouses: rectangular Napoleonic logistics geometry placed inside older organic courtyard compounds

**Faction Expression in Architecture:**
Player territory (Kaster-held Boreas) = island vernacular at full expression, military overlay at varying maintenance. Enemy territory (Notos/Lycurse) = same vernacular base, but fortification geometry faces inward toward Boreas — occupation architecture, not local defense. The angular pattern tells the player which direction the threat faces before intel is gathered. Contested territory: military overlay damaged or incomplete on both sides; island vernacular persists — organic wall faces survive where angular additions have been pulled down. The island outlasts the war.

> **Design test**: Three settlement tiles — player-held, enemy-held, contested. Cover all UI labels. Within 5 seconds, contested must be identifiable as the tile with the least complete angular geometry, regardless of who held it last.

---

### 6.2 Texture Philosophy — Semi-Realistic Painterly, Hand-Authored Normals

**Why this approach**: Photorealistic textures fail the intelligence-delivery function — at campaign-map zoom, photorealistic limestone and timber both resolve to "textured grey-brown." A painterly approach permits material-class exaggeration: limestone = consistently cool and smooth-highlighted; timber = consistently warm and grain-directional; raw earth = consistently matte and ochre.

**Godot 4.6 Forward+ implementation:**
- Normal maps: hand-authored (not baked from geometry) — emphasize terrain relief features that serve intelligence function (hill crests, ford crossings, road camber) over photorealistic accuracy
- Roughness maps: three zones per material class only — specular-highlight (wet stone, metal), mid-roughness (timber, clay tile), full-diffuse (dry earth, thatch). Three zones are sufficient for material-class distinction; avoid micro-variation that reads as noise at campaign zoom
- Albedo faction tinting: SW-02 Kaster Navy (15–20% saturation contribution) on player-territory built structures; SW-06 Burnt Sienna at equivalent weight on enemy structures. **Material decision, not lighting** — tint persists correctly when lighting temperature changes between game states

**Seasonal albedo variants (shared normal + roughness maps, three albedo variants per terrain tile type):**

| Season | Albedo Character | Structural Read |
|---|---|---|
| Dry | SW-03 Weathered Ochre dominant, sparse vegetation, cracked surface in ground normals | Angular road geometry reads with maximum clarity |
| Wet | Darker/more saturated ground, heavier vegetation mass, road surface shows rut lines | Road geometry interrupted; organic shapes visually expand toward road edges |
| Harvest | Full-saturation ochre + green in field tiles, road center-line wear visible | Built structures warm slightly via material only; road wear indicates active supply usage |

**The one painterly rule**: Every texture contains at most **two points of material-class emphasis** — one read for near-zoom (tile inspection), one for mid-zoom (campaign map survey). Details that read only at near-zoom and serve no information function at mid-zoom are not painted.

> **Design test**: Export full campaign map tile set (all terrain types, all seasons) at 50% zoom. A producer unfamiliar with this document must be able to sort tiles into three seasonal groups by terrain texture alone. If they cannot, structural season distinction is insufficient.

---

### 6.3 Prop Density Rules — Density Is a Semantic Signal

**Density by territory control state:**

| Control State | Density | Prop Categories | Player Read |
|---|---|---|---|
| Player-held | High (8–12/settlement tile) | Supply crates, tethered horses, officer banners, garden plots, road markers | Organized, functioning, owned |
| Enemy-held (intact) | High (8–12) | Same density, enemy pattern: different banners, Lycurse-faction insignia | Organized — but owned by someone else |
| Neutral | Medium (4–6) | Civilian only: market goods, fishing nets, domestic items | Neither army runs this settlement |
| Contested | Low (2–4) | Damaged/displaced: overturned furniture, broken barrels, no complete military infrastructure | Supply system broken |
| Recently fallen | Transitional (4–6, mixed) | Previous controller's props (some intact, some damaged) + new controller's (fewer, freshly placed) | Transition visible — old order not cleared, new not established |

**Seasonal density adjustments:**
- Dry: −30% organic props; +field-dry debris (communicates fire-spread risk)
- Wet: +waterlogged ground markers, mud ruts as props; −road-maintenance props (communicates movement penalty before the player issues an order)
- Harvest: +agricultural props at controlled settlements; depleted at contested neighbors (supply burn timing readable)

**Density-complexity rule**: No tile receives props from more than three categories simultaneously. Within each category, props share a repeating silhouette vocabulary (same barrel model in different states — not a zoo of unique objects). A library of 30 objects at varying density states is preferable to 80 unique objects.

> **Design test**: Player-held settlement tile vs. contested tile on campaign map. Contested must be immediately identifiable as "less organized" from prop density alone before any UI label is read. If the distinction requires zoom-in, the density differential is insufficient.

---

### 6.4 Environmental Storytelling Guidelines

*The world tells the war without text.*

**Settlement under siege vs. peacefully occupied:**
- Siege: approach-trench geometry at perimeter (irregular angular cuts approaching from one direction) + battery emplacements at oblique angles + wall breach props at entry point + zero supply-traffic props on outgoing roads
- Occupied: normal control-state density + active supply-traffic ruts on outgoing roads + military geometry faces outward as defense

**Road: heavy military traffic vs. unused months:**
- Heavy traffic: deep center-line compression in road albedo + displaced soil + wheel-cut ruts extending into road-edge ground + dropped supply prop at edges
- Unused: vegetation intrusion on road surface (dry grass in dry season, grass creep in wet) + road maintenance markers absent + bridge props in weathered state (grey-shifted, slightly tilted post geometry)

**Battle aftermath on tactical hex tile (persists 2–3 turns):**
Applied cumulatively in priority order:
1. Geometric: disrupted angular geometry — earthworks partially collapsed, palisades breached
2. Prop density: reduced to 0–2 props, all battle debris category (broken weapons, abandoned equipment)
3. Ground albedo: desaturated patch at hex center (darker, less saturated — "churned ground", not blood coloring)
4. If fire was used: charred ground texture (black-brown, rough) replacing churned patch; prop density zero in charred area

**Harvest settlement: peak vs. burned:**
- Peak: full agricultural prop density + bundled sheaves + open granary door + maximum road center-line wear
- Burned: zero agricultural props + charred ground in adjacent field tiles + bare settlement interior + granary/warehouse shows charred-interior variant (this single prop reads "supply destroyed") + road shows abandonment (vegetation at edges)

> **Design test**: Three screenshots: peacefully-occupied (dry season), same settlement under siege, same settlement burned. A player without UI text must correctly sort all three within 30 seconds. If siege and occupation are indistinguishable without UI: approach-trench geometry is insufficient. If burning and standard aftermath are indistinguishable: charred texture differentiation needs strengthening.

---

### 6.5 Three Authored Environments
*Light states and compositions are locked. Art leads may not adjust without creative director sign-off.*

**Open Field (Act I, Mission 1)**
Light: Harsh midday overcast, grey-flat, 4500K. No directional shadow. Everything equally exposed.

Terrain: Cultivated plain, central northern coast, late Dry season (pre-harvest). Dry-season albedo throughout — ochre-brown ground, sparse stubble in field tiles, hardened road surface. No hill tiles in deployment zone, no forest within 3 hex columns of center.

Authored elements:
- Unit density: highest on screen of any battle encountered — mass communicates scale before battle begins
- Single north-south road as compositional spine — not a movement bonus, a visual axis bisecting both deployment lines
- One hex of low hill at northern edge silhouettes enemy mass against sky under flat 4500K ambient — sharpest read on the battlefield
- The cold unsparing light communicates "this is bad ground" — environment confirms the player was sent to die here

> **Design test**: Open Field vs. any sandbox plain battle, side by side. Player who has completed tutorial must identify which is "more important" from visual composition alone.

---

**Fire Plan (Act II, Mission 4)**
Light: Late afternoon 5500K → pre-timed ambient shift amber (6000K) → red-orange (6800K) over turns 8–10. Fixed clock, not interactive.

Terrain: Interior forest-river corridor, Dry season, maximum forest tile density. River arc (organic curve) crossing the map. Straight military road (the enemy's march route) running through forest mass — its angular geometry conspicuously exposed against the organic canopy.

Fire without particle magic — three interlocking changes:
1. **Ground albedo transition**: When hex fire-state triggers, albedo shifts Dry ochre → charred black in a 2-frame hard cut. Accumulation of black tiles is the fire's progress map — player reads spread by counting dead tiles, not watching flames
2. **Ambient light as fire surrogate**: Pre-timed 5500K→6800K shift warms all tiles and units. Warm-orange ambient against growing charred-tile ground produces correct perceptual read: the world is burning, without depicting a flame larger than a single prop
3. **Road exposure geometry**: As fire tiles accumulate at forest edge (player-set ignition points from Preparation Phase), charred tiles flank the angular road on both sides. When road is flanked on both sides, the trap has closed — geometry tells the player before any text confirmation

Fire-source props (torches, oil-jar props at player-chosen ignition points): static, not animated. Visual confirmation the player authored this outcome.

> **Design test**: Fire Plan at turn 1, turn 5, turn 9. Player must identify fire is spreading without being told — from charred tile accumulation and ambient shift alone.

---

**Arctos Siege (Act III, Mission 5)**
Light: Morning mist, diffuse cool 4200K, no directional light. Fog-of-war active. SW-07 Mist Lead overlay increases with distance: 15% at 4 hex, 35% at 6 hex, 55% at 8+ hex.

*The mist is not weather — it is architecture.* By hiding the full city extent, it makes Arctos feel larger than the tactical map can contain.

Three elements that distinguish Arctos from all other settlements:
1. **Multi-story building mass**: Rare second story on key structures (administrative buildings, fortification tower, gate complex). Reads as "this is a city."
2. **Double-ring wall**: Outer limestone vernacular wall (organic curve, wide, low) + inner Napoleonic-overlay wall (angular, higher, with bastions). Only settlement showing both rings simultaneously — communicates that breach requires two different tactics
3. **Mist as tactical reveal**: Inner ring partially obscured from deployment zone. As units advance, inner wall reveals at 3–4 hex distance — tile transitions from SW-07 grey to actual limestone material. The reveal is a tactical and visual event: player discovers true fortification extent at the moment they are committed to the approach

Enemy occupation markers: Lycurse-faction banner geometry on Boreas-tradition walls reads as wrong immediately. Supply warehouses show enemy prop patterns. The settlement looks like itself but is being run like something else.

> **Design test**: Show Arctos tactical preview before deployment. Player unfamiliar with Arctos must immediately understand from visual composition alone that this is the largest, most complex fortification encountered. If they require a UI label to understand Arctos is different, density differentiation is insufficient.

---

## Section 7: UI/HUD Visual Direction ✅

*This section unifies the art-director's visual direction with the UX-designer's alignment check. Interaction state specifications, minimum accessibility requirements, and three UX conflict resolutions are incorporated in §7.6.*

---

### 7.1 Diegetic vs. Screen-Space HUD Philosophy
*Anchors to: P1 — Victory Through Preparation + P4 — Authored Peaks, Player Valleys*

**The governing position**: This game's UI does not pretend to be the world, and it does not apologize for being information. It occupies the same visual register as a Napoleonic staff officer's overlay map — a document placed *on top of* the terrain to organize what the eye sees below. This framing is specific, period-grounded, and solves the tension between immersion and legibility without forcing a choice between them.

The three game states require three distinct positions on the diegetic axis:

**Campaign Map UI — Transparent Staff Document**

The Campaign Map UI is as close to diegetic as this game gets, but the fiction is not "this UI is part of the world." The fiction is "this UI is a document prepared for a commander who is looking at the world." The difference is load-bearing: a document overlay can be dense with ruled lines, inked grids, and annotated margins without asking the player to believe they exist as 3D objects in Soliterra. Settlement panels enter from the screen's lateral edges as though being placed beside the map by an offscreen staff hand — not appearing from within the terrain. Resource counters inhabit a ruled ledger strip at the screen's lower margin, formatted as supply-register columns, not floating HUD elements. Turn counter: upper-right, in a ruled box, formatted as a regimental date notation — `DAY [n] / SEASON`.

**Preparation Phase UI — Tactical Intelligence Dossier**

The Preparation Phase declares itself as an information-dense read. The visual analogy is not a document on a map but a set of reconnaissance documents spread on a briefing table. Cards exist as cards — their visual grammar announces "these are discrete pieces of intelligence with borders, hierarchy, and category." No attempt to blend card edges into the terrain preview behind them. The terrain preview is visible through a defined aperture (a ruled frame, not a vignette), not as a continuous background. Packed information density communicates "you have everything available to you right now, and the clock is running."

**Tactical HUD — Field Notation**

The Tactical HUD makes no world-integration gesture whatsoever. It is sparse, peripheral, and functions as marginal annotation on an already-complex read: the hex grid. Unit health and morale indicators are minimal field notation attached to the unit counter itself — not fixed HUD panels. Contextual panels (unit inspector, terrain tooltip, officer detail on selection) enter and exit per the standard rule: they do not persist.

**One persistent exception to the entry/exit rule**: A narrow ability-state strip at the screen's bottom edge is exempt from "panels enter and exit." This strip is the minimum persistent element required by the mechanical design — it must display which officer abilities are available, which have been spent, and which are passive for the duration of the battle. Constraints: height ≤36px; ability icons ≤24px; lightest rule weight in the hierarchy. It does not compete with the hex grid.

**The Napoleonic map-overlay language**: The visual grammar that makes "map overlay" feel period-correct is regimental notation design — ruled boxes with consistent weight, minimal serif annotations, grid-reference markers at corners, hatching patterns for territory state (Section 4.5). This is not decoration borrowed from history; it is period-functional design where visual grammar and information purpose are identical.

> **Design test**: Remove all color from the Campaign Map UI layer. The panel-border ruled lines, column divisions, and margin layout must still read as coherent "document on top of map" without color. If the document grammar requires color to be legible as a layer, the ruled-line grammar is insufficient.

---

### 7.2 Typography Direction
*Anchors to: P1 — Victory Through Preparation*

**Typeface personality**: The correct register is **transitional serif** — the category that emerged precisely in the Napoleonic era (Bodoni, Didot, Fournier). High contrast between thick and thin strokes, crisp hairline serifs, nearly vertical stress axis, formal authority. Font family must include a weight range from Light through Bold. No italic for body text — italic is reserved for officer-quote use only.

**Weight hierarchy (heaviest to lightest):**

1. **Header / State label** — Bold, all-caps, widest tracking. Used: phase transition titles ("PREPARATION PHASE"), major panel headers. One header per panel maximum.
2. **Primary data** — Regular weight, tabular figures. Used: resource counts, action points, unit strength. Tabular figures mandatory — column alignment is an information tool.
3. **Named officer text** — Regular weight with slight size increase (~1.15×), small-caps for surname only. Echoes period engraved nameplate typography without a distinct typeface.
4. **Body / supporting text** — Light weight, standard leading. Used: ability descriptions, panel labels, stat category names.
5. **Ambient annotation** — Light weight, 70% opacity, smallest size. Used: column headers, grid-reference markers, non-critical labels. Visually receding.

**Size hierarchy — five levels, minimum sizes at 1080p:**

| Level | Min size (1080p) | Purpose |
|---|---|---|
| L1 | 20px | Phase/state header — one per screen |
| L2 | 15px | Panel headers, named officer surnames |
| L3 | 13px | Primary data values (resource counts, stat values) |
| L4 | 11px | Body text — ability descriptions, supporting labels |
| L5 | 9px | Ambient annotation — absolute floor; nothing goes below |

At 1440p, these sizes scale proportionally with the UI scale factor. At the L5 floor, the transitional serif hairline will begin to collapse — if legibility fails at this size, move content to L4 or reconsider its necessity.

**Period-specific typographic details:**

- Resource count columns on the Campaign Map use ruled hairline separators between value and label — echoing period quartermaster register formatting.
- Turn counter notation: `DAY 14 — WET SEASON`. The em-dash as separator is period-appropriate and visually distinct from colon separators used elsewhere.
- Officer names in panels: SURNAME in small-caps, given name in regular weight below at L4.
- Do not use ornamental, swash, or exaggerated display typefaces. Precision, not decoration.

> **Design test**: Set the Preparation Phase card grid typography in greyscale at full-panel density. A player reading under time pressure must identify: (1) which officer, (2) their WAR stat value, (3) one passive ability — in that sequence, without scanning the full card. If the typographic hierarchy fails to direct that reading path, weight or size differentiation is insufficient.

---

### 7.3 Iconography Style
*Anchors to: P1 — Victory Through Preparation + P2 — Officers Are the Story*

**The governing rule**: Icons must resolve to their category at 16px. If the concept requires more than 16px to read, it is too complex for this game's icon vocabulary.

**Style decision — engraved line**: Single-weight or near-single-weight outlines with minimal internal fill, derived from period military cartography and regimental bookplate illustration. Not flat-filled silhouettes, not softly rendered icons. At 16px, internal line detail collapses to silhouette — design for silhouette-at-16px first; add interior engraving detail for 32px display contexts only.

**Resource icon vocabulary:**

| Resource | Icon Concept | Shape Category | Colorblind rule |
|---|---|---|---|
| Gold | Coin stack, face-on — three stacked horizontal discs | Circular, stacked | Unique round-stacked silhouette in the set |
| Supplies | Barrel — Napoleonic field-supply vessel with two horizontal bands | Tall oval with banding | Distinct from coin stack at 16px |
| Intel | Compass-rose circle with radial marks; number of filled arcs = certainty tier | Circle with radiating marks | Circle reserved exclusively for Intel (Section 4.2) |
| Manpower | Upright standing figure at rest arms | Vertical figure form | Only figurative icon in the set |

**Intel certainty tier differentiation**: The Intel semantic signal uses a single color + circle (locked, Section 4.2). The compass-rose circle is segmented into three arcs. Number of filled arcs indicates certainty tier: one arc = surface intel (unconfirmed); two = network intel (corroborated); three = deep intel (verified). At 16px, reads as partial vs. full circle. At 32px, the three arcs are distinct. This is the only sub-variant within a single semantic signal. The segmented circle must not be used for any other information type.

**Officer ability icon style:**

Icons at 32px minimum in the Tactical HUD ability strip. Each icon carries one period-recognizable object or military action at the category level; text label provides specificity.

Category vocabulary:
- Offensive: weapon or strike geometry (sword diagonal, cannon barrel horizontal)
- Defensive: shield or fortification element (shield face, wall segment)
- Intelligence: surveyor's instrument, sealed dispatch
- Logistics: supply barrel, road marker

**Passive vs. active distinction**: Passive ability icons carry a thin rectangular outer rule. Active ability icons carry no border. Shape of the outer rule communicates interactability — the panel-border vocabulary applied to icons.

> **Design test**: Export all resource icons at 16px. Apply deuteranopia simulation. The four icons must be identifiable as distinct types from shape alone. Additionally, export the Intel icon at three certainty-tier states. The three states must be distinguishable at 32px from arc fill alone.

---

### 7.4 Animation Feel for UI Elements
*Anchors to: P3 — Grounded, Barely Fantastic*

**The foundational constraint**: No UI animation may be mistaken for gameplay. No UI animation produces a visual event that could read as a world-state change. No UI animation exceeds the 3Hz photosensitivity threshold.

**Tactical HUD panel entry and exit:**

Panels enter by **sliding in from the nearest screen edge**, stopping at their resting position. Entry direction maps to function: ability strip slides up from the bottom; unit status panel slides from the edge adjacent to the selected hex. No scaling, no fade-in, no elasticity, no bounce. Strictly translational — a document being placed on a surface.

Exit is the reverse. Duration: 80–120ms. No panel entry/exit may animate more than 25% of screen area simultaneously — photosensitivity constraint preventing flash-equivalent motion. No panel may enter and exit within less than 333ms of each other (prevents >3Hz cycle).

**Selection state transitions:**

Active/selected state (Warm Amber) is a **single-frame swap** — no tween. In a turn-based game, tweened selection introduces latency that could be confused with engine processing. Hover state (SW-04 20% opacity overlay) also applies on the single-frame principle: present or absent, never animated.

**Preparation Phase card grid:**

One permitted animation: when the player first enters the Preparation Phase, cards populate using a staggered entrance. Row 1 cards place first (80ms delay between cards within the row), row 2 follows (80ms after row 1 completes). Total population time: ≤600ms. After population, cards are static. Individual card selection uses the instantaneous Warm Amber swap.

**Transient confirmation signals:**

A distinct category of UI feedback is explicitly **exempt** from the ambient state restraint principle (Section 1, Supporting Principle 2). The restraint principle governs persistent state indicators — a supply shortage is an amber number, not wilting crops. Transient confirmation signals confirm player action receipt and are required:

| Signal type | Visual treatment | Duration | Confirms |
|---|---|---|---|
| Move order accepted | Rule-weight pulse: thin border steps to medium for 2 frames, returns | ~100ms | Order registered |
| Stat value change | Value text: full opacity → 70% → full opacity | 2 frames | Value updated |
| Ability spent | Icon opacity drops to 40% (persistent state: ability consumed) | Instantaneous | Ability used |

These signals use the established UI palette only — no glow, no particles, no color outside vocabulary.

**Semantic signal threshold pulse:**

Semantic signals (danger chevron, depletion bar) are permitted one animation state: a **two-frame pulse** when a threshold is newly crossed. After the pulse, indicators are static. Persistent animated warnings are forbidden — they train the player to ignore them.

**Explicitly forbidden UI animations:**

1. Particle effects or trail effects on any UI element in any state
2. Screen-space shake or vignette pulse triggered by UI events
3. Smooth scale transitions (zoom in/out) on panels or cards
4. Color cycling, hue shifting, or gradient animation in any panel
5. Any animation producing a visual artifact in the hex-grid viewport
6. Idle/ambient animation on any stationary UI element — panels do not breathe, pulse, or shimmer
7. Transition effects overlapping world-state change semantics (no amber glow on UI elements — Warm Amber is selection only)

> **Design test**: Record a 30-second screen capture of the Tactical HUD during active combat. Watch without sound. No UI element's animation should be identifiable as "something happening on the battlefield." If any panel motion draws the eye away from the hex grid for more than the duration of a deliberate panel entry, the animation budget has been exceeded.

---

### 7.5 The Duel UI
*Anchors to: P2 — Officers Are the Story + P4 — Authored Peaks, Player Valleys*

**The Duel state is a deliberate rules violation.** It breaks neutral-portrait lighting (Section 2, Cross-State Rule 1). It breaks the Campaign Map's visual restraint. It breaks the Tactical HUD's minimal-panel philosophy. These violations are the point: Duel is the game's highest-stakes visual state and every normal-rule relaxation communicates this without text.

**Overall character:**

The Duel UI is structured around **two portrait frames as the primary visual subject**, not as supporting HUD elements. In every other game state, portrait frames are information-delivery tools at the periphery of decision-making. In Duel, the portraits are the battlefield. Everything else — desaturated background, stamina/move layer, background world stripped of chromatic relevance — exists to make the two portrait frames the only elements with full color information.

**Portrait frame modifications for Duel:**

1. **Frame scale**: Approximately **1.4–1.6× the normal Preparation Phase portrait frame size**. These two officers now occupy space equivalent to the information layer the entire Preparation Phase card grid occupied.

2. **Frame border temperature**: Shifts to echo the portrait lighting split. Player officer frame: SW-02 border with +8 lightness, slight warm shift. Enemy officer frame: SW-01 with +5 blue-shift. **This is the only instance in the game where a UI border changes temperature.** Reserved for Duel exclusively — must not appear anywhere else.

**Layout:**

Player portrait occupies the left two-thirds of screen width (slightly larger — asymmetric composition). Enemy portrait occupies the right portion. Officer names appear as L2 text directly below each portrait frame with no enclosing box — suspended in the desaturated background. The absence of a panel box signals that normal UI conventions are suspended.

**Stamina and move selection:**

Stamina bars placed immediately below each portrait frame — not in a separate HUD strip. Segmented horizontal bars at larger scale than the standard Depletion signal. Player bar: SW-02 derived fill (~60% opacity). Enemy bar: SW-06 derived fill at equivalent weight. No Warm Amber — Warm Amber is selection, not stamina.

Move selection buttons: centered between the two portrait frames, not affixed to either portrait. Standard 90° corners (no chamfer). Available moves: SW-04 text on SW-02 panel background. Disabled moves follow standard disabled treatment (Section 4.4). Selected move: instantaneous Warm Amber swap.

**Background desaturation:**

An art-pass material decision, not a real-time screen effect (Section 2, Cross-State Rule 3). Implementation: `ShaderMaterial` property change on background `Sprite2D` nodes when Duel state activates — `uniform float saturation` tweened 1.0 → 0.05 over 2–3 frames. This is a per-material shader parameter, not a `Compositor` post-process chain. Result: the world behind the two combatants reads as a greyscale field. The Duel UI layer sits in full color against a monochrome world.

**What is absent from the Duel UI:**

No resource counters. No turn counter. No officer ability strip. No hex cursor. No unit counter panels. The removal of all standard HUD elements is itself the escalation signal.

> **Design test**: Duel state screenshot with all text removed. The warm-cool temperature split between the two portrait frames must be readable as opposing registers within 3 seconds. If the border temperature shift and portrait lighting do not carry the warm-cool opposition without text labels, the frame-border tint is insufficient.

---

### 7.6 Interaction State Specifications and Minimum Standards
*Anchors to: P1 — Victory Through Preparation*
*This subsection specifies implementation requirements the visual direction must accommodate. Three UX conflicts are resolved here.*

**Three interaction states — all interactive panels must support all three:**

| State | Visual treatment | When it applies |
|---|---|---|
| Default | Standard rule weight; SW-04 body text; SW-02 derived panel background | Panel exists; no interaction |
| **Focused** | Rule weight increases by one step (thin → medium, medium → heavy); no color change | Panel holds keyboard/gamepad input focus but has not been selected. Mandatory third state — keyboard navigation cannot function without it. |
| Selected / Active | Warm Amber `#C4872A` border and/or background tint; instantaneous swap | Panel confirmed selected or active |

The focused state must be visually distinct from both default (rule weight differs) and selected (no amber; rule weight only). **Warm Amber is reserved for selected/active exclusively.** The focused state must never use Warm Amber at any opacity.

**Interactive vs. non-interactive panel distinction:**

The chamfer grammar (Section 3) is a content identifier, not an affordance signal. To distinguish interactive panels without relying on hover discovery:

- Interactive panels at medium-rule weight or above are interactive by default
- Thin-rule panels are non-interactive by default
- Exception: when a thin-rule panel becomes interactive (e.g., settlement panel gaining medium-rule weight as a combat objective), the rule-weight change is itself the affordance signal — the only permitted dynamic affordance using the existing vocabulary
- All interactive panels maintain a minimum click target of **32×32px** regardless of content size

**Tooltip and overlay panel treatment:**

When a tooltip or expandable detail panel appears over another panel, visual separation is achieved without curves, shadows, or glow:

1. Overlay panel uses **heavier rule weight** than the panel it covers (minimum one step heavier)
2. Overlay panel background at **opacity 95%** vs. standard 85% — the darker step creates visual elevation without a shadow or glow
3. Overlay always positions above or to the side of its trigger element — never overlapping the element it describes
4. Dismiss: click outside, or press Escape. Exit animation follows standard 80–120ms panel exit.

**Minimum sizes at 1080p (scaling proportionally to other resolutions):**

| Element | Minimum size |
|---|---|
| Body text (L4) | 11px |
| Ambient annotation (L5) | 9px |
| Ability icon (active, in HUD strip) | 24×24px |
| Resource icon | 20×20px |
| Interactive panel click target | 32×32px |
| Portrait frame (Preparation Phase) | 96×120px (minimum for face legibility) |

**UI scale range:**

The Godot UI must support **75%–200%** of the base 1080p layout. Authoring at 100% (1080p). At 200% scale, no panel element may be clipped or overlap. At 75% scale, all L4+ text must remain at or above its minimum pixel size. This range is required for accessibility — players using higher DPI displays, non-standard scaling, or low-vision preferences.

**Depletion Amber-Green (`#7A8A3A`) constraint:**

This color fails WCAG AA contrast at text sizes below L2 (~15px). It is valid as an indicator icon, segmented bar, or shape element. It must **never be used as the text color** for stat numbers, labels, or any element displayed at L3 or below. Its semantic role is communicated by shape (segmented bar) — color is secondary.

> **Design test**: Navigate the Preparation Phase card grid using keyboard Tab traversal only, no mouse. Every interactive element must be reachable by Tab, must show a visible focus indicator (heavier rule weight — not cursor-only), and must be activatable by Enter/Space. If any card is reachable only by mouse hover, the focus state is missing.

---

## Section 8: Asset Standards ✅

*This section merges the art-director's preferences with the technical-artist's hard constraints. Where the two conflict, the resolution is stated explicitly. Technical-artist implementation notes are marked [TA:] for traceability.*

---

### 8.1 File Format Preferences and Pipeline Responsibilities
*Anchors to: P1 — Victory Through Preparation*

**Source files (artist working files)**

All source files retained in native application format under `assets/source/`. Never referenced directly by the engine.

| Asset Category | Source Format | Rationale |
|---|---|---|
| Character portraits | `.psd` or `.kra` | Layers separated: face, costume, SW-05 accent, background. Non-destructive for LOD re-framing. |
| Campaign map tiles | `.psd` or `.kra` | Dry/Wet/Harvest albedo variants as layer groups within a **single file** — not three separate files. Prevents normal/roughness map drift between season variants. |
| Tactical battle tiles | `.psd` or `.kra` | Same structure as campaign tiles; authored-peak variant on a separate layer above base. |
| Settlement props | `.psd` or `.kra` | All damage states of one prop type in a single file as layers. |
| UI panels and borders | `.ai` or `.svg` | Geometric constructs require vector source for clean scaling. Exception: chamfered portrait frame artwork uses `.psd` (painted surface treatment). |
| Resource/ability icons | `.psd` or `.ai` | Full icon category in one artboard. |

**Deliverable files (art team → technical-artist handoff)**

Art team delivers lossless source-equivalent files. Compression is a technical-artist decision made with engine preview.

| Category | Format | Critical note |
|---|---|---|
| All raster content | `.png`, sRGB, 8-bit | Lossless. No pre-compression. No `.webp`. |
| Normal maps | `.png`, **linear color profile — NOT sRGB** | Linear is mandatory. sRGB-encoded normal maps produce incorrect lighting. This instruction appears twice because it is the most common handoff error in painterly pipelines. |
| UI vector-derived elements | `.png` at target canvas size; `.svg` also included | `.svg` required for any UI element needing dynamic runtime resizing. |

**Responsibility boundary:**

Art team delivers clean lossless PNGs. Technical-artist applies compression, sets `.import` flags, approves in-engine results. If compression produces visible artifacts on portrait faces or tile material reads, art director reviews the engine-compressed result and makes an approval call.

---

### 8.2 Naming Convention
*Anchors to: P1 — Victory Through Preparation*

**Philosophy: descriptive-first, structurally consistent.** Names communicate content before pipeline position.

Master pattern: `[category]_[identifier]_[variant].[ext]`

**Character portraits**

`char_[officer-slug]_[state]_portrait.png` — `portrait` is a type designator, not a size.

Examples: `char_kaster_base_portrait.png` / `char_kaster_defeat_portrait.png` / `char_zhuge-jian_base_portrait.png` / `char_generic_scholar_01_portrait.png`

**Character sprites**

`char_[officer-slug]_icon.png` (campaign icon) / `char_[officer-slug]_sprite_hex.png` (tactical hex sprite)

**Campaign map tiles**

`env_tile_[terrain-type]_[season]_[control-state].png` — All three variables mandatory. A tile file omitting any variable is incomplete and rejected at handoff.

Normal/roughness maps: season token replaced with `shared`.
`env_tile_plains_shared_nm.png` / `env_tile_plains_shared_rm.png`

**Tactical battle tiles**

`env_battle_[terrain-type]_[variant].png` — No season token (season inherited from campaign state). `[variant]` = `base` for standard; authored-peak mission slug for authored variants.
`env_battle_plains_fireplan.png` / `env_battle_city_arctos.png`

**Settlement props**

`env_prop_[prop-type]_[damage-state].png` — damage states: `intact`, `damaged`, `destroyed`, `charred`

**UI elements**

`ui_[element-type]_[variant]_[size].png` — size token (`sm`, `md`, `lg`) required when multiple sizes exist; omit for single-size elements.

**General rules:**

- All slugs: lowercase, hyphen-separated, no spaces, no camelCase
- Officer slugs must match `assets/art/characters/README.md` exactly
- Any deliverable file containing `_v2`, `_final`, or `_FINAL2` is a source file not cleaned before handoff — reject at QA

---

### 8.3 Texture Resolution and Compression
*Anchors to: P1 — Victory Through Preparation*

**Resolution preference** states the art team's minimum acceptable canvas for information delivery at intended viewing distance. **Compression format** is the technical-artist's hard constraint for Forward+ / PC Steam / D3D12.

| Asset Category | Canvas | VRAM compression | Mip maps | Notes |
|---|---|---|---|---|
| Character portraits | 512×640px | BC7 (BPTC) | OFF | `compress/high_quality=true` required — BC1/BC3 produces visible blocking on painterly brush edges |
| Campaign icons | 64×64px — hand-authored, not downscaled | BC7 | OFF | Atlas: 512×512 (64 icons/page) |
| Tactical hex sprites | 32×40px — hand-authored | BC7 | OFF | Atlas: 512×512 (128+ sprites/page) |
| Campaign map tiles — albedo | 256×256px | BC7 | ON (full chain, anisotropic 4×) | 3 albedo variants per terrain type (Dry/Wet/Harvest) |
| Campaign map tiles — normal | 256×256px | BC5 (RG channels) | ON | `compress/normal_map=1` non-negotiable — sets BC5 AND renderer normal-map hint flag |
| Campaign map tiles — roughness | 256×256px | BC4 (single channel) | ON | `compress/channel_pack=1` for BC4 |
| Tactical battle tiles | 256×256px — all maps | Same as campaign tiles | ON | Arctos authored-peak tiles exception: 512×512 |
| Settlement props | 64×64 – 128×128px within atlas | BC7 | ON | Atlas: 1024×1024 |
| UI elements | 512×512px panels; 512×640px portrait frame | BC7 | OFF | 3 atlas pages × 2048×2048. Fixed display size — no mip needed |
| Resource/ability icons | 64×64px | BC7 | OFF | Shared atlas with UI |
| Character sprite atlases | 512×512px per page | BC7 | OFF | |

**[TA: Portrait resolution at 1440p]**: The 512×640 canvas will upscale ~1.5× at 1440p. For the semi-realistic painterly style this is acceptable — soft edges are inherent to the aesthetic and 1.5× upscaling is largely indistinguishable from native at this register. No dual-resolution portrait pipeline required.

**[TA: Shader Baker — required]**: With 12–15 terrain types × 3 seasons × 3 material maps, the shader variant count will produce visible first-encounter stutter without pre-compilation. Shader Baker (Godot 4.5+) must be enabled at export: `Project Settings → Rendering → Shaders → Shader Compilation Mode = Synchronous with Cache`. Verify path against engine reference docs.

**[TA: D3D12 Windows default in 4.6]**: BC7 and BC5 are fully supported on D3D12 — compression format choices above are unaffected. Any shader using Vulkan-specific extensions must be audited before release.

---

### 8.4 LOD Expectations
*Anchors to: P2 — Officers Are the Story + P1 — Victory Through Preparation*

**The design-in-reverse mandate** (Section 5.4) applies to all asset categories. Design at the minimum viable LOD first; confirm the design holds at each step up.

**Character named officers — three LOD levels**

*LOD 0 — Portrait (512×640):* All channels active. Minimum readable: individual face identity, SW-05 presence, primary silhouette interruption, costume archetype (military/scholar/civilian), posture read.

*LOD 1 — Campaign Icon (64×64):* Must preserve: faction temperature (SW-05 warm note as area impression), primary silhouette interruption, named-vs-generic distinction. **Production blocker**: Zhuge Jian fallback decision (hanfu sleeve vs. guan cap at this scale) must be documented and locked before LOD 1 is signed off. Cannot be deferred.

*LOD 2 — Tactical Hex Sprite (32×40):* Must preserve: faction color temperature, named-vs-generic read (one shape irregularity vs. compact mass), scholar-vs-military archetype for Zhuge Jian. **Requirement**: Generic unit sprites must be authored as the visual mass counterpart to named officer sprites. A named hex sprite without its corresponding generic unit baseline is incomplete — not a shippable deliverable.

**Generic officers:** Two effective LOD levels. Must not read as named. If a generic sprite reads as an individual, it undermines the visual hierarchy.

**Campaign map tiles — two relevant zoom levels**

*Near zoom (tile inspection):* Material-class distinction (limestone/timber/earth/vegetation), faction tint in built structures, individual prop silhouettes at designed density.

*Far zoom (campaign survey):* Season structural read from tile silhouette. Faction identity from built-structure tint alone. Prop density category readable (high/medium/low) without individual props being distinguishable.

**Hard requirement**: Season structural distinction must survive far zoom. If Dry/Wet/Harvest distinction requires near-zoom to read, redesign the tile silhouette before adding albedo detail.

**Settlement props — damage state legibility**

Each damage state must be readable from shape, not only texture. A charred granary door reads from geometry collapse AND albedo shift. A damaged supply crate reads from geometry break AND texture change. Color alone is insufficient for damage-state communication — colorblind accommodation requires shape backup.

---

### 8.5 Export Settings Philosophy
*Anchors to: P1 — Victory Through Preparation*

**Color space:**
- All albedo/color textures: **sRGB color profile**. The engine handles linearization internally at render time. An albedo exported in linear space will appear washed out in Godot.
- Normal maps: **linear color profile, without exception**. Normal maps are data, not color — sRGB encoding destroys normal data. *This instruction appears twice because it is the most common handoff error in painterly pipelines.*

**Alpha channel requirements by category:**

| Category | Alpha required | Reason |
|---|---|---|
| Character portraits | No | Background (SW-04 Pale Administrative) is authored into the texture. `premult_alpha=true` in `.import` — eliminates fringing on portrait edges against dark UI panels |
| Campaign icons | Yes | Placed on map tiles; irregular silhouette requires transparency |
| Tactical hex sprites | Yes | Alpha boundary IS the silhouette — hand-authored, not auto-edge-selected |
| Campaign map / battle tiles | No | Tiles fill hex geometry completely |
| Settlement props | Yes | Must be authored — not auto-edge-selected (produces sub-pixel fringe visible at small prop sizes) |
| UI panels and backgrounds | No | Engine opacity parameter handles UI transparency |
| UI portrait frame | Yes | Frame artwork placed over portrait background |
| Resource/ability icons | Yes | Placed on panel backgrounds |

**Channel packing for normal/roughness maps**: Deferred to technical-artist. Art team exports: normal maps as RGB PNG, roughness as greyscale L PNG.

**What the art team will never do at export**: Apply sharpening in lieu of adequate resolution; reduce bit depth below 8-bit; export at a different resolution than the authored canvas; apply any lossy compression at any pipeline stage.

---

### 8.6 Technical Conflict Resolutions
*[TA:] Six conflicts flagged during technical review. All are resolved below. Implement each resolution as specified before related assets enter production.*

**Resolution 1 — Faction Territory Tinting**

Art preference (Section 6.2): SW-02 and SW-06 faction tints as a material decision on built structures — tint persists through lighting changes between game states.

Technical constraint: Per-tile faction material instances break draw call batching.

Resolution: Implement faction tinting as a second-pass screen-space overlay. Render terrain first (shared material — 1 draw call per material variant). Render faction tint overlay as a second pass using a `Sprite2D` at SW-02 or SW-06 at 15–20% opacity covering settlement tiles only. Cost: 2–3 additional draw calls for the entire overlay pass. Preserves the art director's material-decision intent (tint is a layer separate from world lighting).

---

**Resolution 2 — Arctos Mist Distance Gradient**

Art preference (Section 6.5): SW-07 Mist Lead overlay at distance-based opacity (15% / 35% / 55% with distance), per-turn update.

Technical constraint: Per-tile opacity materials break batching.

Resolution: Implement as a `CanvasLayer` screen-space overlay with a gradient texture baked per-turn into a 64×64 texture. Single draw call for the entire fog layer. CanvasLayer sits above terrain tiles, below UI panels. Coordinate with engine programmer for CanvasLayer ordering and the fog-of-war update cycle.

---

**Resolution 3 — Duel Background Desaturation**

Art preference (Section 2, Cross-State Rule 3): Background desaturation is "an art-pass material decision, not a real-time screen effect."

Resolution (incorporated in Section 7.5): `ShaderMaterial` `uniform float saturation` parameter tweened 1.0 → 0.05 over 2–3 frames when Duel state activates. Per-material shader parameter — not the `Compositor` post-process chain. Zero additional VRAM cost.

---

**Resolution 4 — Fire Plan Glow Interaction (Godot 4.6)**

Technical constraint: In Godot 4.6, glow now processes before tonemapping (changed from 4.3). At the Fire Plan ambient peak (6800K), materials with any emission value may inadvertently trigger glow.

Resolution: Set `WorldEnvironment.glow_enabled = false` globally for all scenes in this project. The art bible prohibits glow (Section 1, Supporting Principle 2) — the engine must be configured to enforce this. Do not rely on low emission values to avoid triggering glow at warm ambient peaks. Verify that explicitly-disabled glow behaves correctly under the 4.6 glow-before-tonemapping change.

---

**Resolution 5 — Pattern Overlay for Colorblind Faction Read**

Art preference (Section 4.5): Player territory = fine horizontal-rule texture (15–20% opacity); enemy territory = fine diagonal-rule texture; neutral = no texture.

Technical constraint: Per-tile overlay sprites break batching.

Resolution: UV-tiling shader on the shared terrain material. The terrain shader samples a tileable 32×32 or 64×64 rule-pattern texture on a second UV channel. `uniform float pattern_type` controls which pattern (0.0 = none, 1.0 = horizontal, 2.0 = diagonal); `uniform float pattern_opacity` controls weight (0.15–0.20). Two pattern textures authored. Zero draw call cost increase if added to the initial terrain shader spec. **Must be designed into the initial terrain shader — cannot be retrofitted.**

---

**Resolution 6 — Automated Pipeline Validation**

The following checks are implementable as a GDScript tool script or Python pre-commit hook scanning `assets/textures/` before export:

1. **Resolution check**: Portrait files = exactly 512×640. Icon files = exactly 64×64. Tile files per naming convention = specified canvas sizes. Violation = pipeline error.
2. **Normal map companion check**: Every `env_tile_[type]_albedo.png` must have a corresponding `env_tile_[type]_shared_nm.png`. Missing = pipeline error.
3. **Import preset validation**: Every `.png` in `terrain/normals/` must have a companion `.import` containing `compress/normal_map=1`. Every albedo `.import` must contain `mipmaps/generate=true`. Mismatch = pipeline error.
4. **Portrait state completeness**: Every `char_[officer]_base_portrait.png` must have `char_[officer]_defeat_portrait.png`. Missing defeat portrait = pipeline warning (advisory).
5. **Icon greyscale legibility**: Convert each `icon_*.png` to greyscale. If no two distinct foreground regions differ by >30 brightness units, flag for manual deuteranopia review. Soft block (human review, not auto-reject).

---

## Section 9: Reference Direction ✅

*Five references. Each points a different direction. Together they span the game's full visual surface: character art, environmental logic, document/typographic aesthetic, light and atmosphere, and — critically — the boundary case that defines what this game refuses to be. No reference here should be treated as a style target in full. Each is a specific technique extracted from a larger aesthetic whole, one that would be wrong if applied wholesale.*

---

### 9.1 Romance of the Three Kingdoms XIII (Koei Tecmo, 2016) — Character Portrait Rendering

**What to draw from it:** RoTK13's officer portraits achieve a specific balance between academic finish and craft legibility — forms are resolved with enough material specificity (fabric folds, metal hardware, skin at varied temperatures) that the face reads as a living person, while the brushwork remains organized rather than photographic. The technique that transfers directly: **edge control as hierarchy**. Edges in RoTK13 portraits are hard where a form competes for read against an adjacent form of similar value, and soft where a form is receding or subordinate. This is not global softness (painterly as "blurry") or global hardness (photobashing as "sharp everything") — it is a decision made edge-by-edge, form-by-form. The result is that the face, hands, and primary identifying costume elements carry hard edges, while background fabric and ambient forms dissolve. For Kaster's War, this technique solves the primary character art problem: portraits must be information-dense but the eye must be directed to the identifying features (silhouette interruption, SW-05 placement, face) without them being labeled.

**What to avoid:** RoTK13's color language is warm-dominant and tonally loud — portraits use full-saturation reds, golds, and rich purples as primary costume colors for player characters. This creates visual energy appropriate for a game about the drama of dynastic politics, but it would violate the palette contract of Kaster's War (Section 4, core rule: warmth is earned, not ambient). The influence from RoTK13 is rendering technique and edge logic only — not color saturation, not compositional warmth, not the heroic-frontal gaze many RoTK13 officers carry. Kaster's War officers attend to something off-screen; they do not address the viewer.

*Anchors to: P2 — Officers Are the Story*

> **Design test**: Compare a finished Kaster's War officer portrait to a comparable RoTK13 officer portrait at matched canvas size. The Kaster's War portrait must deploy edge control in the same selective manner — hard where identifying, soft where subordinate — but must have a lower average saturation reading when both images are put through a histogram analysis. If the Kaster's War portrait reads as equally warm and chromatically saturated, the influence has been taken too broadly.

---

### 9.2 Waterloo (Bondarchuk, 1970) — Environmental Mass and the Intelligence-Delivering Landscape

**What to draw from it:** Bondarchuk's Waterloo is the closest visual precedent for how terrain in Kaster's War should function: as a document the player reads before committing. In the film, the landscape around the ridgeline of Mont-Saint-Jean is established in early scenes not as scenic backdrop but as a legibility problem — Wellington's position reads clearly from elevation structure, Napoléon's decision to advance is visible as a physical mistake because the audience has already been taught to read the ground. The specific technique: **topographic primacy**. The camera in Waterloo treats terrain as the primary information layer; characters and units are overlaid on it. The ridge, the sunken road, the farmhouse of Hougoumont — these are established before the battle so the player (viewer) can track what is happening geographically without a map. For Kaster's War, this means terrain features that will matter tactically must be visually established in the Preparation Phase preview not as "interesting detail" but as legible structure: the hill that will anchor the left flank, the road that exposes the enemy march route, the ford that determines where cavalry can cross. The terrain's visual prominence in the composition signals tactical importance without a label.

**What to avoid:** Waterloo's production rests partly on scale that cannot be replicated in 2D hex tiles — its visual authority depends on thousands of actual soldiers and full-scale props. The mistake would be to import the film's compositional grammar (deep-focus epic wides, horizon-dominant framing, tiny figures in vast fields) as a literal texture or compositional template for campaign map tiles. The intelligence-delivery principle transfers; the cinematic scale does not. Soliterra is an island smaller than Corsica — its tactical battles are small enough that a commander would know every major terrain feature by name. The maps must read as *personally known ground*, not as surveyed-from-a-balloon landscape.

*Anchors to: P1 — Victory Through Preparation + P3 — Grounded, Barely Fantastic*

> **Design test**: Show the Preparation Phase tactical preview for Open Field to a player who has not yet been told what the battle's tactical problem is. Without UI labels, they must be able to identify: (1) one terrain feature they would want to anchor to, and (2) one terrain feature that represents a risk. If neither read is achievable from tile composition alone, the topographic primacy principle has not been applied.

---

### 9.3 Napoleonic Staff Cartography, 1800–1815 — UI Document Aesthetic and Typographic Register

**What to draw from it:** The Dépôt de la guerre maps, British Ordnance Survey campaign sheets, and regimental quartermaster registers of the 1800–1815 period constitute one of the most functionally refined information-design traditions in European history. The visual technique that transfers: **every graphic element earns its position by carrying information, with hierarchy communicated entirely through line weight and letterform scale.** These documents use no color (or minimal color for territory boundaries only), no decoration that is not also notation, no typeface that prioritizes personality over legibility. The ruled box is the basic organizational unit. Column alignment is the mechanism for fast data parsing under field conditions. The transitional serif — specifically the high-contrast thick-thin stroke of Bodoni/Didot — was developed and refined during exactly this period for exactly this class of printing. For Kaster's War, these documents are not a mood-board reference — they are the functional ancestor of the UI grammar. The Campaign Map's ledger strip, the Preparation Phase's card-grid ruled borders, the Turn Counter notation format: all of these should trace directly back to period document conventions, not as pastiche but as the *original functional solution to the same problem* — presenting strategic information to a decision-maker under time pressure.

**What to avoid:** Period cartography occasionally features ornamental cartouches, allegorical figure borders, and decorative compass roses that are the product of publisher convention, not military function. These elements survive in museum reproductions and are visually appealing as "period flavor." They must not enter the Kaster's War UI. Any decorative element that cannot be justified as an information-delivery mechanism — a flourish, a crowned cartouche, a figurative border illustration — is outside vocabulary. The reference is operational military documents (field use), not publisher cartography (exhibition use). The distinction: a hand-drawn map prepared for Wellington's staff in the field versus a commemorative printed map prepared for Parliament.

*Anchors to: P1 — Victory Through Preparation + P4 — Authored Peaks, Player Valleys*

> **Design test**: Print the Campaign Map UI panel layout in greyscale. Compare it against a period regimental register or staff map. The Kaster's War layout must be immediately legible as belonging to the same visual tradition: ruled divisions, tabular value columns, consistent line weight hierarchy, transitional serif lettering. If the comparison reveals that the Kaster's War panels use UI conventions from a different era (rounded containers, icon-led hierarchy, modern sans-serif), the document grammar has been underapplied.

---

### 9.4 Andrew Wyeth, Tempera Paintings 1940–1965 — Atmospheric Light as Psychological State

**What to draw from it:** Wyeth's mature tempera work is the primary atmospheric reference for how the game's light states should function as psychological signals without becoming theatrical. The specific technique: **low-affect, factual light that accumulates into mood rather than announcing it.** Wyeth's paintings use cold northern or overcast light not as a mood enhancement layer but as the physical truth of what the world looks like under those conditions. The mood arrives not from dramatic lighting choices (golden hour, chiaroscuro, atmospheric haze) but from the *consequences of accurate light on specific surfaces*: the way overcast diffusion kills shadow and makes the geometry of a hillside read purely from form changes; the way a cold interior light flattens a face against a pale wall into near-monochrome. For Kaster's War, this is precisely the atmospheric model for the Campaign Map's 4800–5200K overcast state and the Victory/Defeat screens' quiet endings. The world is not flattering itself. The light is what it is. Emotional content accumulates from the specificity of what is visible under that light, not from the light being dramatically arranged.

**What to avoid:** Wyeth's work carries an unmistakable American regionalist identity — the particular architecture of Pennsylvania German farmsteads, the clothing of his specific neighbors and family, the specific quality of light in southeastern Pennsylvania. This cultural and geographic specificity must not be imported as a visual template for Soliterra's built environment. The island vernacular architecture (grey coastal limestone, clay-tile roofs, compact Mediterranean-pattern clustering) has a completely different regional character. The influence is restricted to *how Wyeth uses light as psychological register* — the principle that factual, non-dramatic light can carry intense emotional content through accuracy rather than spectacle. Subject matter, architecture, and material palette are entirely inapplicable.

*Anchors to: P3 — Grounded, Barely Fantastic + P4 — Authored Peaks, Player Valleys*

> **Design test**: Compare the Campaign Map light state and the Defeat screen light state. Both use cool-neutral diffuse light at low contrast. The emotional difference between them — the Campaign Map's administrative patience versus the Defeat screen's accountable stillness — must arrive from compositional content alone (what is on screen, how much of it, how organized) and not from any difference in light temperature or dramatic quality. If the only way to distinguish the two states emotionally is to change the light, the Wyeth principle has not been applied. The light is the same; the world under it has changed.

---

### 9.5 XCOM 2 (Firaxis, 2016) — The Negative Reference: What Kaster's War Is Not

**What to draw from it:** Nothing. This reference functions exclusively as a boundary marker — a precisely-specified account of the visual language that this game refuses to share, even where the games' mechanical DNA overlaps. XCOM 2 is the genre-defining modern turn-based tactical strategy game, and its visual signature — lens flares on alien technology, particle-heavy ability VFX, chromatic aberration on soldier injuries, animated UI panels with glowing edges, teal-and-orange color grading across all game states, motion-blur on camera transitions, full-screen flash on kill confirmations — is so thoroughly established that it functions as a cognitive default for the genre. Artists joining this project, players previewing screenshots, and UI programmers implementing interaction states will have XCOM 2's visual register in working memory as "what a turn-based tactics game looks like." This reference exists to name that default explicitly and reject it in full.

**What to avoid:** Every element of the XCOM 2 visual language. Specifically: glow of any kind on any element in any state (this prohibition is already absolute in Section 1 and is stated here for the third time because XCOM 2 is the most likely source of unconscious genre contamination); particle VFX attached to ability use, status effects, or officer actions; chromatic aberration as a state-change or injury signal; animated UI borders or pulsing panel edges; screen-space color grading that shifts the overall image temperature as a mood tool; kill or critical-hit confirmation effects with screen flash or slow-motion; teal-orange color contrast as a compositional default; and the heroic power fantasy portrait style in which officers face the viewer with expressions of confident combat readiness. Kaster's War shares with XCOM 2 the presence of named officers, a hex-adjacent tactical grid, and high-stakes tactical decisions. It shares none of XCOM's visual premise: that war is a spectacular, high-energy, kinetically exciting experience in which the player is empowered and the world responds with drama.

*Anchors to: P3 — Grounded, Barely Fantastic + P2 — Officers Are the Story*

> **Design test**: Produce any screen from Kaster's War — portrait review, tactical combat, Preparation Phase — and place it side by side with a comparable XCOM 2 screenshot. The two images must read as products of opposing visual philosophies. If any element of the Kaster's War screenshot could be transplanted into the XCOM 2 screenshot and read as visually consistent — a glowing border, a color-graded ambient, a particle trail on an ability icon — that element has violated the genre boundary and must be removed.

---

### Cross-Reference Summary

| Section | Reference | Primary Visual Domain | Pillars |
|---|---|---|---|
| 9.1 | RoTK XIII | Character portrait rendering — edge control as hierarchy | P2 |
| 9.2 | Waterloo (Bondarchuk, 1970) | Environmental mass — terrain as intelligence document | P1, P3 |
| 9.3 | Napoleonic staff cartography | UI/typography — operational document grammar | P1, P4 |
| 9.4 | Andrew Wyeth, tempera 1940–65 | Atmospheric light — factual, accumulated, non-dramatic | P3, P4 |
| 9.5 | XCOM 2 | Negative reference — genre boundary | P3, P2 |
