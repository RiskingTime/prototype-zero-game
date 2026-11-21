extends RefCounted

const MAX_AP := 3

class Combatant:
    var title: String
    var weapon: String
    var cell: Vector2i
    var hp: int
    var max_hp: int
    var attack_bonus: int
    var defense_bonus: int
    var initiative_bonus: int
    var attack_cost: int
    var damage_dice: int
    var damage_sides: int


var hero: Combatant
var enemy: Combatant
var active: Combatant
var ap := MAX_AP
var round_number := 0
var outcome := ""
var log: Array[String] = []
var _order: Array[Combatant] = []
var _turn_index := 0
var _move_ap := 0
var _grid_size: Vector2i
var _rng := RandomNumberGenerator.new()


func _init(grid_size: Vector2i) -> void:
    _grid_size = grid_size
    _rng.randomize()


func restart() -> void:
    # Starting loadouts and opposed roll bonuses from the frozen browser build.
    hero = _fighter("Knight", "Longsword", Vector2i(3, 4), [24, 6, 6, 3, 1, 1, 6])
    enemy = _fighter("Sword Brute", "Greatsword", Vector2i(7, 4), [22, 5, 4, 4, 2, 2, 8])
    outcome = ""
    round_number = 0
    log.clear()
    _next_round()


func _fighter(title: String, weapon: String, cell: Vector2i, profile: Array[int]) -> Combatant:
    var fighter := Combatant.new()
    fighter.title = title
    fighter.weapon = weapon
    fighter.cell = cell
    fighter.hp = profile[0]
    fighter.max_hp = profile[0]
    fighter.attack_bonus = profile[1]
    fighter.defense_bonus = profile[2]
    fighter.initiative_bonus = profile[3]
    fighter.attack_cost = profile[4]
    fighter.damage_dice = profile[5]
    fighter.damage_sides = profile[6]
    return fighter


func _next_round() -> void:
    round_number += 1
    var hero_total := _rng.randi_range(1, 10) + hero.initiative_bonus
    var enemy_total := _rng.randi_range(1, 10) + enemy.initiative_bonus
    _order.assign([hero, enemy] if hero_total >= enemy_total else [enemy, hero])
    _turn_index = 0
    log.append("Round %d initiative: Knight %d, Sword Brute %d." % [round_number, hero_total, enemy_total])
    _begin_turn()


func _begin_turn() -> void:
    active = _order[_turn_index]
    ap = MAX_AP
    _move_ap = 0


func end_turn() -> void:
    if not outcome.is_empty():
        return
    _turn_index += 1
    if _turn_index == _order.size():
        _next_round()
    else:
        _begin_turn()


static func distance(from: Vector2i, to: Vector2i) -> int:
    return maxi(absi(to.x - from.x), absi(to.y - from.y))


func opponent() -> Combatant:
    return enemy if active == hero else hero


func movement_cost(destination: Vector2i) -> int:
    if not outcome.is_empty() or destination == active.cell or destination == opponent().cell:
        return 0
    if not Rect2i(Vector2i.ZERO, _grid_size).has_point(destination):
        return 0
    # Breadth-first distance for eight-direction movement on this flat board.
    var frontier: Array[Vector2i] = [active.cell]
    var seen := {active.cell: true, opponent().cell: true}
    for cost in range(1, ap + 1):
        var tiles := 3 if _move_ap == 0 and cost == 1 else 2
        for _tile in range(tiles):
            var next: Array[Vector2i] = []
            for cell in frontier:
                for y in range(-1, 2):
                    for x in range(-1, 2):
                        var neighbour := cell + Vector2i(x, y)
                        if seen.has(neighbour) or not Rect2i(Vector2i.ZERO, _grid_size).has_point(neighbour):
                            continue
                        if neighbour == destination:
                            return cost
                        seen[neighbour] = true
                        next.append(neighbour)
            frontier = next
    return 0


func move(destination: Vector2i) -> bool:
    var cost := movement_cost(destination)
    if cost == 0:
        return false
    active.cell = destination
    ap -= cost
    _move_ap += cost
    log.append("%s moved for %d AP." % [active.title, cost])
    return true


func can_attack() -> bool:
    return outcome.is_empty() and ap >= active.attack_cost and distance(active.cell, opponent().cell) == 1


static func attack_hits(attack_die: int, defense_die: int, attack_bonus: int, defense_bonus: int) -> bool:
    if defense_die == 20 or attack_die == 1:
        return false
    return attack_die == 20 or attack_die + attack_bonus > defense_die + defense_bonus


func attack() -> bool:
    if not can_attack():
        return false
    var target := opponent()
    ap -= active.attack_cost
    var attack_die := _rng.randi_range(1, 20)
    var defense_die := _rng.randi_range(1, 20)
    var result := "critical defense" if defense_die == 20 else "miss"
    if attack_hits(attack_die, defense_die, active.attack_bonus, target.defense_bonus):
        var damage := 0
        for _die in range(active.damage_dice):
            damage += _rng.randi_range(1, active.damage_sides)
        if attack_die == 20:
            damage *= 2
        target.hp = maxi(0, target.hp - damage)
        result = "%s for %d" % ["critical hit" if attack_die == 20 else "hit", damage]
        if target.hp == 0:
            outcome = "Victory" if active == hero else "Defeat"
    log.append("%s: d20 %d + %d vs %d + %d, %s." % [
        active.weapon, attack_die, active.attack_bonus, defense_die, target.defense_bonus, result])
    return true


func enemy_action() -> bool:
    if active != enemy or not outcome.is_empty():
        return false
    if can_attack():
        return attack()
    var destination := enemy.cell
    var nearest := distance(enemy.cell, hero.cell)
    for y in range(_grid_size.y):
        for x in range(_grid_size.x):
            var cell := Vector2i(x, y)
            var separation := distance(cell, hero.cell)
            if separation < nearest and movement_cost(cell) == 1:
                destination = cell
                nearest = separation
    return move(destination)
