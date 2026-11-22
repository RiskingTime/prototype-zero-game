extends SceneTree

# Battlefield sprite acceptance (encounter.tscn → encounter_units.gd). Checks the art files
# and their import settings; that every unit keeps its combat ID and one cell and wears a
# camera-facing sprite anchored at the feet, with the capsule kept only as invisible picking
# geometry; facing at spawn, after moves and toward attack, heal and Force Push targets,
# including enemy turns; ground clicks, near-unit and overlapping-unit clicks; death; restart
# and new battle; and the depth-tested selection diamond. Rendering itself is checked in
# windowed screenshots, not here.

const SCENE_PATH := "res://scenes/encounter.tscn"
const UNITS_SCRIPT := "res://scripts/encounter_units.gd"
const Rules = preload("res://scripts/encounter_rules.gd")
const Units = preload("res://scripts/encounter_units.gd")
const BOARD := Vector2i(10, 8)
const IDS := ["K", "A", "W", "C", "S", "L", "B", "M"]
const SLUGS := {
    "K": "knight", "A": "field_archer", "W": "travelling_wizard", "C": "field_cleric",
    "S": "ogre_gate_porter", "L": "rampart_sentry", "B": "mossgate_bowman", "M": "ash_examiner",
}
const FACINGS := ["south", "south-east", "east", "north-east", "north", "north-west", "west", "south-west"]
const SPAWNS := {
    "K": Vector2i(2, 3), "A": Vector2i(0, 2), "W": Vector2i(0, 6), "C": Vector2i(1, 5),
    "S": Vector2i(7, 4), "L": Vector2i(8, 2), "B": Vector2i(9, 5), "M": Vector2i(9, 1),
}
const PX_PER_UNIT := 90.50966799187809
const PX_PER_VERTICAL_UNIT := 0.8660254037844386 * 90.50966799187809

var _failures := 0
var _checks := 0
var scene


func _initialize() -> void:
    call_deferred("_run")


func check(ok: bool, message: String) -> void:
    _checks += 1
    if not ok:
        _failures += 1
        printerr("ENCOUNTER UNITS TEST FAILED: ", message)


func _run() -> void:
    facing_math()
    art_files()
    scene = (load(SCENE_PATH) as PackedScene).instantiate()
    scene.auto_enemy = false
    root.add_child(scene)
    current_scene = scene
    await process_frame
    await process_frame
    check(scene.get_script().resource_path == UNITS_SCRIPT, "encounter.tscn uses encounter_units.gd")
    dressing()
    selection_diamond()
    spawn_facing()
    move_facing()
    attack_facing()
    heal_facing()
    force_push_facing()
    enemy_turn_facing()
    ground_clicks()
    near_unit_clicks()
    death_and_restart()
    if _failures == 0:
        print("ENCOUNTER UNITS TEST PASSED: %d checks — 64 sprite files and import settings, all eight units dressed with feet on their cells, facing at spawn, after moves and toward attack, heal and Force Push targets including enemy turns, ground, near-unit and overlap clicks, death, restart and the depth-tested diamond." % _checks)
    quit(0 if _failures == 0 else 1)


# --- Helpers ---------------------------------------------------------------------------

func seed_for(first: String) -> int:
    var probe = Rules.new(BOARD)
    for n in range(1, 4000):
        probe.start(n)
        if probe.active.id == first:
            return n
    check(false, "No seed starts with " + first)
    return 1


func battle_for(first: String):
    scene.new_battle(seed_for(first))
    return scene.battle


func queue(values: Array) -> void:
    var dice: Array[int] = []
    dice.assign(values)
    scene.battle.queue_rolls(dice)


# Moves units directly (a test fixture), then lets the scene catch up.
func place(cells: Dictionary) -> void:
    for id in cells:
        scene.battle.unit(id).cell = cells[id]
    scene._refresh()


func screen_of(world: Vector3) -> Vector2:
    return scene.get_camera().unproject_position(world)


func feet_screen(id: String) -> Vector2:
    return screen_of(scene.cell_to_world(scene.battle.unit(id).cell))


func figure_px(id: String) -> float:
    var art: Dictionary = Units.UNIT_ART[id]
    return (art["anchor_y"] - art["head_y"]) * art["scale"]


func expected_facing(from: Vector2i, to: Vector2i) -> String:
    return Units.facing_for(Vector2(to - from))


