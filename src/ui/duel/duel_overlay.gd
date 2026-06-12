class_name DuelOverlay
extends CanvasLayer
## Duel sub-game overlay (CanvasLayer 10 per duel-ui.md).
##
## Functional MVP version of the Duel UI spec: opponent panel left, player
## panel right, resolve bars, stamina pips, stance buttons (Q/W/E, R for
## Signature, Y for Yield), Read hint line, exchange reveal text, end
## banner. The full 6-phase screen lifecycle and art treatment land with
## the Duel UI polish pass.

signal duel_finished(engine: DuelEngine)

var engine: DuelEngine = null
var rng: RandomNumberGenerator = null

var _root: Panel
var _player_panel: Label
var _opponent_panel: Label
var _reveal_label: Label
var _hint_label: Label
var _buttons: Dictionary = {}
var _yield_button: Button
var _continue_button: Button
var _ai_stance: DuelEngine.Stance
var _ended: bool = false


func _init() -> void:
	layer = 10
	visible = false


func _ready() -> void:
	_root = Panel.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.offset_left = 160.0
	_root.offset_right = -160.0
	_root.offset_top = 90.0
	_root.offset_bottom = -90.0
	add_child(_root)

	var title := Label.new()
	title.text = "DUEL"
	title.add_theme_font_size_override("font_size", 30)
	title.set_anchors_preset(Control.PRESET_CENTER_TOP)
	title.position.y = 14
	_root.add_child(title)

	_opponent_panel = Label.new()
	_opponent_panel.position = Vector2(40, 70)
	_opponent_panel.custom_minimum_size = Vector2(380, 220)
	_root.add_child(_opponent_panel)

	_player_panel = Label.new()
	_player_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_player_panel.position = Vector2(-420, 70)
	_player_panel.custom_minimum_size = Vector2(380, 220)
	_root.add_child(_player_panel)

	_reveal_label = Label.new()
	_reveal_label.set_anchors_preset(Control.PRESET_CENTER)
	_reveal_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_reveal_label.custom_minimum_size = Vector2(500, 60)
	_reveal_label.position += Vector2(-250, -40)
	_root.add_child(_reveal_label)

	_hint_label = Label.new()
	_hint_label.set_anchors_preset(Control.PRESET_CENTER)
	_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint_label.custom_minimum_size = Vector2(500, 30)
	_hint_label.position += Vector2(-250, 30)
	_hint_label.add_theme_color_override("font_color", Color(0.85, 0.8, 0.5))
	_root.add_child(_hint_label)

	var button_row := HBoxContainer.new()
	button_row.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	button_row.position = Vector2(-280, -100)
	button_row.add_theme_constant_override("separation", 12)
	_root.add_child(button_row)

	for entry in [
		[DuelEngine.Stance.ATTACK, "Attack (Q) -2st"],
		[DuelEngine.Stance.DEFEND, "Defend (W) -1st"],
		[DuelEngine.Stance.FEINT, "Feint (E) -1st"],
		[DuelEngine.Stance.SIGNATURE, "Signature (R)"],
	]:
		var button := Button.new()
		button.text = entry[1]
		button.custom_minimum_size = Vector2(130, 44)
		var stance: DuelEngine.Stance = entry[0]
		button.pressed.connect(func() -> void: _on_stance_pressed(stance))
		button_row.add_child(button)
		_buttons[stance] = button

	_yield_button = Button.new()
	_yield_button.text = "Yield the Killing Blow (Y)"
	_yield_button.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_yield_button.position = Vector2(-110, -48)
	_yield_button.visible = false
	_yield_button.pressed.connect(_on_yield_pressed)
	_root.add_child(_yield_button)

	_continue_button = Button.new()
	_continue_button.text = "Continue"
	_continue_button.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_continue_button.position = Vector2(-60, -48)
	_continue_button.visible = false
	_continue_button.pressed.connect(_on_continue_pressed)
	_root.add_child(_continue_button)


## Opens the overlay for a started engine.
func open(p_engine: DuelEngine, p_rng: RandomNumberGenerator) -> void:
	engine = p_engine
	rng = p_rng
	_ended = false
	_reveal_label.text = "%s vs %s — choose your stance." % [
		engine.p1.officer.display_name, engine.p2.officer.display_name
	]
	_continue_button.visible = false
	visible = true
	_begin_turn()


