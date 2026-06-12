extends "res://tests/helpers/test_case.gd"
## Hex math primitives — design/gdd/hex-movement.md F-3 and
## facing-and-flank.md Formula 1 direction conventions.

const Fixtures := preload("res://tests/helpers/fixtures.gd")


## AC 23: adjacent hex distance = 1.
func test_distance_adjacent_is_one() -> void:
	assert_eq(CubeHex.distance(Vector3i(0, 0, 0), Vector3i(1, -1, 0)), 1)


## AC 24: (0,0,0) → (2,−1,−1) = max(2,1,1) = 2.
func test_distance_two_step() -> void:
	assert_eq(CubeHex.distance(Vector3i(0, 0, 0), Vector3i(2, -1, -1)), 2)


func test_distance_zero_for_same_hex() -> void:
	assert_eq(CubeHex.distance(Vector3i(3, -1, -2), Vector3i(3, -1, -2)), 0)


## All six canonical direction vectors map to their indices (0–5 from East).
func test_direction_index_complete_table() -> void:
	var expected := [
		Vector3i(1, -1, 0), Vector3i(1, 0, -1), Vector3i(0, 1, -1),
		Vector3i(-1, 1, 0), Vector3i(-1, 0, 1), Vector3i(0, -1, 1),
	]
	for i in 6:
		assert_eq(CubeHex.direction_index(expected[i]), i, "direction %d" % i)


func test_direction_index_invalid_delta_returns_minus_one() -> void:
	assert_eq(CubeHex.direction_index(Vector3i(2, -2, 0)), -1)


## Dominant direction for a non-adjacent target (used for attack facing).
func test_direction_between_non_adjacent_dominant() -> void:
	assert_eq(CubeHex.direction_between(Vector3i(0, 0, 0), Vector3i(3, -1, -2)), 1, "delta (3,-1,-2) aligns best with South-East")


## Offset (odd-q) → cube conversion keeps q + r + s = 0.
func test_offset_to_cube_odd_q() -> void:
	assert_eq(CubeHex.offset_to_cube(0, 0), Vector3i(0, 0, 0))
	assert_eq(CubeHex.offset_to_cube(1, 0), Vector3i(1, 0, -1))
	assert_eq(CubeHex.offset_to_cube(2, 0), Vector3i(2, -1, -1))
	assert_eq(CubeHex.offset_to_cube(2, 1), Vector3i(2, 0, -2))
	for col in 5:
		for row in 5:
			var hex := CubeHex.offset_to_cube(col, row)
			assert_eq(hex.x + hex.y + hex.z, 0, "cube invariant at %d,%d" % [col, row])


## Neighbors are exactly distance 1 in all six directions.
func test_neighbors_all_distance_one() -> void:
	var center := Vector3i(2, -1, -1)
	var all := CubeHex.neighbors(center)
	assert_eq(all.size(), 6)
	for hex in all:
		assert_eq(CubeHex.distance(center, hex), 1)
