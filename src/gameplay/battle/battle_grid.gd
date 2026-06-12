class_name BattleGrid
extends RefCounted
## The tactical hex map: tiles, occupancy, pathfinding, and line of sight.
##
## Implements design/gdd/hex-movement.md F-4 (Dijkstra reachable set),
## F-5 (weighted A*), F-6 (cube-lerp LOS), and F-7 (routing target).
## Occupied hexes are impassable as both traversal nodes and destinations.
## Charred tiles block movement (terrain-system.md edge case).

var terrain: TerrainSystem = null
var season: TerrainSystem.Season = TerrainSystem.Season.DRY
## Vector3i (cube) → TerrainTile
var tiles: Dictionary = {}
## Vector3i (cube) → Squad (maintained via place/move/remove)
var _occupied: Dictionary = {}


## Map legend for BattleDefinition map_rows.
const CODE_TO_TYPE := {
	".": TerrainSystem.TerrainType.OPEN_FIELD,
	"r": TerrainSystem.TerrainType.ROAD,
	"h": TerrainSystem.TerrainType.HILL,
	"f": TerrainSystem.TerrainType.FOREST,
	"v": TerrainSystem.TerrainType.VILLAGE,
	"~": TerrainSystem.TerrainType.RIVER,
	"o": TerrainSystem.TerrainType.FORD,
	"b": TerrainSystem.TerrainType.BRIDGE,
}


## Builds a grid from BattleDefinition map_rows (offset storage, odd-q).
static func from_map_rows(map_rows: Array, p_terrain: TerrainSystem, p_season: TerrainSystem.Season = TerrainSystem.Season.DRY) -> BattleGrid:
	var grid := BattleGrid.new()
	grid.terrain = p_terrain
	grid.season = p_season
	for row in map_rows.size():
		var line := String(map_rows[row])
		for col in line.length():
			var code := line[col]
			if not CODE_TO_TYPE.has(code):
				push_error("BattleGrid: unknown terrain code '%s' at %d,%d" % [code, col, row])
				continue
			var hex := CubeHex.offset_to_cube(col, row)
			grid.tiles[hex] = TerrainTile.new(CODE_TO_TYPE[code])
	return grid


func has_hex(hex: Vector3i) -> bool:
	return tiles.has(hex)


func tile_at(hex: Vector3i) -> TerrainTile:
	return tiles.get(hex)


## AP cost to ENTER [param hex] this season; IMPASSABLE for river, charred,
## or off-map hexes.
func movement_cost(hex: Vector3i) -> int:
	var tile: TerrainTile = tiles.get(hex)
	if tile == null:
		return TerrainSystem.IMPASSABLE
	return tile.movement_cost(terrain, season)


func is_occupied(hex: Vector3i) -> bool:
	return _occupied.has(hex)


func squad_at(hex: Vector3i) -> Squad:
	return _occupied.get(hex)


## Registers a squad on the grid (battle setup).
func place_squad(squad: Squad, hex: Vector3i) -> void:
	_occupied[hex] = squad
	squad.position = hex
	squad.tile = tile_at(hex)


## Moves a squad's occupancy record (no AP logic — controller owns that).
func relocate_squad(squad: Squad, to: Vector3i) -> void:
	_occupied.erase(squad.position)
	_occupied[to] = squad
	squad.position = to
	squad.tile = tile_at(to)


## Removes a squad from the grid (death or routed off-map).
func remove_squad(squad: Squad) -> void:
	if _occupied.get(squad.position) == squad:
		_occupied.erase(squad.position)


## F-4: Dijkstra flood fill. Returns Dictionary hex → min AP cost for every
## hex reachable within [param ap_budget] (excluding the start hex).
## Occupied hexes are excluded as traversal nodes AND destinations.
func reachable_hexes(from: Vector3i, ap_budget: int) -> Dictionary:
	var dist: Dictionary = { from: 0 }
	var frontier: Array[Vector3i] = [from]
	while not frontier.is_empty():
		var best_i := 0
		for i in frontier.size():
			if dist[frontier[i]] < dist[frontier[best_i]]:
				best_i = i
		var hex: Vector3i = frontier.pop_at(best_i)
		for neighbor in CubeHex.neighbors(hex):
			if _occupied.has(neighbor):
				continue
			var step := movement_cost(neighbor)
			if step == TerrainSystem.IMPASSABLE:
				continue
			var cost: int = dist[hex] + step
			if cost <= ap_budget and cost < int(dist.get(neighbor, 2147483647)):
				dist[neighbor] = cost
				frontier.append(neighbor)
	dist.erase(from)
	return dist


