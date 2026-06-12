class_name SquadToken
extends Node2D
## Visual token for one squad on the hex map: side-colored disc, facing
## chevron, HP and morale bars, officer initial, and morale-state ring
## (amber SHAKEN / red BROKEN per morale-system.md visual requirements).
## Ghost mode renders the dimmed last-known sprite for PREVIOUSLY_SEEN
## enemies (fog-of-war.md).

const PLAYER_COLOR := Color(0.25, 0.45, 0.85)
const ENEMY_COLOR := Color(0.8, 0.3, 0.25)
const RADIUS := 17.0

var squad: Squad = null
## When true, renders as a fog ghost at last_known_position.
var ghost_mode: bool = false


func _init(p_squad: Squad) -> void:
	squad = p_squad
	z_index = 10


func _draw() -> void:
	if squad == null:
		return
	var base_color := PLAYER_COLOR if squad.side == Squad.Side.PLAYER else ENEMY_COLOR
	if ghost_mode:
		base_color.a = 0.4
		draw_circle(Vector2.ZERO, RADIUS, base_color)
		draw_arc(Vector2.ZERO, RADIUS, 0, TAU, 24, Color(1, 1, 1, 0.3), 2.0)
		_draw_label("?", Color(1, 1, 1, 0.6))
		return

	# Morale state ring (STEADY: none / SHAKEN: amber / BROKEN: red).
	match squad.morale_state:
		Squad.MoraleState.SHAKEN:
			draw_circle(Vector2.ZERO, RADIUS + 4.0, Color(0.95, 0.65, 0.1, 0.6))
		Squad.MoraleState.BROKEN:
			draw_circle(Vector2.ZERO, RADIUS + 4.0, Color(0.9, 0.1, 0.1, 0.7))

	draw_circle(Vector2.ZERO, RADIUS, base_color)
	draw_arc(Vector2.ZERO, RADIUS, 0, TAU, 24, Color(0, 0, 0, 0.55), 1.5)

	# Facing chevron on the token rim.
	var angle := _facing_angle(squad.facing_direction)
	var tip := Vector2.from_angle(angle) * (RADIUS + 7.0)
	var left := Vector2.from_angle(angle + 2.5) * (RADIUS + 1.0)
	var right := Vector2.from_angle(angle - 2.5) * (RADIUS + 1.0)
	draw_colored_polygon(PackedVector2Array([tip, left, right]), Color(1, 1, 1, 0.9))

	# Officer initial (or unit-class letter for officer-less squads).
	var text := squad.officer.display_name.left(1) if squad.officer != null else squad.unit_class.left(1)
	_draw_label(text, Color.WHITE)

	# HP bar (white) and morale bar (state-colored) under the token.
	var bar_width := RADIUS * 2.0
	var hp_frac := squad.hp / squad.max_hp if squad.max_hp > 0 else 0.0
	draw_rect(Rect2(-RADIUS, RADIUS + 6, bar_width, 4), Color(0, 0, 0, 0.6))
	draw_rect(Rect2(-RADIUS, RADIUS + 6, bar_width * hp_frac, 4), Color(0.9, 0.9, 0.9))
	var morale_color := Color(0.3, 0.8, 0.3)
	if squad.morale_state == Squad.MoraleState.SHAKEN:
		morale_color = Color(0.95, 0.65, 0.1)
	elif squad.morale_state == Squad.MoraleState.BROKEN:
		morale_color = Color(0.9, 0.15, 0.15)
	draw_rect(Rect2(-RADIUS, RADIUS + 11, bar_width, 3), Color(0, 0, 0, 0.6))
	draw_rect(Rect2(-RADIUS, RADIUS + 11, bar_width * squad.morale / 100.0, 3), morale_color)


func _draw_label(text: String, color: Color) -> void:
	var font := ThemeDB.fallback_font
	var size := 16
	var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, size)
	draw_string(font, Vector2(-text_size.x / 2.0, size / 2.0 - 2.0), text, HORIZONTAL_ALIGNMENT_CENTER, -1, size, color)


## Screen angle for a direction index (flat-top rendering: dir 0 = East).
func _facing_angle(dir: int) -> float:
	var delta := CubeHex.DIRECTIONS[dir]
	var target := CubeHex.to_pixel(delta, 10.0)
	return target.angle()


## Re-render after any state change.
func refresh() -> void:
	queue_redraw()