func nearest_opponent(who):
    var best = null
    var best_distance := 9999
    for other in scene.battle.units:
        if other.team != who.team and other.alive():
            var d: int = Rules.distance(who.cell, other.cell)
            if d < best_distance:
                best_distance = d
                best = other
    return best


func facings() -> Dictionary:
    var result := {}
    for id in IDS:
        result[id] = scene.unit_facing(id)
    return result


func check_texture(id: String, context: String) -> void:
    var expected := Units.art_path(SLUGS[id], scene.unit_facing(id))
    var texture: Texture2D = scene.unit_sprite(id).texture
    check(texture != null and texture.resource_path == expected,
        "%s: %s shows %s (got %s)" % [context, id, expected, texture.resource_path if texture else "none"])


# --- Static checks ---------------------------------------------------------------------

func facing_math() -> void:
    # Grid x runs down-right on screen and grid z down-left.
    var cases := {
        Vector2(1, 1): "south", Vector2(1, 0): "south-east", Vector2(1, -1): "east",
        Vector2(0, -1): "north-east", Vector2(-1, -1): "north", Vector2(-1, 0): "north-west",
        Vector2(-1, 1): "west", Vector2(0, 1): "south-west", Vector2(3, 3): "south",
        Vector2(0, 0): "",
    }
    for delta in cases:
        check(Units.facing_for(delta) == cases[delta],
            "facing_for(%s) is %s, got %s" % [delta, cases[delta], Units.facing_for(delta)])


func art_files() -> void:
    check(Units.UNIT_ART.size() == 8, "Art for all eight units")
    for id in IDS:
        check(Units.UNIT_ART.has(id) and Units.UNIT_ART[id]["slug"] == SLUGS[id], "Art slug for " + id)
        for facing in FACINGS:
            var path := Units.art_path(SLUGS[id], facing)
            var texture = load(path)
            check(texture is Texture2D and texture.get_width() == 128 and texture.get_height() == 128,
                "128 x 128 texture: " + path)
            var config := ConfigFile.new()
            check(config.load(path + ".import") == OK, "Import file: " + path)
            check(int(config.get_value("params", "compress/mode", -1)) == 0, "Lossless import: " + path)
            check(config.get_value("params", "mipmaps/generate", true) == false, "No mipmaps: " + path)
            check(int(config.get_value("params", "detect_3d/compress_to", -1)) == 0,
                "No VRAM compression when used in 3D: " + path)
    check(Units.UNIT_ART["S"]["scale"] == 1.25, "Ogre drawn at 1.25")
    for id in IDS:
        if id != "S":
            check(Units.UNIT_ART[id]["scale"] == 1.0, id + " drawn 1:1")


# --- Scene checks ----------------------------------------------------------------------

func dressing() -> void:
    scene.new_battle(seed_for("K"))
    var r = scene.battle
    for id in IDS:
        var who = r.unit(id)
        check(who != null and who.cell == SPAWNS[id], "Combat ID and spawn kept: " + id)
        var node: MeshInstance3D = scene.unit_node(id)
        var sprite: Sprite3D = scene.unit_sprite(id)
        check(sprite != null and sprite.get_parent() == node, "Sprite under the unit node: " + id)
        if sprite == null:
            continue
        check(node.layers == 0, "Capsule invisible (picking only): " + id)
        check(node.mesh is CapsuleMesh, "Capsule kept for picking: " + id)
        check(sprite.billboard == BaseMaterial3D.BILLBOARD_ENABLED, "Camera-facing sprite: " + id)
        check(sprite.texture_filter == BaseMaterial3D.TEXTURE_FILTER_NEAREST, "Nearest filter: " + id)
        check(sprite.alpha_cut == SpriteBase3D.ALPHA_CUT_DISCARD, "Alpha-cut sprite writes depth: " + id)
        check(not sprite.shaded, "Unshaded sprite: " + id)
        var art: Dictionary = Units.UNIT_ART[id]
        check(is_equal_approx(sprite.pixel_size, art["scale"] / PX_PER_UNIT), "Pixel size: " + id)
        check(sprite.offset == Vector2(0, art["anchor_y"] - 64), "Feet anchor offset: " + id)
        # The sprite origin (the feet) sits on the cell centre, on the ground.
        var feet: Vector3 = sprite.global_position
        var centre: Vector3 = scene.cell_to_world(who.cell)
        check(feet.distance_to(centre) < 0.001, "Feet on the cell centre: %s %s vs %s" % [id, feet, centre])
        var capsule := node.mesh as CapsuleMesh
        check(absf(capsule.height * PX_PER_VERTICAL_UNIT - figure_px(id)) < 1.0, "Capsule spans the figure: " + id)
        check(absf(node.global_position.y - capsule.height * 0.5) < 0.001, "Capsule stands on the ground: " + id)
        var hp: Label3D = scene._hp_labels[id]
        check(hp.text.begins_with(id + " %d/%d" % [who.hp, who.max_hp]), "HP label reads '%s': %s" % [id, hp.text])
        var label_px: float = hp.global_position.y * PX_PER_VERTICAL_UNIT
        check(label_px > figure_px(id) and label_px < figure_px(id) + 20.0, "HP label just above the head: " + id)
        for child in node.get_children():
            if child is Label3D and child != hp:
                check(not child.visible, "Placeholder letter hidden: " + id)
        check_texture(id, "Dressing")


