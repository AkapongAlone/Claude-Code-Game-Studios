# Tactical HUD

> **Status**: In Design
> **Author**: Game Designer + UX Designer
> **Last Updated**: 2026-06-12
> **Implements Pillar**: P1 — Victory Through Preparation + P2 — Officers Are the Story

---

## Overview

The Tactical HUD is the read-only display layer for the hex tactical battlefield. It consumes state from eight upstream systems — Combat Resolution, Morale, Hex Movement, Facing & Flank, Fog of War, Officer Passive Ability, Victory/Defeat Conditions, and Officer Stats — and renders that state to the player without owning any game logic. Four functional domains compose the HUD: (1) hex-grid overlay layer (movement highlights, arc indicators, objective markers), (2) unit token layer (squad sprites, officer portrait crops, facing arrows, morale borders), (3) unit inspector panel (detailed friendly-squad breakdown), and (4) battle status bar (turn, phase, victory progress). This document also resolves Hex Movement GDD open question #1 by establishing **flat-top hex orientation** as the project standard (flat edges top and bottom, vertices at left and right) — this matches the Napoleonic line-formation aesthetic and provides natural horizontal rows across the battlefield.

---

## Player Fantasy

The tactical map is Kaster's planning table. Every glance at the battlefield should feel like a commander reading terrain at a glance — morale borders pulse the danger, facing arrows reveal the vulnerability, ghost tokens hint at a threat you have not yet confirmed. The player thinks about the battle, not about reading the interface. Every element on screen earns its place by answering a real tactical question. P1 (Victory Through Preparation) is served because everything displayed has a decision attached to it; P2 (Officers Are the Story) is served because officer identity — portrait, name, passive names — surfaces directly on the tokens and inspector panel, making officers feel present on the field rather than abstracted into stat numbers.

---

## Detailed Design

### Core Rules

**Rendering Layer**

The HUD lives in `TacticalHUDLayer` at `CanvasLayer 5`. Duel UI occupies `CanvasLayer 10`. A battle-end overlay occupies `CanvasLayer 15`. Pause/menu occupies `CanvasLayer 20`. During an active duel the HUD remains rendered but is non-interactive: `TacticalHUD.set_interactive(false)` is called by the Battle Flow Controller.

**Hex Grid Orientation**

Flat-top hexes. Flat edges at top and bottom; vertices at left and right. East direction maps to cube-coordinate offset (+1, −1, 0). Hex index direction 0 = East; directions increment clockwise.

**Selection Model**

| Player Action | HUD Response |
|---|---|
| Click empty hex | Deselect; return to IDLE |
| Click friendly squad (Movement Phase) | Enter SQUAD_SELECTED; show movement overlay + inspector panel |
| Click enemy squad (VISIBLE) | Enter ENEMY_SELECTED; show enemy info panel |
| Click ghost token (PREVIOUSLY_SEEN) | Enter GHOST_SELECTED; show ghost tooltip |
| Click move destination (SQUAD_SELECTED) | Show path preview; confirm moves squad |
| Click Kaster Inspect button | Enter TARGETING; ranged Inspect action |
| Morale/Routing phase begins | Enter AUTOMATED_PHASE; interaction disabled |

**HUD Modes**

| Mode | Trigger |
|---|---|
| `IDLE` | No selection, player phase |
| `SQUAD_SELECTED` | Friendly squad clicked (Movement Phase) |
| `ENEMY_SELECTED` | VISIBLE enemy clicked |
| `GHOST_SELECTED` | Ghost token clicked |
| `TARGETING` | Ranged attack or Inspect targeting active |
| `AUTOMATED_PHASE` | Morale/Routing phases; interaction disabled |
| `INTERACTION_LOCKED` | Duel active; `set_interactive(false)` |

---

### Squad Token (always visible)

Each squad on the battlefield renders a token comprising:

- Unit sprite (faction-colored)
- Officer portrait crop — Miniature Icon tier (32×40 px) from Portrait & Character Display GDD
- Facing arrow (direction of current facing)
- Morale state border: green = STEADY, amber = SHAKEN, red = BROKEN
- Routing indicator (animated arrow) visible only on BROKEN squads that are routing
- AP pips — visible only when this squad is the currently selected squad (during SQUAD_SELECTED mode)

---

### Unit Inspector Panel (right side — SQUAD_SELECTED mode)

Displayed when the player selects a friendly squad. Contents:

- **PortraitCard Compact Bar tier** (TACTICAL context: WAR + LDR stats) — embedded from Portrait & Character Display GDD
- Officer name
- Unit type label
- AP display: `"N / N"` text + pip count equals ap_remaining
- Morale bar (fill fraction from F-1) with color snapping on state boundaries
- Morale state label (STEADY / SHAKEN / BROKEN)
- Recovery rate tooltip on morale bar hover
- Passive names list (only `is_player_visible: true` passives from `officer.get_display_passives()` — Heirloom Blade is absent)
- Facing label (direction + degrees)
- Kaster Inspect action button (grayed with tooltip when no valid targets)

If the squad has no assigned officer: silhouette portrait fallback, "No Officer" name, no passive names.

---

### Enemy Info Panel (ENEMY_SELECTED mode — VISIBLE enemies only)

- Thumbnail portrait crop
- Officer name
- Unit type label
- 5-segment approximate HP bar (not exact value — preserves intelligence uncertainty from Fog of War)
- Inspect results container (hidden until Inspect action is used; shows revealed data)

If the enemy squad has no officer: silhouette fallback, "Officer: Unknown".

---

### Ghost Info Tooltip (GHOST_SELECTED mode)

Tooltip text: `"Last known position — [unit type] — [N] turn(s) ago"`

No portrait. No unit stats. No Inspect affordance.

---

### Battle Status Bar (top — always visible)

- Turn counter: `"Turn N"`
- Phase label: current phase name (MOVEMENT / COMBAT / MORALE / AI TURN / etc.)
- Enemy force indicator: `"Enemy: N / M squads broken"` (route fraction — see F-4)
- Condition tracker: active victory condition label (HOLD_OBJECTIVE / SURVIVE_TURNS / EXCEED_TURN_LIMIT)
- Player route fraction: hidden by default; toggled by accessibility option `show_player_route_fraction`

---

### Floating Text Layer (push-driven)

Events push floating text to a hex position; text animates upward and fades.

| Event | Text | Color |
|---|---|---|
| HP damage (standard) | `"−N"` | White |
| HP damage (flank hit) | `"−N"` | Orange |
| HP damage (high — ≥30) | `"−N"` | Red |
| Morale damage | `"−N MOR"` | Blue-gray, 0.3s delay after HP number |
| State transition to SHAKEN | `"SHAKEN!"` | Amber |
| State transition to BROKEN | `"BROKEN!"` | Red |
| Attack ineffective (< 1 damage) | `"INEFFECTIVE!"` | Gray |

Multiple floating texts at the same hex: HP number appears first; morale number appears 0.3s later, vertically stacked above the HP number.

---

### Fog of War Display

| Vision State | Rendering |
|---|---|
| VISIBLE | Full opacity, full saturation |
| PREVIOUSLY_SEEN | 45% opacity, desaturated (ghost token) |
| UNSEEN | No token rendered |

Ghost badge: `"?"` badge rendered on ghost token when `staleness_turns >= staleness_threshold (3)`.

No terrain fog overlay is managed by the Tactical HUD; that is owned by the Fog of War system.

---

### Hex Overlay Layer (SQUAD_SELECTED mode)

Active when a friendly squad is selected:

- **Movement range highlights** — reachable hexes tinted (blue-green overlay)
- **Path preview** — line drawn from selected squad along hover path to cursor hex
- **Facing arc overlay** — forward arc hexes (3-hex cone) = green tint; flank arc hexes (3-hex cone) = amber/red tint. See F-6 for arc calculation.
- **LDR aura ring** — rendered around selected squad on hover-only, radius determined by LDR stat (from Officer Stats GDD)
- **Ambush-ready indicator** — icon on hex if current position qualifies as ambush terrain (from Fog of War GDD)
- **Objective hex markers** — ring rendered on any hex flagged as an objective by Victory/Defeat Conditions GDD

---

### Push Interface Contract

```gdscript
TacticalHUD.show_combat_result(result: CombatResult) -> void
TacticalHUD.on_morale_change(squad_id: int, old_morale: int, new_morale: int, new_state: MoraleState) -> void
TacticalHUD.on_state_transition(squad_id: int, new_state: MoraleState) -> void
TacticalHUD.set_interactive(enabled: bool) -> void
TacticalHUD.set_phase(phase: BattlePhase) -> void
```

All other HUD state (bars, AP, fog visibility) is pulled each frame from the relevant game systems.

---

### States and Transitions

