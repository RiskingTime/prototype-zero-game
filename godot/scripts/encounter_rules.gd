extends RefCounted

# Stage 3: rules for the first 4-vs-4 encounter, ported from the frozen browser build
# (history/v0.13/index.html). No scene dependencies, so tests can drive it directly.
# Out of scope here: terrain, cover, line of sight, reactions, Fortify, Brace, Blur and
# v0.13's tactical AI scorer.

const MAX_AP := 3
const PROFICIENCY := 2
# Base order from v0.13: initiative ties and roll order follow it.
const UNIT_ORDER: Array[String] = ["K", "A", "W", "C", "S", "L", "B", "M"]

const SPELLS := {
    "arcane_dart": {"name": "Arcane Dart", "kind": "damage", "ap": 1, "range": 6,
        "stat": "wis", "type": "magic", "dice": Vector2i(1, 6)},
    "arcane_bolt": {"name": "Arcane Bolt", "kind": "damage", "ap": 2, "range": 7,
        "stat": "wis", "type": "magic", "dice": Vector2i(2, 6)},
    "force_push": {"name": "Force Push", "kind": "push", "ap": 2, "range": 5,
        "stat": "wis", "type": "magic", "dice": Vector2i(1, 6), "push": 5},
    "slow": {"name": "Slow", "kind": "slow", "ap": 2, "range": 6,
        "stat": "wis", "type": "magic", "dice": Vector2i(0, 0)},
    "healing_light": {"name": "Healing Light", "kind": "heal", "ap": 1, "range": 5,
        "stat": "int", "type": "magic", "dice": Vector2i(1, 6)},
}


class Unit:
    var id: String
    var name: String
    var team: String
    var cell: Vector2i
    var hp: int
    var max_hp: int
    var stats: Dictionary
    var weapon: Dictionary
    var spells: Array[String] = []
    var gear_attack := 0
    var gear_ac := 0
    var gear_mr := 0
    var first_move := 3
    var ap := 3
    var move_ap_spent := 0
    var turn_count := 0
    var slow_until_turn_count := 0
    var heal_used_round := 0
    var initiative := 0

    func alive() -> bool:
        return hp > 0


var seed := 0
var round_number := 0
var active: Unit
var order: Array[Unit] = []
var units: Array[Unit] = []
var outcome := ""
var log: Array[String] = []
var last_error := ""
# The latest successful action ({"actor", "target", "id", "count"}), for presentation only
# (unit facing). It never affects rules.
var last_action := {}

var _grid_size: Vector2i
var _turn_index := 0
var _rng := RandomNumberGenerator.new()
var _forced_rolls: Array[int] = []

static var _chance_cache: Dictionary = {}


func _init(grid_size: Vector2i) -> void:
    _grid_size = grid_size


# Sets up the fixed deployment and rolls initiative for round 1. The same seed and the
# same actions reproduce the same battle.
func start(battle_seed: int) -> void:
    seed = battle_seed
    last_action = {}
    _rng.seed = battle_seed
    units.clear()
    # Fixed deployment, mirrored through the board centre so no unit stands directly behind
    # another on screen (Stage 3 correction, agreed with Codex).
    # id, name, team, cell, HP, STR DEX CON INT WIS, weapon, gear attack/AC/MR, first move
    _add("K", "Knight", "hero", Vector2i(2, 3), 24, [9, 4, 7, 3, 2],
        _weapon("Longsword", "str", "physical", 1, 1, Vector2i(1, 6)), 0, 4, 0, 3)
    _add("A", "Archer", "hero", Vector2i(0, 2), 18, [3, 9, 4, 6, 3],
        _weapon("Longbow", "dex", "physical", 2, 9, Vector2i(2, 6)), 0, 1, 0, 4)
    _add("W", "Wizard", "hero", Vector2i(0, 6), 16, [2, 4, 3, 7, 9], {}, 1, 0, 0, 3)
    _add("C", "Cleric", "hero", Vector2i(1, 5), 22, [4, 3, 6, 9, 3],
        _weapon("Blessed Mace", "str", "physical", 2, 1, Vector2i(1, 8)), 0, 3, 1, 3)
    _add("S", "Sword Brute", "enemy", Vector2i(7, 4), 22, [8, 4, 7, 4, 2],
        _weapon("Greatsword", "str", "physical", 2, 1, Vector2i(2, 8)), 0, 2, 0, 3)
    _add("L", "Light Melee", "enemy", Vector2i(8, 2), 16, [5, 7, 4, 6, 3],
        _weapon("Shortsword", "dex", "physical", 1, 1, Vector2i(1, 6)), 0, 1, 0, 3)
    _add("B", "Bowman", "enemy", Vector2i(9, 5), 16, [4, 7, 4, 5, 5],
        _weapon("War Bow", "dex", "physical", 2, 9, Vector2i(2, 6)), 0, 1, 0, 4)
    _add("M", "Enemy Mage", "enemy", Vector2i(9, 1), 15, [2, 4, 3, 8, 8],
        _weapon("Ash Wand", "wis", "magic", 2, 7, Vector2i(3, 6)), 0, 0, 0, 3)
    unit("W").spells.assign(["arcane_dart", "arcane_bolt", "force_push", "slow"])
    unit("C").spells.assign(["healing_light"])
    round_number = 0
    outcome = ""
    last_error = ""
    log.clear()
    log.append("Seed %d. Heroes deploy west, enemies east." % seed)
    _next_round()


