extends SceneTree

# Writer's HUD layout regression for Stage 3: measures the real text against the laid-out
# label widths at 1280x800, including threatened previews with one, three and four threats.
const SCENE_PATH := "res://scenes/encounter.tscn"
const Rules = preload("res://scripts/encounter_rules.gd")
var _failures := 0


func _initialize() -> void:
    call_deferred("_verify")


func _check(condition: bool, message: String) -> void:
    if not condition:
        _failures += 1
        printerr("ENCOUNTER HUD TEST FAILED: ", message)


func _text_width(control: Control, text: String) -> float:
    var font := control.get_theme_font("font")
    var size := control.get_theme_font_size("font_size")
    return font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x


func _seed_for(first: String) -> int:
    var probe = Rules.new(Vector2i(10, 8))
    for n in range(1, 4000):
        probe.start(n)
        if probe.active.id == first:
            return n
    return 1


func _settle() -> void:
    await process_frame
    await process_frame


# Every visible single-line label and button shows its whole text, inside the viewport.
func _check_layout(scene, context: String) -> void:
    var viewport := root.get_visible_rect()
    for control in scene.get_node("HUD").find_children("*", "Control", true, false):
        if not control.is_visible_in_tree():
            continue
        if control is Label or control is Button:
            var rect: Rect2 = control.get_global_rect()
            _check(viewport.encloses(rect), "%s: %s is inside the viewport." % [context, control.name])
        if control is Label and control.autowrap_mode == TextServer.AUTOWRAP_OFF:
            for line in control.text.split("\n"):
                var needed := _text_width(control, line)
                _check(needed <= control.size.x + 0.5, "%s: %s needs %.0f px but has %.0f px: %s" % [
                    context, control.name, needed, control.size.x, line])
        if control is Button:
            var box: StyleBox = control.get_theme_stylebox("normal")
            var needed := _text_width(control, control.text) + box.get_margin(SIDE_LEFT) + box.get_margin(SIDE_RIGHT)
            _check(needed <= control.size.x + 0.5, "%s: button %s is clipped." % [context, control.text])
    # The bottom panel stays below the board's front corner.
    var camera: Camera3D = scene.get_camera()
    var front := camera.unproject_position(Vector3(5, 0, 4))
    var bottom: Control = scene.get_node("HUD/BottomPanel")
    _check(bottom.get_global_rect().position.y > front.y, "%s: bottom panel clears the board." % context)


func _preview_fits(scene, cell: Vector2i, context: String) -> String:
    scene._hover_cell = Vector2i(-1, -1)
    scene._set_hover(cell)
    await _settle()
    var label: Label = scene._preview_label
    var needed := _text_width(label, label.text)
    _check(not label.text.is_empty(), "%s: preview is shown." % context)
    _check(needed <= label.size.x, "%s: preview needs %.0f px but has %.0f px." % [context, needed, label.size.x])
    return label.text


func _verify() -> void:
    var scene = load(SCENE_PATH).instantiate()
    scene.auto_enemy = false
    root.add_child(scene)
    await _settle()
    _check(root.get_visible_rect().size == Vector2(1280, 800), "Reference viewport is 1280x800.")

    # Each hero's turn, with each of its actions selected and each enemy hovered.
    for id in ["K", "A", "W", "C"]:
        scene.new_battle(_seed_for(id))
        await _settle()
        var battle = scene.battle
        _check(battle.active.id == id, "Fixture reaches %s's turn." % id)
        for action_id in battle.actions_for(battle.active):
            scene.select_action(action_id)
            for enemy in battle.living("enemy"):
                await _preview_fits(scene, enemy.cell, "%s %s → %s" % [id, action_id, enemy.id])
            _check_layout(scene, "%s with %s" % [id, action_id])
    # A Slowed Wizard has the longest controls row.
    scene.new_battle(_seed_for("W"))
    scene.battle.active.slow_until_turn_count = scene.battle.active.turn_count + 1
    scene.select_action("force_push")
    await _settle()
    _check_layout(scene, "Slowed Wizard")

    # Threatened longbow previews: one, three and four adjacent enemies.
    scene.new_battle(_seed_for("A"))
    var battle = scene.battle
    var archer = battle.unit("A")
    archer.cell = Vector2i(5, 4)
    battle.unit("S").cell = Vector2i(4, 4)
    scene.select_action("basic")
    var one: String = await _preview_fits(scene, battle.unit("B").cell, "One threat")
    for part in ["52.8% to hit", "Disadvantage", "Sword Brute", "2 AP", "2d6"]:
        _check(part in one, "One-threat preview shows '%s': %s" % [part, one])
    battle.unit("L").cell = Vector2i(5, 3)
    battle.unit("M").cell = Vector2i(6, 5)
    scene._refresh()
    var three: String = await _preview_fits(scene, battle.unit("B").cell, "Three threats")
    for part in ["Sword Brute", "Light Melee", "Enemy Mage", "Disadvantage", "2d6", "2 AP", "%"]:
        _check(part in three, "Three-threat preview shows '%s': %s" % [part, three])
    battle.unit("B").cell = Vector2i(6, 4)
    scene._refresh()
    var four: String = await _preview_fits(scene, battle.unit("B").cell, "Four threats")
    _check("Bowman" in four and "Enemy Mage" in four and "2d6" in four, "Four-threat preview stays whole: " + four)
    _check_layout(scene, "Four threats")

    # Turn order lists every living unit with HP, and follows damage and defeat.
    scene.new_battle(_seed_for("K"))
    battle = scene.battle
    var order_text: String = scene._round_label.text
    for who in battle.units:
        _check("%s %d/%d" % [who.name, who.hp, who.max_hp] in order_text, "Turn order shows %s's HP." % who.name)
    battle.unit("B").hp = 7
    battle.unit("M").hp = 0
    scene._refresh()
    order_text = scene._round_label.text
    _check("Bowman 7/16" in order_text and not "Enemy Mage" in order_text, "Turn order follows damage and defeat.")
    _check(("[Knight 24/24]" in order_text), "The active unit is marked in the turn order.")

    # New battle never repeats the current seed.
    var repeats := 0
    for attempt in range(200):
        var previous: int = scene.battle.seed
        scene.new_battle()
        if scene.battle.seed == previous:
            repeats += 1
    _check(repeats == 0, "New battle changed the seed every time (%d repeats)." % repeats)

    # Outcome screen fits too.
    for enemy in scene.battle.living("enemy"):
        enemy.hp = 0
    scene.battle._check_outcome()
    scene._refresh()
    await _settle()
    _check(scene._round_label.text.begins_with("VICTORY"), "Victory is announced in the header.")
    _check_layout(scene, "Victory")

    if _failures == 0:
        print("ENCOUNTER HUD TEST PASSED: previews with 1/3/4 threats, every hero's controls, turn-order HP, new seeds, outcome.")
    quit(0 if _failures == 0 else 1)
