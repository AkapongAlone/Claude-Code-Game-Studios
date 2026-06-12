# Save/Load System

> **Status**: In Design
> **Author**: Lead Programmer + Game Designer
> **Last Updated**: 2026-06-12
> **Implements Pillar**: P1 — Victory Through Preparation (campaign progress preserved) + P4 — Authored Peaks, Player Valleys (story beats survive session end)

---

## Overview

The Save/Load System is a meta-layer infrastructure service that persists game state to disk and restores it on demand. It supports two save scopes: **Campaign Saves** (full game state between battles — officer registry, campaign layer, story flags) and **Tactical Saves** (mid-battle snapshots capturing the current battle state at turn start). A third variant, **Auto-Save**, fires automatically at natural checkpoints and writes to a dedicated slot. The system does not own any game state; it delegates serialization to each subsystem via a defined manifest contract and orchestrates the collection and restoration cycle. Save files are JSON, consistent with the project's data-driven file conventions (`assets/data/*.json`). All files are written to Godot's `user://saves/` directory. The system defines a save-format version field in every file header, enabling forward migration of older saves across game updates. MVP scope covers tactical saves in full and campaign saves provisionally — campaign save state will be extended as Campaign Layer GDDs are designed.

## Player Fantasy

The Save/Load system is pure infrastructure — the player never "plays" it. What the player feels is **confidence and trust**: they invest an hour into a careful campaign turn, push hard for an intel advantage going into the next battle, and close the game knowing that work will be there tomorrow, exactly as they left it. The absence of a save system would be felt immediately; the presence of a well-working one is felt as absence of anxiety. Save/Load serves P1 (Victory Through Preparation) by ensuring that preparation — planning, intel work, officer assignments — is never lost to an accidental close or a crash. It serves P4 (Authored Peaks, Player Valleys) by ensuring the authored story beats the player unlocked remain unlocked. The moment the player sees "Game Saved" and the progress indicator fills, there is a small exhale of relief. That is the entire emotional signature this system needs to deliver.

> *`creative-director` not consulted — Lean mode. Review manually before production.*

## Detailed Design

### Core Rules

**Save Categories**

| Category | Scope | Slots | When Allowed |
|---|---|---|---|
| Campaign Save | Full game state between battles | 3 manual + 1 auto | Only from campaign layer (not mid-battle) |
| Tactical Save | Current battle state at turn start | 1 (always overwrites) | Only from tactical layer, only at the start of the player's turn |
| Auto-Save | Automatic checkpoint write | 1 dedicated | At defined automatic triggers (see below) |

**Save Slot Rules**

1. Three manual Campaign Save slots. Each slot shows: slot name, battle name or campaign date, playtime, date saved.
2. One Campaign Auto-Save slot. Overwrites silently on each trigger.
3. One Tactical Save slot. Can only hold one mid-battle save at a time; writing a new one overwrites the previous without warning.
4. The Tactical Save slot is cleared when the battle ends (win or loss). After a battle end, a Campaign Auto-Save fires to capture the outcome — the tactical slot is then empty.
5. There is no limit on the number of times the player may manually overwrite a campaign save slot.

**Auto-Save Triggers**

| Trigger | Save Type | Description |
|---|---|---|
| Battle deployment confirmed | Campaign Auto-Save | Before the first turn begins; captures pre-battle officer and campaign state |
| Battle end (win or loss) | Campaign Auto-Save | After victory/defeat resolution, before returning to campaign layer |
| Campaign turn end | Campaign Auto-Save | At the end of each campaign turn (not yet defined — provisional, flagged below) |
| Player turn start (tactical) | Tactical Save | Overwrites the tactical slot at the start of each player turn |

**Mid-Duel Save Restriction**

Saving mid-duel is not permitted. The last Tactical Save before a duel began is the reload point if the player quits during a duel. When a duel is triggered:
- The system checks for an unsaved tactical state; if none, the automatic turn-start save was already written.
- The existing Tactical Save file is not touched during the duel.
- If the player force-quits mid-duel and reloads, they replay from the start of the turn on which the duel was triggered.