See HUD Modes table in Core Rules. Transitions follow selection model table. INTERACTION_LOCKED can only be cleared by `set_interactive(true)`. AUTOMATED_PHASE clears when `set_phase()` signals return to MOVEMENT or COMBAT phase.

---

### Interactions with Other Systems

| System | Direction | Data Flowing |
|---|---|---|
| Hex Movement | Pull | Reachable hexes, AP pool, AP remaining, path cost |
| Combat Resolution | Push (push) | `CombatResult` (damage, flank flag, ineffective flag) |
| Morale | Push + Pull | Push: `on_morale_change`, `on_state_transition`; Pull: current morale value for bar |
| Facing & Flank | Pull | Squad facing direction (0–5), flank arc hex set |
| Fog of War | Pull | Per-squad vision state (VISIBLE / PREVIOUSLY_SEEN / UNSEEN), staleness_turns |
| Officer Passive | Pull | `officer.get_display_passives()` — visible passive name list only |
| Victory/Defeat Conditions | Pull | `VictoryChecker.get_route_fraction(side)`, objective hex positions, condition type |
| Officer Stats / Portrait Display | Pull | Portrait asset, officer name, WAR + LDR stats for PortraitCard |
| Battle Flow Controller | Caller | Calls `set_interactive()` and `set_phase()` |

---

## Formulas

**F-1: Morale Bar Fill**

```
morale_fill_fraction = float(squad.morale) / 100.0
```

Range: [0.0, 1.0]. Bar color snaps (no lerp) on state boundaries:
- morale ≥ SHAKEN_THRESHOLD → green
- BROKEN_THRESHOLD ≤ morale < SHAKEN_THRESHOLD → amber
- morale < BROKEN_THRESHOLD → red

(Thresholds owned by Morale System GDD.)

Example: morale = 62 → fill = 0.62 → green bar.

**F-2: AP Display String**

```
ap_display = str(ap_remaining) + " / " + str(ap_pool)
pip_count   = ap_remaining
```

Example: ap_remaining = 2, ap_pool = 3 → display `"2 / 3"`, 2 filled pips.

**F-3: HP Segment Fill (Approximate — enemy squads only)**

```
hp_fill_fraction = float(squad.current_hp) / float(squad.max_hp)
segments_shown   = floor(hp_fill_fraction * hp_segment_count)
```

`hp_segment_count` default = 5. Range: 0–5 segments. Friendly squads show exact HP value.

Example: 60/100 HP → fill = 0.60 → `floor(0.60 × 5)` = 3 segments shown.

**F-4: Enemy Route Fraction Label**

```
route_label = "Enemy: " + str(VictoryChecker.get_route_fraction(ENEMY).broken) + " / " +
              str(VictoryChecker.get_route_fraction(ENEMY).total) + " squads broken"
```

Delegates to `VictoryChecker.get_route_fraction(side)` — denominator is fixed at battle start per Victory/Defeat Conditions GDD.

**F-5: Ghost Staleness Badge**

```
show_staleness_badge = (current_turn - squad.last_seen_turn) >= staleness_threshold
```

`staleness_threshold` = 3 (constant owned by entity registry, sourced from Fog of War GDD).

Example: last seen on turn 4, current turn 7 → (7 − 4) = 3 ≥ 3 → badge shown.

**F-6: Facing Arc Hex Set**

Facing direction D ∈ {0, 1, 2, 3, 4, 5} (flat-top, 0 = East, clockwise).

```
forward_arc  = { D, (D+1) mod 6, (D+5) mod 6 }   # 3 hexes: straight and ±1 side
flank_arc    = { (D+2) mod 6, (D+3) mod 6, (D+4) mod 6 }   # 3 hexes: rear and ±1 rear
```

Flank arc hexes receive amber/red overlay. Forward arc hexes receive green overlay.

Example: D = 0 (East) → forward = {0, 1, 5}, flank = {2, 3, 4}.

---

## Edge Cases

**E-01** — Squad enters BROKEN mid-player-turn: immediately deselect the squad and return to IDLE mode. No movement overlay for a broken squad.

**E-02** — Cursor hovers ghost token while a friendly squad is SQUAD_SELECTED: movement overlay takes visual priority. Ghost tooltip suppressed until squad is deselected.

**E-03** — Kaster Inspect button has no valid targets: button rendered grayed; on hover show tooltip `"No valid targets in range"`.

