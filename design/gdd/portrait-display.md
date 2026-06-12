# Portrait & Character Display System

> **Status**: Designed
> **Author**: Art Director + UX Designer (lean mode)
> **Last Updated**: 2026-06-12
> **Implements Pillar**: P2 — Officers Are the Story

## Overview

The Portrait & Character Display System is the reusable "character card" component that presents officer identity — portrait image, name, five-stat block, passive abilities, assignment status, and growth indicators — across every UI context that surfaces officer information. It is not a screen; it is a shared display component that the Tactical HUD, Campaign Map UI, Preparation Phase UI, Recruitment screen, and Army Management screen each embed. The system operates in three rendering tiers — Full Panel, Compact Bar, and Miniature Icon — each appropriate for different information density needs. The component reads officer data from the Officer Stats System and passive data from the Officer Passive Ability System; it owns no game state and makes no gameplay decisions. Its central design constraint is the Heirloom Blade rule: Kaster's hidden passive must never appear in any player-facing panel, list, tooltip, or text — not under any circumstances.

## Player Fantasy

*Lean mode: `creative-director` not consulted — review against art bible and game pillars before production.*

P2 says officers ARE the story. The portrait is where that promise is kept or broken. A neoclassical oil painting of Alexsen tells the player everything before a single stat is read — the set jaw, the armor style, the color palette. But the stat block must immediately reinforce what the portrait implies: WAR 98 should not surprise anyone who looked at the portrait first. The two systems work together; the portrait is the emotional beat, the numbers are the confirmation.

The fantasy this system serves is **recognition** — the sensation of knowing your officers. After 10 hours with the game, seeing Alexsen's portrait at the edge of a tactical map should make the player feel a specific kind of confidence (or dread, if he's in the wrong position). The display system earns this by being consistent: same portrait, same five numbers, same layout every time Alexsen appears. Familiarity breeds attachment.

The compact and miniature tiers serve a different purpose: **scanning**. A player managing a complex Campaign Map needs to find "who has the highest POL here" in under three seconds. The compact bar exists to enable that scan without requiring the player to open every officer's full panel. The stats must be legible at small sizes — which constrains both font size and bar contrast more than visual elegance does.

The Heirloom Blade constraint is a player fantasy decision too. The mystery of Kaster's second passive — something happening in combat that has no explanation — is a P3 (Grounded, Barely Fantastic) story beat. The display system preserves it by rendering Kaster's passive section with only "Read the Field" and leaving no visual gap or "?" placeholder that would signal a hidden second entry. Absence of information is the design; a missing slot would be information.

## Detailed Design

### Core Rules

**Three Rendering Tiers:**

The character card is implemented as a single configurable component with three rendering modes. Calling code specifies the tier and optional context type; the component handles layout and information density accordingly.

```
PortraitCard.render(
    officer: Officer,
    tier: PortraitTier,         # FULL | COMPACT | MINIATURE
    context: DisplayContext,    # CAMPAIGN | TACTICAL | DIPLOMATIC | RECRUITMENT
    show_stats: Array[StatKey]  # optional override — omit to use tier defaults
)
```

---

**Tier 1: Full Panel**

Used in: Campaign Map officer inspector, Army Management screen, Recruitment screen.

Information displayed in full panel:
1. **Portrait image** — full-size neoclassical painting (see Visual/Audio Requirements). Artist's expression conveys character.
2. **Name label** — full officer name. Named officers use their canonical name; generic officers use a generated name.
3. **Title / Role label** — one-line current assignment (e.g., "Governor of Kasterfall", "Commander, 2nd Army", "Available"). Derived from campaign state, not from Officer Stats.
4. **Five-stat block** — all five stats displayed:
   - WAR, LDR, INT, POL, CHR — each as an integer [1, 100]
   - Each accompanied by a proportional bar (fill = stat_value / 100)
   - Growth indicator: a small delta symbol (▲) appears next to any stat that has grown above its Prologue baseline value
   - Stats are listed in canonical order: WAR · LDR · INT · POL · CHR
5. **Passive ability list** — all player-visible passive abilities, by name only (no mechanical description in the list itself). On hover, a tooltip shows a 2-sentence description.
   - Named passives: listed by display name (e.g., "Read the Field", "Juggernaut", "Shadow Work")
   - Generic passives (if any): listed by display name
   - **HEIRLOOM BLADE CONSTRAINT**: Kaster's `heirloom_blade` passive MUST NOT appear anywhere — not in the list, not as a blank entry, not as a "???" placeholder. The passive list renders exactly and only the passives returned by `officer.get_display_passives()`. The Officer Passive Ability System's `get_display_passives()` method never returns `heirloom_blade` — it is filtered out at the data layer, not at the rendering layer. The rendering layer has no special case for it; the constraint is enforced upstream.
