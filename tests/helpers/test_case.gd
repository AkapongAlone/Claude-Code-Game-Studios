extends RefCounted
## Minimal assertion base class for headless unit tests.
##
## Test scripts extend this file (by path, so no global class cache is
## required) and define `test_*` methods. tests/headless_runner.gd
## instantiates a FRESH instance per test method (test isolation), calls
## setup(), the test method, then teardown(), and reads failures via
## get_failures().

var _failures: PackedStringArray = PackedStringArray()
var _assert_count: int = 0


## Override for per-test setup. A fresh instance runs each test method,
## so state set here can never leak between tests.
func setup() -> void:
	pass


## Override for per-test cleanup.
func teardown() -> void:
	pass


## Failure messages collected by this test instance (empty = pass).
func get_failures() -> PackedStringArray:
	return _failures


## Number of assertions executed (sanity check that the test asserted).
func get_assert_count() -> int:
	return _assert_count


func assert_true(condition: bool, message: String = "") -> void:
	_assert_count += 1
	if not condition:
		_fail("expected true", message)


func assert_false(condition: bool, message: String = "") -> void:
	_assert_count += 1
	if condition:
		_fail("expected false", message)


## Strict equality — use for int/String/bool. For floats use assert_almost_eq.
func assert_eq(actual: Variant, expected: Variant, message: String = "") -> void:
	_assert_count += 1
	if actual != expected:
		_fail("expected %s but got %s" % [str(expected), str(actual)], message)


func assert_ne(actual: Variant, not_expected: Variant, message: String = "") -> void:
	_assert_count += 1
	if actual == not_expected:
		_fail("expected anything but %s" % str(not_expected), message)


## Float comparison within [param tolerance].
func assert_almost_eq(actual: float, expected: float, tolerance: float = 0.0001, message: String = "") -> void:
	_assert_count += 1
	if absf(actual - expected) > tolerance:
		_fail("expected %f ± %f but got %f" % [expected, tolerance, actual], message)


func assert_null(value: Variant, message: String = "") -> void:
	_assert_count += 1
	if value != null:
		_fail("expected null but got %s" % str(value), message)


func assert_not_null(value: Variant, message: String = "") -> void:
	_assert_count += 1
	if value == null:
		_fail("expected non-null", message)


## Asserts [param value] lies in the inclusive range [low, high].
func assert_between(value: float, low: float, high: float, message: String = "") -> void:
	_assert_count += 1
	if value < low or value > high:
		_fail("expected value in [%s, %s] but got %s" % [str(low), str(high), str(value)], message)


func _fail(detail: String, message: String) -> void:
	var text := detail if message.is_empty() else "%s — %s" % [message, detail]
	_failures.append(text)