## F-5: weighted A*. Returns the ordered hex path from [param from] to
## [param to] (excluding start, including destination), or [] when the
## destination is unreachable or exceeds [param ap_budget]
## (budget -1 = unlimited, used for routing pathfinding).
func pathfind(from: Vector3i, to: Vector3i, ap_budget: int = -1) -> Array[Vector3i]:
	var empty: Array[Vector3i] = []
	if from == to or not has_hex(to):
		return empty
	if _occupied.has(to):
		return empty
	var g: Dictionary = { from: 0 }
	var came: Dictionary = {}
	var open: Array[Vector3i] = [from]
	while not open.is_empty():
		var best_i := 0
		var best_f: int = int(g[open[0]]) + CubeHex.distance(open[0], to)
		for i in range(1, open.size()):
			var f: int = int(g[open[i]]) + CubeHex.distance(open[i], to)
			if f < best_f:
				best_f = f
				best_i = i
		var current: Vector3i = open.pop_at(best_i)
		if current == to:
			var path: Array[Vector3i] = []
			var node := to
			while node != from:
				path.push_front(node)
				node = came[node]
			if ap_budget >= 0 and int(g[to]) > ap_budget:
				return empty
			return path
		for neighbor in CubeHex.neighbors(current):
			if _occupied.has(neighbor):
				continue
			var step := movement_cost(neighbor)
			if step == TerrainSystem.IMPASSABLE:
				continue
			var cost: int = int(g[current]) + step
			if ap_budget >= 0 and cost > ap_budget:
				continue
			if cost < int(g.get(neighbor, 2147483647)):
				g[neighbor] = cost
				came[neighbor] = current
				open.append(neighbor)
	return empty


## Total AP cost of a path returned by pathfind().
func path_cost(path: Array[Vector3i]) -> int:
	var total := 0
	for hex in path:
		total += movement_cost(hex)
	return total


## F-6: line of sight via cube lerp. Forest and Village block; endpoints are
## excluded; corner ambiguity resolves in favor of LOS (a hex blocks only
## when both epsilon-nudged rays pass through it). Range 1 is always true.
func has_line_of_sight(a: Vector3i, b: Vector3i) -> bool:
	var pair := CubeHex.los_intermediate_pairs(a, b)
	var line_a: Array = pair[0]
	var line_b: Array = pair[1]
	for i in line_a.size():
		var hex_a: Vector3i = line_a[i]
		var hex_b: Vector3i = line_b[i]
		if hex_a == hex_b:
			if _blocks_los(hex_a):
				return false
		else:
			# Corner case: ambiguous between two hexes — blocks only if BOTH block.
			if _blocks_los(hex_a) and _blocks_los(hex_b):
				return false
	return true


func _blocks_los(hex: Vector3i) -> bool:
	var tile: TerrainTile = tiles.get(hex)
	if tile == null:
		return false  # off-map hexes never block (hex-movement.md E-8)
	return terrain.is_los_blocking(tile.type)


## True when [param hex] lies on the map boundary (has at least one
## neighbor outside the map).
func is_edge_hex(hex: Vector3i) -> bool:
	for neighbor in CubeHex.neighbors(hex):
		if not tiles.has(neighbor):
			return true
	return false


## F-7: routing target — nearest map-edge hex by Chebyshev distance,
## tiebreak lowest q.
func routing_target(from: Vector3i) -> Vector3i:
	var best := from
	var best_dist := 2147483647
	for hex: Vector3i in tiles.keys():
		if not is_edge_hex(hex):
			continue
		var d := CubeHex.distance(from, hex)
		if d < best_dist or (d == best_dist and hex.x < best.x):
			best_dist = d
			best = hex
	return best