**File Format**

All save files are UTF-8 JSON. Structure:

```json
{
  "save_format_version": 1,
  "game_version": "0.1.0",
  "save_type": "campaign | tactical | auto",
  "timestamp": "ISO-8601",
  "playtime_seconds": 0,
  "slot_display_name": "",
  "checksum": "",
  "state": { ... }
}
```

- `save_format_version` is the serialization schema version, not the game version. Increments only when the schema changes in a breaking way.
- `checksum` is an MD5 hash of the `state` field as a serialized string. Used to detect file corruption only — not for security or anti-cheat.
- `game_version` is informational. Used in migration logic and error messages.

**File Locations**

```
user://saves/campaign/slot_1.json
user://saves/campaign/slot_2.json
user://saves/campaign/slot_3.json
user://saves/campaign/auto.json
user://saves/tactical/battle.json
```

**Serialization Contract**

Each gameplay system that owns persistent state implements a serialization interface:

```gdscript
func serialize() -> Dictionary:
    # Returns a Dictionary of this system's saveable state.

func deserialize(data: Dictionary) -> void:
    # Restores this system's state from a Dictionary.
    # Must validate keys before accessing — missing keys should use defaults.
```

The Save/Load System calls `serialize()` on each registered system during a save, collects the results into the `state` field, and calls `deserialize()` on each registered system during a load, passing each system its slice of the state Dictionary.

Systems register themselves with the Save/Load System at game start. The order of `deserialize()` calls must respect dependency order: Officer Registry before Squad state, Terrain before Fog of War.

**Tactical Save State Inventory (MVP — fully specified)**

The `state` field of a Tactical Save contains the following keys:

```json
{
  "battle": {
    "battle_id": "",
    "turn_number": 0,
    "current_phase": "MOVEMENT | COMBAT | MORALE | AI_TURN",
    "active_side": "PLAYER | ENEMY",
    "condition_type": "ROUTE_ENEMY | HOLD_OBJECTIVE | SURVIVE_TURNS | SCRIPTED",
    "turn_limit": 0,
    "objective_hexes": [ { "q": 0, "r": 0, "s": 0 } ]
  },
  "squads": [
    {
      "squad_id": 0,
      "side": "PLAYER | ENEMY",
      "unit_type": "INF | LI | CAV | ART",
      "officer_id": "",
      "position": { "q": 0, "r": 0, "s": 0 },
      "facing": 0,
      "current_hp": 0,
      "max_hp": 0,
      "morale": 0,
      "morale_state": "STEADY | SHAKEN | BROKEN",
      "ap_remaining": 0,
      "ap_pool": 0,
      "has_moved_this_turn": false,
      "has_attacked_this_turn": false
    }
  ],
  "fog": {
    "squad_vision_states": [
      {
        "squad_id": 0,
        "vision_state": "VISIBLE | PREVIOUSLY_SEEN | UNSEEN",
        "last_known_position": { "q": 0, "r": 0, "s": 0 },
        "last_seen_turn": 0
      }
    ]
  },
  "terrain_deltas": [
    {
      "position": { "q": 0, "r": 0, "s": 0 },
      "charred": false,
      "has_ford_crossing": false
    }
  ],
  "victory_progress": {
    "player_broken_count": 0,
    "player_routed_count": 0,
    "player_dead_count": 0,
    "player_starting_count": 0,
    "enemy_broken_count": 0,
    "enemy_routed_count": 0,
    "enemy_dead_count": 0,
    "enemy_starting_count": 0,
    "objective_held_turns": 0,
    "survive_turns_elapsed": 0
  },
  "officers": [
    {
      "officer_id": "",
      "war": 0, "ldr": 0, "int_stat": 0, "pol": 0, "chr": 0
    }
  ]
}
```

