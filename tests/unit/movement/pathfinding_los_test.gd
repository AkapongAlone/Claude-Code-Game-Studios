extends "res://tests/helpers/test_case.gd"
## BattleGrid pathfinding + LOS — design/gdd/hex-movement.md F-4/F-5/F-6/F-7
## acceptance criteria (reachable sets, occupancy, A* detours, LOS blocking).

const Fixtures := preload("res://tests/helpers/fixtures.gd")


## AC 9: flood fill includes hexes up to exactly the AP budget, none above.
func test_reachable_boundary_at_exact_budget() -> void:
	var grid := Fixtures.grid_from_rows([".....", ".....", ".....", ".....", "....."])
	var start := CubeHex.offset_to_cube(2, 2)
	var reachable := grid.reachable_hexes(start, 3)
	assert_false(reachable.is_empty())
	var found_exact := false
	for hex: Vector3i in reachable.keys():
		assert_between(int(reachable[hex]), 1, 3, "cost above budget leaked into result")
		if int(reachable[hex]) == 3:
			found_exact = true
	assert_true(found_exact, "hexes at exactly cost 3 must be included")


## AC 10/18/19: occupied hexes are excluded as stop AND traversal nodes.
## Single-row corridor: blocker in the middle cuts everything beyond.
func test_occupied_hex_blocks_corridor() -> void:
	var grid := Fixtures.grid_from_rows(["....."])
	var blocker := Fixtures.battle_squad("blocker", Squad.Side.ENEMY, CubeHex.offset_to_cube(2, 0), null, "swordsman", grid)
	assert_not_null(blocker)
	var start := CubeHex.offset_to_cube(0, 0)
	var reachable := grid.reachable_hexes(start, 5)
	assert_false(reachable.has(CubeHex.offset_to_cube(2, 0)), "occupied hex must not be a destination")
	assert_false(reachable.has(CubeHex.offset_to_cube(3, 0)), "hex behind blocker must be unreachable")
	assert_false(reachable.has(CubeHex.offset_to_cube(4, 0)))
	assert_true(reachable.has(CubeHex.offset_to_cube(1, 0)))
	var path := grid.pathfind(start, CubeHex.offset_to_cube(4, 0), 5)
	assert_eq(path.size(), 0, "AC 19: no path through an occupied corridor")


## AC 11: river hexes are excluded from the reachable set at any AP.
func test_river_impassable_in_flood_fill() -> void:
	var grid := Fixtures.grid_from_rows([".~."])
	var reachable := grid.reachable_hexes(CubeHex.offset_to_cube(0, 0), 99)
	assert_false(reachable.has(CubeHex.offset_to_cube(1, 0)), "river must be excluded")


## AC 12: valid path returned with correct cumulative cost.
func test_pathfind_straight_road() -> void:
	var grid := Fixtures.grid_from_rows(["rrrrr"])
	var path := grid.pathfind(CubeHex.offset_to_cube(0, 0), CubeHex.offset_to_cube(4, 0), 7)
	assert_eq(path.size(), 4)
	assert_eq(grid.path_cost(path), 4)
	assert_eq(path[3], CubeHex.offset_to_cube(4, 0), "path ends at the destination")


## AC 13: destination beyond the AP budget returns [].
func test_pathfind_empty_when_over_budget() -> void:
	var grid := Fixtures.grid_from_rows(["....."])
	var path := grid.pathfind(CubeHex.offset_to_cube(0, 0), CubeHex.offset_to_cube(3, 0), 2)
	assert_eq(path.size(), 0)


## AC 14: A* routes around a blocked hex when a detour fits the budget.
func test_pathfind_detours_around_blocker() -> void:
	var grid := Fixtures.grid_from_rows(["...", "..."])
	Fixtures.battle_squad("blocker", Squad.Side.ENEMY, CubeHex.offset_to_cube(1, 0), null, "swordsman", grid)
	var start := CubeHex.offset_to_cube(0, 0)
	var goal := CubeHex.offset_to_cube(2, 0)
	var path := grid.pathfind(start, goal, 6)
	assert_true(path.size() > 0, "detour must exist")
	assert_false(path.has(CubeHex.offset_to_cube(1, 0)), "path must avoid the occupied hex")
	assert_eq(path[path.size() - 1], goal)


## AC 25/27: Forest on the ray blocks LOS; Hill does not.
func test_los_forest_blocks_hill_does_not() -> void:
	var forest_grid := Fixtures.grid_from_rows([".f.", "..."])
	var a := CubeHex.offset_to_cube(0, 0)
	var b := CubeHex.offset_to_cube(2, 1)
	assert_eq(CubeHex.distance(a, b), 2)
	assert_false(forest_grid.has_line_of_sight(a, b), "forest intermediate must block")
	var hill_grid := Fixtures.grid_from_rows([".h.", "..."])
	assert_true(hill_grid.has_line_of_sight(a, b), "hill must NOT block")


## AC 26: Village blocks LOS.
func test_los_village_blocks() -> void:
	var grid := Fixtures.grid_from_rows([".v.", "..."])
	assert_false(grid.has_line_of_sight(CubeHex.offset_to_cube(0, 0), CubeHex.offset_to_cube(2, 1)))


## AC 28: range 1 always has LOS, even into a Forest hex.
func test_los_range_one_always_true() -> void:
	var grid := Fixtures.grid_from_rows(["ff"])
	assert_true(grid.has_line_of_sight(CubeHex.offset_to_cube(0, 0), CubeHex.offset_to_cube(1, 0)))


## AC 29: the source hex's own terrain never blocks outgoing LOS.
func test_los_source_forest_does_not_block() -> void:
	var grid := Fixtures.grid_from_rows(["f..", "..."])
	assert_true(grid.has_line_of_sight(CubeHex.offset_to_cube(0, 0), CubeHex.offset_to_cube(2, 1)))


## AC 30: routing target is the nearest map-edge hex (here: everything is
## an edge on a tiny map — target must be a valid edge hex at distance ≤ 1).
func test_routing_target_nearest_edge() -> void:
	var grid := Fixtures.grid_from_rows([".....", ".....", ".....", ".....", "....."])
	var center := CubeHex.offset_to_cube(2, 2)
	var target := grid.routing_target(center)
	assert_true(grid.is_edge_hex(target))
	assert_between(CubeHex.distance(center, target), 1, 2)


## Charred tiles become impassable mid-battle (terrain edge case).
func test_charred_blocks_pathfinding() -> void:
	var grid := Fixtures.grid_from_rows(["..."])
	grid.tile_at(CubeHex.offset_to_cube(1, 0)).set_charred()
	var reachable := grid.reachable_hexes(CubeHex.offset_to_cube(0, 0), 5)
	assert_false(reachable.has(CubeHex.offset_to_cube(1, 0)))
