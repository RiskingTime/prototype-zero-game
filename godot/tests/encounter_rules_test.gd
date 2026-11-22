extends SceneTree

# Writer's rules tests for Stage 3 (Codex's acceptance tests are separate).
const Rules = preload("res://scripts/encounter_rules.gd")
var _failures := 0


func _initialize() -> void:
    call_deferred("_verify")


func _check(condition: bool, message: String) -> void:
    if not condition:
        _failures += 1
        printerr("ENCOUNTER RULES TEST FAILED: ", message)


func _fresh(battle_seed := 5) -> RefCounted:
    var battle = Rules.new(Vector2i(10, 8))
    battle.start(battle_seed)
    return battle


# Make a unit the active one with a fresh turn, for focused checks.
func _activate(battle, id: String) -> void:
    var who = battle.unit(id)
    battle.active = who
    who.ap = 3
    who.move_ap_spent = 0


func _verify() -> void:
    _check_stats()
    _check_chances()
    _check_initiative()
    _check_movement()
    _check_attacks()
    _check_spells()
    _check_healing()
    _check_outcomes_and_ai()
    _check_seed_replay()
    if _failures == 0:
        print("ENCOUNTER RULES TEST PASSED: stats, chances, initiative, movement, attacks, spells, healing, outcomes, AI, seeds.")
    quit(0 if _failures == 0 else 1)


func _check_stats() -> void:
    var battle = _fresh()
    # id: [cell, HP, initiative, attack, AC, MR, actions]
    var expected := {
        "K": [Vector2i(2, 3), 24, 3, 6, 6, -4, ["basic"]],
        "A": [Vector2i(0, 2), 18, 6, 6, 2, -2, ["basic"]],
        "W": [Vector2i(0, 6), 16, 7, 7, -2, 5, ["arcane_dart", "arcane_bolt", "force_push", "slow"]],
        "C": [Vector2i(1, 5), 22, 9, 1, 3, 1, ["basic", "healing_light"]],
        "S": [Vector2i(7, 4), 22, 4, 5, 4, -3, ["basic"]],
        "L": [Vector2i(8, 2), 16, 6, 4, 1, -2, ["basic"]],
        "B": [Vector2i(9, 5), 16, 5, 4, 1, 0, ["basic"]],
        "M": [Vector2i(9, 1), 15, 8, 5, -2, 4, ["basic"]],
    }
    for id in expected:
        var who = battle.unit(id)
        var row: Array = expected[id]
        var actions: Array = battle.actions_for(who)
        _check(who != null and who.cell == row[0] and who.hp == row[1] and who.max_hp == row[1],
            "%s deploys at %s with %d HP." % [id, row[0], row[1]])
        _check(battle.initiative_bonus(who) == row[2], "%s initiative bonus %d." % [id, row[2]])
        _check(battle.attack_bonus(who, actions[0]) == row[3], "%s attack bonus %d." % [id, row[3]])
        _check(battle.physical_defense(who) == row[4], "%s AC %d." % [id, row[4]])
        _check(battle.magic_defense(who) == row[5], "%s MR %d." % [id, row[5]])
        _check(actions == row[6], "%s actions %s." % [id, row[6]])
    var bow: Dictionary = battle.action(battle.unit("A"), "basic")
    _check(bow["ap"] == 2 and bow["range"] == 9 and bow["dice"] == Vector2i(2, 6) and bow["type"] == "physical",
        "Longbow is 2 AP, range 9, 2d6 physical.")
    var wand: Dictionary = battle.action(battle.unit("M"), "basic")
    _check(wand["ap"] == 2 and wand["range"] == 7 and wand["dice"] == Vector2i(3, 6) and wand["type"] == "magic",
        "Ash Wand is 2 AP, range 7, 3d6 magic.")


func _check_chances() -> void:
    _check(Rules.opposed_chance(6, 4) == 56.3, "6 vs 4 is 56.3%.")
    _check(Rules.opposed_chance(6, 1, "disadvantage") == 52.8, "6 vs 1 with attacker disadvantage is 52.8%.")
    _check(Rules.opposed_chance(7, -3) == 81.3, "7 vs -3 is 81.3%.")
    _check(Rules.opposed_chance(1, 4) == 34.8, "1 vs 4 is 34.8%.")


