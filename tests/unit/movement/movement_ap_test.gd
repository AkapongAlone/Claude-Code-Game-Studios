extends "res://tests/helpers/test_case.gd"
## AP pool formula — design/gdd/hex-movement.md F-1 acceptance criteria 1–7.
## ap_pool = min(base_ap[class] + floor((ldr-1)/34), max_ap[class])

const Fixtures := preload("res://tests/helpers/fixtures.gd")

var _config: Dictionary


func setup() -> void:
	_config = Fixtures.movement_config()


## AC 1: INF with LDR 20 → min(3 + 0, 5) = 3.
func test_inf_ldr20_no_bonus() -> void:
	assert_eq(MovementRules.ap_pool("INF", 20, _config), 3)


## AC 2: INF with LDR 50 → min(3 + 1, 5) = 4.
func test_inf_ldr50_tier1_bonus() -> void:
	assert_eq(MovementRules.ap_pool("INF", 50, _config), 4)


## AC 3: CAV with LDR 96 → min(5 + 2, 7) = 7.
func test_cav_ldr96_tier2_bonus() -> void:
	assert_eq(MovementRules.ap_pool("CAV", 96, _config), 7)


## AC 4: CAV with LDR 100 → still 7, not 8 (hard cap).
func test_cav_ldr100_hard_cap() -> void:
	assert_eq(MovementRules.ap_pool("CAV", 100, _config), 7)


## AC 5: ART with LDR 1 → min(2 + 0, 4) = 2.
func test_art_ldr1_minimum() -> void:
	assert_eq(MovementRules.ap_pool("ART", 1, _config), 2)


## AC 6: ART with LDR 80 → min(2 + 2, 4) = 4 — cap holds.
func test_art_ldr80_cap() -> void:
	assert_eq(MovementRules.ap_pool("ART", 80, _config), 4)


## AC 7: LDR boundary 34 vs 35 — bonus becomes +1 exactly at 35.
func test_ldr_boundary_34_vs_35() -> void:
	assert_eq(MovementRules.ap_pool("INF", 34, _config), 3)
	assert_eq(MovementRules.ap_pool("INF", 35, _config), 4)


## Officer-less squads (ldr 0) get the base value.
func test_officerless_uses_base() -> void:
	assert_eq(MovementRules.ap_pool("LI", 0, _config), 4)
