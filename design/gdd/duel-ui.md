# Duel UI

> **Status**: Designed
> **Author**: UX Designer + Art Director (lean mode)
> **Last Updated**: 2026-06-12
> **Implements Pillar**: P2 — Officers Are the Story · P4 — Authored Peaks, Player Valleys

## Overview

The Duel UI is the full-screen presentation layer for the Duel System sub-game. It renders two officer panels (portraits, resolve bars, stamina pips), the simultaneous stance selection interface (Attack / Defend / Feint / Signature Move buttons), the stance reveal sequence, the Read hint, and the conditionally visible Yield button. The UI owns no game logic — all game state is provided by the Duel System; the Duel UI translates that state into a legible, dramatic display and relays player input back as committed stance decisions. It operates identically across all three duel contexts (field challenge, scripted story moment, diplomatic resolution) — the calling context is transparent to the UI layer. The Duel UI is a full-scene overlay that suspends the battlefield view for the duration of the duel, then restores it.

## Player Fantasy

*Lean mode: `creative-director` not consulted — review against art bible and game pillars before production.*

The Duel UI serves P2 and P4 together. P2 says officers ARE the story — the screen must make the duel feel like a confrontation between specific legends, not a generic rock-paper-scissors overlay. The portraits carry this. Every other element exists to support the moment when two officers look each other in the eye across the center reveal area and commit their choice simultaneously.

The core tension to preserve: the player knows their own stance, the opponent does not, and neither knows the other's final choice until both are revealed at the same instant. The reveal animation — both stance icons flipping simultaneously — is the game's most important single moment of feedback. It must feel simultaneous (not sequential), must be unambiguous (outcome text within 0.3 seconds of the flip), and must carry weight proportional to what was at stake that turn. A Crushing Blow landing should feel different from a Defend-vs-Defend tie.

The stamina pip row earns its place by making depletion *visceral*. Players who cannot count numbers will still feel "running out" when pips go dark one by one. This is especially important for the late-duel moment when Alexsen is at 1 stamina and locked to Defend — the UI should communicate that constraint through grayed buttons and a depleted pip row, not through a text tooltip.

The Read hint must feel like an insight, not a notification. The visual treatment should suggest internal realization — a subtle pulse on the opponent's portrait side, flavor text in a muted style — not a UI alert. The 70% accuracy is a design fact, not a displayed stat; players learn the accuracy from experience, not from a tooltip.

## Detailed Design

### Core Rules

**Screen Lifecycle — Six Phases:**

**Phase 1: INIT (transition in)**
1. Duel System calls `DuelUI.initialize(duel_state: DuelState)` before the overlay is visible.
2. UI reads from `DuelState`: both `DuelParticipant` objects (officer names, max_resolve, max_stamina, portrait path, signature_move reference), the duel context type, and any `ScriptedDuelDefinition` if present.
3. Battlefield darkens behind the overlay (blend: 0.3 s). Duel frame fades in (0.4 s).
4. During the fade-in: resolve bars animate from 0 → full (showing both officers at max). Stamina pips populate left-to-right. Turn counter shows "Turn 1."
5. Stance buttons are visible but non-interactive during the 0.7 s transition. They become interactive as the transition completes.
6. Initial state: YIELD button is hidden. Signature Move button is rendered only if the player's officer has a non-null signature move.

**Phase 2: UI_SELECTING (player input)**
1. All available stance buttons are interactive. Hover state: subtle highlight ring.
2. Availability rules (see Section D for exact formulas):
   - Attack: interactive if player stamina ≥ 2
   - Defend: interactive if player stamina ≥ 1
   - Feint: interactive if player stamina ≥ 1
   - Signature Move: interactive if player stamina ≥ sig_move_cost AND not yet used this duel
   - If player stamina = 0: only Defend is interactive; all others are non-interactive (grayed)
3. Player commits a stance by pressing the button or keyboard shortcut. There is NO separate confirm step — the press is the commitment.
4. On commitment: all stance buttons immediately lock (non-interactive). A small "committed" indicator appears on the player portrait side (e.g., stance icon quietly shown to player only — not revealed to opponent panel). Turn advances to RESOLVING.

