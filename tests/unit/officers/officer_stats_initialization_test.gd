extends "res://tests/helpers/test_case.gd"
## Officer Stats — initialization + read contract.
## Covers design/gdd/officer-stats.md acceptance criteria:
## named baseline values, null for missing officers, write rejection,
## invalid stat name → 0.

const Fixtures := preload("res://tests/helpers/fixtures.gd")

var _registry: OfficerRegistry


func setup() -> void:
	_registry = Fixtures.officer_registry()


## AC: fresh campaign at Prologue → Kaster reads exactly 82/96/92/85/88.
func test_kaster_baseline_matches_gdd_table() -> void:
	var kaster := _registry.get_officer("kaster")
	assert_not_null(kaster, "Kaster must exist in registry")
	assert_eq(kaster.war(), 82)
	assert_eq(kaster.ldr(), 96)
	assert_eq(kaster.intel(), 92)
	assert_eq(kaster.pol(), 85)
	assert_eq(kaster.chr(), 88)


## All 7 named officers exist with every stat in [1, 100].
func test_all_seven_named_officers_present_with_valid_stats() -> void:
	var expected_ids := ["kaster", "bon_shi_hai", "alexsen", "thane", "zhuge_jian", "jin_tao", "sander"]
	for officer_id: String in expected_ids:
		var officer := _registry.get_officer(officer_id)
		assert_not_null(officer, "missing officer: %s" % officer_id)
		if officer == null:
			continue
		assert_true(officer.is_named, "%s must be a named officer" % officer_id)
		for stat: Officer.Stat in Officer.Stat.values():
			assert_between(officer.get_stat(stat), 1, 100, "%s stat %s out of range" % [officer_id, Officer.Stat.keys()[stat]])


## AC: Combat Resolution queries Alexsen's WAR → receives 98 without error.
func test_alexsen_war_readable_by_dependent_system() -> void:
	var alexsen := _registry.get_officer("alexsen")
	assert_not_null(alexsen)
	assert_eq(alexsen.war(), 98)
	assert_eq(alexsen.get_stat_by_name("WAR"), 98)


## AC: querying an officer that does not exist returns null (caller handles).
func test_unknown_officer_query_returns_null() -> void:
	assert_null(_registry.get_officer("nonexistent_officer"))


## AC: dependent system calls set_stat → rejected, error logged, value unchanged.
## (The push_error output below is EXPECTED noise from this test.)
func test_set_stat_rejected_and_value_unchanged() -> void:
	var alexsen := _registry.get_officer("alexsen")
	var accepted := alexsen.set_stat(Officer.Stat.WAR, 50)
	assert_false(accepted, "set_stat must be rejected")
	assert_eq(alexsen.war(), 98, "WAR must remain unchanged after rejected write")


## GDD error handling: invalid stat type ("FEAR") → log error, return 0.
## (The push_error output below is EXPECTED noise from this test.)
func test_invalid_stat_name_returns_zero() -> void:
	var kaster := _registry.get_officer("kaster")
	assert_eq(kaster.get_stat_by_name("FEAR"), 0)


## Initialization clamps out-of-range input values to [1, 100].
func test_initialization_clamps_out_of_range_values() -> void:
	var officer := Fixtures.make_officer("clamp_check", 150, 0, -5, 100, 1)
	assert_eq(officer.war(), 100, "150 must clamp to 100")
	assert_eq(officer.ldr(), 1, "0 must clamp to 1")
	assert_eq(officer.intel(), 1, "-5 must clamp to 1")
	assert_eq(officer.pol(), 100)
	assert_eq(officer.chr(), 1)