6. **Act stage indicator** — a small label showing the current act (e.g., "Act II") and how many growth events have occurred. Does NOT show future growth or amounts.
7. **Availability badge** — if the officer is unavailable (e.g., 2-turn diplomatic duel injury), an overlay badge reading "Injured — N turns remaining" appears over the portrait.

**Tier 2: Compact Bar**

Used in: Tactical HUD unit inspector, Preparation Phase officer list, Army roster sidebar.

Information displayed in compact bar:
1. **Portrait thumbnail** — cropped to face (64×80 px), same portrait asset as Full Panel, different crop region.
2. **Name label** — officer name, truncated if necessary.
3. **Context-sensitive stats** — 2–3 stats selected by `DisplayContext`:
   - `TACTICAL`: WAR + LDR (combat effectiveness reads)
   - `DIPLOMATIC`: CHR + INT (persuasion reads)
   - `RECRUITMENT`: all 5 stats, but at reduced font size and smaller bars
   - `CAMPAIGN`: INT + POL (strategic reads)
4. **Morale state badge** (TACTICAL context only) — shows the officer's current squad morale state: STEADY / SHAKEN / BROKEN. Color-coded: green / yellow / red.
5. **Passive names** — listed below stats, as a comma-separated one-liner (no hover tooltip in compact view). Truncated to ~30 characters.

**Tier 3: Miniature Icon**

Used in: Army roster list items, City governor slot, Campaign map squad hex indicator.

Information displayed in miniature:
1. **Portrait thumbnail** — very small (32×40 px), face-cropped. Circular mask optional (per calling screen).
2. **Name label** — short form (first name or initials only).
3. **No stats shown** — stats are accessible by hover (triggers a compact bar tooltip) or by clicking through to the full panel.
4. **Status dot** — a small colored dot indicating availability: green = available, orange = on assignment, red = injured/unavailable.

---

**Information Hierarchy Rules (across all tiers):**

- The portrait image is always present (never omitted, even at miniature tier).
- If a portrait asset is missing for an officer, a silhouette placeholder renders (see Edge Cases).
- Stats are always displayed as integers — never as fractions, percentages, or letter grades.
- The five stat names (WAR / LDR / INT / POL / CHR) are always abbreviated, never spelled out — space is scarce in compact/miniature tiers.
- Passive abilities are only named, never mechanically described in the list itself — always in a tooltip on hover.
- The Heirloom Blade constraint applies at ALL tiers. No tier reveals it.

---

**Display Name vs. Mechanic Name:**

The portrait system uses display names for passives (as stored in `passive_config.json` under `display_name`). The internal mechanic ID (e.g., `"read_the_field"`, `"heirloom_blade"`) is never surfaced to the player. The `get_display_passives()` interface returns only display names and descriptions for passives that have `is_player_visible: true`. Heirloom Blade has `is_player_visible: false`.

### States and Transitions

The Portrait & Character Display System is a stateless display component — it has no internal state machine. Each call to `PortraitCard.render()` produces a fresh render from current officer data; there is no "open/close" transition owned by this component.

**Officer display states (derived from campaign state, not owned here):**

| Display State | What triggers it | Visual indicator |
|---------------|-----------------|-----------------|
| Available | Officer has no current assignment | No badge |
| On Assignment | Officer is in active army or governing a city | No badge (role label shows assignment) |
| Injured | Officer lost a diplomatic duel; `unavailable_turns > 0` | "Injured — N turns" badge over portrait |
| Dead | Officer death (named officers are not killed — N/A for named officers; generic officer death removes them from roster) | Card is not rendered (removed from roster) |

**Availability badge transition:** When `officer.unavailable_turns` decrements to 0 at the end of a campaign turn, the badge disappears. No animation — the badge is present or absent; there is no fade.

**Growth indicator transition:** When an act transition fires and a stat increases, the delta symbol (▲) appears next to the grown stat. It persists for the remainder of the campaign; it does not disappear after the player views it. The ▲ marks that the stat is above Prologue baseline — it is informational, not a "new" alert.

### Interactions with Other Systems