func _weapon(weapon_name: String, stat: String, damage_type: String, cost: int, reach: int, dice: Vector2i) -> Dictionary:
    return {"name": weapon_name, "kind": "basic", "ap": cost, "range": reach, "stat": stat,
        "type": damage_type, "dice": dice}


func _add(id: String, unit_name: String, team: String, cell: Vector2i, hp: int, scores: Array,
        weapon: Dictionary, gear_attack: int, gear_ac: int, gear_mr: int, first_move: int) -> void:
    var who := Unit.new()
    who.id = id
    who.name = unit_name
    who.team = team
    who.cell = cell
    who.hp = hp
    who.max_hp = hp
    who.stats = {"str": scores[0], "dex": scores[1], "con": scores[2], "int": scores[3], "wis": scores[4]}
    who.weapon = weapon
    who.gear_attack = gear_attack
    who.gear_ac = gear_ac
    who.gear_mr = gear_mr
    who.first_move = first_move
    units.append(who)


# Test hook: each later die roll takes the next queued value, clamped to the die.
func queue_rolls(values: Array) -> void:
    for value in values:
        _forced_rolls.append(int(value))


func unit(id: String) -> Unit:
    for candidate in units:
        if candidate.id == id:
            return candidate
    return null


func unit_at(cell: Vector2i, except: Unit = null) -> Unit:
    for candidate in units:
        if candidate != except and candidate.alive() and candidate.cell == cell:
            return candidate
    return null


func living(team: String) -> Array[Unit]:
    var result: Array[Unit] = []
    for candidate in units:
        if candidate.team == team and candidate.alive():
            result.append(candidate)
    return result


# --- Actions and derived numbers -------------------------------------------------------

func actions_for(who: Unit) -> Array[String]:
    var result: Array[String] = []
    if not who.weapon.is_empty():
        result.append("basic")
    result.append_array(who.spells)
    return result


func action(who: Unit, id: String) -> Dictionary:
    if who == null or not actions_for(who).has(id):
        return {}
    var result: Dictionary = (who.weapon if id == "basic" else SPELLS[id]).duplicate()
    result["id"] = id
    return result


static func ability_mod(score: int) -> int:
    return score - 5


# Half a modifier, rounded toward zero (v0.13 halfMod).
static func half_mod(value: int) -> int:
    return int(value / 2.0)


func attack_bonus(who: Unit, id: String) -> int:
    var chosen := action(who, id)
    if chosen.is_empty():
        return 0
    return ability_mod(who.stats[chosen["stat"]]) + PROFICIENCY + who.gear_attack


func physical_defense(who: Unit) -> int:
    return ability_mod(who.stats["con"]) + half_mod(ability_mod(who.stats["dex"])) + who.gear_ac