- `terrain_deltas` contains only hexes whose state differs from the base map definition. Empty if no terrain has changed.
- Officer stats are serialized for the officers present in this battle (to capture any mid-battle growth; base stats are immutable per Officer Stats GDD so this may be empty at MVP).

**Campaign Save State Inventory (provisional — campaign systems not yet designed)**

```json
{
  "campaign": {
    "act": 0,
    "campaign_turn": 0,
    "story_flags": {},
    "officer_registry": [ { "officer_id": "", "war": 0, "ldr": 0, "int_stat": 0, "pol": 0, "chr": 0, "available": true, "assignment": "" } ]
  }
}
```

The following campaign state keys are flagged **PROVISIONAL** — they will be extended as Campaign Layer GDDs are designed (Resource System, Settlement Data, Campaign Map, Intel, Army Composition):
- `resources` (Gold, Supplies, Manpower, Intel)
- `settlements` (ownership, loyalty, special resources)
- `campaign_map_state` (faction control, road damage)
- `army_compositions` (which squads are in which army)
- `intel_state` (revealed intelligence, decay counters)
- `covert_ops_state`
- `diplomatic_state`

**Load Sequence**

1. Read file from disk.
2. Validate JSON parse (if malformed: show error dialog).
3. Validate checksum (if mismatch: warn player, offer to load anyway or cancel).
4. Check `save_format_version` against current schema (if incompatible: run migration or show incompatibility error).
5. Deserialize in dependency order: Battle metadata → Officer Registry → Squad state → Terrain deltas → Fog of War → Victory progress.
6. Transition the game to the correct scene (Campaign Map or Tactical Battle).
7. Confirm load success (brief "Loaded" status in UI).

### States and Transitions

The Save/Load System is stateless between operations. Each save or load is an atomic operation from the system's perspective.

| Operation | Initial State | Steps | Final State |
|---|---|---|---|
| Manual Campaign Save | Game running | Show save slot picker → player selects slot → serialize() on all systems → write JSON → update slot metadata → show "Saved" | File written |
| Manual Tactical Save | Player turn active in tactical | Serialize battle state → write `user://saves/tactical/battle.json` → show "Saved" indicator | File written |
| Auto-Save | Trigger fired | Serialize appropriate state → write to auto slot → no player-facing prompt | File written silently |
| Load from Campaign Menu | Main menu or campaign menu | Show load slot picker → player selects slot → read file → validate → deserialize() on all systems → transition scene | Game state restored |
| Load after Quit (Tactical) | Main menu | Show "Resume battle?" prompt (if tactical save exists) → load tactical save → restore battle scene | Battle restored |
| Load Error | Any load attempt | Read file → validation fails → show error dialog → offer retry or cancel → return to menu | No state change |

**Tactical Save Availability**

The Tactical Save option (from the pause menu during battle) is available only:
- During the player's turn
- When current phase is MOVEMENT or COMBAT
- Not during MORALE phase
- Not during AI_TURN
- Not during an active duel (`INTERACTION_LOCKED` mode)

### Interactions with Other Systems

| System | Direction | Interface |
|---|---|---|
| Officer Registry / Officer Stats | Pull (on save) | `OfficerRegistry.serialize()` → officer_id, all 5 stats, availability, assignment |
| Squad / Combat Resolution | Pull (on save) | `SquadManager.serialize()` → position, facing, HP, morale, morale_state, AP, unit_type, officer_id per squad |
| Terrain System | Pull (on save) | `TerrainSystem.serialize_deltas()` → only hexes modified from base map (charred, ford) |
| Fog of War System | Pull (on save) | `FogOfWarSystem.serialize()` → per-squad vision_state, last_known_position, last_seen_turn |
| Morale System | Covered by Squad serialization | `morale` integer and `morale_state` enum included in squad record |
| Facing & Flank | Covered by Squad serialization | `facing` direction (0–5) included in squad record |
| Hex Movement | Covered by Squad serialization | `ap_remaining`, `ap_pool`, `has_moved_this_turn` included in squad record |
| Victory/Defeat Conditions | Pull (on save) | `VictoryChecker.serialize()` → broken/routed/dead counts, starting counts, progress counters |
| Battle Flow Controller | Caller | Triggers auto-save at battle start and battle end; passes battle_id and phase state |
| Campaign Layer (provisional) | Pull (on save) | Not yet designed — will extend campaign save state as GDDs are authored |
| Scene Manager | Called (on load) | SaveLoadSystem calls scene transition after deserialization completes |
| UI (Save/Load menus) | Calls SaveLoadSystem | Save menu calls `SaveLoadSystem.save_campaign(slot)` or `SaveLoadSystem.save_tactical()` |

