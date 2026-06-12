extends "res://tests/helpers/test_case.gd"
## Morale System — design/gdd/morale-system.md acceptance criteria:
## initialization, state boundaries, triggers, aura, cascade cap, recovery.

const Fixtures := preload("res://tests/helpers/fixtures.gd")

var _morale: MoraleSystem


func setup() -> void:
	_morale = Fixtures.morale_system()


## AC: officer-led squads start at 100; officer-less at 70.
func test_starting_morale_by_officer_presence() -> void:
	var led := Fixtures.battle_squad("led", Squad.Side.PLAYER, Vector3i.ZERO, Fixtures.make_officer("o1", 50, 50, 50, 50, 50))
	var unled := Fixtures.battle_squad("unled", Squad.Side.PLAYER, Vector3i(1, -1, 0))
	assert_eq(led.morale, 100)
	assert_eq(unled.morale, 70)


## AC: morale exactly 30 is STEADY; exactly 10 is SHAKEN (not BROKEN).
func test_state_boundaries_inclusive() -> void:
	var squad := Fixtures.battle_squad("s", Squad.Side.PLAYER, Vector3i.ZERO)
	squad.set_morale(30)
	assert_eq(squad.morale_state, Squad.MoraleState.STEADY)
	squad.set_morale(10)
	assert_eq(squad.morale_state, Squad.MoraleState.SHAKEN)
	squad.set_morale(9)
	assert_eq(squad.morale_state, Squad.MoraleState.BROKEN)


## AC: morale clamps to 0; BROKEN is terminal even if the value recovers.
func test_broken_is_terminal_and_clamped() -> void:
	var squad := Fixtures.battle_squad("s", Squad.Side.PLAYER, Vector3i.ZERO)
	squad.set_morale(5)
	squad.set_morale(squad.morale - 20)
	assert_eq(squad.morale, 0, "clamped to 0, not negative")
	squad.set_morale(50)
	assert_eq(squad.morale_state, Squad.MoraleState.BROKEN, "no transition out of BROKEN")


## AC F-1: aura radius brackets — 96→4, 70→2, boundary values 50/75/90.
func test_aura_radius_brackets() -> void:
	assert_eq(_morale.aura_radius(96), 4)
	assert_eq(_morale.aura_radius(70), 2)
	assert_eq(_morale.aura_radius(49), 1)
	assert_eq(_morale.aura_radius(50), 2, "boundary: 50 is the 2-hex bracket")
	assert_eq(_morale.aura_radius(75), 3, "boundary: 75 is the 3-hex bracket")
	assert_eq(_morale.aura_radius(90), 4, "boundary: 90 is the 4-hex bracket")


## AC F-2: recovery = floor(CHR / 25); CHR 24 → 0.
func test_recovery_amount_brackets() -> void:
	assert_eq(_morale.recovery_amount(75), 3)
	assert_eq(_morale.recovery_amount(50), 2)
	assert_eq(_morale.recovery_amount(24), 0)
	assert_eq(_morale.recovery_amount(100), 4)


## AC F-3: 25% HP loss → floor(0.25 × 50) = 12 morale damage.
func test_casualty_damage_formula() -> void:
	assert_eq(_morale.casualty_damage(25.0, 100.0), 12)
	assert_eq(_morale.casualty_damage(80.0, 100.0), 40)
	assert_eq(_morale.casualty_damage(0.0, 100.0), 0)


## AC: unprotected squad takes casualties + flank (12 + 10 = 22).
func test_casualty_and_flank_triggers_unprotected() -> void:
	var squad := Fixtures.battle_squad("s", Squad.Side.PLAYER, Vector3i.ZERO)
	squad.hp_lost_this_turn = squad.max_hp * 0.25
	squad.is_flanked_this_turn = true
	_morale.resolve_morale_phase([squad])
	assert_eq(squad.morale, 70 - 22)


## AC F-7: aura applies floor((raw) × 0.75) ONCE to the combined total.
## Kaster (LDR 96) covers his own squad: raw 22 → floor(16.5) = 16.
func test_aura_reduces_combined_total_floor_once() -> void:
	var kaster := Fixtures.officer_registry().get_officer("kaster")
	var squad := Fixtures.battle_squad("s", Squad.Side.PLAYER, Vector3i.ZERO, kaster)
	squad.hp_lost_this_turn = squad.max_hp * 0.25
	squad.is_flanked_this_turn = true
	_morale.resolve_morale_phase([squad])
	assert_eq(squad.morale, 100 - 16)


## AC: officer killed this turn → flat 30 (STEADY/SHAKEN squads only).
func test_officer_loss_trigger() -> void:
	var squad := Fixtures.battle_squad("s", Squad.Side.PLAYER, Vector3i.ZERO,
		Fixtures.make_officer("o1", 50, 40, 50, 50, 50))
	squad.lose_officer()
	_morale.resolve_morale_phase([squad])
	assert_eq(squad.morale, 100 - 30)