func magic_defense(who: Unit) -> int:
    return ability_mod(who.stats["wis"]) + half_mod(ability_mod(who.stats["int"])) + who.gear_mr


func initiative_bonus(who: Unit) -> int:
    return who.stats["int"]


func defense_for(target: Unit, damage_type: String) -> int:
    return magic_defense(target) if damage_type == "magic" else physical_defense(target)


static func distance(from: Vector2i, to: Vector2i) -> int:
    return maxi(absi(to.x - from.x), absi(to.y - from.y))


func adjacent_enemies(who: Unit, at := Vector2i(-99, -99)) -> Array[Unit]:
    var origin := who.cell if at == Vector2i(-99, -99) else at
    var result: Array[Unit] = []
    for other in units:
        if other.alive() and other.team != who.team and distance(origin, other.cell) <= 1:
            result.append(other)
    return result


func roll_modes(attacker: Unit, target: Unit, id: String) -> Dictionary:
    var chosen := action(attacker, id)
    var attack_disadvantages: Array[String] = []
    if chosen.get("kind") == "basic" and chosen.get("type") == "physical" and chosen.get("range", 1) > 1:
        var nearby := adjacent_enemies(attacker)
        if not nearby.is_empty():
            var names: Array[String] = []
            for other in nearby:
                names.append(other.name)
            attack_disadvantages.append("Adjacent enemy: " + ", ".join(names))
    return {
        "attack": "disadvantage" if not attack_disadvantages.is_empty() else "normal",
        "defense": "normal",
        "reasons": attack_disadvantages,
    }


static func kept_roll(mode: String, first: int, second: int) -> int:
    if mode == "advantage":
        return maxi(first, second)
    if mode == "disadvantage":
        return mini(first, second)
    return first


static func attack_hits(attack_die: int, defense_die: int, attack_total: int, defense_total: int) -> bool:
    if defense_die == 20:
        return false
    if attack_die == 20:
        return true
    return attack_die != 1 and attack_total > defense_total


# Exact hit chance by enumeration (v0.13 opposedChance2), as a percentage rounded half up to 0.1.
static func opposed_chance(attack: int, defense: int, attack_mode := "normal", defense_mode := "normal") -> float:
    var key := "%d|%d|%s|%s" % [attack, defense, attack_mode, defense_mode]
    if _chance_cache.has(key):
        return _chance_cache[key]
    var attack_seconds: Array = [0] if attack_mode == "normal" else range(1, 21)
    var defense_seconds: Array = [0] if defense_mode == "normal" else range(1, 21)
    var hits := 0
    var total := 0
    for a1 in range(1, 21):
        for a2 in attack_seconds:
            var kept_attack := kept_roll(attack_mode, a1, a2)
            for d1 in range(1, 21):
                for d2 in defense_seconds:
                    var kept_defense := kept_roll(defense_mode, d1, d2)
                    if attack_hits(kept_attack, kept_defense, kept_attack + attack, kept_defense + defense):
                        hits += 1
                    total += 1
    var result := floorf(float(hits) / float(total) * 1000.0 + 0.5) / 10.0
    _chance_cache[key] = result
    return result


func hit_chance(attacker: Unit, target: Unit, id: String) -> float:
    var chosen := action(attacker, id)
    if chosen.is_empty() or chosen["kind"] == "heal":
        return 0.0
    var modes := roll_modes(attacker, target, id)
    return opposed_chance(attack_bonus(attacker, id), defense_for(target, chosen["type"]),
        modes["attack"], modes["defense"])


