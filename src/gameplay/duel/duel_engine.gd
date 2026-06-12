class_name DuelEngine
extends RefCounted
## Officer-vs-officer duel sub-game (design/gdd/duel-system.md).
##
## Simultaneous-stance RPS: Attack beats Feint, Feint beats Defend, Defend
## beats Attack. Stats derive from officer stats (F-1/2/3); Stamina is the
## implicit turn limiter; the Read mechanic hints the higher-WAR side every
## 3rd turn at 70% accuracy. Signature Moves resolve through a data-driven
## override (Alexsen's Crushing Blow). Context effects (field morale deltas,
## story flags) are owned by the caller via the DuelResult.

enum Stance { ATTACK, DEFEND, FEINT, SIGNATURE }
enum Outcome { ONGOING, VICTORY, DEFEAT, YIELD, DRAW }

## One side of the duel.
class Participant:
	extends RefCounted
	var officer: Officer = null
	var max_resolve: int = 0
	var resolve: int = 0
	var stamina: int = 0
	var attack_damage: int = 0
	## Signature move data entry ({} = none).
	var signature: Dictionary = {}
	var signature_used: bool = false
	var total_damage_dealt: int = 0


## Result of one resolved turn, consumed by the Duel UI.
class TurnResult:
	extends RefCounted
	var p1_stance: Stance
	var p2_stance: Stance
	var damage_to_p1: int = 0
	var damage_to_p2: int = 0
	var outcome: Outcome = Outcome.ONGOING

var config: Dictionary = {}
var p1: Participant = null   # player side
var p2: Participant = null   # opponent side
var current_turn: int = 1
var outcome: Outcome = Outcome.ONGOING
## Scripted behavior: "" | "intentional_miss" (miss_frequency applies)
var ai_behavior: String = ""
var miss_frequency: float = 0.0


static func from_config(p_config: Dictionary) -> DuelEngine:
	var engine := DuelEngine.new()
	engine.config = p_config
	return engine


## Derives a DuelParticipant from an officer:
## F-1 resolve = floor(CHR/2) + 40 · F-2 stamina = floor(INT/10) + 5 ·
## F-3 attack = floor(WAR/10) + 5.
func make_participant(officer: Officer) -> Participant:
	var participant := Participant.new()
	participant.officer = officer
	participant.max_resolve = officer.chr() / 2 + int(config.get("duel_resolve_base", 40))
	participant.resolve = participant.max_resolve
	participant.stamina = officer.intel() / 10 + int(config.get("duel_stamina_base", 5))
	participant.attack_damage = officer.war() / 10 + int(config.get("duel_attack_base", 5))
	var moves: Dictionary = config.get("signature_moves", {})
	for move_id: String in moves:
		if String(moves[move_id].get("officer_id", "")) == officer.id:
			participant.signature = moves[move_id]
	return participant


## Begins a duel between two officers (p1 = player side).
func start(player_officer: Officer, opponent_officer: Officer) -> void:
	p1 = make_participant(player_officer)
	p2 = make_participant(opponent_officer)
	current_turn = 1
	outcome = Outcome.ONGOING
	ai_behavior = ""
	miss_frequency = 0.0


## Stances legal for [param participant] this turn (stamina constraints):
## ≥2 all three; 1 → Defend/Feint; 0 (Exhausted) → Defend only.
## Signature requires stamina ≥ cost and one use per duel.
func available_stances(participant: Participant) -> Array:
	var costs: Dictionary = config.get("stamina_costs", { "attack": 2, "defend": 1, "feint": 1 })
	var stances: Array = [Stance.DEFEND]
	if participant.stamina >= int(costs.get("feint", 1)) and participant.stamina > 0:
		stances.append(Stance.FEINT)
	if participant.stamina >= int(costs.get("attack", 2)):
		stances.append(Stance.ATTACK)
	if not participant.signature.is_empty() and not participant.signature_used \
			and participant.stamina >= int(participant.signature.get("stamina_cost", 4)):
		stances.append(Stance.SIGNATURE)
	return stances


