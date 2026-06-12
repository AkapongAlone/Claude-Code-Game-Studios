class_name CubeHex
extends RefCounted
## Canonical cube-coordinate hex math (q + r + s = 0).
##
## Implements the shared spatial conventions from design/gdd/hex-movement.md:
## the 6 direction vectors indexed clockwise from East, Chebyshev distance,
## cube rounding for line-of-sight rays, and the flat-top pixel mapping.
## Every tactical system uses these primitives — keep them allocation-light.

## The six canonical direction vectors, indexed 0–5 clockwise from East
## (facing-and-flank.md Formula 1).
const DIRECTIONS: Array[Vector3i] = [
	Vector3i(1, -1, 0),   # 0 East
	Vector3i(1, 0, -1),   # 1 South-East
	Vector3i(0, 1, -1),   # 2 South-West
	Vector3i(-1, 1, 0),   # 3 West
	Vector3i(-1, 0, 1),   # 4 North-West
	Vector3i(0, -1, 1),   # 5 North-East
]

const DIRECTION_NAMES: Array[String] = [
	"East", "South-East", "South-West", "West", "North-West", "North-East"
]


## Builds a cube coordinate from axial (q, r).
static func axial(q: int, r: int) -> Vector3i:
	return Vector3i(q, r, -q - r)


## Converts offset map storage (col, row — "odd-q" vertical layout for
## flat-top rendering) to cube coordinates.
static func offset_to_cube(col: int, row: int) -> Vector3i:
	var q := col
	var r := row - (col - (col & 1)) / 2
	return Vector3i(q, r, -q - r)


## F-3: Chebyshev hex distance = max(|dq|, |dr|, |ds|).
static func distance(a: Vector3i, b: Vector3i) -> int:
	return maxi(maxi(absi(a.x - b.x), absi(a.y - b.y)), absi(a.z - b.z))


## The neighbor of [param hex] in direction [param dir] (0–5).
static func neighbor(hex: Vector3i, dir: int) -> Vector3i:
	return hex + DIRECTIONS[dir]


## All six adjacent hexes.
static func neighbors(hex: Vector3i) -> Array[Vector3i]:
	var result: Array[Vector3i] = []
	for dir in DIRECTIONS:
		result.append(hex + dir)
	return result


## Direction index [0, 5] for an exact one-step cube delta; -1 if the delta
## is not one of the six canonical vectors (illegal move step).
static func direction_index(delta: Vector3i) -> int:
	return DIRECTIONS.find(delta)


## Dominant direction index from [param from] toward [param to] — exact for
## adjacent hexes, best-aligned (max dot product) for longer separations.
## Used for attack-facing updates and the flank arc check (attacker direction
## R relative to the defender's hex).
static func direction_between(from: Vector3i, to: Vector3i) -> int:
	var delta := to - from
	var exact := DIRECTIONS.find(delta)
	if exact != -1:
		return exact
	var fdelta := Vector3(delta)
	var best := 0
	var best_dot := -INF
	for i in DIRECTIONS.size():
		var dot := fdelta.dot(Vector3(DIRECTIONS[i]))
		if dot > best_dot:
			best_dot = dot
			best = i
	return best


## Rounds fractional cube coordinates to the nearest hex (standard cube_round).
static func cube_round(frac: Vector3) -> Vector3i:
	var q := roundf(frac.x)
	var r := roundf(frac.y)
	var s := roundf(frac.z)
	var dq := absf(q - frac.x)
	var dr := absf(r - frac.y)
	var ds := absf(s - frac.z)
	if dq > dr and dq > ds:
		q = -r - s
	elif dr > ds:
		r = -q - s
	else:
		s = -q - r
	return Vector3i(int(q), int(r), int(s))


## Intermediate hexes on the ray from [param a] to [param b], EXCLUDING both
## endpoints (hex-movement.md F-6). Returns two candidate lines (positive and
## negative epsilon nudge): a hex only counts as ray-blocking when it appears
## in BOTH — implementing the "corner ambiguity resolves in favor of LOS" rule.
static func los_intermediate_pairs(a: Vector3i, b: Vector3i) -> Array:
	var n := distance(a, b)
	var lines: Array = [[], []]
	if n <= 1:
		return lines
	var fa := Vector3(a)
	var fb := Vector3(b)
	var epsilons: Array[Vector3] = [
		Vector3(1e-6, 2e-6, -3e-6),
		Vector3(-1e-6, -2e-6, 3e-6),
	]
	for e in 2:
		var hexes: Array[Vector3i] = []
		for i in range(1, n):
			var t := float(i) / float(n)
			var point := fa.lerp(fb, t) + epsilons[e]
			hexes.append(cube_round(point))
		lines[e] = hexes
	return lines


## Flat-top pixel center for a cube hex (project_summary: flat-top, East
## renders rightward). [param size] is the hex outer radius in pixels.
static func to_pixel(hex: Vector3i, size: float) -> Vector2:
	var x := size * 1.5 * hex.x
	var y := size * sqrt(3.0) * (hex.y + hex.x / 2.0)
	return Vector2(x, y)


## Inverse of to_pixel — pixel position to nearest cube hex.
static func from_pixel(pos: Vector2, size: float) -> Vector3i:
	var q := (2.0 / 3.0) * pos.x / size
	var r := (-1.0 / 3.0) * pos.x / size + (sqrt(3.0) / 3.0) * pos.y / size
	return cube_round(Vector3(q, r, -q - r))