## Formulas

The Save/Load System has no mathematical gameplay formulas. Its "formulas" are deterministic schema contracts and integrity rules.

**F-1: Checksum Calculation**

```
checksum = MD5(JSON.stringify(state))
```

**Variables:**

| Variable | Type | Description |
|---|---|---|
| `state` | Dictionary | The complete `state` field of the save file (excludes header fields) |
| `JSON.stringify(state)` | String | Deterministic JSON serialization of the state dictionary |
| `MD5(s)` | String (hex) | 32-character hex MD5 digest |

**Output**: 32-character lowercase hex string.

**On load**: Recompute `MD5(JSON.stringify(file["state"]))` and compare to the stored `checksum`. A mismatch does not block loading — it triggers a warning dialog ("This save file may be corrupted. Load anyway?").

**Example**: `state = {"battle": {"turn_number": 4, ...}}` → `checksum = "d8e8fca2dc0f896fd7cb4cb0031ba249"` (illustrative).

---

**F-2: Save Format Version Migration Rule**

```
migration_required = (file.save_format_version < CURRENT_SAVE_FORMAT_VERSION)
migration_possible = (file.save_format_version >= CURRENT_SAVE_FORMAT_VERSION - MAX_MIGRATION_DEPTH)
```

**Variables:**

| Variable | Type | Range | Description |
|---|---|---|---|
| `file.save_format_version` | int | ≥ 1 | Version recorded in the save file |
| `CURRENT_SAVE_FORMAT_VERSION` | int constant | current | The schema version the running game expects |
| `MAX_MIGRATION_DEPTH` | int constant | 2 (default) | How many major versions back migration is supported |

**Output**:
- `migration_required = true` AND `migration_possible = true` → migrate and load
- `migration_required = true` AND `migration_possible = false` → incompatible save; show error, do not load
- `migration_required = false` → load directly

**Example**: `CURRENT = 3`, `file.version = 2`, `MAX_MIGRATION_DEPTH = 2` → required=true, possible=true → migrate.

---

**F-3: File Path Construction**

```
campaign_path(slot) = "user://saves/campaign/slot_" + str(slot) + ".json"   # slot ∈ {1, 2, 3}
campaign_auto_path  = "user://saves/campaign/auto.json"
tactical_path       = "user://saves/tactical/battle.json"
```

**Variables:**

| Variable | Type | Range | Description |
|---|---|---|---|
| `slot` | int | 1–3 | Manual campaign save slot number |

All paths resolve to the OS user data directory via Godot's `user://` path alias (`OS.get_user_data_dir()`).

---

**F-4: Playtime Accumulator**

```
playtime_seconds(save) = previous_playtime + elapsed_since_last_save
```

**Variables:**

| Variable | Type | Description |
|---|---|---|
| `previous_playtime` | int | Seconds stored in the last save file in this slot |
| `elapsed_since_last_save` | float | Wall-clock seconds since the last successful save in this slot |

**Output**: Cumulative integer seconds. Displayed as `"H:MM"` in the save slot UI.

**Example**: `previous = 3600`, `elapsed = 754.3` → `playtime = 4354` → displayed as `"1:12"`.

## Edge Cases

**E-01** — JSON parse failure on load: show error dialog "This save file is unreadable and cannot be loaded." Offer to delete the file or cancel. Do not attempt partial deserialization.

