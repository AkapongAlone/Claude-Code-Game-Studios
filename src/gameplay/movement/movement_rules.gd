class_name MovementRules
extends RefCounted
## AP pool formula (design/gdd/hex-movement.md F-1).
##
## ap_pool = min(base_ap[unit_class] + floor((ldr - 1) / 34), max_ap[unit_class])
## LDR breakpoints: 1–34 → +0, 35–67 → +1, 68–100 → +2.
## All values are data-driven via assets/data/movement.json.

## Computes the per-turn AP budget for a squad. [param ldr] is the
## commanding officer's LDR, or 0 for officer-less squads (treated as LDR 1
## — no bonus).
static func ap_pool(unit_class: String, ldr: int, config: Dictionary) -> int:
	var base_ap: Dictionary = config.get("base_ap", {})
	var max_ap: Dictionary = config.get("max_ap", {})
	var divisor: int = int(config.get("ldr_ap_divisor", 34))
	var base: int = int(base_ap.get(unit_class, 3))
	var cap: int = int(max_ap.get(unit_class, 5))
	var bonus: int = maxi(ldr - 1, 0) / divisor
	return mini(base + bonus, cap)