**E-04** — Friendly squad has no assigned officer: silhouette portrait fallback in inspector panel, name shows `"No Officer"`, passive names list empty, PortraitCard renders stat bars with dashes.

**E-05** — Visible enemy squad has no assigned officer: enemy info panel shows silhouette portrait, name shows `"Officer: Unknown"`.

**E-06** — Multiple floating texts at the same hex in the same frame: HP damage number animates first. Morale damage number waits 0.3s (`morale_number_delay_sec`), then spawns stacked above the HP number.

**E-07** — Player clicks a BROKEN, routing squad: inspector panel opens in read-only mode showing `"ROUTING"` state label. No movement overlay rendered. No Inspect button.

**E-08** — Enemy squad transitions from PREVIOUSLY_SEEN to VISIBLE during the player's turn (vision range entered): ghost token fades in to full-opacity full-saturation over 0.4s.

**E-09** — Objective hex contains a ghost token: objective ring is rendered below the ghost token (lower z-index). On hover, objective counter tooltip takes priority over ghost tooltip.

**E-10** — Phase transition occurs while floating text animations are mid-play: queued animations complete during the transition. No animations are dropped.

**E-11** — Reinforcements arrive mid-battle: route fraction denominator stays fixed at the value set at battle start per Victory/Defeat Conditions GDD. Denominator does not update.

**E-12** — Heirloom Blade procs and generates a large damage number: the number renders as a standard white damage float (same as any HP loss). No unique visual treatment, no unique audio cue, no special animation.

**E-13** — Duel begins while player has a squad selected (INTERACTION_LOCKED): click events no longer reach HUD. Inspector panel and movement overlay remain visible but frozen. `set_interactive(false)` clears all interactive affordances.

**E-14** — Accessibility option `show_player_route_fraction` is enabled: a second route counter `"Friendly: N / M squads broken"` appears in the Battle Status Bar beside the enemy counter.

---

## Dependencies

### Upstream (this GDD depends on)

| System | What This GDD Requires |
|---|---|
| Hex Movement GDD | AP pool size, reachable hex set, movement cost per hex, path preview API |
| Combat Resolution GDD | `CombatResult` data structure (damage, flank flag, ineffective flag) |
| Morale System GDD | Morale value range [0–100], state thresholds (SHAKEN / BROKEN), MoraleState enum |
| Facing & Flank GDD | Facing direction model (6-direction, 0–5), flank arc definition |
| Fog of War GDD | VisionState enum (VISIBLE / PREVIOUSLY_SEEN / UNSEEN), `last_seen_turn`, `staleness_threshold` constant |
| Officer Passive Ability GDD | `officer.get_display_passives()` contract; `is_player_visible` flag; Heirloom Blade must never appear |
| Victory/Defeat Conditions GDD | `VictoryChecker.get_route_fraction(side)` API, objective hex positions, condition type enum |
| Officer Stats / Portrait Display GDD | Portrait assets, officer name, WAR + LDR stats, PortraitCard Compact Bar tier |

### Downstream (depends on this GDD)

| System | What They Expect |
|---|---|
| Battle Flow Controller | `set_interactive(bool)` and `set_phase(BattlePhase)` entry points |
| Combat Resolution | `TacticalHUD.show_combat_result(CombatResult)` push method exists |
| Morale System | `TacticalHUD.on_morale_change()` and `on_state_transition()` push methods exist |

---

## Tuning Knobs

All values live in `assets/data/tactical_hud_config.json`.

| Key | Default | Safe Range | Affects |
|---|---|---|---|
| `damage_number_duration_sec` | 1.2 | [0.8, 2.0] | How long HP/morale float numbers remain visible |
| `morale_number_delay_sec` | 0.3 | [0.1, 0.6] | Delay between HP number and morale number at same hex |
| `path_preview_line_width` | 3.0 | [2.0, 5.0] | Visual weight of the path preview line |
| `movement_highlight_opacity` | 0.35 | [0.20, 0.50] | Visibility of reachable-hex tint overlay |
| `ghost_token_opacity` | 0.45 | [0.30, 0.60] | Opacity of PREVIOUSLY_SEEN ghost tokens |
| `flank_arc_overlay_opacity` | 0.20 | [0.10, 0.35] | Visibility of flank arc hex tint |
| `aura_ring_opacity` | 0.25 | [0.15, 0.40] | Visibility of LDR aura ring on hover |
| `hp_segment_count` | 5 | [3, 10] | Number of HP bar segments in enemy info panel |
| `show_player_route_fraction` | false | [true, false] | Accessibility: show friendly route fraction in status bar |
| `secondary_ap_ring_visible` | true | [true, false] | Show AP pip ring around selected squad token |
| `floating_text_font_size` | 24 | [18, 32] | Font size for damage/morale float numbers |