| System | This Component Reads | This Component Writes |
|--------|---------------------|----------------------|
| **Officer Stats System** | `officer.war`, `officer.ldr`, `officer.int_stat`, `officer.pol`, `officer.chr`, `officer.name`, `officer.portrait_path`, `officer.prologue_stats` (baseline for growth indicator) | — (read-only) |
| **Officer Passive Ability System** | `officer.get_display_passives()` — returns array of `{display_name, description}` for passives with `is_player_visible: true` | — (read-only). The heirloom_blade filter is upstream — this component never sees it |
| **Campaign State** (not yet designed) | `officer.current_assignment`, `officer.unavailable_turns`, `current_act` — for role label, injury badge, growth indicator | — (read-only) |
| **Tactical HUD** | — | Provides character card component for the unit inspector panel |
| **Campaign Map UI** | — | Provides character card component for the officer detail panel |
| **Preparation Phase UI** | — | Provides character card component for officer selection |
| **Recruitment Screen** | — | Provides character card component for recruitment candidates |

**Portrait asset path convention:**
- Named officers: `assets/art/portraits/[officer_id]_full.png` (full panel) and `assets/art/portraits/[officer_id]_thumb.png` (pre-cropped thumbnail)
- Generic officers: `assets/art/portraits/generic_[archetype]_[variant].png` — variants allow multiple portrait options per archetype (e.g., `generic_warrior_01.png`, `generic_warrior_02.png`)
- Fallback: `assets/art/portraits/silhouette_[archetype].png` (gray silhouette used when specific portrait is unavailable)

**Interface contract:**

The component is a pure display node — calling code provides data, component renders, no callbacks. Calling code handles open/close events and panel transitions; the character card does not know what screen it is embedded in.

## Formulas

*Lean mode: display-only derivations; no new game-math introduced. All gameplay values are read from Officer Stats System and referenced, not redefined.*

---

### F-1: Stat Bar Fill Fraction

```
stat_bar_fill = float(stat_value) / 100.0
```

**Variables:**
| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| Stat value | stat_value | int | [1, 100] | Current stat value from Officer Stats System |
| Bar fill fraction (output) | stat_bar_fill | float | [0.01, 1.0] | Proportion of the bar that is filled |

**Output range:** 0.01 (stat = 1, minimum fill) to 1.0 (stat = 100, full bar).
**Note:** Stat value 1 produces a 1% fill — the bar is never completely empty (a stat of 1 is not "zero"). This preserves information: an empty bar would imply the officer has NO capability, which is not true even at stat = 1.
**Example:** Alexsen WAR 98 → fill = 0.98 (nearly full bar). Zhuge Jian WAR 30 → fill = 0.30 (30% bar).

---

### F-2: Stat Bar Color Tier

```
bar_color = "green"  if stat_value > 60
          = "yellow" if stat_value > 40
          = "red"    if stat_value ≤ 40
```

**Variables:**
| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| Stat value | stat_value | int | [1, 100] | Current stat value |
| Bar color (output) | bar_color | enum | green/yellow/red | Color tier for the stat bar |

**Thresholds are tunable** (see Tuning Knobs). Color transition between tiers is a discrete snap, NOT a lerp — stats are integers, so the color changes at a defined threshold value.
**Rationale:** The color communicates "is this officer strong or weak in this stat at a glance." Green = serviceable to excellent (61–100), Yellow = below average (41–60), Red = low (1–40).

---

### F-3: Growth Indicator Visibility

```
growth_visible = (current_stat_value > prologue_stat_value)
```

**Variables:**
| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| Current stat value | current_stat_value | int | [1, 100] | Current value, post-growth |
| Prologue baseline value | prologue_stat_value | int | [1, 100] | The fixed starting value from `assets/data/officers.json` |
| Growth visible (output) | growth_visible | bool | true/false | Whether the ▲ indicator appears next to this stat |

**Example:** Kaster WAR baseline = 82. After Act I→II growth of +2, current WAR = 84. `84 > 82` → ▲ visible next to WAR.
**Note:** This formula uses the Prologue baseline (the constant in `officers.json`), NOT the value at the start of the current act. Once a stat grows, ▲ remains visible for the rest of the campaign — it marks "above original" not "recently grown."

---

### F-4: Thumbnail Crop Region

Portrait thumbnails (used in Compact and Miniature tiers) are derived from the full portrait image via a fixed crop specification per officer:

```
thumb_region = {x: crop_x, y: crop_y, w: crop_w, h: crop_h}
```

