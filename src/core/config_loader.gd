class_name ConfigLoader
extends RefCounted
## Loads gameplay configuration from external JSON files.
##
## All gameplay values are data-driven (see .claude/docs/coding-standards.md).
## Systems receive their config Dictionary via dependency injection so unit
## tests can substitute fixture data without touching the filesystem.

## Loads and parses a JSON file into a Dictionary.
## Returns an empty Dictionary (and logs an error) when the file is missing,
## unreadable, or does not contain a top-level JSON object.
static func load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_error("ConfigLoader: file not found: %s" % path)
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("ConfigLoader: cannot open %s (error %d)" % [path, FileAccess.get_open_error()])
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed == null or not (parsed is Dictionary):
		push_error("ConfigLoader: %s is not a valid JSON object" % path)
		return {}
	return parsed