## F-4 derived damages for a winning officer's attack value.
func counter_damage(attack: int) -> int:
	return int(ceilf(attack * float(config.get("counter_damage_ratio", 0.40))))


func feint_break_damage(attack: int) -> int:
	return int(ceilf(attack * float(config.get("feint_break_ratio", 0.60))))


func tie_attack_damage(attack: int) -> int:
	return int(floorf(attack * float(config.get("tie_attack_ratio", 0.50))))


## Resolves one simultaneous turn. [param rng] drives scripted-miss rolls
## only — the RPS table itself is deterministic.
func resolve_turn(p1_stance: Stance, p2_stance: Stance, rng: RandomNumberGenerator = null) -> TurnResult:
	var result := TurnResult.new()
	result.p1_stance = p1_stance
	result.p2_stance = p2_stance

	if p1_stance == Stance.SIGNATURE or p2_stance == Stance.SIGNATURE:
		_resolve_signature(result)
	else:
		var damages := _stance_table(p1_stance, p2_stance, p1.attack_damage, p2.attack_damage)
		result.damage_to_p2 = damages[0]
		result.damage_to_p1 = damages[1]

	# Scripted intentional miss: AI (p2) wins are voided at miss_frequency.
	if ai_behavior == "intentional_miss" and rng != null and result.damage_to_p1 > 0:
		if rng.randf() < miss_frequency:
			result.damage_to_p1 = 0

	p1.resolve -= result.damage_to_p1
	p2.resolve -= result.damage_to_p2
	p1.total_damage_dealt += result.damage_to_p2
	p2.total_damage_dealt += result.damage_to_p1
	_deduct_stamina(p1, p1_stance)
	_deduct_stamina(p2, p2_stance)

	# Termination 1: resolve depleted (mutual → draw per AC-25).
	if p1.resolve <= 0 and p2.resolve <= 0:
		outcome = Outcome.DRAW
	elif p2.resolve <= 0:
		outcome = Outcome.VICTORY
	elif p1.resolve <= 0:
		outcome = Outcome.DEFEAT
	# Termination 2: mutual exhaustion → Final Exchange (both Defend, 0
	# damage) → higher resolve wins; exact tie → draw (AC-26).
	elif p1.stamina <= 0 and p2.stamina <= 0:
		if p1.resolve > p2.resolve:
			outcome = Outcome.VICTORY
		elif p2.resolve > p1.resolve:
			outcome = Outcome.DEFEAT
		else:
			outcome = Outcome.DRAW

	result.outcome = outcome
	current_turn += 1
	return result


## Read mechanic gating (F-5): fires on turns 3, 6, 9… for the strictly
## higher-WAR participant. Equal WAR → never fires.
func read_fires_for(participant: Participant, other: Participant) -> bool:
	var interval := int(config.get("read_turn_interval", 3))
	if current_turn % interval != 0:
		return false
	if participant.officer == null or other.officer == null:
		return false
	return participant.officer.war() > other.officer.war()


## Rolls the Read hint: 70% the true stance, 30% a random different stance.
## Returns the stance to DISPLAY (the caller never learns correctness).
func roll_read_hint(actual: Stance, rng: RandomNumberGenerator) -> Stance:
	if rng.randf() < float(config.get("read_accuracy", 0.70)):
		return actual
	var options: Array = [Stance.ATTACK, Stance.DEFEND, Stance.FEINT]
	options.erase(actual)
	return options[rng.randi_range(0, options.size() - 1)]


## Yield availability: opponent resolve ≤ yield_threshold × max (inclusive).
func yield_available() -> bool:
	return outcome == Outcome.ONGOING \
		and p2.resolve <= int(p2.max_resolve * float(config.get("yield_threshold", 0.30)))


## Player yields the killing blow — ends the duel immediately.
func player_yield() -> void:
	outcome = Outcome.YIELD