**E-02** — Checksum mismatch on load: show warning dialog "This save file may be corrupted. Load anyway?" Options: Load (risky), Cancel. If the player loads a corrupt file, any resulting broken state is their responsibility. Log the mismatch to the error log.

**E-03** — `save_format_version` in the file exceeds `CURRENT_SAVE_FORMAT_VERSION`: the save was made with a newer version of the game. Show error: "This save requires a newer version of the game." Do not load.

**E-04** — Migration required but `save_format_version` is too old (beyond `MAX_MIGRATION_DEPTH`): show error "This save is from an older version and cannot be migrated. A new game is required." Do not load. Offer to delete.

**E-05** — Disk full on write: catch `FileAccess` write error; show error "Save failed — disk full. Free up space and try again." Do not leave a partially written file (write to a temp file first, then rename on success — atomic write pattern).

**E-06** — Campaign save attempted while mid-battle: Save/Load System refuses the call and returns an error. Campaign Save is only available from the campaign layer. The UI should not surface this option mid-battle, but the system must guard against it regardless.

**E-07** — Tactical save attempted during MORALE phase or AI_TURN: Save/Load System refuses the call. The UI should grey out the Save option during these phases; the system returns early if called unexpectedly.

**E-08** — Tactical save attempted while duel is active (`INTERACTION_LOCKED`): Save/Load System refuses the call. The Duel UI does not expose a save option, but the system must guard it.

**E-09** — Player quits mid-battle and reloads: if `user://saves/tactical/battle.json` exists, the main menu shows a "Resume Battle" prompt. Loading restores the tactical save. The player replays from the start of that turn.

**E-10** — Battle ends, tactical save file still exists: Battle Flow Controller triggers a Campaign Auto-Save on battle end. After the auto-save completes successfully, the Save/Load System deletes `user://saves/tactical/battle.json`. If the auto-save fails, the tactical file is preserved and a warning is shown.

**E-11** — Two auto-save triggers fire near-simultaneously (e.g., "player turn start" at the same moment as a scripted event): the Save/Load System queues save operations; it does not run two saves concurrently. The second trigger is dropped if the first save is still in progress.

**E-12** — Player loads a Campaign Save that references a `battle_id` that no longer exists in the game (e.g., content removed in a patch): load proceeds but the battle reference is treated as null. The campaign loads to the campaign map layer. Log a warning.

**E-13** — Save slot is overwritten with a new save while that slot is "in use" (player confirming in a dialog): the overwrite does not begin until the player confirms. If the player dismisses without confirming, the existing save is preserved.

**E-14** — Officer data in a tactical save references an `officer_id` not present in the officer registry (data inconsistency): deserialize skips that officer with a warning log entry. The squad that referenced the officer proceeds with no assigned officer (silhouette fallback per Tactical HUD GDD E-04).

## Dependencies

### Upstream (this GDD depends on — must serialize their state)

| System | GDD Status | What Save/Load Needs |
|---|---|---|
| Officer Stats System | Approved | `officer_id`, 5 stats, availability, assignment |
| Terrain System | Approved | Modified tile deltas (charred, ford crossing) |
| Combat Resolution System | Approved | Squad HP, unit_type, officer_id |
| Morale System | Designed | Squad morale integer, MoraleState enum value |
| Facing & Flank System | Designed | Squad facing direction (0–5) |
| Hex Movement System | Designed | Squad position (cube coords), AP remaining, AP pool, has_moved, has_attacked |
| Fog of War System | Designed | Per-squad VisionState, last_known_position, last_seen_turn |
| Victory/Defeat Conditions System | Designed | broken/routed/dead counts, starting counts, objective progress counters |
| Duel System | Designed | No mid-duel save; duel state not serialized |
| Officer Passive Ability System | Designed | No passive state at MVP (passives are deterministic from stats) |
| Tactical HUD | Designed | No state to save — HUD state is derived from gameplay systems on load |
| Duel UI | Designed | No state to save — not saveable mid-duel |
| Portrait & Character Display | Designed | No state to save — display only |
| Resource System | Not Started | *(provisional)* Gold, Supplies, Manpower, Intel values |
| Settlement Data System | Not Started | *(provisional)* Ownership, loyalty, special resources per settlement |
| Campaign Map System | Not Started | *(provisional)* Faction control, road state |
| Intel System | Not Started | *(provisional)* Revealed intel, decay counters, misinformation flags |
| Army Composition System | Not Started | *(provisional)* Which squads are in which army |
| Story Event System | Not Started | *(provisional)* Triggered event flags, act/scene state |