func selection_diamond() -> void:
    var bars: Array = scene._selection.get_children()
    check(bars.size() == 4, "Selection diamond has four edges")
    for bar in bars:
        var material := (bar as MeshInstance3D).material_override as StandardMaterial3D
        check(material != null and not material.no_depth_test, "Diamond edge is depth-tested: " + bar.name)
    check(scene._selection.visible and scene._selection.position.distance_to(
        scene.cell_to_world(scene.battle.active.cell)) < 0.02, "Diamond on the active unit")


func spawn_facing() -> void:
    for first in ["K", "S"]:
        scene.new_battle(seed_for(first))
        for id in IDS:
            var who = scene.battle.unit(id)
            var foe = nearest_opponent(who)
            var expected := expected_facing(who.cell, foe.cell)
            check(scene.unit_facing(id) == expected,
                "Spawn: %s faces nearest opponent %s (%s), got %s" % [id, foe.id, expected, scene.unit_facing(id)])
            var east_half := ["east", "south-east", "north-east"].has(scene.unit_facing(id))
            check(east_half == (who.team == "hero"), "Spawn: %s faces across the board" % id)
            check_texture(id, "Spawn")


func move_facing() -> void:
    var r = battle_for("K")
    var k = r.unit("K")
    var start: Vector2i = k.cell
    var target := start + Vector2i(-1, -1)
    check(r.reachable(k).has(target), "Fixture: Knight can step north")
    check(scene.play_cell(target) and k.cell == target, "Knight moves north")
    check(scene.unit_facing("K") == "north", "After a move the Knight faces north, got " + scene.unit_facing("K"))
    check_texture("K", "Move")
    if r.active == k:
        var next: Vector2i = k.cell + Vector2i(1, 0)
        if r.reachable(k).has(next) and r.unit_at(next) == null:
            scene.play_cell(next)
            check(k.cell == next and scene.unit_facing("K") == "south-east",
                "Second move turns the Knight south-east, got " + scene.unit_facing("K"))
    # Units that did not move keep their spawn facing.
    var a = r.unit("A")
    check(scene.unit_facing("A") == expected_facing(a.cell, nearest_opponent(a).cell), "Bystander keeps its facing")


func attack_facing() -> void:
    var r = battle_for("K")
    var k = r.unit("K")
    place({"L": k.cell + Vector2i(1, -1)})
    var before: String = scene.unit_facing("K")
    check(before != "east", "Fixture: Knight not already facing east")
    scene.select_action("basic")
    queue([1, 20])
    var cell: Vector2i = k.cell
    check(scene.play_cell(r.unit("L").cell), "Knight attacks the Sentry")
    check(k.cell == cell, "Attack does not move the Knight")
    check(scene.unit_facing("K") == "east", "Attacker faces its target (east), got " + scene.unit_facing("K"))
    check_texture("K", "Attack")


func heal_facing() -> void:
    var r = battle_for("C")
    var c = r.unit("C")
    var k = r.unit("K")
    place({"K": c.cell + Vector2i(1, 1)})
    k.hp = 10
    var before: String = scene.unit_facing("C")
    check(before != "south", "Fixture: Cleric not already facing south")
    check(scene.select_action("healing_light"), "Select Healing Light")
    queue([3])
    check(scene.play_cell(k.cell) and k.hp > 10, "Cleric heals the Knight")
    check(c.cell == SPAWNS["C"], "Healing does not move the Cleric")
    check(scene.unit_facing("C") == "south", "Healer faces the ally (south), got " + scene.unit_facing("C"))
    check_texture("C", "Heal")
    # Healing yourself leaves your facing alone.
    r = battle_for("C")
    c = r.unit("C")
    c.hp = 10
    var own_facing: String = scene.unit_facing("C")
    scene.select_action("healing_light")
    queue([3])
    check(scene.play_cell(c.cell) and c.hp > 10, "Cleric heals herself")
    check(scene.unit_facing("C") == own_facing, "Self-heal keeps the facing")