## Simple opponent stance pick for field duels (Tactical AI is post-MVP):
## weighted random over available stances; prefers Signature when affordable.
func ai_pick_stance(participant: Participant, rng: RandomNumberGenerator) -> Stance:
	var stances := available_stances(participant)
	if stances.has(Stance.SIGNATURE) and rng.randf() < 0.5:
		return Stance.SIGNATURE
	stances.erase(Stance.SIGNATURE)
	var weights := { Stance.ATTACK: 0.45, Stance.DEFEND: 0.25, Stance.FEINT: 0.30 }
	var total := 0.0
	for stance: Stance in stances:
		total += float(weights.get(stance, 0.2))
	var roll := rng.randf() * total
	for stance: Stance in stances:
		roll -= float(weights.get(stance, 0.2))
		if roll <= 0.0:
			return stance
	return Stance.DEFEND


## Stance Resolution Table → [damage_to_p2, damage_to_p1].
func _stance_table(s1: Stance, s2: Stance, atk1: int, atk2: int) -> Array[int]:
	match [s1, s2]:
		[Stance.ATTACK, Stance.ATTACK]:
			# Each takes the OTHER's halved attack (AC 10).
			return [tie_attack_damage(atk1), tie_attack_damage(atk2)]
		[Stance.ATTACK, Stance.DEFEND]:
			return [0, counter_damage(atk2)]
		[Stance.ATTACK, Stance.FEINT]:
			return [atk1, 0]
		[Stance.DEFEND, Stance.ATTACK]:
			return [counter_damage(atk1), 0]
		[Stance.DEFEND, Stance.DEFEND]:
			return [0, 0]
		[Stance.DEFEND, Stance.FEINT]:
			return [0, feint_break_damage(atk2)]
		[Stance.FEINT, Stance.ATTACK]:
			return [0, atk2]
		[Stance.FEINT, Stance.DEFEND]:
			return [feint_break_damage(atk1), 0]
		[Stance.FEINT, Stance.FEINT]:
			return [0, 0]
		_:
			push_error("DuelEngine: unhandled stance pair %s/%s" % [s1, s2])
			return [0, 0]


## Signature Move resolution (Crushing Blow ratios from duel_config.json).
## Both declare: higher WAR fires first; if it defeats the opponent, the
## second move does not fire (E-04). Both-signature head-on: both take the
## other's full attack_damage (AC 22).
func _resolve_signature(result: TurnResult) -> void:
	if result.p1_stance == Stance.SIGNATURE and result.p2_stance == Stance.SIGNATURE:
		result.damage_to_p2 = p1.attack_damage
		result.damage_to_p1 = p2.attack_damage
		p1.signature_used = true
		p2.signature_used = true
		return
	var sig_is_p1 := result.p1_stance == Stance.SIGNATURE
	var attacker := p1 if sig_is_p1 else p2
	var defender := p2 if sig_is_p1 else p1
	var defender_stance := result.p2_stance if sig_is_p1 else result.p1_stance
	attacker.signature_used = true
	var move := attacker.signature
	var to_defender := 0
	var to_attacker := 0
	match defender_stance:
		Stance.DEFEND:
			to_defender = int(ceilf(attacker.attack_damage * float(move.get("vs_defend_ratio", 1.0))))
		Stance.FEINT:
			to_defender = int(ceilf(attacker.attack_damage * float(move.get("vs_feint_ratio", 0.75))))
		Stance.ATTACK:
			to_defender = attacker.attack_damage
			to_attacker = int(ceilf(defender.attack_damage * float(move.get("vs_attack_self_ratio", 0.75))))
		_:
			to_defender = attacker.attack_damage
	if sig_is_p1:
		result.damage_to_p2 = to_defender
		result.damage_to_p1 = to_attacker
	else:
		result.damage_to_p1 = to_defender
		result.damage_to_p2 = to_attacker


func _deduct_stamina(participant: Participant, stance: Stance) -> void:
	var costs: Dictionary = config.get("stamina_costs", { "attack": 2, "defend": 1, "feint": 1 })
	var cost := 0
	match stance:
		Stance.ATTACK:
			cost = int(costs.get("attack", 2))
		Stance.DEFEND:
			cost = int(costs.get("defend", 1))
		Stance.FEINT:
			cost = int(costs.get("feint", 1))
		Stance.SIGNATURE:
			cost = int(participant.signature.get("stamina_cost", 4))
	participant.stamina = maxi(participant.stamina - cost, 0)