### Downstream (depends on this GDD)

No systems depend on Save/Load. It is the terminal meta system.

### Bidirectionality Note

Each upstream system whose GDD is already written should add "depended on by: Save/Load System" to its Dependencies section. This backfill is deferred until the next design review cycle for those GDDs.

## Tuning Knobs

All values live in `assets/data/save_config.json`.

| Key | Default | Safe Range | Affects |
|---|---|---|---|
| `campaign_save_slots` | 3 | [1, 10] | Number of manual campaign save slots available |
| `max_migration_depth` | 2 | [1, 5] | How many save format versions back migration is supported |
| `auto_save_enabled` | true | [true, false] | Toggle all auto-save triggers on/off |
| `tactical_auto_save_on_turn_start` | true | [true, false] | Whether tactical save fires at the start of each player turn |
| `campaign_auto_save_on_turn_end` | true | [true, false] | Whether campaign auto-save fires at end of campaign turn |
| `atomic_write_enabled` | true | [true, false] | Write to temp file then rename (protects against partial write on crash) |
| `playtime_display_format` | "H:MM" | ["H:MM", "H:MM:SS"] | How playtime is shown in save slot UI |
| `checksum_algorithm` | "md5" | ["md5", "sha1"] | Hash algorithm for save file integrity check |
| `save_compression_enabled` | false | [true, false] | Enable gzip compression on save JSON (reduces file size, adds ~5ms to save time) |

**Knob interaction note**: Setting `atomic_write_enabled = false` reduces file safety on crash. Only disable during development if debugging partial-write scenarios. Setting `save_compression_enabled = true` requires the load path to decompress before JSON parse — the load sequence must handle both compressed and uncompressed files for backward compatibility.

## Acceptance Criteria

**Campaign Save / Load Round-Trip**

- AC-01: GIVEN a campaign game is in progress, WHEN the player saves to slot 1 from the campaign menu, THEN a valid JSON file exists at `user://saves/campaign/slot_1.json` with correct `save_format_version`, `save_type: "campaign"`, and a non-empty `checksum` field.
- AC-02: GIVEN a campaign save exists in slot 1, WHEN the player loads from slot 1, THEN all officer stats (all 5 per officer), officer assignments, and campaign state values match the values at the time of save.
- AC-03: GIVEN three campaign save slots exist, WHEN the player saves to slot 2, THEN only `slot_2.json` is modified; `slot_1.json` and `slot_3.json` are unchanged.

**Tactical Save / Load Round-Trip**

- AC-04: GIVEN a battle is in progress and it is the player's MOVEMENT phase, WHEN the player saves tactically, THEN `user://saves/tactical/battle.json` is written with all squad positions (cube coordinates), HP, morale, morale_state, facing, and AP values.
- AC-05: GIVEN a tactical save exists and the player quits and relaunches, WHEN the player selects "Resume Battle" from the main menu, THEN the battle scene loads with all squads at their saved positions, HP, and morale states — matching the values at time of save.
- AC-06: GIVEN a tactical save from turn N exists, WHEN the player completes a new turn and a new auto-save fires, THEN the tactical save is overwritten and the new save reflects turn N+1 state.
- AC-07: GIVEN a battle ends in victory or defeat, WHEN the battle-end resolution completes, THEN `user://saves/tactical/battle.json` no longer exists (file deleted after campaign auto-save succeeds).