**Phase 3: UI_RESOLVING (stance reveal)**
1. 0.3 s pause after player commits (mimics opponent deliberation — creates anticipation).
2. Both stance icons appear simultaneously in the center reveal area and "flip" from face-down (0.5 s animation). Both participant's chosen stances are revealed at the same frame.
3. Result text appears immediately after the flip completes (~0.3 s after reveal):
   - "Attack beats Feint" / "Feint beats Defend" / "Defend beats Attack"
   - "Tie!" (for matched stances)
   - "Counter!" (for Defend winning against Attack)
   - "Feint Break!" (for Feint winning against Defend)
   - "Crushing Blow!" (Alexsen's Signature Move)
4. Damage numbers animate over the affected portrait: e.g., "–14" in red, floating up and fading over 0.6 s.
5. Resolve bars tween to their new values over 0.4 s. Color transitions (green → yellow → red) update if thresholds are crossed.
6. Stamina pips for used stamina deactivate with a 0.2 s stagger (one pip per frame).
7. After all animations complete: if the duel has not ended (no termination condition), transition to UI_READ_HINT (if Read fires this turn) or UI_SELECTING (if Read does not fire).

**Phase 4: UI_READ_HINT (when Read fires)**
1. Triggers only when the Duel System signals `read_fired` on this turn.
2. Fires AFTER the RESOLVING animations complete (the hint is about the NEXT turn's stance, not the current one — it fires at the end of step 3 in the duel turn, so the prior resolution is complete before the hint appears).
3. A subtle pulse animation plays on the higher-WAR participant's portrait side.
4. Read hint container fades in over 0.3 s. Contents:
   - "★ Read" header label (small, styled as an insight marker — not a system alert)
   - Flavor text: one line, max 10 words (e.g., "He shifts his weight forward...")
   - Stance icon: the hinted stance (correct or incorrect — the UI shows it the same way either time; players cannot distinguish correct from incorrect hints visually — they must learn the 70% base rate)
5. Hint remains visible for 2.5 s, then fades over 0.3 s.
6. Stance buttons remain non-interactive during Read display.
7. After Read fades: transition to UI_SELECTING.

**Phase 5: UI_YIELD_AVAILABLE (persistent state flag)**
1. The Yield button is a separate element, always rendered below the action bar but hidden (opacity 0) until the yield condition is first met.
2. When the Duel System signals `yield_available` (opponent resolve ≤ yield_threshold × max_resolve), the Yield button fades in over 0.5 s.
3. Once visible, the Yield button remains visible for the rest of the duel — it does NOT hide again even if the opponent recovers (which is not possible by system rules, but the UI should not de-render interactive elements mid-duel).
4. The Yield button is interactive during UI_SELECTING only (not during RESOLVING or READ_HINT).
5. The Yield button is visually distinct: different background color (suggested: muted gold / amber) and vertical position (below the action bar gap). It must not be confused with a stance button.
6. If the scripted duel has `yield_forced_at_resolve_pct` active: when the forced yield threshold is met, the stance buttons (Attack / Defend / Feint / Signature Move) are HIDDEN (not just grayed) and only the Yield button is interactive. This is an authored emotional moment — the player has no alternative.

**Phase 6: UI_END (duel resolution)**
1. Duel System calls `DuelUI.on_duel_ended(result: DuelResult)`.
2. A title card overlays the duel frame (0.3 s fade in):
   - ENDED_VICTORY: "Victory" in gold text; winner portrait brightens (×1.3 brightness); loser portrait dims (×0.5 brightness + desaturation).
   - ENDED_DEFEAT: "Defeat" in muted red; player portrait dims; opponent brightens.
   - ENDED_YIELD: "Honour Given" (or localized equivalent); player portrait dims slightly; opponent remains normal brightness.
   - ENDED_DRAW: "Draw" in neutral silver; both portraits dim slightly (×0.7 brightness).
3. Title card holds for 1.5 s.
4. Duel frame fades out (0.4 s). Battlefield returns to full brightness (0.3 s).
5. `DuelUI` emits `duel_ui_closed` signal → Duel System proceeds with context callbacks (morale effects, story flags, etc.).

### States and Transitions

**UI State Machine:**

| UI State | Entry Condition | Buttons Interactive | Duration |
|----------|----------------|---------------------|---------|
| `UI_INIT` | `DuelUI.initialize()` called | None | ~0.7 s (transition in) |
| `UI_SELECTING` | INIT complete OR prior RESOLVING/READ_HINT complete | Stance buttons (per stamina rules) + Yield (if available) | Until player commits |
| `UI_RESOLVING` | Player committed stance | None | ~1.5 s (0.3 s pause + 0.5 s reveal + 0.4 s bar anim + 0.3 s result text) |
| `UI_READ_HINT` | Duel System fires `read_fired` after RESOLVING complete | None | ~3.1 s (0.3 s fade in + 2.5 s display + 0.3 s fade out) |
| `UI_END` | `DuelUI.on_duel_ended()` called | None | ~2.2 s (0.3 s fade in + 1.5 s hold + 0.4 s fade out) |

**Transitions:**

```
UI_INIT
  → UI_SELECTING          (transition animation complete)

UI_SELECTING
  → UI_RESOLVING          (player commits a stance)

UI_RESOLVING
  → UI_READ_HINT          (Read fires this turn — after resolving animations complete)
  → UI_SELECTING          (no Read, no termination — next turn)
  → UI_END                (termination condition met — Duel System calls on_duel_ended())

UI_READ_HINT
  → UI_SELECTING          (hint display complete — next turn begins)
  → UI_END                (termination condition met mid-hint — Duel System calls on_duel_ended())

UI_SELECTING (any state)
  → UI_END                (Duel System calls on_duel_ended() — e.g., scripted override fires)
```

**Note on YIELD_AVAILABLE:** `yield_available` is NOT a blocking UI state — it is a persistent flag that modifies what is rendered in `UI_SELECTING`. The Yield button fades in the first time the condition is met and remains visible until `UI_END`. The forced-yield override (scripted duels only) IS a blocking modification to UI_SELECTING: stance buttons are hidden, leaving only Yield interactive.

**Note on Final Exchange:** When the Duel System triggers a Final Exchange (both participants simultaneously exhausted), the UI transitions directly to `UI_RESOLVING` with both participants forced to Defend — NO player input is requested. The resolve bar animations play, then `UI_END` fires.

### Interactions with Other Systems

| System | This UI Reads | This UI Writes |
|--------|--------------|----------------|
| **Duel System** | All game state via `DuelState` object: both participant stats (current/max resolve, current stamina, max stamina), turn number, available actions, Read hint data, yield condition flag, duel end result | Player committed stance (via `DuelSystem.commit_stance(player_stance)`), Yield action (via `DuelSystem.commit_yield()`) |
| **Officer Stats System** | Portrait path, officer name (via `Officer` reference inside `DuelParticipant`) | — (read-only) |
| **Officer Passive Ability System** | Signature move name, stamina cost, tooltip text (via `SignatureMove` reference loaded by Duel System) | — (read-only) |
| **Battlefield / Tactical Layer** | — | Signals `duel_ui_closed` when the UI fully fades out; the battlefield resumes rendering after this signal |

**Interface contract with Duel System:**

The Duel System drives the UI through explicit method calls and signals. The UI never polls game state — it is push-driven:

```
# Duel System → UI calls:
DuelUI.initialize(duel_state: DuelState)
DuelUI.on_turn_resolved(result: TurnResult)   # provides new resolve/stamina values + Read hint if any
DuelUI.on_yield_available()                    # triggers Yield button fade-in
DuelUI.on_duel_ended(result: DuelResult)       # triggers UI_END phase

# UI → Duel System calls:
DuelSystem.commit_stance(stance: DuelStance)   # called when player presses a stance button
DuelSystem.commit_yield()                       # called when player presses Yield

# UI → Tactical Layer signal:
duel_ui_closed                                 # emitted when fade-out is complete
```

The `TurnResult` object provided to `on_turn_resolved()` contains:
- `player_stance`: the player's committed stance (already known to UI)
- `opponent_stance`: the opponent's chosen stance (revealed now)
- `outcome`: the RPS result enum (ATTACK_WINS, DEFEND_WINS, FEINT_WINS, TIE, SIGNATURE_MOVE)
- `damage_to_player`: int (may be 0)
- `damage_to_opponent`: int (may be 0)
- `player_resolve_new`: int (post-damage resolve)
- `opponent_resolve_new`: int (post-damage resolve)
- `player_stamina_new`: int (post-cost stamina)
- `opponent_stamina_new`: int (post-cost stamina)
- `read_hint`: optional ReadHintData (null if Read did not fire)

The UI does not compute any of these values — it only renders them.

## Formulas

*Lean mode: `systems-designer` not spawned for this section — all formulas are display-only derivations of values owned by the Duel System GDD. No new game-math introduced here. Registry values are referenced, not redefined.*

The Duel UI contains no game logic formulas. All gameplay math is owned by the Duel System. The formulas below define how the UI translates numerical game state into rendered display state.

---

### F-1: Resolve Bar Fill Fraction

```
resolve_fill_fraction = float(current_resolve) / float(max_resolve)
```

**Variables:**
| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| Current resolve | current_resolve | int | [0, 90] | Officer's remaining duel HP, from `DuelParticipant` |
| Maximum resolve | max_resolve | int | [40, 90] | Officer's starting duel HP (from `duel_resolve` formula, locked at duel start) |
| Fill fraction (output) | resolve_fill_fraction | float | [0.0, 1.0] | Width of the resolve bar as a proportion of full width |

**Output range:** 0.0 (resolve = 0, bar empty) to 1.0 (full resolve, bar full).
**Color threshold:** fill_fraction > 0.60 → green; 0.30–0.60 → yellow; < 0.30 → red. Color transitions with the tween, not in discrete steps.
**Example:** Kaster, current 35, max 84 → fill = 35/84 ≈ 0.417 → yellow zone.

---

### F-2: Stamina Pip Count

```
pips_filled = current_stamina      (integer, one lit pip per remaining stamina point)
pips_total  = max_stamina          (fixed at duel start, from duel_stamina formula)
pips_empty  = max_stamina - current_stamina
```

**Variables:**
| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| Current stamina | current_stamina | int | [0, 15] | Remaining stamina, from `DuelParticipant` |
| Max stamina | max_stamina | int | [5, 15] | Starting stamina (from `duel_stamina` formula, locked at duel start) |
| Pips filled (output) | pips_filled | int | [0, 15] | Number of lit pips in the pip row |
| Pips empty (output) | pips_empty | int | [0, 15] | Number of dark pips in the pip row |

**Note:** Pip row always renders exactly `max_stamina` pips. The leftmost pips are filled; rightmost go dark as stamina depletes. This is the opposite of health bars (which fill left) — pips deplete visually as if counting down remaining actions.

---

### F-3: Yield Button Visibility

```
yield_button_visible = (float(opponent_current_resolve) / float(opponent_max_resolve)) <= yield_threshold
```

**Variables:**
| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| Opponent's current resolve | opponent_current_resolve | int | [0, 90] | From `DuelParticipant` (opponent) |
| Opponent's max resolve | opponent_max_resolve | int | [40, 90] | Fixed at duel start |
| Yield threshold | yield_threshold | float | 0.30 (default) | From `duel_config.json`; registry constant `duel_yield_threshold` |
| Yield visible (output) | yield_button_visible | bool | true/false | Whether the Yield button is rendered and interactive |

**Note:** Once `yield_button_visible` transitions from false → true, the UI flag is permanently set to true for this duel (yield button never re-hides). The condition is evaluated after each RESOLVING phase.
**Example:** Opponent max_resolve = 77 (Alexsen). Yield threshold = 0.30. Button appears when opponent resolve drops to ≤ `floor(77 × 0.30) = 23`.

---

### F-4: Stance Button Availability

```
attack_available   = (player_current_stamina >= 2)
defend_available   = (player_current_stamina >= 1)
feint_available    = (player_current_stamina >= 1)
sig_move_available = (player_current_stamina >= sig_move_cost) AND (NOT sig_move_used_this_duel)
```

**Variables:**
| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| Player current stamina | player_current_stamina | int | [0, 15] | From `DuelParticipant` (player) |
| Sig move cost | sig_move_cost | int | [3, 5] | Defined per officer in `signature_moves.json` (Crushing Blow: 4) |
| Sig move used | sig_move_used_this_duel | bool | true/false | Set when player uses Signature Move; cleared at duel init |

**Note:** Buttons where `*_available = false` are rendered but non-interactive (grayed). They are NOT hidden — the player should always see all four stances to maintain spatial consistency even when some are unavailable. The exception: Signature Move button is ABSENT (not rendered) for officers with no signature move (`sig_move == null`), and the forced-yield scripted override hides all stance buttons entirely.

---

### F-5: Resolve Bar Color Zone

```
bar_color_zone = "green"  if resolve_fill_fraction > 0.60
               = "yellow" if resolve_fill_fraction > 0.30
               = "red"    if resolve_fill_fraction <= 0.30
```

**Note:** Color transitions are continuous (lerp between zone anchors during bar tween), not discrete snaps. The specific hex colors are defined in the art bible / UI theme resource, not this GDD. This formula defines the zone boundaries only.

---

### F-6: Damage Number Display

```
damage_label_text = "–" + str(damage_value)    (for damage_value > 0)
damage_label_text = ""                           (for damage_value = 0, no label shown)
```

**Variables:**
| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| Damage value | damage_value | int | [0, 15] | From `TurnResult.damage_to_player` or `damage_to_opponent` |

**Display rules:** Labels float upward from the affected portrait and fade over 0.6 s. A damage value of 0 produces no label (Defend–Defend ties, Defend-winning-Attack counters where attacker takes 0). Font size scales slightly with damage value: ≤ 5 → small; 6–10 → medium; ≥ 11 → large (for Crushing Blow impact emphasis).

## Edge Cases

| # | Situation | Rule |
|---|-----------|------|
| E-01 | **Officer has no Signature Move** | The Signature Move button is absent — not rendered, not grayed. The action bar renders with three buttons (Attack / Defend / Feint) and additional spacing. No tooltip or "locked" indicator appears for the absent slot. |
| E-02 | **Yield condition met during RESOLVING animation** | The `yield_available` flag is set, but the Yield button does not begin its fade-in until RESOLVING is complete. Queuing the fade-in ensures the button never appears mid-animation. Result: Yield button fades in at the same moment stance buttons unlock for the next selection. |
| E-03 | **Read hint fires on the same turn as duel termination** | The Duel System calls `on_duel_ended()` after termination is checked, which supersedes Read hint display. The Read hint does NOT display if the duel ends that turn. UI transitions directly from RESOLVING to UI_END. (Matches Duel System edge case E-11: "the Read is a 'too late' moment.") |
| E-04 | **Both participants reach stamina 0 simultaneously (Final Exchange)** | No player input is requested. UI transitions to UI_RESOLVING with both stances shown as Defend (forced). The resolve bar animations play, result text shows "Draw — Final Exchange," then UI_END fires. If one participant's resolve was higher, the winner is shown normally (ENDED_VICTORY / ENDED_DEFEAT). |
| E-05 | **Scripted duel: `yield_forced_at_resolve_pct` active and threshold reached** | All stance buttons (Attack / Defend / Feint / Signature Move) become HIDDEN (not grayed). Only the Yield button is rendered and interactive. No UI text explains why. The authored moment should communicate the context through the scene itself (e.g., post-reveal dialogue). |
| E-06 | **Signature Move already used this duel** | The Signature Move button is rendered but non-interactive (grayed), with no cost label change. The stamina cost label still shows (so the player can see what it cost, even though they can't use it again). Grayed state persists for the rest of the duel. |
| E-07 | **Player selects a stance while animation is playing** | Input is blocked during UI_RESOLVING and UI_READ_HINT. Button presses and keyboard shortcuts are silently discarded during these states. The UI input lock is enforced in the UI layer, not the Duel System — the Duel System never receives a stance during resolution. |
| E-08 | **Resolve bar animated while a new `on_turn_resolved()` call arrives** | The second call is queued. The resolve bar animation for the first call completes first, then the second tween begins. Resolution calls cannot overlap. (In practice this cannot happen — the Duel System waits for `commit_stance()` from the UI before computing the next turn; UI only calls commit_stance in UI_SELECTING.) |
| E-09 | **Officer portrait path is missing or fails to load** | A placeholder portrait (silhouette + officer name initial) renders in the same space. No error is surfaced to the player. The issue is logged to the error log. |
| E-10 | **Read hint text for an incorrect hint (30% accuracy miss)** | The UI renders the incorrect stance icon identically to a correct hint. There is no visual or audio indicator of hint accuracy — players cannot distinguish a correct hint from an incorrect one. The flavor text may be intentionally ambiguous ("He seems to be reading you...") when the system selects the wrong stance, but ONLY as general flavor — never as a signal that the hint is wrong. |
| E-11 | **Player stamina = 1 (Attack locked, Feint locked)** | Attack and Feint buttons are grayed (rendered non-interactive). Defend is the only interactive option. The pip row shows 1 filled pip. No text label or tooltip is added — the grayed state communicates the constraint. |
| E-12 | **Scripted duel with `allow_player_loss: false`: player resolve hits 0** | The Duel System freezes the player's resolve at 1 and sends `on_turn_resolved()` with `player_resolve_new = 1`. The resolve bar animates to its 1-unit fill (near-empty, red). No special UI text appears — the scripted intervention is handled narratively outside the duel UI (e.g., cutscene, dialogue). |
| E-13 | **Duel UI opened over a scripted cutscene (scripted context)** | The battlefield is replaced by the cutscene background — the DuelUI overlay renders over whatever is behind it. The blur/darken layer applies to whatever the background is (could be a cutscene frame). The UI layer is unaware of the underlying scene. |
| E-14 | **Player presses Escape during a duel** | A pause/options menu is pushed above the DuelUI layer. Escape NEVER exits the duel without explicit player confirmation. The pause menu provides a "Forfeit Duel" option (for field and diplomatic duels), which is explicitly unavailable in scripted duels that have `allow_player_loss: false`. |
| E-15 | **Damage value is 0 (Defend–Defend tie or Attack miss in scripted duel)** | No floating damage label is rendered (F-6: damage_value = 0 produces no label). Resolve bars do not animate (they are already at their current value). Stamina pips update normally for the cost paid. Result text still shows ("Tie!" for Defend–Defend). |

## Dependencies

### Upstream Dependencies (this system reads from)

| System | Data Consumed | Interface | Notes |
|--------|--------------|-----------|-------|
| **Duel System** | Full `DuelState` at init; `TurnResult` per turn; `DuelResult` at end; `yield_available` signal; `read_fired` signal | Push-driven: Duel System calls DuelUI methods | Primary upstream. All game state originates here. |
| **Officer Stats System** | Officer name, portrait path | Via `Officer` reference inside `DuelParticipant` | Portrait path must resolve to an importable texture asset. |
| **Officer Passive Ability System** | Signature Move name, stamina cost, tooltip description | Via `SignatureMove` data reference loaded by Duel System | Duel UI displays the move name on the button and tooltip on hover. Does not implement the move logic. |

### Downstream Dependents (this system writes to / signals)

| System | Data Produced | Interface | Notes |
|--------|--------------|-----------|-------|
| **Duel System** | Player committed stance choice | `DuelSystem.commit_stance(player_stance)` | Only call during UI_SELECTING — never during RESOLVING or READ_HINT. |
| **Duel System** | Player Yield action | `DuelSystem.commit_yield()` | Only callable when yield_button_visible = true. |
| **Tactical Battle Controller / Scene Manager** | `duel_ui_closed` signal | Emitted after UI fade-out completes | Battle controller waits on this signal before resuming tactical turn processing. |

### Note on Context Transparency

The Duel UI does not know which context called it (field / scripted / diplomatic). The Duel System provides all relevant state diffs via the standard interface. The only exception: the UI receives a context_type flag in `DuelState` SOLELY to drive the forfeit confirmation text in the pause menu ("Forfeit Field Challenge" vs "Forfeit Diplomatic Duel"). This does NOT change any gameplay UI elements.

## Tuning Knobs

All UI timing knobs are in `assets/data/duel_ui_config.json`. Game-logic knobs (yield_threshold, read_accuracy, etc.) are in `assets/data/duel_config.json` — do not duplicate them here.

| Knob | Default | Safe Range | Effect if Too Low | Effect if Too High |
|------|---------|-----------|------------------|-------------------|
| `reveal_pause_duration` | 0.30 s | [0.10, 0.60] | Reveal feels immediate — no anticipation | Feels sluggish; reveals are too delayed |
| `reveal_animation_duration` | 0.50 s | [0.30, 0.80] | Stance reveal feels jarring / instant | Reveal animation drags; pacing breaks |
| `resolve_bar_tween_duration` | 0.40 s | [0.20, 0.70] | Bar snaps to new value — damage feels numeric | Bar tween overlaps with next Read hint display |
| `stamina_pip_stagger` | 0.20 s | [0.10, 0.40] | Pips all deactivate at once (less expressive) | Stagger outlasts the bar tween (timing gap) |
| `read_hint_display_duration` | 2.50 s | [1.50, 4.00] | Player doesn't have time to read the text | Read hint blocks the next selection too long |
| `read_hint_fade_duration` | 0.30 s | [0.15, 0.50] | Hint snaps off abruptly | Hint lingers past its intended display time |
| `yield_button_fade_duration` | 0.50 s | [0.20, 1.00] | Yield button pops in jarringly | Fade-in delays player noticing the option |
| `end_title_hold_duration` | 1.50 s | [0.80, 3.00] | Win/loss screen flashes by unreadably | End screen overstays before returning to battle |
| `background_darken_amount` | 0.70 | [0.50, 0.85] | Battlefield too visible — distracts from duel | Battlefield completely invisible (P3 grounding lost) |
| `damage_label_float_height` | 40 px | [20, 80] | Damage labels clip into the portrait | Labels float into the reveal area (overlap) |
| `damage_label_duration` | 0.60 s | [0.30, 1.00] | Labels disappear before player sees them | Labels linger during next stance selection |
| `resolve_color_yellow_threshold` | 0.60 | [0.50, 0.70] | Yellow zone too short; jumps green → red | Yellow zone too wide; feels alarmed too early |
| `resolve_color_red_threshold` | 0.30 | [0.20, 0.40] | Red zone too small; low resolve barely communicates | Red zone too wide; feels desperate too early in duel |

## Visual/Audio Requirements

*Visual/Audio is REQUIRED for this system (UI category). Lean mode: `art-director` not spawned — review against art bible before production. Cross-reference the Duel System GDD's Visual/Audio section: this GDD specifies the IMPLEMENTATION requirements; that GDD specified the DESIGN intent.*

### Visual

| Element | Implementation Requirement |
|---------|---------------------------|
| **Duel overlay background** | CanvasLayer above the battlefield. Darkening layer: ColorRect at ~70% opacity (tunable: `background_darken_amount`). Duel frame: centered Control node, ~80% viewport width, ~85% viewport height. |
| **Officer portraits** | `TextureRect` with `expand_mode: EXPAND_FIT_WIDTH_PROPORTIONAL` (crop to fill, never stretch). Portrait area: ~40% of each officer panel width. Each officer gets their own portrait from `assets/art/portraits/[officer_id]_duel.png`. |
| **Resolve bar** | Custom `TextureProgress` (not default Godot ProgressBar) using a segmented bar texture. Three color zones (green / yellow / red) defined by `resolve_color_*_threshold` knobs. Color interpolation is continuous via lerp on the bar's `tint_progress` property. |
| **Stamina pip row** | HBoxContainer with N TextureRect children (N = max_stamina). Each pip: 12×12 px icon, 4 px gap between pips. Filled pip texture: bright amber circle. Empty pip texture: dark grey circle. Instantiated at duel init from pip scene template. |
| **Stance icons** | 64×64 px square icons for each of: Attack, Defend, Feint, and per Signature Move. Hidden (opacity 0) until reveal animation. Reveal: scale from 0.5 → 1.0 over `reveal_animation_duration`. |
| **Stance buttons** | 120×60 px minimum tap area. Layout: icon (32×32) + label (stance name) + subtitle (stamina cost, smaller font). Disabled state: 40% opacity, no hover response. Visual style: neoclassical frame border matching art bible. |
| **Signature Move button** | 140×70 px (slightly larger than standard stance buttons). Distinct border color (gold / amber vs. neutral grey for standard stances). Shows: move name (full), stamina cost, one-line tooltip on hover. |
| **Yield button** | 160×48 px. Positioned vertically below the action bar with a 16 px gap. Background: muted amber/gold (distinct from all stance button colors). Text: "Yield" (or localized). Initial opacity: 0; fades to 1.0 via tween. |
| **Center reveal area** | Occupies center 20% of horizontal space between the two panels. During RESOLVING: shows both stance icons + result text. During READ_HINT: shows hint icon + flavor text. During SELECTING: shows VS divider or turn counter. |
| **Damage labels** | RichTextLabel nodes instantiated at runtime, parented to the affected portrait. Float 40 px upward over `damage_label_duration`. Font size tiers: small (damage ≤ 5), medium (6–10), large (≥ 11). Color: red for damage, no color for 0 (not rendered). |
| **Read hint display** | Fade-in container below the center reveal area. Contents: "★ Read" header (12 px, muted gold), one line of flavor text (14 px, italic), 32×32 stance icon on the right. Semi-transparent background panel. |
| **Duel end title card** | Full-width banner overlaying the duel frame. "Victory" in gold, "Defeat" in muted red, "Draw" in silver, "Honour Given" in muted gold. Font size: 48 px display font. Holds for `end_title_hold_duration`. |
| **Turn counter** | Small label, 12 px font, positioned in the top-right corner of the duel frame. "Turn N" format. Updates each turn without animation. |

### Audio

Cross-reference with the Duel System GDD's Audio section. This section maps game events to audio event IDs:

| Event | Audio Event ID | Notes |
|-------|---------------|-------|
| Duel overlay opens | `duel/music/duel_theme_start` | Fades in over 0.5 s. |
| Stance reveal (Attack wins) | `duel/sfx/clash_attack` | Sword impact. |
| Stance reveal (Defend wins) | `duel/sfx/clash_defend` | Defensive parry ring. |
| Stance reveal (Feint wins) | `duel/sfx/clash_feint` | Whoosh deflect. |
| Stance reveal (Tie — matched) | `duel/sfx/clash_tie` | Heavier, simultaneous collision sound. |
| Signature Move (Crushing Blow) | `duel/sfx/crushing_blow` | Heavy wind-up + bone-crack impact. Unique per move. |
| Damage taken (standard) | `duel/sfx/impact_grunt_[light/medium/heavy]` | Volume/variant scales with damage tier (same tiers as label size). |
| Read hint fires | `duel/sfx/read_hint_chime` | Subtle insight chime — NOT a UI ping or button sound. |
| Yield button appears | `duel/sfx/yield_available` | Soft horn swell — brief, solemn. |
| Duel end — Victory | `duel/sfx/victory_sting` | Short orchestral phrase, triumphant but not bombastic. |
| Duel end — Defeat | `duel/sfx/defeat_sting` | Descending minor phrase. |
| Duel end — Draw | `duel/sfx/draw_sting` | Unresolved chord, brief. |
| Duel overlay closes | `duel/music/duel_theme_end` | Fades out as battlefield returns. |

📌 **Asset Spec** — Visual/Audio requirements are defined. After the art bible is approved, run `/asset-spec system:duel-ui` to produce per-asset visual descriptions, dimensions, and generation prompts from this section.

## UI Requirements

### Screen Layout

```
┌─────────────────────────────────────────────────────────┐
│  [OPPONENT PORTRAIT]             [PLAYER PORTRAIT]      │
│  [Name Label]                    [Name Label]           │
│  Resolve ████████████░░          Resolve ██████░░░░░░  │
│  84 / 84                         62 / 84                │
│  Stamina ●●●●●●●●●               Stamina ●●●●●●○○○○○○ │
│                                                         │
│         [ Stance A icon ] vs [ Stance B icon ]          │
│              "Attack beats Feint!"                      │
│                                                         │
│             ★ Read  "He shifts his weight..."           │
│                          [Feint icon]                   │
│                                                         │
│  [ Attack ]  [ Defend ]  [ Feint ]  [ Crushing Blow ]  │
│                   [Stamina costs shown as subtitle]     │
│                                                         │
│                    [ Yield ] ← conditionally visible   │
│                                                         │
│                                              Turn 7     │
└─────────────────────────────────────────────────────────┘
```

### Component Table

| Component | Node Type | Behavior |
|-----------|-----------|----------|
| `DuelOverlayLayer` | CanvasLayer (layer 10) | Root overlay node. Renders above battlefield. |
| `BackgroundDarken` | ColorRect (full viewport) | Dark semi-transparent rect behind duel frame. Opacity: `background_darken_amount`. |
| `DuelFrame` | PanelContainer | Centered panel, ~80% viewport width. Neoclassical border styling. |
| `OpponentPanel` | HBoxContainer (left ~45%) | Contains portrait, name, resolve bar, stamina pips. |
| `PlayerPanel` | HBoxContainer (right ~45%) | Mirror of opponent panel. |
| `PortraitImage` | TextureRect (×2) | Officer portrait. Crop-to-fill mode. |
| `NameLabel` | Label (×2) | Officer name. Font: display/header font. |
| `ResolveBar` | Custom TextureProgress (×2) | Color-interpolating bar. Tweens on resolve change. |
| `ResolveLabel` | Label (×2) | "[current] / [max]" below resolve bar. |
| `StaminaPipRow` | HBoxContainer (×2) | N pip TextureRects. Pips deactivate on stamina spend. |
| `CenterDivider` | VBoxContainer (center ~10%) | VS text during SELECTING; stance icons + result during RESOLVING; hint during READ_HINT. |
| `OpponentStanceSlot` | TextureRect | Opponent's chosen stance icon. Hidden until reveal. |
| `PlayerStanceSlot` | TextureRect | Player's chosen stance icon. Hidden until reveal (shown privately after commit). |
| `ResultLabel` | Label | RPS outcome text. Visible during RESOLVING only. |
| `ReadHintContainer` | PanelContainer | Holds all Read hint elements. Opacity 0 until Read fires. |
| `ReadHintLabel` | Label | Flavor text. Italic. Max 10 words. |
| `ReadHintStanceIcon` | TextureRect (32×32) | The hinted stance icon. |
| `ActionBar` | HBoxContainer | Bottom of duel frame. Always rendered. |
| `AttackButton` | Button [Q] | Attack stance. Grayed when stamina < 2. |
| `DefendButton` | Button [W] | Defend stance. Grayed when stamina < 1. |
| `FeintButton` | Button [E] | Feint stance. Grayed when stamina < 1. |
| `SignatureMoveButton` | Button [R] | Sig Move. Absent if null; grayed if used or insufficient stamina. |
| `YieldButton` | Button [Y] | Separate from ActionBar. Opacity 0 until yield condition. |
| `TurnCounter` | Label | "Turn N" in corner. Updates each turn. |
| `DuelEndOverlay` | Control | Positioned above DuelFrame. Title card + portrait modulation. |

### Keyboard Navigation

| Key | Action | Available In |
|-----|--------|-------------|
| Q | Attack | UI_SELECTING (if attack_available) |
| W | Defend | UI_SELECTING (if stamina ≥ 1) |
| E | Feint | UI_SELECTING (if stamina ≥ 1) |
| R | Signature Move | UI_SELECTING (if sig_move_available) |
| Y | Yield | UI_SELECTING (if yield_button_visible) |
| D-pad / Arrow keys | Cycle focus between available buttons | UI_SELECTING |
| Enter / Space / A (gamepad) | Confirm focused button | UI_SELECTING |
| Escape / Start (gamepad) | Open pause menu | All phases |

No mouse hover feedback is shown during UI_RESOLVING or UI_READ_HINT — all interactive visual states are cleared on phase entry.

### Gamepad Support (Partial)

D-pad navigates between the available stance buttons. Focus order: Attack → Defend → Feint → Signature Move (if present) → Yield (if visible). A button confirms. Grayed buttons are skipped in focus order.

**NOT supported**: Analog stick navigation, trigger shortcuts. Gamepad is partial support per technical preferences — the primary UX is keyboard/mouse.

📌 **UX Flag — Duel UI**: This system has UI requirements. In Phase 4 (Pre-Production), run `/ux-design` to create a UX spec for each screen or HUD element this system contributes to **before** writing epics. Stories that reference UI should cite `design/ux/duel-screen.md`, not the GDD directly.

## Acceptance Criteria

*Lean mode: `qa-lead` not consulted — review manually before production. Criteria cover all core rules from Section C and all display formulas from Section D.*

### Initialization

1. **GIVEN** a duel is initiated with two named officers, **WHEN** `DuelUI.initialize()` is called, **THEN** both officer portraits appear, both officer names appear, and both resolve bars display at full fill (1.0 fraction) within 0.7 seconds of the call.

2. **GIVEN** the initialization transition is playing, **WHEN** the player presses any stance key (Q / W / E / R), **THEN** no stance is committed — input is discarded until the transition completes.

3. **GIVEN** an officer with no Signature Move (null), **WHEN** the duel UI initializes for that officer, **THEN** no Signature Move button is rendered in the action bar — the bar contains exactly three buttons (Attack, Defend, Feint).

4. **GIVEN** an officer with a Signature Move, **WHEN** the duel UI initializes, **THEN** the action bar contains four buttons and the Signature Move button displays the move name and stamina cost in a subtitle.

### Resolve Bar (F-1)

5. **GIVEN** an officer's resolve is at full (current = max), **WHEN** the resolve bar is rendered, **THEN** the bar fill is 1.0 (completely filled) and the bar color is green.

6. **GIVEN** an officer's resolve fill fraction falls below 0.60, **WHEN** the resolve bar updates, **THEN** the bar color transitions from green toward yellow continuously (not a discrete snap).

7. **GIVEN** an officer's resolve fill fraction falls below 0.30, **WHEN** the resolve bar updates, **THEN** the bar color is in the red zone.

8. **GIVEN** damage is applied this turn and the officer's resolve changes, **WHEN** the resolve bar receives the new value, **THEN** the bar tweens from the old fill to the new fill over `resolve_bar_tween_duration` (default 0.4 s).

9. **GIVEN** Kaster (max resolve 84) takes 14 damage (current resolve = 70), **WHEN** the resolve bar is rendered, **THEN** fill fraction = 70/84 ≈ 0.833 and the bar is in the green zone.

### Stamina Pips (F-2)

10. **GIVEN** Alexsen (max stamina 9) begins a duel, **WHEN** the stamina pip row is initialized, **THEN** exactly 9 pips are rendered and all 9 are lit.

11. **GIVEN** Alexsen uses Crushing Blow (cost 4), **WHEN** the turn resolves, **THEN** 4 pips deactivate with a 0.2 s stagger, leaving 5 lit pips and 4 dark pips.

12. **GIVEN** any officer's current stamina = 0, **WHEN** the stamina pip row is rendered, **THEN** all pips are dark (0 lit pips).

### Stance Button Availability (F-4)

13. **GIVEN** a player officer with current stamina = 2, **WHEN** stance buttons are rendered, **THEN** Attack (cost 2), Defend (cost 1), and Feint (cost 1) are all interactive; Signature Move is locked if stamina < sig_move_cost.

14. **GIVEN** a player officer with current stamina = 1, **WHEN** stance buttons are rendered, **THEN** Attack is non-interactive (grayed); Defend and Feint are interactive.

15. **GIVEN** a player officer with current stamina = 0, **WHEN** stance buttons are rendered, **THEN** Attack and Feint are non-interactive (grayed); Defend is the only interactive stance.

16. **GIVEN** a player officer has already used their Signature Move this duel, **WHEN** stance buttons are rendered in a subsequent turn, **THEN** the Signature Move button is rendered but non-interactive (grayed), regardless of current stamina.

17. **GIVEN** a player officer's current stamina is sufficient for Signature Move AND the move has not been used, **WHEN** the player presses [R], **THEN** the Signature Move is committed and all stance buttons immediately lock.

### Input and Commitment

18. **GIVEN** the UI is in UI_SELECTING state, **WHEN** the player presses [Q] (Attack) and Attack is available, **THEN** the Attack stance is committed, all stance buttons lock, and the UI transitions to UI_RESOLVING.

19. **GIVEN** the UI is in UI_RESOLVING state, **WHEN** the player presses any stance key or clicks any button, **THEN** the input is discarded — no stance is committed, no state changes.

20. **GIVEN** the UI is in UI_READ_HINT state, **WHEN** the player presses any stance key, **THEN** the input is discarded — the Read hint completes its display duration before the next selection phase begins.

21. **GIVEN** the UI has committed a player stance and is in UI_RESOLVING, **WHEN** the player presses Escape, **THEN** a pause menu opens above the duel UI layer and the duel state is not modified.

### Stance Reveal Sequence

22. **GIVEN** a turn has resolved, **WHEN** both stances are revealed, **THEN** both stance icons appear in the center reveal area simultaneously (within the same animation frame, not sequentially).

23. **GIVEN** the stance icons have flipped, **WHEN** the outcome is determined, **THEN** result text appears within 0.3 s of the flip completing and accurately describes the outcome (e.g., "Attack beats Feint", "Tie!", "Counter!", "Crushing Blow!").

24. **GIVEN** damage was dealt to an officer, **WHEN** the damage number is displayed, **THEN** a "–[N]" label floats upward from the affected portrait and fades over `damage_label_duration` seconds.

25. **GIVEN** no damage was dealt (e.g., Defend–Defend tie or scripted miss), **WHEN** the turn resolves, **THEN** no floating damage label appears for the participant who took 0 damage.

26. **GIVEN** Alexsen uses Crushing Blow (damage dealt = attack_damage = 14), **WHEN** the damage number renders, **THEN** the label uses the large font size tier (damage ≥ 11).

### Read Hint Display

27. **GIVEN** the Duel System signals `read_fired` on turn 3 with a Read hint, **WHEN** the RESOLVING animations complete, **THEN** the Read hint area fades in with the flavor text and a stance icon.

28. **GIVEN** a Read hint is displayed, **WHEN** the displayed stance icon is rendered, **THEN** there is NO visual or audio difference between a correct hint (70% case) and an incorrect hint (30% case) — both render identically.

29. **GIVEN** a Read hint is displaying, **WHEN** `read_hint_display_duration` elapses (default 2.5 s), **THEN** the hint fades out over `read_hint_fade_duration` and UI_SELECTING begins.

30. **GIVEN** the duel ends on the same turn as a Read hint would fire, **WHEN** `on_duel_ended()` is received before the Read hint is queued, **THEN** the Read hint is NOT displayed — UI transitions directly to UI_END.

### Yield Button

31. **GIVEN** the opponent's resolve has not yet dropped below the yield threshold, **WHEN** the UI renders the action area, **THEN** the Yield button is not visible (opacity 0, not interactive).

32. **GIVEN** opponent's resolve drops to exactly `floor(opponent_max_resolve × 0.30)` or below, **WHEN** RESOLVING animations complete, **THEN** the Yield button begins its fade-in over `yield_button_fade_duration` seconds.

33. **GIVEN** the Yield button has become visible, **WHEN** the player presses [Y], **THEN** `DuelSystem.commit_yield()` is called, the duel ends, and the UI transitions to UI_END with ENDED_YIELD result.

34. **GIVEN** a scripted duel with `yield_forced_at_resolve_pct` triggers, **WHEN** the forced threshold is met, **THEN** Attack, Defend, Feint, and Signature Move buttons are ALL hidden (not visible), and only the Yield button is rendered and interactive.

### Duel End

35. **GIVEN** the duel ends with `ENDED_VICTORY`, **WHEN** UI_END fires, **THEN** the "Victory" title card displays, the player's portrait brightens, the opponent's portrait dims, and the overlay holds for `end_title_hold_duration` seconds.

36. **GIVEN** the duel ends with `ENDED_DEFEAT`, **WHEN** UI_END fires, **THEN** the "Defeat" title card displays and the player's portrait dims.

37. **GIVEN** the duel ends with `ENDED_YIELD`, **WHEN** UI_END fires, **THEN** an "Honour Given" (or localized equivalent) title card displays.

38. **GIVEN** the duel ends with `ENDED_DRAW`, **WHEN** UI_END fires, **THEN** the "Draw" title card displays and both portraits dim slightly.

39. **GIVEN** any duel end result, **WHEN** the title card hold completes, **THEN** the duel frame fades out, the battlefield returns to normal brightness, and `duel_ui_closed` is emitted — in that order.

40. **GIVEN** `duel_ui_closed` has NOT yet been emitted, **WHEN** the Tactical Battle Controller checks for duel state, **THEN** the duel is still considered active and no tactical turn processing resumes.

### Final Exchange

41. **GIVEN** both participants simultaneously reach stamina 0 (Final Exchange condition), **WHEN** the UI receives `on_turn_resolved()` for the Final Exchange turn, **THEN** both stance icons are shown as Defend, result text shows "Final Exchange", and NO player input is requested before the resolve bars animate.

### Keyboard Navigation

42. **GIVEN** the UI is in UI_SELECTING state with all stances available, **WHEN** the player navigates using D-pad, **THEN** focus cycles through Attack → Defend → Feint → (Signature Move if present) → Yield (if visible) → back to Attack.

43. **GIVEN** a stance button is grayed (non-interactive), **WHEN** the player navigates with D-pad, **THEN** focus skips the grayed button and moves to the next interactive button.

44. **GIVEN** Escape is pressed during UI_RESOLVING or UI_READ_HINT, **WHEN** the pause menu attempts to open, **THEN** the duel input lock is maintained — the pause menu opens but the duel UI state does not change and no stance is committed.

## Open Questions

1. **Privately showing the player's committed stance**: After the player commits their stance, should the player see their own stance icon privately (on their portrait side) before the reveal? This makes the 0.3 s anticipation pause feel less blank. Risk: it subtly removes the "commitment anxiety" of not seeing your choice reflected back. Confirm with UX review.

2. **Scripted duel: should the stance buttons lock during scripted opponent "thinking"?** The 0.3 s pause after commitment mimics opponent deliberation. In scripted duels, the AI behavior is deterministic — the pause is purely cosmetic. Some scripted scenes may benefit from a longer pause (e.g., Mission 6 Thane's intentional miss should feel like hesitation). Consider a per-mission `opponent_deliberation_time` override in `ScriptedDuelDefinition`.

3. **Read hint flavor text authoring**: The Duel System generates a Read hint each time one fires, but the flavor text must be authored (not formula-derived). Who owns the flavor text bank? Each officer-pair combination may warrant unique lines ("He shifts his weight..." works generically; "Thane's grip loosens, almost deliberately..." is specific to Mission 6). Assign to writer agent with a spec for each named-officer pairing before implementation.

4. **Signature Move tooltip on hover**: The Signature Move button shows a tooltip describing the move's effect. Who authors the tooltip text? The GDD describes mechanics; the tooltip needs a 2-line player-facing description. Assign to writer agent.

5. **Resolve color theme for scripted duels with emotional framing**: The standard green → yellow → red color scheme communicates "danger." For Mission 6 (Thane intentionally letting Alexsen win), the red zone on Thane's bar appears as Thane is "losing" — but the player later learns Thane was in control the whole time. Consider whether the standard color treatment is at odds with the narrative subtext, or whether the subversion IS the point. Confirm with art director + narrative director before production.
