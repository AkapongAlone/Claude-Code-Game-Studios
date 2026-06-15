class_name TacticalHUD
extends CanvasLayer
## Tactical battle HUD (CanvasLayer 5 per tactical-hud.md).
##
## Functional MVP version built in code: top status bar (turn + enemy rout
## tracker), right-side unit inspector, End Turn / Duel buttons, event log,
## and the battle-end overlay. The full Tactical HUD GDD spec (7 modes,
## push/pull hybrid) lands in a later pass — this covers the playable loop.

signal end_turn_pressed
signal duel_pressed
signal restart_pressed

var _turn_label: Label
var _tracker_label: Label
var _portrait: TextureRect
var _inspector: Label
var _log_label: Label
var _duel_button: Button
var _end_overlay: Panel
var _log_lines: Array[String] = []
## Injected so the inspector can show player-visible passives (Heirloom
## Blade is filtered upstream and never reaches this layer).
var passives: PassiveRegistry = null


func _init() -> void:
	layer = 5


func _ready() -> void:
	var top := Panel.new()
	top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top.custom_minimum_size = Vector2(0, 40)
	add_child(top)

	_turn_label = Label.new()
	_turn_label.position = Vector2(16, 8)
	top.add_child(_turn_label)

	_tracker_label = Label.new()
	_tracker_label.position = Vector2(380, 8)
	top.add_child(_tracker_label)

	var side := Panel.new()
	side.anchor_left = 1.0
	side.anchor_right = 1.0
	side.anchor_top = 0.0
	side.anchor_bottom = 1.0
	side.offset_left = -270.0
	side.offset_top = 40.0
	add_child(side)

	var layout := VBoxContainer.new()
	layout.set_anchors_preset(Control.PRESET_FULL_RECT)
	layout.offset_left = 12.0
	layout.offset_top = 12.0
	layout.offset_right = -12.0
	layout.add_theme_constant_override("separation", 10)
	side.add_child(layout)

	var inspector_title := Label.new()
	inspector_title.text = "UNIT INSPECTOR"
	layout.add_child(inspector_title)

	_portrait = TextureRect.new()
	_portrait.custom_minimum_size = Vector2(246, 120)
	_portrait.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_portrait.visible = false
	layout.add_child(_portrait)

	_inspector = Label.new()
	_inspector.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_inspector.custom_minimum_size = Vector2(0, 250)
	_inspector.text = "Select a squad."
	layout.add_child(_inspector)

	_duel_button = Button.new()
	_duel_button.text = "Challenge to Duel (D)"
	_duel_button.visible = false
	_duel_button.pressed.connect(func() -> void: duel_pressed.emit())
	layout.add_child(_duel_button)

	var end_turn := Button.new()
	end_turn.text = "End Turn (Enter)"
	end_turn.pressed.connect(func() -> void: end_turn_pressed.emit())
	layout.add_child(end_turn)

	var log_title := Label.new()
	log_title.text = "BATTLE LOG"
	layout.add_child(log_title)

	_log_label = Label.new()
	_log_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_log_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(_log_label)


## Updates the top bar: turn counter + enemy rout-fraction tracker
## ("Enemy: 3/10 squads broken" per victory-defeat UI requirements).
func update_status(turn: int, battle_name: String, enemy_broken: int, enemy_total: int) -> void:
	_turn_label.text = "%s — Turn %d" % [battle_name, turn]
	_tracker_label.text = "Enemy squads broken: %d / %d (rout at %d)" % [enemy_broken, enemy_total, int(ceilf(enemy_total * 0.5))]


## Shows the selected squad in the inspector.
func show_squad(squad: Squad) -> void:
	_duel_button.visible = false
	_portrait.visible = false
	if squad == null:
		_inspector.text = "Select a squad."
		return
	var lines: Array[String] = []
	lines.append("%s  [%s]" % [squad.id, squad.unit_type_id])
	if squad.officer != null:
		var officer := squad.officer
		if not officer.portrait_path.is_empty():
			var tex: Texture2D = load(officer.portrait_path)
			if tex != null:
				_portrait.texture = tex
				_portrait.visible = true
		lines.append("Officer: %s" % officer.display_name)
		lines.append("WAR %d  LDR %d  INT %d" % [officer.war(), officer.ldr(), officer.intel()])
		lines.append("POL %d  CHR %d" % [officer.pol(), officer.chr()])
		if passives != null:
			var names := passives.display_passives(officer)
			if not names.is_empty():
				lines.append("Passives: %s" % ", ".join(names))
	else:
		lines.append("Officer: none (brittle)")
	lines.append("HP: %.0f / %.0f" % [squad.hp, squad.max_hp])
	var state_name: String = Squad.MoraleState.keys()[squad.morale_state]
	lines.append("Morale: %d (%s)" % [squad.morale, state_name])
	lines.append("AP: %d / %d" % [squad.ap_remaining, squad.ap_pool])
	lines.append("Facing: %s" % CubeHex.DIRECTION_NAMES[squad.facing_direction])
	if squad.tile != null:
		var terrain_name: String = TerrainSystem.TerrainType.keys()[squad.tile.type]
		lines.append("Terrain: %s" % terrain_name.capitalize())
	_inspector.text = "\n".join(lines)


## Shows/hides the contextual duel button.
func set_duel_available(available: bool) -> void:
	_duel_button.visible = available


## Appends one line to the battle log (keeps the last 8).
func log_line(message: String) -> void:
	_log_lines.append(message)
	if _log_lines.size() > 8:
		_log_lines = _log_lines.slice(_log_lines.size() - 8)
	_log_label.text = "\n".join(_log_lines)


## Full-screen battle end overlay (victory-defeat-conditions.md UI spec).
func show_battle_end(report: VictoryChecker.BattleResult) -> void:
	if _end_overlay != null:
		return
	_end_overlay = Panel.new()
	_end_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_end_overlay.modulate = Color(1, 1, 1, 0.97)
	add_child(_end_overlay)

	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_CENTER)
	box.custom_minimum_size = Vector2(420, 0)
	box.add_theme_constant_override("separation", 14)
	_end_overlay.add_child(box)

	var title := Label.new()
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 42)
	match report.result:
		VictoryChecker.Result.VICTORY:
			title.text = "VICTORY"
			title.add_theme_color_override("font_color", Color(0.85, 0.75, 0.3))
		VictoryChecker.Result.DEFEAT:
			title.text = "DEFEAT"
			title.add_theme_color_override("font_color", Color(0.8, 0.25, 0.2))
		_:
			title.text = "DRAW"
	box.add_child(title)

	var detail := Label.new()
	detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	detail.text = "%s\nTurn %d\nYour losses: %.0f%%   Enemy losses: %.0f%%" % [
		_trigger_text(report.trigger_type),
		report.end_turn,
		report.route_fraction_player * 100.0,
		report.route_fraction_enemy * 100.0,
	]
	box.add_child(detail)

	var restart := Button.new()
	restart.text = "Fight Again"
	restart.pressed.connect(func() -> void: restart_pressed.emit())
	box.add_child(restart)


func _trigger_text(trigger: String) -> String:
	match trigger:
		"ROUTE_ENEMY":
			return "The enemy line has broken."
		"PLAYER_ROUTED":
			return "Your army has broken."
		"LOSE_VIP":
			return "Kaster has fallen."
		"EXCEED_TURN_LIMIT":
			return "Time has run out."
		_:
			return trigger
