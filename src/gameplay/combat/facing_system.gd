class_name FacingSystem
extends RefCounted
## Facing direction and flank classification (design/gdd/facing-and-flank.md).
##
## Stateless: all functions are static formulas over squad state. The squad's
## facing_direction is the only persistent field, stored on Squad and updated
## here after moves and attacks.

## Formula 1: facing from a one-step move delta. Returns -1 for illegal
## (non-adjacent) deltas — Hex Movement gates this before calling.
static func facing_from_move(from: Vector3i, to: Vector3i) -> int:
	var dir := CubeHex.direction_index(to - from)
	if dir == -1:
		push_error("FacingSystem: non-adjacent move delta %s — facing unchanged" % str(to - from))
	return dir


## Facing toward an attack target (attack-without-move rule; also fires
## after a move+attack — final facing is toward the last target).
static func facing_toward(from: Vector3i, target: Vector3i) -> int:
	return CubeHex.direction_between(from, target)


## Formula 2: flank arc check.
## relative_dir = (R - D + 6) mod 6; values 3, 4, 5 are the flank/rear arc.
static func is_flank_direction(defender_facing: int, attacker_direction: int) -> bool:
	var relative_dir := (attacker_direction - defender_facing + 6) % 6
	return relative_dir >= 3


## Full flank classification for an attack: Formula 2 (facing arc) OR
## Formula 3 (forest ambush override). Terrain-only inputs are passed as
## booleans so the formula stays unit-testable without a grid.
static func is_flanking(attacker: Squad, defender: Squad, attacker_in_forest: bool) -> bool:
	var attacker_dir := CubeHex.direction_between(defender.position, attacker.position)
	if is_flank_direction(defender.facing_direction, attacker_dir):
		return true
	return is_forest_ambush(attacker_in_forest, attacker.moved_this_turn, defender.moved_this_turn)


## Formula 3: forest ambush — stationary attacker in forest vs. a target
## that moved this turn. OR-override on the facing check; never stacks.
static func is_forest_ambush(attacker_in_forest: bool, attacker_moved: bool, target_moved: bool) -> bool:
	return attacker_in_forest and not attacker_moved and target_moved


## Default battle-start facing: toward the nearest enemy squad (GDD edge
## case). Falls back to East (0) when no enemies exist.
static func default_facing(squad_position: Vector3i, enemy_positions: Array) -> int:
	if enemy_positions.is_empty():
		return 0
	var nearest: Vector3i = enemy_positions[0]
	var best := CubeHex.distance(squad_position, nearest)
	for pos: Vector3i in enemy_positions:
		var d := CubeHex.distance(squad_position, pos)
		if d < best:
			best = d
			nearest = pos
	return CubeHex.direction_between(squad_position, nearest)