func _check_initiative() -> void:
    var battle = Rules.new(Vector2i(10, 8))
    # All d10s roll 1: totals K 4, A 7, W 8, C 10, S 5, L 7, B 6, M 9. A and L tie; A keeps base order.
    battle.queue_rolls([1, 1, 1, 1, 1, 1, 1, 1])
    battle.start(3)
    var ids: Array[String] = []
    for who in battle.order:
        ids.append(who.id)
    _check(ids == ["C", "M", "W", "A", "L", "B", "S", "K"], "Initiative order with ties: %s." % [ids])
    _check(battle.active.id == "C" and battle.active.ap == 3, "Highest initiative acts first with 3 AP.")
    # Defeated units drop out of the next round's order.
    battle.unit("S").hp = 0
    for _turn in range(8):
        battle.end_turn()
    _check(battle.round_number == 2 and battle.order.size() == 7, "Round 2 re-rolls and skips the defeated.")
    for who in battle.order:
        _check(who.id != "S", "Defeated Sword Brute has no turn.")


func _check_movement() -> void:
    var battle = _fresh()
    _activate(battle, "K")
    var knight = battle.unit("K")
    _check(battle.movement_cost(knight, Vector2i(5, 3)) == 1, "Knight's first AP moves 3 tiles.")
    _check(battle.movement_cost(knight, Vector2i(6, 3)) == 2, "4 or 5 tiles cost 2 AP.")
    _check(battle.movement_cost(knight, Vector2i(2, 0)) == 1, "Moving 3 tiles north costs 1 AP.")
    _check(battle.movement_cost(knight, Vector2i(7, 4)) == 0, "Can't end on an enemy.")
    _check(battle.movement_cost(knight, Vector2i(0, 2)) == 0, "Can't end on an ally.")
    var archer = battle.unit("A")
    _activate(battle, "A")
    _check(battle.movement_cost(archer, Vector2i(4, 2)) == 1, "Archer's first AP moves 4 tiles.")
    _activate(battle, "K")
    _check(battle.move(Vector2i(4, 3)) and knight.ap == 2 and knight.move_ap_spent == 1, "Move spends whole AP.")
    _check(battle.movement_cost(knight, Vector2i(6, 3)) == 1, "Later movement AP gives 2 tiles.")
    _check(battle.movement_cost(knight, Vector2i(7, 3)) == 2, "Three more tiles need 2 AP.")
    var overlay: Dictionary = battle.reachable(knight)
    _check(overlay.get(Vector2i(6, 3)) == 1 and overlay.get(Vector2i(8, 3)) == 2 and not overlay.has(Vector2i(7, 4)),
        "reachable() matches movement_cost and skips occupied cells.")
    # Enemies block; allies can be walked through.
    var blocked = _fresh()
    var wall := [Vector2i(3, 0), Vector2i(3, 1), Vector2i(3, 2)]
    var ids := ["S", "L", "B"]
    for index in range(3):
        blocked.unit(ids[index]).cell = wall[index]
    blocked.unit("A").cell = Vector2i(2, 2)
    _activate(blocked, "K")
    blocked.unit("K").cell = Vector2i(2, 0)
    _check(blocked.movement_cost(blocked.unit("K"), Vector2i(4, 0)) == 3,
        "An enemy wall forces a 6-step detour through an ally (3 AP).")
    var through = _fresh()
    var hero_wall := ["A", "C", "W"]
    for index in range(3):
        through.unit(hero_wall[index]).cell = Vector2i(3, index + 2)
    through.unit("K").cell = Vector2i(2, 3)
    _activate(through, "K")
    _check(through.movement_cost(through.unit("K"), Vector2i(4, 3)) == 1, "Allies can be walked through.")
    # Slowed: 2 tiles for the first AP, then 1 per AP.
    var slowed = _fresh()
    _activate(slowed, "K")
    var slow_knight = slowed.unit("K")
    slow_knight.slow_until_turn_count = slow_knight.turn_count + 1
    _check(slowed.is_slowed(slow_knight), "Slow marks the unit.")
    _check(slowed.movement_cost(slow_knight, Vector2i(4, 3)) == 1 and slowed.movement_cost(slow_knight, Vector2i(5, 3)) == 2
        and slowed.movement_cost(slow_knight, Vector2i(6, 3)) == 3, "Slowed movement is 2/3/4.")