**Variables:**
| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| Crop origin X | crop_x | int | [0, full_portrait_w] | Leftmost pixel of the face region in the full portrait |
| Crop origin Y | crop_y | int | [0, full_portrait_h] | Topmost pixel of the face region |
| Crop width | crop_w | int | [1, full_portrait_w] | Width of the face region |
| Crop height | crop_h | int | [1, full_portrait_h] | Height of the face region |

**Output:** A texture region that, when scaled to 64×80 px (Compact) or 32×40 px (Miniature), shows the officer's face legibly centered.

**Per-officer crop coordinates** are defined in `assets/art/portraits/portrait_config.json` by the art director, not this GDD. This GDD specifies the convention; the exact pixel values are art production data.

**Pre-cropped thumbnails:** When possible, art production delivers pre-cropped `[officer_id]_thumb.png` assets to avoid runtime crop computation. The crop formula is the fallback for assets that only exist in full size.

## Edge Cases

| # | Situation | Rule |
|---|-----------|------|
| E-01 | **Portrait asset file is missing or fails to load** | Silhouette placeholder renders: a gray outline of a human form appropriate to the officer's archetype (e.g., `silhouette_warrior.png`). The name label, stats, and all other data still render normally. No error is surfaced to the player. Error logged to output. |
| E-02 | **Generic officer has no portrait variant assigned** | Use `generic_[archetype]_01.png` as the default fallback. If that also fails, use the archetype silhouette. |
| E-03 | **Stat value is exactly at a color threshold (e.g., stat = 60)** | `stat_value > 60 = false` → yellow (not green). `stat_value > 40 = true` → yellow. Boundaries are exclusive on the upper side (green is > 60, not ≥ 60). Consistent with F-2. |
| E-04 | **Stat value is 100 (maximum)** | Bar is completely filled (fill = 1.0, green). No special "max" indicator or star — 100 is a reachable value, not a special UI state. |
| E-05 | **Stat value is 1 (minimum)** | Bar fill = 0.01 (1% width). Bar is visible as a thin sliver, red zone. This communicates "almost nothing" without implying "zero." |
| E-06 | **Officer with zero player-visible passives (generic, no passive assigned)** | The passive list area in the full panel renders empty — blank row or "None" label in a muted style. No gap or placeholder slot that would imply a hidden entry. |
| E-07 | **Kaster's passive list — Heirloom Blade** | `officer.get_display_passives()` returns only `["Read the Field"]`. The rendering component receives this array and renders exactly one entry. There is no code path in the renderer that checks for Heirloom Blade or handles it specially — the filter is upstream. Attempting to add a second entry for Heirloom Blade at the rendering layer is a design violation. |
| E-08 | **Officer injured from diplomatic duel (unavailable_turns > 0) shown in full panel** | The "Injured — N turns remaining" badge overlays the portrait (semi-transparent red overlay in the corner or a banner below the portrait). Stats and passives still display normally — injury does not change the stat block. The role label changes to "Unavailable — injured." |
| E-09 | **Named officer shown in Recruitment screen context** | Named officers are not recruitable (they join via story events). If a named officer's card is shown in the Recruitment context by error, it should still render correctly using the RECRUITMENT display context defaults. No special case error — the component is context-agnostic. |
| E-10 | **Growth indicator on a stat that grew, then was queried before Prologue data is loaded** | `prologue_stat_value` is loaded at game start from `officers.json`. If it is not yet available, `growth_visible = false` (default safe state — show no indicator rather than a false positive). |
| E-11 | **Generic officer with more than one passive (should not occur by spec)** | Render all passives returned by `get_display_passives()`. The component does not enforce a maximum passive count — that constraint is owned by the Officer Passive Ability System. If the system returns 2 passives for a generic officer (data error), both render. |
| E-12 | **Officer name exceeds display width in compact tier** | Truncate to fit with an ellipsis ("…"). The name is fully visible in the full panel; truncation is a compact-tier display compromise only. |
| E-13 | **Officer stat queried while Officer Stats System is not yet initialized** | Returns null. Portrait component renders a loading placeholder (spinning indicator or greyed card). Once officer data is available, re-render. This should never occur in normal play — loading sequence ensures Officer Stats is initialized before any UI is shown. |
| E-14 | **Passive description text exceeds tooltip width** | Tooltip wraps at the component's max width. No truncation — the player must be able to read the full description. If text is very long, the tooltip scrolls or the component adjusts width. This is an art/implementation constraint, not a design limit. |

## Dependencies

### Upstream Dependencies (this system reads from)