func force_push_facing() -> void:
    var r = battle_for("W")
    var w = r.unit("W")
    var s = r.unit("S")
    place({"S": w.cell + Vector2i(2, 0)})
    var placed: Vector2i = s.cell
    check(scene.select_action("force_push"), "Select Force Push")
    queue([20, 1])
    check(scene.play_cell(s.cell), "Wizard casts Force Push")
    check(s.cell != placed and s.cell.y == placed.y and s.cell.x > placed.x, "Ogre pushed away: %s" % s.cell)
    check(scene.unit_facing("S") == expected_facing(s.cell, w.cell),
        "Pushed unit faces the pusher (%s), got %s" % [expected_facing(s.cell, w.cell), scene.unit_facing("S")])
    check(scene.unit_facing("W") == "south-east", "Pusher faces the target, got " + scene.unit_facing("W"))
    check_texture("S", "Force Push")


func enemy_turn_facing() -> void:
    # An enemy attack on the enemy's own turn, through the scene's enemy step.
    var r = battle_for("S")
    var s = r.unit("S")
    place({"K": s.cell + Vector2i(0, 1)})
    check(scene.unit_facing("S") != "south-west", "Fixture: Ogre not already facing south-west")
    queue([1, 20])
    var log_size: int = r.log.size()
    enemy_step()
    check(r.log.size() > log_size and r.unit("S").cell == SPAWNS["S"], "Ogre attacks in place on its turn")
    check(scene.unit_facing("S") == "south-west", "Enemy attacker faces its target, got " + scene.unit_facing("S"))
    check_texture("S", "Enemy attack")
    # An enemy move on its turn.
    r = battle_for("L")
    var l = r.unit("L")
    var from: Vector2i = l.cell
    enemy_step()
    check(l.cell != from, "Fixture: Sentry moves on its turn")
    check(scene.unit_facing("L") == expected_facing(from, l.cell),
        "Enemy faces its direction of travel (%s), got %s" % [expected_facing(from, l.cell), scene.unit_facing("L")])
    check_texture("L", "Enemy move")


func enemy_step() -> void:
    scene.auto_enemy = true
    scene._enemy_step()
    scene.auto_enemy = false
    scene._enemy_timer.stop()


# The unit standing in front of a cell's centre in the same screen column, if its figure
# reaches that high: one cell in front for everyone, two for the 1.25x Ogre. Nearest first.
func covering_unit(cell: Vector2i):
    for k in [2, 1]:
        var front = scene.battle.unit_at(cell + Vector2i(k, k))
        if front != null and (k == 1 or front.id == "S"):
            return front
    return null


# Clicking a ground cell's centre selects that cell, unless a unit stands in front of it in
# the same screen column and covers it: the cell directly behind any unit, and two behind
# the 1.25x Ogre. The nearest covering unit wins, as for any overlap.
func ground_clicks() -> void:
    var layouts := [
        SPAWNS,
        {"K": Vector2i(4, 4), "A": Vector2i(5, 3), "W": Vector2i(3, 5), "C": Vector2i(5, 5),
         "S": Vector2i(6, 6), "L": Vector2i(2, 2), "B": Vector2i(7, 3), "M": Vector2i(3, 2)},
    ]
    for layout in layouts:
        scene.new_battle(seed_for("K"))
        place(layout)
        var r = scene.battle
        var mismatches := 0
        for x in range(BOARD.x):
            for z in range(BOARD.y):
                var cell := Vector2i(x, z)
                if r.unit_at(cell) != null:
                    continue
                var expected := cell
                var front = covering_unit(cell)
                if front != null:
                    expected = front.cell
                var got: Vector2i = scene._cell_under(screen_of(scene.cell_to_world(cell)))
                if got != expected:
                    mismatches += 1
                    check(false, "Ground click at %s selects %s, expected %s" % [cell, got, expected])
        check(mismatches == 0, "Ground clicks in layout %s" % str(layout.values()))