func _check_attacks() -> void:
    var battle = _fresh()
    var knight = battle.unit("K")
    var brute = battle.unit("S")
    knight.cell = Vector2i(6, 4)
    brute.cell = Vector2i(7, 4)
    _activate(battle, "K")
    _check(battle.hit_chance(knight, brute, "basic") == Rules.opposed_chance(6, 4), "Knight vs Brute uses +6 vs AC +4.")
    battle.queue_rolls([20, 5, 4])
    _check(battle.use_action("basic", brute) and brute.hp == 14 and knight.ap == 2,
        "Natural 20 longsword hit doubles 4 to 8.")
    battle.queue_rolls([15, 20])
    battle.use_action("basic", brute)
    _check(brute.hp == 14 and battle.log.back().ends_with("critical defence."), "Defender's natural 20 always defends.")
    battle.queue_rolls([1, 1])
    battle.use_action("basic", brute)
    _check(brute.hp == 14 and knight.ap == 0, "Natural 1 misses and still spends AP.")
    _check(battle.target_reason(knight, brute, "basic").begins_with("Cannot use Longsword: needs 1 AP"),
        "Out of AP is explained.")
    # Ranged attack with an adjacent enemy has Disadvantage.
    var ranged = _fresh()
    var archer = ranged.unit("A")
    var light = ranged.unit("L")
    light.cell = Vector2i(1, 2)
    _activate(ranged, "A")
    var modes: Dictionary = ranged.roll_modes(archer, ranged.unit("B"), "basic")
    _check(modes["attack"] == "disadvantage" and modes["reasons"][0] == "Adjacent enemy: Light Melee",
        "Adjacent enemy gives the longbow Disadvantage.")
    _check(ranged.hit_chance(archer, ranged.unit("B"), "basic") == Rules.opposed_chance(6, 1, "disadvantage"),
        "Hit chance uses the disadvantage roll.")
    ranged.queue_rolls([18, 3, 15])
    ranged.use_action("basic", ranged.unit("B"))
    _check(ranged.unit("B").hp == 16 and ranged.log.back().ends_with("miss."), "Disadvantage keeps the lower d20 (3).")
    _check(ranged.roll_modes(archer, light, "basic")["attack"] == "disadvantage", "Shooting the adjacent enemy also has Disadvantage.")
    _check(ranged.roll_modes(ranged.unit("K"), light, "basic")["attack"] == "normal", "Melee attacks never do.")
    # Range is Chebyshev distance.
    var far = _fresh()
    _activate(far, "C")
    _check(far.target_reason(far.unit("C"), far.unit("S"), "basic").contains("range is 1"), "Mace needs adjacency.")


func _check_spells() -> void:
    var battle = _fresh()
    var wizard = battle.unit("W")
    var brute = battle.unit("S")
    wizard.cell = Vector2i(4, 4)
    _activate(battle, "W")
    _check(battle.hit_chance(wizard, brute, "arcane_dart") == Rules.opposed_chance(7, -3), "Spells attack +7 vs MR.")
    battle.queue_rolls([20, 2, 5])
    battle.use_action("arcane_dart", brute)
    _check(brute.hp == 17 and wizard.ap == 2, "Magic natural 20 is not doubled (5 damage, 1 AP).")
    battle.queue_rolls([12, 2, 3, 4])
    battle.use_action("arcane_bolt", brute)
    _check(brute.hp == 10 and wizard.ap == 0, "Arcane Bolt deals 2d6 for 2 AP.")
    # Force Push: away from the caster, stopping at the edge with 1d6 collision damage.
    var push = _fresh()
    var caster = push.unit("W")
    var target = push.unit("M")
    caster.cell = Vector2i(5, 3)
    target.cell = Vector2i(7, 3)
    push.unit("L").cell = Vector2i(5, 0)
    push.unit("S").cell = Vector2i(8, 7)
    _activate(push, "W")
    push.queue_rolls([15, 2, 4])
    push.use_action("force_push", target)
    _check(target.cell == Vector2i(9, 3) and target.hp == 11, "Push stops at the edge after 2 tiles; collision deals 4.")
    var clean = _fresh()
    clean.unit("W").cell = Vector2i(2, 4)
    clean.unit("S").cell = Vector2i(3, 4)
    clean.unit("B").cell = Vector2i(9, 7)
    clean.unit("L").cell = Vector2i(8, 7)
    _activate(clean, "W")
    clean.queue_rolls([15, 2])
    clean.use_action("force_push", clean.unit("S"))
    _check(clean.unit("S").cell == Vector2i(8, 4) and clean.unit("S").hp == 22, "Full 5-tile push without collision.")
    var diagonal = _fresh()
    diagonal.unit("W").cell = Vector2i(3, 3)
    diagonal.unit("S").cell = Vector2i(4, 4)
    diagonal.unit("B").cell = Vector2i(6, 6)
    _activate(diagonal, "W")
    diagonal.queue_rolls([15, 2, 3])
    diagonal.use_action("force_push", diagonal.unit("S"))
    _check(diagonal.unit("S").cell == Vector2i(5, 5) and diagonal.unit("S").hp == 19, "Push stops before a unit; collision 3.")
    # Slow lasts through the target's next turn.
    var slow = _fresh()
    var slowed = slow.unit("S")
    slow.unit("W").cell = Vector2i(3, 4)
    _activate(slow, "W")
    slow.queue_rolls([15, 2])
    slow.use_action("slow", slowed)
    _check(slow.is_slowed(slowed), "Slow applies on a hit.")
    slowed.turn_count += 1
    _check(not slow.is_slowed(slowed), "Slow ends after the target's next turn.")
    slow.unit("W").ap = 3
    _check(slow.target_reason(slow.unit("W"), slow.unit("K"), "slow") == "Slow targets an enemy.", "Spells target enemies.")