# Why an action can't be used on a target, or "" when it is legal.
func target_reason(attacker: Unit, target: Unit, id: String) -> String:
    if attacker == null or target == null:
        return "No target."
    if not outcome.is_empty():
        return "The battle is over."
    var chosen := action(attacker, id)
    if chosen.is_empty():
        return "%s can't use that action." % attacker.name
    if attacker.ap < chosen["ap"]:
        return "Cannot use %s: needs %d AP, but only %d AP remains." % [chosen["name"], chosen["ap"], attacker.ap]
    if chosen["kind"] == "heal":
        if target.team != attacker.team:
            return "Healing Light targets an ally."
        if not target.alive():
            return "Cannot heal a defeated unit."
        if target.hp >= target.max_hp:
            return "%s is already at full HP." % target.name
        if attacker.heal_used_round == round_number:
            return "Healing Light has already been used this round."
    else:
        if target.team == attacker.team:
            return "%s targets an enemy." % chosen["name"]
        if not target.alive():
            return "%s is already defeated." % target.name
    var gap := distance(attacker.cell, target.cell)
    if gap > chosen["range"]:
        return "Cannot use %s: target is %d tiles away and range is %d. Move closer first." % [
            chosen["name"], gap, chosen["range"]]
    return ""


# --- Movement --------------------------------------------------------------------------

func is_slowed(who: Unit) -> bool:
    return who.slow_until_turn_count > who.turn_count


func move_increment(who: Unit, index: int) -> int:
    if is_slowed(who):
        return 2 if index == 1 else 1
    return who.first_move if index == 1 else 2


func movement_allowance(who: Unit, additional_ap: int) -> int:
    var total := 0
    for step in range(1, additional_ap + 1):
        total += move_increment(who, who.move_ap_spent + step)
    return total


func _max_move_ap(who: Unit) -> int:
    return mini(who.ap, MAX_AP - who.move_ap_spent)


func _on_board(cell: Vector2i) -> bool:
    return Rect2i(Vector2i.ZERO, _grid_size).has_point(cell)


# Steps from the unit to every cell it could walk to with its remaining movement.
# Allies can be walked through; enemies block.
func _step_counts(who: Unit) -> Dictionary:
    var limit := movement_allowance(who, _max_move_ap(who))
    var steps := {who.cell: 0}
    var frontier: Array[Vector2i] = [who.cell]
    for count in range(1, limit + 1):
        var next: Array[Vector2i] = []
        for cell in frontier:
            for dy in range(-1, 2):
                for dx in range(-1, 2):
                    var neighbour := cell + Vector2i(dx, dy)
                    if steps.has(neighbour) or not _on_board(neighbour):
                        continue
                    var occupant := unit_at(neighbour, who)
                    if occupant != null and occupant.team != who.team:
                        continue
                    steps[neighbour] = count
                    next.append(neighbour)
        frontier = next
    return steps


func _cost_for_steps(who: Unit, count: int) -> int:
    for spend in range(1, _max_move_ap(who) + 1):
        if count <= movement_allowance(who, spend):
            return spend
    return 0


func movement_cost(who: Unit, cell: Vector2i) -> int:
    if who == null or not outcome.is_empty() or not who.alive():
        return 0
    if cell == who.cell or not _on_board(cell) or unit_at(cell, who) != null:
        return 0
    var steps := _step_counts(who)
    if not steps.has(cell):
        return 0
    return _cost_for_steps(who, steps[cell])


func reachable(who: Unit) -> Dictionary:
    var result := {}
    if who == null or not outcome.is_empty() or not who.alive():
        return result
    var steps := _step_counts(who)
    for cell in steps:
        if cell == who.cell or unit_at(cell, who) != null:
            continue
        var cost := _cost_for_steps(who, steps[cell])
        if cost > 0:
            result[cell] = cost
    return result


func move(cell: Vector2i) -> bool:
    var cost := movement_cost(active, cell)
    if cost == 0:
        last_error = "That tile is out of reach."
        return false
    active.cell = cell
    active.ap -= cost
    active.move_ap_spent += cost
    last_error = ""
    log.append("%s moves to (%d, %d) for %d AP." % [active.name, cell.x, cell.y, cost])
    return true


# --- Resolving actions -----------------------------------------------------------------

func _roll(sides: int) -> int:
    if not _forced_rolls.is_empty():
        return clampi(_forced_rolls.pop_front(), 1, sides)
    return _rng.randi_range(1, sides)


func _roll_d20(mode: String) -> Array[int]:
    var first := _roll(20)
    if mode == "normal":
        return [first, first]
    var second := _roll(20)
    return [kept_roll(mode, first, second), second]


static func _signed(value: int) -> String:
    return "+ %d" % value if value >= 0 else "− %d" % -value