## AC F-6 + cascade: two squads break in Pass 1 → witness within 2 hexes
## takes 2 × 10 = 20 in Pass 2; a Pass-2 break generates NO Pass 3.
func test_witnessing_and_cascade_cap() -> void:
	var a := Fixtures.battle_squad("a", Squad.Side.PLAYER, Vector3i.ZERO)
	var b := Fixtures.battle_squad("b", Squad.Side.PLAYER, Vector3i(1, -1, 0))
	var c := Fixtures.battle_squad("c", Squad.Side.PLAYER, Vector3i(2, -2, 0))
	var d := Fixtures.battle_squad("d", Squad.Side.PLAYER, Vector3i(4, -4, 0))
	a.set_morale(11)
	b.set_morale(11)
	c.set_morale(15)
	d.set_morale(40)
	# Pass 1: a and b take 12 casualty damage → 0 → BROKEN.
	a.hp_lost_this_turn = a.max_hp * 0.25
	b.hp_lost_this_turn = b.max_hp * 0.25
	_morale.resolve_morale_phase([a, b, c, d])
	assert_eq(a.morale_state, Squad.MoraleState.BROKEN)
	assert_eq(b.morale_state, Squad.MoraleState.BROKEN)
	# c is within 2 hexes of both → 20 witnessing → morale 0 → BROKEN (Pass 2).
	assert_eq(c.morale_state, Squad.MoraleState.BROKEN)
	# d (distance 2 from c, 3+ from a/b); c broke in Pass 2 → NO Pass 3 damage.
	assert_eq(d.morale, 40, "cascade cap: pass-2 breaks generate no witnessing")


## AC: enemy routs do not demoralize the other side.
func test_enemy_rout_does_not_affect_player() -> void:
	var enemy := Fixtures.battle_squad("e", Squad.Side.ENEMY, Vector3i.ZERO)
	var player := Fixtures.battle_squad("p", Squad.Side.PLAYER, Vector3i(1, -1, 0))
	enemy.set_morale(11)
	enemy.hp_lost_this_turn = enemy.max_hp * 0.25
	_morale.resolve_morale_phase([enemy, player])
	assert_eq(enemy.morale_state, Squad.MoraleState.BROKEN)
	assert_eq(player.morale, 70, "enemy break must not damage player morale (officer-less start is 70)")


## AC: recovery applies only on zero-damage turns; SHAKEN 28 + CHR 75 → 31
## and the state returns to STEADY.
func test_recovery_on_quiet_turn_restores_steady() -> void:
	var officer := Fixtures.make_officer("o1", 50, 50, 50, 50, 75)
	var squad := Fixtures.battle_squad("s", Squad.Side.PLAYER, Vector3i.ZERO, officer)
	squad.set_morale(28)
	assert_eq(squad.morale_state, Squad.MoraleState.SHAKEN)
	_morale.recovery_phase([squad])
	assert_eq(squad.morale, 31)
	assert_eq(squad.morale_state, Squad.MoraleState.STEADY)


## AC: recovery suppressed on a turn with any morale damage.
func test_recovery_suppressed_after_damage() -> void:
	var officer := Fixtures.make_officer("o1", 50, 50, 50, 50, 75)
	var squad := Fixtures.battle_squad("s", Squad.Side.PLAYER, Vector3i.ZERO, officer)
	squad.set_morale(50)
	squad.hp_lost_this_turn = squad.max_hp * 0.25
	_morale.resolve_morale_phase([squad])
	var after_damage := squad.morale
	_morale.recovery_phase([squad])
	assert_eq(squad.morale, after_damage, "no recovery on damage turns")


## AC: officer-less squad recovers only inside a friendly officer's aura,
## using the aura officer's CHR.
func test_officerless_recovery_via_aura() -> void:
	var alone := Fixtures.battle_squad("alone", Squad.Side.PLAYER, Vector3i(8, -8, 0))
	alone.set_morale(60)
	_morale.recovery_phase([alone])
	assert_eq(alone.morale, 60, "no aura → no recovery")
	var officer := Fixtures.make_officer("o1", 50, 60, 50, 50, 50)
	var leader := Fixtures.battle_squad("leader", Squad.Side.PLAYER, Vector3i(7, -7, 0), officer)
	_morale.recovery_phase([alone, leader])
	assert_eq(alone.morale, 62, "aura officer CHR 50 → +2")


## AC: BROKEN squads never recover.
func test_broken_never_recovers() -> void:
	var officer := Fixtures.make_officer("o1", 50, 90, 50, 50, 100)
	var squad := Fixtures.battle_squad("s", Squad.Side.PLAYER, Vector3i.ZERO, officer)
	squad.set_morale(5)
	_morale.recovery_phase([squad])
	assert_eq(squad.morale, 5)


## AC clamp: morale 98 + recovery 4 → 100, not 102.
func test_recovery_clamped_at_100() -> void:
	var officer := Fixtures.make_officer("o1", 50, 50, 50, 50, 100)
	var squad := Fixtures.battle_squad("s", Squad.Side.PLAYER, Vector3i.ZERO, officer)
	squad.set_morale(98)
	_morale.recovery_phase([squad])
	assert_eq(squad.morale, 100)


## AC aura priority: only the highest-LDR aura applies (no stacking).
## LDR 88 officer's aura (radius 3) vs LDR 70 (radius 2) — damage uses one
## 25% reduction, not two.
func test_overlapping_auras_do_not_stack() -> void:
	var strong := Fixtures.battle_squad("strong", Squad.Side.PLAYER, Vector3i(1, -1, 0),
		Fixtures.make_officer("o_strong", 50, 88, 50, 50, 50))
	var weak := Fixtures.battle_squad("weak", Squad.Side.PLAYER, Vector3i(0, 1, -1),
		Fixtures.make_officer("o_weak", 50, 70, 50, 50, 50))
	var squad := Fixtures.battle_squad("s", Squad.Side.PLAYER, Vector3i.ZERO)
	squad.hp_lost_this_turn = squad.max_hp * 0.5  # raw 25
	_morale.resolve_morale_phase([strong, weak, squad])
	assert_eq(squad.morale, 70 - 18, "floor(25 × 0.75) = 18 — single reduction only")
