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

    var scene_path := ProjectSettings.get_setting("application/run/main_scene") as String
    var scene := load(scene_path) as PackedScene
    var duel := scene.instantiate() as Duel
    _check(duel != null, "Project launches the duel scene.")
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
    _click(duel, battle.enemy.cell)
    _check(battle.ap == 3, "Out-of-range attack leaves AP intact.")
    _click(duel, Vector2i(6, 4))
    _check(battle.hero.cell == Vector2i(6, 4) and battle.ap == 2, "Three tiles cost one AP.")
    _check(battle.movement_cost(Vector2i(3, 4)) == 2, "Later movement grants two tiles per AP.")
    _click(duel, battle.enemy.cell)
    _check(battle.ap == 1, "Adjacent attack through viewport costs one AP.")

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
    var event := InputEventMouseButton.new()
    event.position = duel.get_camera().unproject_position(duel.cell_to_world(cell))
    event.button_index = MOUSE_BUTTON_LEFT
    event.pressed = true
    root.push_input(event, true)