func _dice_text(rolls: Array[int]) -> String:
    var parts: Array[String] = []
    for value in rolls:
        parts.append(str(value))
    return " + ".join(parts)


func use_action(id: String, target: Unit) -> bool:
    var reason := target_reason(active, target, id)
    if not reason.is_empty():
        last_error = reason
        return false
    last_error = ""
    var chosen := action(active, id)
    active.ap -= chosen["ap"]
    if chosen["kind"] == "heal":
        _heal(chosen, target)
    else:
        _resolve_opposed(id, chosen, target)
    last_action = {"actor": active.id, "target": target.id, "id": id, "count": int(last_action.get("count", 0)) + 1}
    _check_outcome()
    return true


func _heal(chosen: Dictionary, target: Unit) -> void:
    var raw := _roll(6)
    var bonus := ability_mod(active.stats["int"])
    var rolled := maxi(1, raw + bonus)
    var restored := mini(target.max_hp - target.hp, rolled)
    target.hp += restored
    active.heal_used_round = round_number
    log.append("%s casts %s on %s: d6 %d %s, +%d HP (%d/%d)." % [
        active.name, chosen["name"], target.name, raw, _signed(bonus), restored, target.hp, target.max_hp])


func _resolve_opposed(id: String, chosen: Dictionary, target: Unit) -> void:
    var modes := roll_modes(active, target, id)
    var bonus := attack_bonus(active, id)
    var defense := defense_for(target, chosen["type"])
    var attack_die := _roll_d20(modes["attack"])[0]
    var defense_die := _roll_d20(modes["defense"])[0]
    var attack_total := attack_die + bonus
    var defense_total := defense_die + defense
    var mode_note := "" if modes["attack"] == "normal" else " (%s)" % modes["attack"]
    var summary := "%s → %s, %s: d20 %d%s %s = %d vs d20 %d %s = %d" % [
        active.name, target.name, chosen["name"], attack_die, mode_note, _signed(bonus), attack_total,
        defense_die, _signed(defense), defense_total]
    if not attack_hits(attack_die, defense_die, attack_total, defense_total):
        log.append(summary + (", critical defence." if defense_die == 20 else ", miss."))
        return
    match chosen["kind"]:
        "basic", "damage":
            var rolls: Array[int] = []
            for _die in range(chosen["dice"].x):
                rolls.append(_roll(chosen["dice"].y))
            var damage := 0
            for value in rolls:
                damage += value
            var critical: bool = chosen["kind"] == "basic" and chosen["type"] == "physical" and attack_die == 20
            if critical:
                damage *= 2
            target.hp = maxi(0, target.hp - damage)
            log.append("%s, %s for %d (%s%s). %s %s." % [
                summary, "critical hit" if critical else "hit", damage, _dice_text(rolls),
                " × 2" if critical else "", target.name,
                "is defeated" if target.hp == 0 else "has %d/%d HP" % [target.hp, target.max_hp]])
        "slow":
            target.slow_until_turn_count = target.turn_count + 1
            log.append("%s, hit. %s is Slowed through its next turn." % [summary, target.name])
        "push":
            _push(summary, chosen, target)


func _push(summary: String, chosen: Dictionary, target: Unit) -> void:
    var step := Vector2i(signi(target.cell.x - active.cell.x), signi(target.cell.y - active.cell.y))
    var moved := 0
    var collision := ""
    for _tile in range(chosen["push"]):
        var next := target.cell + step
        if not _on_board(next):
            collision = "the board edge"
            break
        var blocker := unit_at(next, target)
        if blocker != null:
            collision = blocker.name
            break
        target.cell = next
        moved += 1
    var text := "%s, hit. %s is pushed %d tile%s" % [summary, target.name, moved, "" if moved == 1 else "s"]
    if collision.is_empty():
        log.append(text + ".")
        return
    var damage := _roll(6)
    target.hp = maxi(0, target.hp - damage)
    log.append("%s into %s: collision d6 %d. %s %s." % [text, collision, damage, target.name,
        "is defeated" if target.hp == 0 else "has %d/%d HP" % [target.hp, target.max_hp]])