**Auto-Save Triggers**

- AC-08: GIVEN a battle is about to begin, WHEN the player confirms deployment, THEN a campaign auto-save fires before the first turn begins, writing to `user://saves/campaign/auto.json`.
- AC-09: GIVEN a battle just ended, WHEN the victory/defeat screen is dismissed, THEN a campaign auto-save fires, capturing the post-battle state.
- AC-10: GIVEN `tactical_auto_save_on_turn_start = true`, WHEN the player's turn begins (phase transitions to MOVEMENT), THEN a tactical auto-save fires and overwrites the existing tactical slot.

**Save Restrictions**

- AC-11: GIVEN the game is in the MORALE phase, WHEN the player attempts to open the save menu, THEN the Tactical Save option is unavailable (greyed out or hidden).
- AC-12: GIVEN a duel is active (`INTERACTION_LOCKED`), WHEN the player attempts to save, THEN no save occurs and an appropriate error or lockout is shown.
- AC-13: GIVEN the game is in the campaign layer, WHEN the player attempts to initiate a Campaign Save, THEN the save proceeds; confirming there is no blocking restriction in campaign layer.

**Integrity and Error Handling**

- AC-14: GIVEN a save file with a manually altered `state` field (simulated corruption), WHEN the file is loaded, THEN the checksum mismatch is detected and a warning dialog is shown before loading proceeds.
- AC-15: GIVEN a save file with `save_format_version` set to a value two versions old, WHEN the file is loaded, THEN migration runs without error and the game state loads correctly.
- AC-16: GIVEN a save file with `save_format_version` set to a value three versions old (beyond `MAX_MIGRATION_DEPTH = 2`), WHEN the file is loaded, THEN an incompatibility error is shown and the load is rejected.
- AC-17: GIVEN disk is full at the time of a save attempt, WHEN the save is triggered, THEN a "disk full" error message is displayed and no partial file is written to the existing slot.

**Atomic Write**

- AC-18: GIVEN `atomic_write_enabled = true`, WHEN a save is performed, THEN the system writes to a `.tmp` file first and renames it to the final path only after a successful write. The final path file is not modified if the write process is interrupted.

**Slot UI**

- AC-19: GIVEN a save slot contains a save, WHEN the save slot is displayed in the UI, THEN it shows the slot name, battle or campaign location, playtime in `"H:MM"` format, and the save date.
- AC-20: GIVEN a save slot is empty, WHEN the save slot is displayed in the UI, THEN it shows "Empty" and no other data.

**Playtime Accumulation**

- AC-21: GIVEN a game session where the player plays for 30 minutes, saves, closes the game, resumes, and plays another 15 minutes, WHEN the player saves again to the same slot, THEN the playtime displayed is 45 minutes (cumulative).

## Open Questions

1. **Steam Cloud Save**: Should `user://saves/` be mirrored to Steam Cloud? This is a post-launch concern but affects the file path architecture at MVP (Steam Cloud requires specific path registration). Flag for Technical Director before Steam integration begins.

2. **Save encryption**: Should save files be obfuscated or encrypted before release? JSON saves are trivially editable. For a single-player game with no leaderboard or online component, this is a low-priority concern, but it should be confirmed as "out of scope" or "post-launch" before shipping.

3. **Campaign turn auto-save timing**: The "campaign turn end" auto-save trigger is provisional — the Campaign Map System has not defined what constitutes a campaign turn or where its end boundary is. This trigger must be finalized when the Campaign Map GDD is designed.

4. **Mid-battle passive state**: Officer Passive Ability GDD states passives are deterministic from stats (no runtime passive state at MVP). If a future GDD introduces passive cooldowns or per-battle charges, the tactical save state inventory must be updated.

5. **Multiplayer**: If a co-op or competitive multiplayer mode is added in a sequel, the single-player save contract is incompatible — each player would need their own state slice. This GDD explicitly covers single-player only. Flag if multiplayer scope expands.