func _begin_turn() -> void:
	_ai_stance = engine.ai_pick_stance(engine.p2, rng)
	_hint_label.text = ""
	if engine.read_fires_for(engine.p1, engine.p2):
		var shown := engine.roll_read_hint(_ai_stance, rng)
		_hint_label.text = "Read: %s seems to favor %s..." % [
			engine.p2.officer.display_name, _stance_name(shown)
		]
	_refresh_panels()
	_refresh_buttons()


func _on_stance_pressed(stance: DuelEngine.Stance) -> void:
	if _ended or engine == null:
		return
	var result := engine.resolve_turn(stance, _ai_stance, rng)
	_reveal_label.text = "%s: %s   vs   %s: %s\nYou dealt %d — you took %d." % [
		engine.p1.officer.display_name, _stance_name(result.p1_stance),
		engine.p2.officer.display_name, _stance_name(result.p2_stance),
		result.damage_to_p2, result.damage_to_p1,
	]
	if result.outcome != DuelEngine.Outcome.ONGOING:
		_finish(result.outcome)
		return
	_begin_turn()


func _on_yield_pressed() -> void:
	if _ended or engine == null or not engine.yield_available():
		return
	engine.player_yield()
	_finish(DuelEngine.Outcome.YIELD)


func _finish(result_outcome: DuelEngine.Outcome) -> void:
	_ended = true
	_refresh_panels()
	for button: Button in _buttons.values():
		button.disabled = true
	_yield_button.visible = false
	match result_outcome:
		DuelEngine.Outcome.VICTORY:
			_hint_label.text = "%s is victorious!" % engine.p1.officer.display_name
		DuelEngine.Outcome.YIELD:
			_hint_label.text = "%s yields the killing blow — %s withdraws." % [
				engine.p1.officer.display_name, engine.p2.officer.display_name
			]
		DuelEngine.Outcome.DEFEAT:
			_hint_label.text = "%s is defeated..." % engine.p1.officer.display_name
		_:
			_hint_label.text = "Both officers are spent. A draw."
	_continue_button.visible = true


func _on_continue_pressed() -> void:
	visible = false
	duel_finished.emit(engine)


func _refresh_panels() -> void:
	_opponent_panel.text = _participant_text(engine.p2)
	_player_panel.text = _participant_text(engine.p1)


func _participant_text(participant: DuelEngine.Participant) -> String:
	var pips := ""
	for i in participant.stamina:
		pips += "●"
	var lines: Array[String] = []
	lines.append(participant.officer.display_name)
	lines.append("Resolve: %d / %d" % [maxi(participant.resolve, 0), participant.max_resolve])
	lines.append("Stamina: %s (%d)" % [pips, participant.stamina])
	lines.append("Attack: %d" % participant.attack_damage)
	return "\n".join(lines)


func _refresh_buttons() -> void:
	var available := engine.available_stances(engine.p1)
	for stance: DuelEngine.Stance in _buttons:
		var button: Button = _buttons[stance]
		button.disabled = not available.has(stance)
		if stance == DuelEngine.Stance.SIGNATURE:
			button.visible = not engine.p1.signature.is_empty()
			if button.visible:
				button.text = "%s (R) -%dst" % [
					String(engine.p1.signature.get("display_name", "Signature")),
					int(engine.p1.signature.get("stamina_cost", 4)),
				]
	_yield_button.visible = engine.yield_available()


func _unhandled_input(event: InputEvent) -> void:
	if not visible or _ended or engine == null:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_Q: _try_stance(DuelEngine.Stance.ATTACK)
			KEY_W: _try_stance(DuelEngine.Stance.DEFEND)
			KEY_E: _try_stance(DuelEngine.Stance.FEINT)
			KEY_R: _try_stance(DuelEngine.Stance.SIGNATURE)
			KEY_Y: _on_yield_pressed()


func _try_stance(stance: DuelEngine.Stance) -> void:
	if engine.available_stances(engine.p1).has(stance):
		_on_stance_pressed(stance)


func _stance_name(stance: DuelEngine.Stance) -> String:
	match stance:
		DuelEngine.Stance.ATTACK: return "Attack"
		DuelEngine.Stance.DEFEND: return "Defend"
		DuelEngine.Stance.FEINT: return "Feint"
		_: return "Signature Move"