| System | Data Consumed | Interface | Hard/Soft |
|--------|--------------|-----------|-----------|
| **Officer Stats System** | All 5 stats (`war`, `ldr`, `int_stat`, `pol`, `chr`), officer name, portrait path, Prologue baseline stats | `Officer` resource object; stat values via `officer.war()`, etc. | Hard |
| **Officer Passive Ability System** | Visible passive names and descriptions | `officer.get_display_passives()` → `Array[{display_name: String, description: String}]`. Returns only passives where `is_player_visible: true`. Heirloom Blade excluded upstream. | Hard (for passive display) |
| **Campaign State** *(not yet designed)* | `officer.current_assignment: String`, `officer.unavailable_turns: int`, `current_act: int` | Provisional interface — will be formalized in Campaign Map GDD. If unavailable, assignment label shows "Unknown" and no growth indicator renders. | Soft |

### Downstream Dependents (this component is used by)

| System | How they use this component | Notes |
|--------|----------------------------|-------|
| **Tactical HUD** | Embeds Compact Bar in the unit inspector panel | Provides `TACTICAL` context — shows WAR + LDR + morale state |
| **Campaign Map UI** | Embeds Full Panel in the officer detail panel | Provides `CAMPAIGN` context |
| **Preparation Phase UI** | Embeds Compact Bar in officer selection list | Provides `CAMPAIGN` context or `RECRUITMENT` context |
| **Recruitment Screen** | Embeds Full Panel for officer candidates | Provides `RECRUITMENT` context |
| **Duel UI** | Uses portrait art and name label (NOT the full character card) | Duel UI has its own layout for portraits — it does NOT embed PortraitCard. It references the same portrait asset (`[officer_id]_full.png`) and follows this system's naming convention. |
| **Army Management Screen** | Embeds Full Panel for officer roster | Provides `CAMPAIGN` context |

### Bidirectionality Note

The Officer Stats GDD lists "Portrait & Character Display" as a downstream dependent of Officer Stats (reads varies, for "display context"). This is consistent with the upstream relationship documented here. No bidirectionality issue.

The Officer Passive Ability GDD owns the `is_player_visible` filter for passives; this GDD consumes it. The constraint is implemented in the Passive Ability System, not the display component.

## Tuning Knobs

All display knobs are in `assets/data/portrait_config.json` (layout and sizing) and `assets/art/portraits/portrait_config.json` (per-officer crop data). Gameplay-affecting constants (stat values, passive effects) are NOT owned here — they are in their respective system configs.

| Knob | Default | Safe Range | Effect if Too Low | Effect if Too High |
|------|---------|-----------|------------------|-------------------|
| `full_panel_portrait_width` | 240 px | [160, 360] | Portrait too small; expression detail lost | Panel too wide; crowds the stat block |
| `compact_thumb_width` | 64 px | [48, 96] | Thumbnail unrecognizable (too small) | Takes up too much horizontal space in compact bar |
| `miniature_icon_width` | 32 px | [24, 48] | Face detail lost completely | Miniature is no longer "mini" |
| `stat_bar_height` | 8 px | [4, 16] | Bar too thin; hard to read color | Bar too tall; crowds the stat row |
| `stat_green_threshold` | 60 | [50, 70] | Green zone too wide; feels like everything is good | Green zone too narrow; stats feel uniformly mediocre |
| `stat_yellow_threshold` | 40 | [30, 50] | Yellow zone too narrow; jumps green → red | Yellow zone too wide; nothing feels critical |
| `passive_display_name_max_chars` | 28 | [20, 40] | Long passive names are truncated confusingly | Names wrap unexpectedly in compact bar |
| `tooltip_max_width` | 240 px | [180, 360] | Tooltip too narrow; description wraps excessively | Tooltip covers too much of the screen |
| `growth_indicator_symbol` | "▲" | N/A (string) | N/A — symbol choice is art direction, not tuning | N/A |
| `injury_badge_opacity` | 0.85 | [0.60, 1.00] | Badge too faint; missed by player | Badge too opaque; obscures the portrait entirely |

## Visual/Audio Requirements

*Visual/Audio is REQUIRED for this system (Character Display / UI category). Lean mode: `art-director` not spawned — review against art bible before production.*

### Visual

