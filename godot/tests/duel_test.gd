extends SceneTree

const Rules = preload("res://scripts/duel_rules.gd")
const Duel = preload("res://scripts/duel.gd")
var _failures := 0


func _initialize() -> void:
    call_deferred("_verify")


func _check(condition: bool, message: String) -> void:
    if not condition:
        _failures += 1
        printerr("DUEL TEST FAILED: ", message)


func _verify() -> void:
    _check(not Rules.attack_hits(20, 20, 6, 4), "Natural 20 defense wins.")
    _check(not Rules.attack_hits(1, 2, 6, 4), "Natural 1 attack misses.")
    _check(not Rules.attack_hits(12, 14, 6, 4), "Tied totals favor the defender.")
    _check(Rules.attack_hits(20, 19, 0, 99), "Natural 20 attack hits normal defense.")

    # Stage 3 made the 4-vs-4 encounter the main scene; the duel scene is still kept and tested.
    var scene := load("res://scenes/duel.tscn") as PackedScene
    var duel := scene.instantiate() as Duel
    _check(duel != null, "The duel scene loads.")
    if duel == null:
        quit(1)
        return
    root.add_child(duel)
    await process_frame
    await process_frame
    var battle := duel.battle
    # Fix initiative for the input checks and avoid animation timing in headless tests.
    battle.active = battle.hero
    duel._enemy_timer.stop()
    duel._refresh()
    var hud_rect := duel._end_button.get_global_rect()
    _check(hud_rect.has_area() and root.get_visible_rect().encloses(hud_rect),
        "End turn control fits the viewport.")
    var brute_chest := duel.cell_to_world(battle.enemy.cell) + Vector3.UP * 0.9
    var start := battle.hero.cell
    _click_world(duel, brute_chest)
    _check(battle.ap == 3 and battle.hero.cell == start,
        "Clicking the out-of-range Brute's chest cannot move the Knight.")
    _click(duel, Vector2i(6, 4))
    _check(battle.hero.cell == Vector2i(6, 4) and battle.ap == 2, "Three tiles cost one AP.")
    _check(battle.movement_cost(Vector2i(3, 4)) == 2, "Later movement grants two tiles per AP.")
    _click_world(duel, duel.cell_to_world(battle.hero.cell) + Vector3.UP * 0.9)
    _check(battle.ap == 2 and battle.hero.cell == Vector2i(6, 4),
        "Clicking the Knight's body cannot move the Knight.")
    _click_world(duel, brute_chest)
    _check(battle.ap == 1 and battle.hero.cell == Vector2i(6, 4)
        and battle.log.back().begins_with("Longsword:"),
        "Clicking the adjacent Brute's chest attacks without moving.")

    battle.active = battle.enemy
    battle._rng.seed = 112
    battle.ap = 3
    _check(battle.enemy_action() and battle.ap == 1, "Enemy takes a two-AP attack.")
    _check(not battle.enemy_action(), "Enemy cannot overspend AP.")

    for winner in [battle.hero, battle.enemy]:
        var expected := "Victory" if winner == battle.hero else "Defeat"
        battle.outcome = ""
        battle.active = winner
        battle.opponent().hp = 1
        battle._rng.seed = 112
        for attempt in range(20):
            battle.ap = 3
            battle.attack()
            if not battle.outcome.is_empty():
                break
        _check(battle.outcome == expected, expected + " ends combat.")
        _check(not battle.attack(), "Attacks stop after the outcome.")
    duel.restart()
    _check(battle.outcome.is_empty() and battle.hero.hp == 24 and battle.enemy.hp == 22
        and battle.round_number == 1 and battle.ap == 3, "Restart resets the match.")

    if _failures == 0:
        print("DUEL TEST PASSED: launch, input, AP, opposed rolls, AI attack, outcomes, restart.")
    quit(0 if _failures == 0 else 1)


func _click(duel: Duel, cell: Vector2i) -> void:
    _click_world(duel, duel.cell_to_world(cell))


func _click_world(duel: Duel, position: Vector3) -> void:
    var event := InputEventMouseButton.new()
    event.position = duel.get_camera().unproject_position(position)
    event.button_index = MOUSE_BUTTON_LEFT
    event.pressed = true
    root.push_input(event, true)
