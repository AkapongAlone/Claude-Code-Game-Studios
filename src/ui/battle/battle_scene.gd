class_name BattleScene
extends Node2D
## The playable tactical battle scene — entry point of the game (F5).
##
## Renders the hex map (flat-top, painted-map placeholder colors), squad
## tokens, movement overlay, floating damage numbers, the Tactical HUD
## (CanvasLayer 5) and the Duel overlay (CanvasLayer 10). All rules run in
## BattleController; this scene is input + presentation only.
##
## Controls: click squad to select · click highlighted hex to move · click
## a visible enemy in range to attack · D = duel an adjacent enemy officer ·
## Enter = end turn · Esc = deselect.

const HEX_SIZE := 36.0
const MAP_OFFSET := Vector2(80, 110)

const TERRAIN_COLORS := {
	TerrainSystem.TerrainType.OPEN_FIELD: Color(0.56, 0.6, 0.38),
	TerrainSystem.TerrainType.ROAD: Color(0.72, 0.63, 0.46),
	TerrainSystem.TerrainType.HILL: Color(0.62, 0.52, 0.36),
	TerrainSystem.TerrainType.FOREST: Color(0.27, 0.43, 0.27),
	TerrainSystem.TerrainType.VILLAGE: Color(0.78, 0.6, 0.44),
	TerrainSystem.TerrainType.RIVER: Color(0.32, 0.5, 0.68),
	TerrainSystem.TerrainType.FORD: Color(0.48, 0.62, 0.72),
	TerrainSystem.TerrainType.BRIDGE: Color(0.55, 0.43, 0.3),
}

var controller: BattleController = null
var rng := RandomNumberGenerator.new()
var hud: TacticalHUD = null
var duel_overlay: DuelOverlay = null
var tokens: Dictionary = {}
var selected: Squad = null
var reachable: Dictionary = {}
var _duel_challenger: Squad = null
var _duel_target: Squad = null


func _ready() -> void:
	rng.randomize()
	var definition := ConfigLoader.load_json("res://assets/data/battles/open_field_demo.json")
	controller = BattleController.load_battle(definition, rng)

	hud = TacticalHUD.new()
	hud.passives = controller.passives
	add_child(hud)
	hud.end_turn_pressed.connect(_on_end_turn)
	hud.duel_pressed.connect(_on_duel_requested)
	hud.restart_pressed.connect(func() -> void: get_tree().reload_current_scene())

	duel_overlay = DuelOverlay.new()
	add_child(duel_overlay)
	duel_overlay.duel_finished.connect(_on_duel_finished)

	controller.log_event.connect(hud.log_line)
	controller.attack_resolved.connect(_on_attack_resolved)
	controller.squad_removed.connect(func(_squad: Squad, _reason: String) -> void: _refresh_all())
	controller.battle_ended.connect(func(report: VictoryChecker.BattleResult) -> void:
		hud.show_battle_end(report)
		_refresh_all())

	for squad: Squad in controller.squads:
		var token := SquadToken.new(squad)
		add_child(token)
		tokens[squad] = token

	hud.log_line("Battle begins: %s" % controller.battle_name)
	hud.log_line("Click a blue squad, move, attack. Enter ends the turn.")
	_refresh_all()


# ------------------------------------------------------------------- input

func _unhandled_input(event: InputEvent) -> void:
	if controller.battle_over or controller.duel_active:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_on_click(CubeHex.from_pixel(get_global_mouse_position() - MAP_OFFSET, HEX_SIZE))
	elif event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_ENTER, KEY_KP_ENTER:
				_on_end_turn()
			KEY_ESCAPE:
				_select(null)
			KEY_D:
				_on_duel_requested()


func _on_click(hex: Vector3i) -> void:
	if not controller.grid.has_hex(hex):
		return
	var squad_at := controller.grid.squad_at(hex)
	if squad_at != null and squad_at.side == Squad.Side.PLAYER:
		_select(squad_at)
		return
	if selected == null:
		return
	if squad_at != null and squad_at.side == Squad.Side.ENEMY:
		if controller.can_attack(selected, squad_at):
			controller.attack(selected, squad_at)
			_refresh_all()
		return
	if reachable.has(hex):
		controller.move_squad(selected, hex)
		reachable = controller.reachable_for(selected)
		_refresh_all()


func _select(squad: Squad) -> void:
	selected = squad
	reachable = controller.reachable_for(squad) if squad != null else {}
	hud.show_squad(squad)
	hud.set_duel_available(_duel_target_for(squad) != null)
	queue_redraw()