| Element | Specification |
|---------|--------------|
| **Portrait style** | Neoclassical oil painting aesthetic (from art bible). Named officers: individual commissions, unique composition and expression per officer. Generic officers: archetype-appropriate painting in a consistent style, 4–6 variants per archetype to avoid visual repetition. |
| **Full portrait dimensions** | 240×300 px minimum canvas (2:2.5 aspect ratio). Art delivered at 2× resolution (480×600 px) for high-DPI displays. |
| **Thumbnail dimensions** | 64×80 px (Compact), 32×40 px (Miniature). Pre-cropped assets preferred; face crop formula is the fallback. |
| **Portrait frame** | A painted or illustrated border (not a plain pixel rect). Named officers may have unique frame details (e.g., gold inlay, army banner). Generic officers share a common archetype-appropriate frame. |
| **Stat bars** | Horizontal bars, 8 px tall (default). Green (`#4CAF50` or art bible equivalent), Yellow (`#FFC107`), Red (`#F44336`). Bars sit below the stat abbreviation and numeric value. |
| **Stat label format** | Abbreviation left, numeric value right (e.g., `WAR   82`). Monospace or tabular number font for alignment. |
| **Growth indicator** | Small "▲" in a distinct accent color (gold/amber) immediately to the right of the numeric value. Does NOT change bar color — it is additive information. |
| **Injury badge** | A semi-transparent red rectangular overlay at the bottom of the portrait, containing the text "Injured — N turns" in white. Width = portrait width. Height = ~20% of portrait height. Opacity: 0.85 (default). |
| **Availability status dot** (miniature tier) | 8×8 px dot in the lower-right corner of the miniature icon. Green = available, Orange = assigned, Red = injured. |
| **Passive list** | Plain text list in the full panel. Each entry: a bullet point, display name, no icon. On hover: tooltip with 2-sentence description in a styled tooltip box. |
| **Silhouette placeholder** | A gray silhouette appropriate to the archetype (e.g., a figure with sword for Warrior, a figure with quill for Scholar). Background matches the standard portrait frame style. |

### Audio

The Portrait & Character Display System has minimal audio — it is a UI display component, not an interactive game system. Audio events are limited to UI feedback:

| Event | Audio Event ID | Notes |
|-------|---------------|-------|
| Full panel opens | `ui/sfx/panel_open` | Standard UI open sound; shared with other panels |
| Passive ability tooltip opens | `ui/sfx/tooltip_show` | Subtle hover chime |
| Panel closes | `ui/sfx/panel_close` | Standard UI close sound |

No unique audio per officer when the portrait is displayed — officer-specific audio is owned by the Story Event System (character voice lines, etc.).

📌 **Asset Spec** — Visual requirements are defined. After the art bible is approved, run `/asset-spec system:portrait-display` to produce per-asset visual descriptions, dimensions, and generation prompts for all 7 named officer portraits and archetype silhouettes.

## UI Requirements

### Full Panel Layout

```
┌────────────────────────────────────────────┐
│ ┌──────────────────┐  Officer Name          │
│ │                  │  Title / Role          │
│ │   PORTRAIT       │                        │
│ │   (240×300 px)   │  WAR  82  ████████░░  │
│ │                  │  LDR  96  ██████████  │
│ │ [Injured badge   │  INT  92  █████████░  │
│ │  if applicable]  │  POL  85  ████████░░  │
│ │                  │  CHR  88  ████████░░  │
│ └──────────────────┘                        │
│                       ▲ = grown since start │
│                                             │
│  Passives:                                  │
│  • Read the Field                           │
│                                             │
│  Act II ▮▮▮░░  [growth events shown]        │
└────────────────────────────────────────────┘
```

### Compact Bar Layout

```
[64×80 thumb]  Officer Name    WAR 82 ████  LDR 96 ████  [STEADY]
```

### Miniature Icon Layout

```
[32×40 thumb]
 Name label (short)
       ●  ← status dot
```

### Component Behavior Table

| Component | Full Panel | Compact Bar | Miniature |
|-----------|-----------|-------------|-----------|
| Portrait | Full size | Face thumbnail | Face miniature |
| Name | Full name | Full name (truncated if long) | First name / initials |
| Role label | Yes | No | No |
| WAR stat | Yes | TACTICAL context only | No |
| LDR stat | Yes | TACTICAL context only | No |
| INT stat | Yes | CAMPAIGN/DIPLOMATIC context | No |
| POL stat | Yes | CAMPAIGN/DIPLOMATIC context | No |
| CHR stat | Yes | DIPLOMATIC context only | No |
| Stat bars | Yes | Yes | No |
| Growth (▲) | Yes | No | No |
| Passive list | Yes | Comma-separated names (abbreviated) | No |
| Passive tooltip | Yes (hover) | No | No (hover = compact bar) |
| Injury badge | Yes | Badge text in role slot | Status dot (red) |
| Act indicator | Yes | No | No |