---

## Visual/Audio Requirements

**Squad Token Design**

- Token base: 64×64 px square with rounded corners; faction color tint on border
- Facing arrow: directional chevron aligned to facing direction; rotates with the squad
- Morale border: 3 px border, color = green / amber / red per state (snaps, no gradient)
- Portrait crop: 32×40 px Miniature Icon tier (per Portrait Display GDD spec)
- Routing indicator: pulsing directional arrow (direction of retreat hex), amber

**Ghost Token Design**

- Identical structure to squad token but desaturated and at `ghost_token_opacity` (0.45)
- `"?"` badge: white circle with `"?"` glyph, positioned top-right of token; visible when `show_staleness_badge` = true

**Damage Number Colors**

- Standard HP loss: white `"−N"`
- Flank damage: orange `"−N"`
- High damage (≥30): red `"−N"`
- Morale damage: blue-gray `"−N MOR"`
- SHAKEN transition: amber `"SHAKEN!"`
- BROKEN transition: red `"BROKEN!"`
- Ineffective: gray `"INEFFECTIVE!"`

**Movement Overlay**

- Reachable hexes: semi-transparent blue-green fill
- Path preview: solid line, `path_preview_line_width` px, white with slight drop shadow
- Objective hex ring: gold ring, 4 px, rendered below all tokens

**Audio**

The Tactical HUD owns no audio system. One exception: a soft confirm tap sound plays on squad selection click (friendly squad selected entering SQUAD_SELECTED mode). All combat audio is owned by Combat Resolution.

> **Asset Spec Flag**: Audio designer must spec the squad-selection confirm tap sound. Suggest: short, dry, parchment-paper quality — consistent with a commander placing a piece on a planning map.

---

## UI Requirements

This section consolidates UI obligations from all upstream GDDs that the Tactical HUD is responsible for rendering.

**From Hex Movement GDD**: Reachable hex highlighting, path cost display, AP pip display.

**From Morale System GDD**: Morale bar, state label, state-transition floating text.

**From Facing & Flank GDD**: Facing arrow on token, facing arc overlay (forward green, flank amber/red).

**From Fog of War GDD**: Ghost token rendering, `"?"` staleness badge, ghost tooltip.

**From Officer Passive Ability GDD**: Passive names list in inspector (visible passives only, Heirloom Blade absent).

**From Victory/Defeat Conditions GDD**: Route fraction label, objective hex markers, condition type label.

**From Combat Resolution GDD**: HP damage float, flank flag color, ineffective text.

**Keyboard Navigation**

| Key | Action |
|---|---|
| Tab | Cycle selection to next friendly squad |
| Shift+Tab | Cycle selection to previous friendly squad |
| Enter | Confirm pending action (move / attack) |
| Escape | Deselect / cancel pending action |
| G | Open glossary overlay |
| F | Focus inspector panel (keyboard focus to right panel) |

All menus and overlays must support keyboard navigation per technical preferences.

> **UX Flag**: Full keyboard navigation spec (tab order, focus rings, panel traversal) belongs in `design/ux/hud.md`. The keys above are the minimum contract; the UX document owns the interaction detail.

---

## Acceptance Criteria

**Movement Overlay**

- AC-01: When a friendly squad is selected in MOVEMENT phase, all reachable hexes within AP budget are highlighted within one frame.
- AC-02: Path preview line updates on every hex the cursor enters; no frame lag visible at 60 fps.
- AC-03: AP pips on the selected squad token update immediately when a move is confirmed.
- AC-04: Movement overlay clears immediately when a different squad is selected or Escape is pressed.

**Unit Inspector Panel**

- AC-05: Inspector panel appears on the right side within one frame of a friendly squad click.
- AC-06: PortraitCard Compact Bar renders correct WAR and LDR values for the selected officer.
- AC-07: Passive names list contains only passives with `is_player_visible: true`; Heirloom Blade (`"heirloom_blade"`) never appears in any displayed string.
- AC-08: AP display shows `"N / N"` format and pip count matches ap_remaining.
- AC-09: Morale bar fill matches `morale_fill_fraction` formula; color snaps (no lerp) on state boundary crossing.
- AC-10: Inspector panel is read-only for BROKEN squads; movement overlay is absent; state label shows `"ROUTING"`.
- AC-11: Squads with no assigned officer show silhouette portrait, `"No Officer"` name, empty passive list.