## An adjacent enemy officer squad eligible for a field challenge, or null.
func _duel_target_for(squad: Squad) -> Squad:
	if squad == null or squad.officer == null or squad.challenge_used:
		return null
	for direction in CubeHex.DIRECTIONS:
		var neighbor := controller.grid.squad_at(squad.position + direction)
		if neighbor != null and neighbor.side == Squad.Side.ENEMY and neighbor.officer != null:
			if neighbor.visibility_state == Squad.Visibility.VISIBLE:
				return neighbor
	return null


func _on_duel_requested() -> void:
	var target := _duel_target_for(selected)
	if target == null:
		return
	var engine := controller.start_field_duel(selected, target)
	if engine == null:
		return
	_duel_challenger = selected
	_duel_target = target
	duel_overlay.open(engine, rng)


func _on_duel_finished(engine: DuelEngine) -> void:
	controller.finish_field_duel(engine, _duel_challenger, _duel_target)
	_select(selected)
	_refresh_all()


func _on_end_turn() -> void:
	controller.end_player_turn()
	_select(selected if selected != null and selected.is_active() else null)
	_refresh_all()


# ------------------------------------------------------------ presentation

func hex_to_screen(hex: Vector3i) -> Vector2:
	return CubeHex.to_pixel(hex, HEX_SIZE) + MAP_OFFSET


func _draw() -> void:
	if controller == null:
		return
	for hex: Vector3i in controller.grid.tiles.keys():
		var tile: TerrainTile = controller.grid.tiles[hex]
		var center := hex_to_screen(hex)
		var points := _hex_points(center)
		var color: Color = TERRAIN_COLORS.get(tile.type, Color.MAGENTA)
		if tile.charred:
			color = color.darkened(0.6)
		draw_colored_polygon(points, color)
		draw_polyline(points + PackedVector2Array([points[0]]), Color(0.1, 0.1, 0.1, 0.35), 1.5)
	# Movement overlay for the selected squad.
	for hex: Vector3i in reachable.keys():
		var points := _hex_points(hex_to_screen(hex))
		draw_colored_polygon(points, Color(0.4, 0.7, 1.0, 0.28))
	if selected != null:
		var points := _hex_points(hex_to_screen(selected.position))
		draw_polyline(points + PackedVector2Array([points[0]]), Color(1, 1, 0.4, 0.9), 3.0)


func _hex_points(center: Vector2) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in 6:
		points.append(center + Vector2.from_angle(TAU * i / 6.0) * (HEX_SIZE - 1.0))
	return points


func _refresh_all() -> void:
	for squad: Squad in tokens.keys():
		var token: SquadToken = tokens[squad]
		if not squad.is_active():
			token.visible = false
			continue
		if squad.side == Squad.Side.PLAYER:
			token.visible = true
			token.ghost_mode = false
			token.position = hex_to_screen(squad.position)
		else:
			match squad.visibility_state:
				Squad.Visibility.VISIBLE:
					token.visible = true
					token.ghost_mode = false
					token.position = hex_to_screen(squad.position)
				Squad.Visibility.PREVIOUSLY_SEEN:
					token.visible = true
					token.ghost_mode = true
					token.position = hex_to_screen(squad.last_known_position)
				_:
					token.visible = false
		token.refresh()
	var enemy_total := 0
	var enemy_broken := 0
	for squad: Squad in controller.squads:
		if squad.side == Squad.Side.ENEMY:
			enemy_total += 1
			if not squad.is_active() or squad.morale_state == Squad.MoraleState.BROKEN:
				enemy_broken += 1
	hud.update_status(controller.current_turn, controller.battle_name, enemy_broken, enemy_total)
	if selected != null:
		hud.show_squad(selected)
		hud.set_duel_available(_duel_target_for(selected) != null)
	queue_redraw()


func _on_attack_resolved(attacker: Squad, defender: Squad, result: CombatResolver.AttackResult) -> void:
	var label := Label.new()
	label.text = "-%d%s" % [roundi(result.effective_damage), " FLANK" if result.was_flank else ""]
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color(1.0, 0.55, 0.2) if result.was_flank else Color.WHITE)
	label.position = hex_to_screen(defender.position) + Vector2(-18, -44)
	label.z_index = 50
	add_child(label)
	var tween := create_tween()
	tween.tween_property(label, "position:y", label.position.y - 28.0, 0.9)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.9)
	tween.tween_callback(label.queue_free)
	hud.log_line("%s hits %s for %d%s" % [
		attacker.id, defender.id, roundi(result.effective_damage),
		" (flank)" if result.was_flank else "",
	])