### Keyboard Navigation

| Context | Key | Behavior |
|---------|-----|---------|
| Full panel open | Tab / D-pad | Cycles focus through stats, passive entries |
| Passive entry focused | Enter / A | Opens tooltip (keyboard users can access tooltip without mouse) |
| Full panel | Escape / B | Closes panel |
| Miniature hovered | Enter / A | Opens full panel |

### Context Behavior

| Display Context | Stats shown in Compact | Notes |
|----------------|----------------------|-------|
| TACTICAL | WAR, LDR | Combat and leadership reads |
| CAMPAIGN | INT, POL | Strategic and governance reads |
| DIPLOMATIC | CHR, INT | Persuasion and intel reads |
| RECRUITMENT | All 5 (small bars) | Comparing officer candidates |

📌 **UX Flag — Portrait & Character Display**: This system has UI requirements. In Phase 4 (Pre-Production), run `/ux-design` to create UX specs for `design/ux/officer-full-panel.md` and `design/ux/officer-compact-bar.md` before writing epics. Stories that reference officer display should cite these UX specs, not this GDD directly.

## Acceptance Criteria

*Lean mode: `qa-lead` not consulted — review manually before production. Covers all core rules (Section C) and display formulas (Section D).*

### Stat Display

1. **GIVEN** Kaster is rendered in Full Panel, **WHEN** the stat block is displayed, **THEN** all five stats read exactly: WAR 82 · LDR 96 · INT 92 · POL 85 · CHR 88 (matching `assets/data/officers.json`).

2. **GIVEN** Kaster's WAR stat (82), **WHEN** the stat bar fill is computed using F-1, **THEN** `fill = 82 / 100 = 0.82` and the bar renders at 82% width in the green color tier (82 > 60).

3. **GIVEN** Thane's CHR stat (45), **WHEN** the stat bar is rendered, **THEN** `fill = 0.45` (yellow zone: 45 > 40 but ≤ 60).

4. **GIVEN** Alexsen's INT stat (40), **WHEN** the stat bar is rendered, **THEN** `fill = 0.40` (red zone: 40 ≤ 40, the threshold is exclusive on the upper side).

5. **GIVEN** any officer's stat is exactly at the green threshold (stat = 61), **WHEN** the bar renders, **THEN** the color is green (61 > 60).

6. **GIVEN** any officer's stat is exactly at the green threshold boundary (stat = 60), **WHEN** the bar renders, **THEN** the color is yellow (60 is NOT > 60).

7. **GIVEN** any officer's stat is exactly 1 (minimum), **WHEN** the bar renders, **THEN** `fill = 0.01` — a thin sliver is visible, NOT an empty bar.

8. **GIVEN** any officer's stat is exactly 100 (maximum), **WHEN** the bar renders, **THEN** `fill = 1.0` — the bar is completely filled, green zone, with no special "max" indicator.

### Growth Indicator

9. **GIVEN** Kaster at Prologue (WAR baseline = 82) before any act transitions, **WHEN** the full panel renders, **THEN** no ▲ indicator appears next to any stat.

10. **GIVEN** Kaster's WAR has grown to 85 after Act II transition (prologue baseline = 82), **WHEN** the full panel renders, **THEN** a ▲ indicator appears next to the WAR stat.

11. **GIVEN** Kaster's LDR has NOT grown (still 96, same as Prologue), **WHEN** the full panel renders, **THEN** no ▲ indicator appears next to LDR, even if other stats show ▲.

### Passive Display — Heirloom Blade

12. **GIVEN** Kaster is rendered in Full Panel, **WHEN** the passive ability list is displayed, **THEN** exactly ONE passive is shown: "Read the Field." No second entry, no blank entry, no "???" placeholder, no hidden slot exists.

13. **GIVEN** any UI context (Full Panel, Compact Bar, Miniature, tooltip, glossary, any screen in the game), **WHEN** passive abilities are rendered for Kaster, **THEN** "Heirloom Blade" does not appear anywhere in any player-visible text.

14. **GIVEN** a code search of all rendering paths for officer passive display, **WHEN** each path is audited, **THEN** no rendering path conditionally hides or specially handles a passive named "Heirloom Blade" — the filter is upstream in `get_display_passives()`, making the renderer unaware of its existence.