**Morale Bar and State Transitions**

- AC-12: Morale bar color changes from green to amber exactly at SHAKEN threshold (no intermediate color).
- AC-13: Morale bar color changes from amber to red exactly at BROKEN threshold.
- AC-14: `"SHAKEN!"` floating text appears in amber when `on_state_transition` fires with SHAKEN.
- AC-15: `"BROKEN!"` floating text appears in red when `on_state_transition` fires with BROKEN.

**AP Display**

- AC-16: AP `"N / N"` string updates immediately after a move action is confirmed.
- AC-17: Pip count on token matches ap_remaining value; no pip is shown for spent AP.

**Facing and Arc Overlay**

- AC-18: Facing arrow on squad token points in the correct flat-top hex direction (0–5, clockwise from East).
- AC-19: Forward arc (3 hexes) highlighted in green when squad is selected.
- AC-20: Flank arc (3 hexes) highlighted in amber/red when squad is selected.
- AC-21: Arc overlay updates immediately when squad facing changes.

**Fog of War Display**

- AC-22: VISIBLE enemy squads render at full opacity, full color.
- AC-23: PREVIOUSLY_SEEN ghost tokens render at `ghost_token_opacity` (default 0.45) and desaturated.
- AC-24: UNSEEN squads have no token rendered (not even a ghost).
- AC-25: `"?"` badge appears on ghost token when `(current_turn − last_seen_turn) >= 3`.
- AC-26: Ghost info tooltip shows `"Last known position — [unit type] — [N] turn(s) ago"` on ghost click.
- AC-27: Ghost-to-visible transition fades in over 0.4s when a ghost enters vision range.

**Enemy Info Panel**

- AC-28: Enemy info panel appears on VISIBLE enemy squad click; does not appear on ghost click.
- AC-29: HP bar shows `floor(hp_fill_fraction × hp_segment_count)` filled segments (not exact HP number).
- AC-30: Enemy with no officer shows silhouette and `"Officer: Unknown"`.

**Battle Status Bar**

- AC-31: Turn counter increments at the start of each new turn; never decrements.
- AC-32: Phase label updates within one frame when `set_phase()` is called.
- AC-33: Enemy route fraction label matches `VictoryChecker.get_route_fraction(ENEMY)` output each turn.
- AC-34: When `show_player_route_fraction = true`, a friendly route counter also appears in the status bar.

**Floating Text**

- AC-35: HP damage number appears within one frame of `show_combat_result()` being called.
- AC-36: Morale damage number appears exactly `morale_number_delay_sec` (0.3s) after the HP number at the same hex.
- AC-37: Heirloom Blade proc produces a standard white damage number — no unique color, no unique animation, no unique audio.

**Interaction Lock**

- AC-38: While `INTERACTION_LOCKED`, no click on any hex or token changes HUD selection state.
- AC-39: While `AUTOMATED_PHASE`, no player input moves the selection or triggers overlays.

**Keyboard Navigation**

- AC-40: Tab cycles selection to the next friendly squad on the field.
- AC-41: Escape deselects the current squad and returns to IDLE mode.
- AC-42: Enter confirms the currently hovered move destination when in SQUAD_SELECTED mode.

---

## Open Questions

1. **Full CanvasLayer table**: CanvasLayer numbers above (5/10/15/20) are provisional. Confirm the complete table with Technical Director before implementation.

2. **Battle-end overlay ownership**: Who owns the victory/defeat overlay? Likely Battle Flow Controller GDD — flag for that GDD's author.

3. **Turn log panel**: A scrollable log of `"[Officer] struck [Officer] for N damage"` events would serve P1. Is this MVP scope or post-MVP? If MVP, it needs a fifth functional domain in this GDD.

4. **Enemy arc overlay**: Should the enemy squad's flank arc be shown when the player selects an enemy squad (as an intelligence aid)? Currently not shown. Could be an accessibility option or a toggleable HUD element.

5. **Flat-top hex mapping utility**: F-6 and the arc overlay require a utility function to enumerate arc hexes given a direction and a center cube coordinate. Suggested location: `src/core/hex_utils.gd`. Confirm with Lead Programmer before implementation.