func near_unit_clicks() -> void:
    scene.new_battle(seed_for("K"))
    # A tight cluster: side-by-side rows, diagonal neighbours and a one-column stack.
    place({"K": Vector2i(4, 4), "A": Vector2i(5, 3), "W": Vector2i(5, 4), "C": Vector2i(4, 5),
           "L": Vector2i(3, 3), "S": Vector2i(6, 6), "B": Vector2i(8, 1), "M": Vector2i(1, 7)})
    var r = scene.battle
    for id in IDS:
        var who = r.unit(id)
        var feet := feet_screen(id)
        var h := figure_px(id)
        var art: Dictionary = Units.UNIT_ART[id]
        # Feet and torso select the unit inside the cluster, unless a unit in front covers
        # them (then the front unit wins, checked below).
        if covering_unit(who.cell) == null:
            for f in [0.06, 0.45]:
                var got: Vector2i = scene._cell_under(feet - Vector2(0, h * f))
                check(got == who.cell, "%s at %.2f of its height selects %s, got %s" % [id, f, who.cell, got])
        else:
            var front = covering_unit(who.cell)
            check(scene._cell_under(feet - Vector2(0, h * 0.06)) == front.cell,
                "%s's feet are covered by %s in front" % [id, front.id])
        # Just beside the torso is not the unit.
        var reach: float = clampf(art["half_width"] * art["scale"], 20.0, 40.7) + 6.0
        for side in [-1, 1]:
            var got2: Vector2i = scene._cell_under(feet + Vector2(side * reach, -h * 0.45))
            check(got2 != who.cell, "%s: %.0f px beside the torso is not the unit" % [id, side * reach])
    # In the K/L stack (L behind K), K's head over L's legs picks K; L's exposed head picks L.
    var k_feet := feet_screen("K")
    check(scene._cell_under(k_feet - Vector2(0, figure_px("K") * 0.85)) == r.unit("K").cell, "Front head wins")
    var l_feet := feet_screen("L")
    check(scene._cell_under(l_feet - Vector2(0, figure_px("L") * 0.92)) == r.unit("L").cell, "Back head still picks")
    # Clicking an adjacent enemy's chest with the Knight's longsword attacks without moving.
    r = battle_for("K")
    place({"L": r.unit("K").cell + Vector2i(1, -1)})
    scene.select_action("basic")
    queue([1, 20])
    var ap: int = r.unit("K").ap
    scene.play_cell(scene._cell_under(feet_screen("L") - Vector2(0, figure_px("L") * 0.5)))
    check(r.unit("K").ap == ap - 1 and r.unit("K").cell == SPAWNS["K"], "Chest click on an adjacent enemy attacks")


func death_and_restart() -> void:
    var r = battle_for("K")
    var initial := facings()
    var k = r.unit("K")
    var l = r.unit("L")
    place({"L": k.cell + Vector2i(1, -1)})
    l.hp = 1
    scene.select_action("basic")
    queue([20, 1, 6])
    var dead_cell: Vector2i = l.cell
    var torso := feet_screen("L") - Vector2(0, figure_px("L") * 0.45)
    check(scene.play_cell(dead_cell) and not l.alive(), "Knight defeats the Sentry")
    var node: Node3D = scene.unit_node("L")
    check(not node.visible and not scene.unit_sprite("L").is_visible_in_tree()
        and not scene._hp_labels["L"].is_visible_in_tree(), "Defeated unit, sprite and label hidden")
    check(scene._cell_under(torso) == scene.screen_to_cell(torso), "Defeated unit no longer takes clicks")
    check(r.unit_at(dead_cell) == null, "Defeated unit frees its cell")
    for id in IDS:
        if id != "L":
            check(scene.unit_node(id).visible, "Living unit still visible: " + id)
    scene.restart_same_seed()
    r = scene.battle
    check(r.unit("L").alive() and scene.unit_node("L").visible and scene.unit_sprite("L").is_visible_in_tree(),
        "Restart brings the Sentry back")
    for id in IDS:
        check(r.unit(id).cell == SPAWNS[id], "Restart redeploys " + id)
        check_texture(id, "Restart")
    check(facings() == initial, "Restart restores spawn facings: %s vs %s" % [facings(), initial])
    scene.new_battle()
    for id in IDS:
        var who = scene.battle.unit(id)
        check(scene.unit_facing(id) == expected_facing(who.cell, nearest_opponent(who).cell),
            "New battle resets facing: " + id)