func _check_healing() -> void:
    var battle = _fresh()
    var cleric = battle.unit("C")
    var knight = battle.unit("K")
    _activate(battle, "C")
    _check(battle.target_reason(cleric, knight, "healing_light") == "Knight is already at full HP.", "No healing at full HP.")
    knight.hp = 20
    battle.queue_rolls([6])
    _check(battle.use_action("healing_light", knight) and knight.hp == 24 and cleric.ap == 2, "Healing is capped at max HP.")
    battle.unit("A").hp = 3
    _check(battle.target_reason(cleric, battle.unit("A"), "healing_light") == "Healing Light has already been used this round.",
        "Healing Light once per round.")
    var again = _fresh()
    _activate(again, "C")
    again.unit("C").hp = 10
    again.queue_rolls([1])
    again.use_action("healing_light", again.unit("C"))
    _check(again.unit("C").hp == 15, "The Cleric can heal itself for 1 + 4.")
    _check(again.target_reason(again.unit("C"), again.unit("S"), "healing_light") == "Healing Light targets an ally.",
        "Healing Light can't target enemies.")
    var far = _fresh()
    _activate(far, "C")
    far.unit("K").hp = 5
    far.unit("K").cell = Vector2i(7, 5)
    _check(far.target_reason(far.unit("C"), far.unit("K"), "healing_light").contains("range is 5"), "Healing range is 5.")


func _check_outcomes_and_ai() -> void:
    var battle = _fresh()
    for id in ["L", "B", "M"]:
        battle.unit(id).hp = 0
    battle.unit("S").hp = 1
    battle.unit("S").cell = Vector2i(7, 4)
    battle.unit("K").cell = Vector2i(6, 4)
    _activate(battle, "K")
    battle.queue_rolls([15, 2, 3])
    battle.use_action("basic", battle.unit("S"))
    _check(battle.outcome == "Victory", "Defeating the last enemy wins.")
    _check(not battle.use_action("basic", battle.unit("S")) and battle.reachable(battle.unit("K")).is_empty(),
        "Nothing happens after the outcome.")
    # AI: the active enemy attacks the weakest hero it can reach.
    var ai = _fresh()
    var light = ai.unit("L")
    light.cell = Vector2i(3, 3)
    ai.unit("A").cell = Vector2i(4, 3)
    ai.unit("A").hp = 5
    _activate(ai, "L")
    ai.queue_rolls([15, 2, 1])
    _check(ai.enemy_step() and ai.unit("A").hp == 4, "Light Melee attacks the weaker adjacent hero.")
    # AI moves into range when it can't attack yet, then attacks.
    var approach = _fresh()
    var brute = approach.unit("S")
    brute.cell = Vector2i(5, 3)
    _activate(approach, "S")
    var moved: bool = approach.enemy_step()
    var nearest := 99
    for hero in approach.living("hero"):
        nearest = mini(nearest, Rules.distance(brute.cell, hero.cell))
    _check(moved and brute.ap == 2 and nearest == 1, "Sword Brute spends 1 AP to reach a hero.")
    approach.queue_rolls([2, 19])
    _check(approach.enemy_step() and brute.ap == 0, "Then attacks for 2 AP.")
    _check(not approach.enemy_step(), "With 0 AP the enemy is done.")
    # Passive heroes lose: the AI finishes a battle on its own.
    var passive = _fresh(11)
    var steps := 0
    while passive.outcome.is_empty() and steps < 2000:
        steps += 1
        if passive.active.team == "enemy" and passive.enemy_step() and passive.active.ap > 0:
            continue
        passive.end_turn()
    _check(passive.outcome == "Defeat", "Enemy AI defeats a passive party.")


func _check_seed_replay() -> void:
    var first = _fresh(424242)
    var second = _fresh(424242)
    for battle in [first, second]:
        var steps := 0
        while battle.outcome.is_empty() and steps < 2000:
            steps += 1
            if battle.active.team == "enemy" and battle.enemy_step() and battle.active.ap > 0:
                continue
            battle.end_turn()
    _check(first.log == second.log and not first.log.is_empty(), "The same seed and actions replay the same battle.")
    var other = _fresh(424243)
    _check(other.seed == 424243 and other.log[0].begins_with("Seed 424243"), "start() records the seed in the log.")