15. **GIVEN** Zhuge Jian is rendered in Full Panel, **WHEN** the passive list displays, **THEN** "The Treatises" appears as the single passive entry.

16. **GIVEN** a generic officer with no passive assigned, **WHEN** the passive section renders, **THEN** the passive area shows a "None" label in a muted style (no crash, no blank gap).

### Display Tiers

17. **GIVEN** a Compact Bar is rendered with `context: TACTICAL`, **WHEN** the stats display, **THEN** only WAR and LDR are shown — INT, POL, and CHR are not rendered in this configuration.

18. **GIVEN** a Compact Bar is rendered with `context: DIPLOMATIC`, **WHEN** the stats display, **THEN** CHR and INT are shown; WAR is not shown.

19. **GIVEN** a Miniature Icon is rendered, **WHEN** the player hovers over it, **THEN** a Compact Bar appears as a tooltip.

20. **GIVEN** a Miniature Icon is rendered, **WHEN** the player clicks/activates it, **THEN** the Full Panel opens.

### Injury Badge

21. **GIVEN** an officer has `unavailable_turns = 2` (diplomatic duel injury), **WHEN** the Full Panel renders, **THEN** an "Injured — 2 turns remaining" badge overlays the lower portion of the portrait.

22. **GIVEN** an officer has `unavailable_turns = 0` (available), **WHEN** the Full Panel renders, **THEN** no injury badge appears.

23. **GIVEN** an officer is injured and rendered in the Miniature tier, **WHEN** the status dot is evaluated, **THEN** the dot color is red.

### Missing Portrait Fallback

24. **GIVEN** a portrait asset fails to load (file not found), **WHEN** the portrait renders, **THEN** the appropriate archetype silhouette (`silhouette_[archetype].png`) renders in its place — no error is surfaced to the player.

25. **GIVEN** the archetype silhouette also fails to load, **WHEN** the portrait renders, **THEN** a solid gray rectangle fills the portrait area — the component does not crash or produce a blank node.

### Stat Labels

26. **GIVEN** any officer in Full Panel, **WHEN** the five stats are displayed, **THEN** they appear in canonical order: WAR · LDR · INT · POL · CHR — no other order.

27. **GIVEN** an officer name that exceeds the compact bar's display width, **WHEN** the name renders, **THEN** it is truncated with an ellipsis ("…") — no wrapping or overflow.

### Cross-System Correctness

28. **GIVEN** Alexsen's WAR stat reads from Officer Stats System as 98, **WHEN** the stat bar fill is computed, **THEN** `fill = 98 / 100 = 0.98` — the display value exactly matches the authoritative Officer Stats value with no rounding or offset.

29. **GIVEN** the Officer Stats System returns a stat value of null (officer not yet initialized), **WHEN** the portrait card attempts to render, **THEN** a loading placeholder renders — no crash, no undefined value displayed as "0" or "-1."

## Open Questions

1. **Generic officer portrait bank size**: The GDD specifies 4–6 portrait variants per archetype (~8–10 archetypes). With 25–30 generic officers recruitable per campaign, how many variants are needed before the same portrait appears twice? If the player recruits 6 Warriors and only 4 Warrior portraits exist, at least 2 Warriors share a face. Is this acceptable, or do we need more variants? Confirm target with art director before commissioning portraits.

2. **Expression variation across acts**: Should named officer portraits change between acts to reflect narrative growth (e.g., Alexsen looks battle-worn by Act III)? The art bible style supports this but it doubles or triples named portrait art count. If yes, define act-portrait mapping before production. If no, document the choice here.

3. **Tooltip accessibility on gamepad**: The passive ability tooltip requires hover. For gamepad users, the current spec uses Tab/D-pad focus and Enter to open. Does a focused-but-not-opened state display a hint ("Press A for details") or just wait for input? UX spec for officer full panel should clarify.

4. **Campaign State interface (provisional)**: The `officer.current_assignment` and `officer.unavailable_turns` data is provisional — the Campaign Map System is not yet designed. This GDD assumes these fields exist on the Officer object. When the Campaign Map System is designed, formalize this interface and update Section F accordingly.

5. **Growth indicator persistence question**: The ▲ indicator marks "stat is above Prologue baseline" for the full campaign. Should there be a way for the player to compare current stats to a specific act's values (e.g., "how much did Kaster grow this act")? Currently: no — the indicator is binary (grown or not). If act-by-act growth tracking becomes a design goal, this component needs a "compare to act N" display mode.