func _check_outcome() -> void:
    if living("enemy").is_empty():
        outcome = "Victory"
        log.append("Victory: the enemy squad is defeated.")
    elif living("hero").is_empty():
        outcome = "Defeat"
        log.append("Defeat: the party has fallen.")


# --- Turn flow -------------------------------------------------------------------------

func _next_round() -> void:
    round_number += 1
    var rolled: Array[Unit] = []
    var parts: Array[String] = []
    for id in UNIT_ORDER:
        var who := unit(id)
        if who == null or not who.alive():
            continue
        who.initiative = _roll(10) + initiative_bonus(who)
        rolled.append(who)
    # Stable sort, high to low: ties keep the v0.13 base order.
    var ranked: Array[Unit] = []
    for who in rolled:
        var index := ranked.size()
        for position in range(ranked.size()):
            if who.initiative > ranked[position].initiative:
                index = position
                break
        ranked.insert(index, who)
    order = ranked
    for who in order:
        parts.append("%s %d" % [who.name, who.initiative])
    log.append("Round %d initiative: %s." % [round_number, ", ".join(parts)])
    _turn_index = 0
    _begin_turn(order[0])


func _begin_turn(who: Unit) -> void:
    active = who
    who.ap = MAX_AP
    who.move_ap_spent = 0


func end_turn() -> void:
    if not outcome.is_empty() or active == null:
        return
    active.turn_count += 1
    _turn_index += 1
    while _turn_index < order.size() and not order[_turn_index].alive():
        _turn_index += 1
    if _turn_index >= order.size():
        _next_round()
    else:
        _begin_turn(order[_turn_index])


# --- Simple enemy AI -------------------------------------------------------------------

# One enemy decision. Returns false when the active enemy can't do anything useful, and
# the caller then ends its turn.
func enemy_step() -> bool:
    if active == null or active.team != "enemy" or not outcome.is_empty():
        return false
    var target := _best_target(active, active.cell)
    if target != null:
        return use_action("basic", target)
    var weapon: Dictionary = active.weapon
    var options := reachable(active)
    var ranged: bool = weapon["range"] > 1
    var best_cell := Vector2i(-1, -1)
    var best_key: Array = []
    for cell in options:
        var cost: int = options[cell]
        if active.ap - cost < weapon["ap"]:
            continue
        var heroes_in_range := 0
        var weakest := 9999
        for hero in living("hero"):
            if distance(cell, hero.cell) <= weapon["range"]:
                heroes_in_range += 1
                weakest = mini(weakest, hero.hp)
        if heroes_in_range == 0:
            continue
        var crowded := 1 if ranged and not adjacent_enemies(active, cell).is_empty() else 0
        var key := [cost, crowded, weakest, cell.y, cell.x]
        if best_key.is_empty() or key < best_key:
            best_key = key
            best_cell = cell
    if best_cell != Vector2i(-1, -1):
        return move(best_cell)
    # No attack position this turn: close in on the nearest hero. A ranged unit that
    # already has a hero in range holds its position instead.
    var current := _nearest_hero_distance(active.cell)
    if ranged and current <= weapon["range"]:
        return false
    for cell in options:
        var gap := _nearest_hero_distance(cell)
        if gap >= current:
            continue
        var key := [gap, options[cell], cell.y, cell.x]
        if best_key.is_empty() or key < best_key:
            best_key = key
            best_cell = cell
    if best_cell != Vector2i(-1, -1):
        return move(best_cell)
    return false


func _best_target(attacker: Unit, _from: Vector2i) -> Unit:
    var best: Unit = null
    var best_key: Array = []
    for hero in living("hero"):
        if not target_reason(attacker, hero, "basic").is_empty():
            continue
        var key := [hero.hp, -hit_chance(attacker, hero, "basic"), UNIT_ORDER.find(hero.id)]
        if best_key.is_empty() or key < best_key:
            best_key = key
            best = hero
    return best


func _nearest_hero_distance(cell: Vector2i) -> int:
    var nearest := 9999
    for hero in living("hero"):
        nearest = mini(nearest, distance(cell, hero.cell))
    return nearest
