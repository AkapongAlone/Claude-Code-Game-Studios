extends SceneTree
## Headless unit test runner — zero addon dependencies.
##
## Usage (from the project root):
##   godot --headless --path . --script tests/headless_runner.gd
##
## Discovers every *_test.gd under tests/unit/, instantiates a FRESH test
## instance per test_* method (isolation), runs setup() → test → teardown(),
## and exits 0 on full pass / 1 on any failure (CI blocking gate).
##
## NOTE: run `godot --headless --path . --import` once after cloning so the
## global script-class cache exists (class_name resolution).

const TEST_ROOT := "res://tests/unit"


func _initialize() -> void:
	var test_files: Array[String] = []
	_collect_test_files(TEST_ROOT, test_files)
	test_files.sort()

	if test_files.is_empty():
		push_error("headless_runner: no *_test.gd files found under %s" % TEST_ROOT)
		quit(1)
		return

	var total := 0
	var failed := 0
	var failed_labels: Array[String] = []

	print("")
	print("=== Kaster's War — Headless Test Run ===")
	for path in test_files:
		var script: GDScript = load(path)
		if script == null or not script.can_instantiate():
			push_error("headless_runner: cannot load %s" % path)
			failed += 1
			failed_labels.append(path)
			continue
		print("\n%s" % path.trim_prefix("res://"))
		for method in script.get_script_method_list():
			var method_name: String = method["name"]
			if not method_name.begins_with("test_"):
				continue
			total += 1
			var case: RefCounted = script.new()
			case.setup()
			case.call(method_name)
			case.teardown()
			var failures: PackedStringArray = case.get_failures()
			if failures.is_empty() and case.get_assert_count() == 0:
				failures.append("test made no assertions")
			if failures.is_empty():
				print("  PASS  %s" % method_name)
			else:
				failed += 1
				failed_labels.append("%s :: %s" % [path.trim_prefix("res://"), method_name])
				print("  FAIL  %s" % method_name)
				for failure in failures:
					print("        -> %s" % failure)

	print("\n=== Summary: %d/%d passed ===" % [total - failed, total])
	if failed > 0:
		print("Failed tests:")
		for label in failed_labels:
			print("  - %s" % label)
	quit(0 if failed == 0 else 1)


func _collect_test_files(dir_path: String, out: Array[String]) -> void:
	var dir := DirAccess.open(dir_path)
	if dir == null:
		push_error("headless_runner: cannot open directory %s" % dir_path)
		return
	dir.list_dir_begin()
	var entry := dir.get_next()
	while entry != "":
		if dir.current_is_dir():
			if not entry.begins_with("."):
				_collect_test_files(dir_path.path_join(entry), out)
		elif entry.ends_with("_test.gd"):
			out.append(dir_path.path_join(entry))
		entry = dir.get_next()
	dir.list_dir_end()
