extends SceneTree

# Stage 3 reviewer contract. Visual appearance, the exported BUILD.txt path,
# frozen Git paths and the three sibling test scripts are verified separately.
const RULES_PATH := "res://scripts/encounter_rules.gd"
const SCENE_PATH := "res://scenes/encounter.tscn"
const BOARD := Vector2i(10, 8)
const IDS := ["K", "A", "W", "C", "S", "L", "B", "M"]
# id: name, start cell, HP, initiative bonus, attack bonus, AC, MR
const ROSTER := {
    "K": ["Knight", Vector2i(2,3), 24, 3, 6, 6, -4],
    "A": ["Archer", Vector2i(0,2), 18, 6, 6, 2, -2],
    "W": ["Wizard", Vector2i(0,6), 16, 7, 7, -2, 5],
    "C": ["Cleric", Vector2i(1,5), 22, 9, 1, 3, 1],
    "S": ["Sword Brute", Vector2i(7,4), 22, 4, 5, 4, -3],
    "L": ["Light Melee", Vector2i(8,2), 16, 6, 4, 1, -2],
    "B": ["Bowman", Vector2i(9,5), 16, 5, 4, 1, 0],
    "M": ["Enemy Mage", Vector2i(9,1), 15, 8, 5, -2, 4],
}
# id, action, display name, AP, Chebyshev range, damage dice, damage type
const ATTACKS := [
    ["K","basic","Longsword",1,1,Vector2i(1,6),"physical"],
    ["A","basic","Longbow",2,9,Vector2i(2,6),"physical"],
    ["C","basic","Blessed Mace",2,1,Vector2i(1,8),"physical"],
    ["S","basic","Greatsword",2,1,Vector2i(2,8),"physical"],
    ["L","basic","Shortsword",1,1,Vector2i(1,6),"physical"],
    ["B","basic","War Bow",2,9,Vector2i(2,6),"physical"],
    ["M","basic","Ash Wand",2,7,Vector2i(3,6),"magic"],
    ["W","arcane_dart","Arcane Dart",1,6,Vector2i(1,6),"magic"],
    ["W","arcane_bolt","Arcane Bolt",2,7,Vector2i(2,6),"magic"],
]
var rules_script
var failures := 0
var completed := 0

func _initialize() -> void:
    call_deferred("_run")

func check(ok: bool, reason: String) -> void:
    if not ok:
        failures += 1
        printerr("ENCOUNTER ACCEPTANCE FAILED: ", reason)

func fresh(first := ""):
    var r = rules_script.new(BOARD)
    r.start(32017)
    if first != "":
        for i in range(8):
            if r.active.id == first:
                break
            r.end_turn()
        check(r.active.id == first, "Fixture could not reach turn for " + first)
    return r

func queue(r, values: Array) -> void:
    var dice: Array[int] = []
    dice.assign(values)
    r.queue_rolls(dice)

func ids(order) -> Array:
    var result := []
    for u in order:
        result.append(u.id)
    return result

func _run() -> void:
    if not ResourceLoader.exists(RULES_PATH) or not ResourceLoader.exists(SCENE_PATH):
        printerr("ENCOUNTER ACCEPTANCE FAILED: Stage 3 encounter rules or scene missing.")
        quit(1)
        return
    rules_script = load(RULES_PATH)
    check(ProjectSettings.get_setting("application/run/main_scene") == SCENE_PATH, "Launch encounter.tscn")
    roster_and_turns()
    movement()
    combat()
    spells()
    healing()
    ai_and_outcomes()
    await scene_checks()
    check(completed == 7, "All seven test groups reached their final assertion")
    if failures == 0:
        print("ENCOUNTER ACCEPTANCE PASSED")
    quit(0 if failures == 0 else 1)

func roster_and_turns() -> void:
    var r = fresh()
    check(r.units.size() == 8 and r.order.size() == 8, "Eight combatants at launch")
    for id in IDS:
        var u = r.unit(id)
        var row = ROSTER[id]
        check(u.name == row[0] and u.cell == row[1] and u.hp == row[2] and u.max_hp == row[2],
            "Deployment and HP: " + id)
        check(u.team == ("hero" if id in ["K","A","W","C"] else "enemy"), "Team: " + id)
        check(r.initiative_bonus(u) == row[3] and r.physical_defense(u) == row[5]
            and r.magic_defense(u) == row[6], "Initiative, AC, MR: " + id)
        var expected := ["basic"]
        if id == "W":
            expected = ["arcane_dart","arcane_bolt","force_push","slow"]
        elif id == "C":
            expected.append("healing_light")
        var actual: Array = r.actions_for(u).duplicate()
        actual.sort()
        expected.sort()
        check(actual == expected, "Action list: " + id)
    for row in ATTACKS:
        var u = r.unit(row[0])
        var a = r.action(u, row[1])
        check(a.name == row[2] and a.ap == row[3] and a.range == row[4]
            and a.dice == row[5] and a.type == row[6]
            and r.attack_bonus(u,row[1]) == ROSTER[row[0]][4], "Attack profile: " + row[2])
    for i in range(7):
        r.end_turn()
    # All eight totals equal 12. This checks raw INT bonuses, die order, and tie ordering.
    queue(r,[9,6,5,3,8,6,7,4])
    r.end_turn()
    check(r.round_number == 2 and ids(r.order) == IDS, "Tied initiative uses roster order")
    r.unit("A").hp = 0
    for id in ["K","W","C","S","L","B","M"]:
        check(r.active.id == id and r.active.ap == 3, "Skip defeated or reset AP: " + id)
        if id == "M":
            queue(r,[1,2,3,4,5,6,7])
        r.end_turn()
    check(r.round_number == 3 and ids(r.order) == ["M","C","L","B","W","S","K"],
        "Reroll for living units only")

    completed += 1

func movement() -> void:
    for id in ["K","A","B"]:
        var r = fresh(id)
        var u = r.active
        # Clear a flat test lane on row zero.
        u.cell = Vector2i.ZERO
        var first := 4 if id in ["A","B"] else 3
        for ap in range(1,4):
            var last := first + 2 * (ap-1)
            check(r.movement_cost(u,Vector2i(last,0)) == ap, "Movement boundary: " + id)
        check(r.move(Vector2i(1,0)) and u.ap == 2 and u.move_ap_spent == 1, "Whole AP for short move")
        check(r.movement_cost(u,Vector2i(4,0)) == 2, "No carryover from a short move")
    var r = fresh("K")
    var k = r.active
    k.cell = Vector2i.ZERO
    r.unit("A").cell = Vector2i(1,0)
    r.unit("S").cell = Vector2i(0,1)
    r.unit("L").cell = Vector2i(1,1)
    check(r.movement_cost(k,Vector2i(2,0)) == 1, "Walk through ally")
    for dest in [Vector2i(1,0),Vector2i(0,1),Vector2i(-1,0),Vector2i(10,0)]:
        check(r.movement_cost(k,dest) == 0 and not r.move(dest) and k.ap == 3, "Reject occupied/outside cell")
    r.unit("A").cell = Vector2i(0,2)
    r.unit("M").cell = Vector2i(1,0)
    check(r.movement_cost(k,Vector2i(2,0)) == 0, "Enemies block all three exits")

    completed += 1

func combat() -> void:
    for row in [[6,4,"normal",56.3],[6,1,"disadvantage",52.8],[7,-3,"normal",81.3]]:
        check(is_equal_approx(rules_script.opposed_chance(row[0],row[1],row[2],"normal"),row[3]),
            "Opposed chance reference " + str(row))
    for row in [[[20,20],0], [[1,2],0], [[10,12],0], [[20,19,5],10], [[12,8,5],5]]:
        var r = fresh("K")
        var t = r.unit("S")
        t.cell = r.active.cell + Vector2i.RIGHT
        queue(r,row[0])
        check(r.use_action("basic",t) and t.hp == 22-row[1] and r.unit("K").ap == 2,
            "Knight opposed roll " + str(row))
    var r = fresh("A")
    var t = r.unit("L")
    r.unit("S").cell = r.active.cell + Vector2i.RIGHT
    var modes = r.roll_modes(r.active,t,"basic")
    check(modes.attack == "disadvantage" and modes.defense == "normal" and not modes.reasons.is_empty(),
        "Adjacent threat gives physical ranged disadvantage and a reason")
    check(is_equal_approx(r.hit_chance(r.active,t,"basic"),52.8), "Target-specific threatened hit chance")
    queue(r,[20,1,4])
    check(r.use_action("basic",t) and t.hp == 16, "Threatened bow keeps lower attack die")

    completed += 1

func spells() -> void:
    var r = fresh("W")
    var w = r.active
    var t = r.unit("S")
    w.cell = Vector2i(2,2)
    t.cell = Vector2i(5,5)
    r.unit("L").cell = Vector2i(2,1)
    check(r.roll_modes(w,t,"arcane_bolt").attack == "normal", "Threat does not penalize magic")
    queue(r,[20,19,2,3])
    check(r.use_action("arcane_bolt",t) and t.hp == 17 and w.ap == 1, "Magic critical does ordinary damage")
    queue(r,[15,3,4])
    check(r.use_action("arcane_dart",t) and t.hp == 13, "Arcane Dart costs the last AP")
    for case in ["open","edge","unit","miss"]:
        r = fresh("W")
        w = r.active
        t = r.unit("S")
        w.cell = Vector2i(1,0)
        t.cell = Vector2i(2,0)
        var finish := Vector2i(7,0)
        var damage := 0
        if case == "edge":
            w.cell = Vector2i(5,0)
            t.cell = Vector2i(7,0)
            finish = Vector2i(9,0)
            damage = 4
        elif case == "unit":
            w.cell = Vector2i(1,1)
            t.cell = Vector2i(2,2)
            r.unit("B").cell = Vector2i(4,4)
            finish = Vector2i(3,3)
            damage = 4
        elif case == "miss":
            finish = t.cell
        var a = r.action(w,"force_push")
        check(a.ap == 2 and a.range == 5, "Force Push profile")
        queue(r,[1,11] if case == "miss" else [19,1,4])
        check(r.use_action("force_push",t) and t.cell == finish and t.hp == 22-damage
            and r.unit("B").hp == 16 and w.ap == 1, "Push " + case)
    r = fresh("W")
    w = r.active
    t = r.unit("B")
    t.cell = Vector2i(1,6)
    var slow = r.action(w,"slow")
    check(slow.ap == 2 and slow.range == 6, "Slow profile")
    queue(r,[18,1])
    check(r.use_action("slow",t) and r.is_slowed(t), "Slow applies on hit")
    for i in range(16):
        if r.active == t:
            break
        r.end_turn()
    t.cell = Vector2i.ZERO
    check(r.active == t and r.is_slowed(t), "Slow persists through target's next turn")
    for row in [[2,1],[3,2],[4,3],[5,0]]:
        check(r.movement_cost(t,Vector2i(row[0],0)) == row[1], "Slowed movement " + str(row))
    r.end_turn()
    check(not r.is_slowed(t), "Slow expires after affected turn")

    completed += 1

func healing() -> void:
    var r = fresh("C")
    var c = r.active
    var k = r.unit("K")
    var a = r.action(c,"healing_light")
    check(a.ap == 1 and a.range == 5, "Healing Light profile")
    check(not r.use_action("healing_light",k) and c.ap == 3, "Reject full-health ally")
    var foe = r.unit("S")
    foe.cell = Vector2i(2,4)
    foe.hp -= 2
    check(not r.use_action("healing_light",foe), "Reject enemy heal")
    k.cell = Vector2i(7,4)
    k.hp = 10
    check(not r.use_action("healing_light",k) and c.ap == 3, "Reject heal at six tiles")
    k.cell = Vector2i(6,7)
    queue(r,[2])
    check(r.use_action("healing_light",k) and k.hp == 16 and c.ap == 2, "Heal ally at range five for d6+4")
    check(not r.use_action("healing_light",k) and c.ap == 2, "Once per round")
    for i in range(16):
        r.end_turn()
        if r.active == c:
            break
    c.hp = c.max_hp - 1
    queue(r,[6])
    check(r.use_action("healing_light",c) and c.hp == c.max_hp, "Next round self-heal capped at max HP")

    completed += 1

func ai_and_outcomes() -> void:
    var r = fresh("B")
    var a = r.unit("A")
    a.hp = 7
    queue(r,[20,2,1,1])
    r.enemy_step()
    check(a.hp == 3, "Bowman attacks lowest-HP legal hero")
    # Two equally wounded heroes: the hero with weaker AC has the higher hit chance.
    r = fresh("B")
    r.unit("A").hp = 8
    r.unit("W").hp = 8
    queue(r,[20,1,1,1])
    r.enemy_step()
    check(r.unit("A").hp == 8 and r.unit("W").hp == 4, "Equal HP: prefer better hit chance")
    # S starts too far to attack K. A three-tile move can reach melee for one AP.
    r = fresh("S")
    r.unit("S").cell = Vector2i(5,3)
    r.enemy_step()
    check(r.unit("S").ap == 2 and r.unit("S").cell != Vector2i(5,3),
        "Melee AI gets into range using one AP")
    var legal := false
    for id in ["K","A","W","C"]:
        legal = legal or r.target_reason(r.unit("S"),r.unit(id),"basic") == ""
    check(legal, "AI selects a cell with a legal follow-up attack")
    for winner in ["K","S"]:
        r = fresh(winner)
        var actor = r.active
        var victim = r.unit("S" if winner == "K" else "K")
        for id in IDS:
            var u = r.unit(id)
            if u.team == victim.team:
                u.hp = 0
        victim.hp = 1
        victim.cell = actor.cell + Vector2i.RIGHT
        queue(r,[20,1,2,2])
        check(r.use_action("basic",victim), "Final attack")
        var expected := "Victory" if winner == "K" else "Defeat"
        check(r.outcome == expected, expected)
        var before := str([actor.hp,actor.ap,actor.cell,r.round_number,r.outcome])
        check(not r.move(Vector2i(4,4)) and not r.use_action("basic",victim), "Outcome locks actions")
        r.end_turn()
        check(before == str([actor.hp,actor.ap,actor.cell,r.round_number,r.outcome]), "Terminal turn frozen")

    completed += 1

func seed_for(first: String) -> int:
    var r = rules_script.new(BOARD)
    for n in range(1,1025):
        r.start(n)
        if r.active.id == first:
            return n
    check(false, "Cannot select a seed starting with " + first)
    return 1

func click(scene, world: Vector3) -> void:
    var point: Vector2 = scene.get_camera().unproject_position(world)
    for pressed in [true,false]:
        var event := InputEventMouseButton.new()
        event.position = point
        event.global_position = point
        event.button_index = MOUSE_BUTTON_LEFT
        event.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
        event.pressed = pressed
        root.push_input(event,true)

func visible_text(hud: Node) -> String:
    var bits := PackedStringArray()
    for n in hud.find_children("*","Control",true,false):
        if n.is_visible_in_tree() and (n is Label or n is Button or n is RichTextLabel):
            bits.append(n.text)
    return " ".join(bits)

func snapshot(r) -> Array:
    var data := [r.seed,r.round_number,ids(r.order),r.active.id]
    for id in IDS:
        var u = r.unit(id)
        data.append([u.cell,u.hp,u.ap])
    return data

func check_hud_geometry(scene, hud) -> void:
    var camera: Camera3D = scene.get_camera()
    var board_polygon := PackedVector2Array()
    for corner in [Vector3(-5,0,-4),Vector3(5,0,-4),Vector3(5,0,4),Vector3(-5,0,4)]:
        board_polygon.append(camera.unproject_position(corner))
    for widget in hud.find_children("*","Control",true,false):
        if not widget.is_visible_in_tree():
            continue
        var rect: Rect2 = widget.get_global_rect()
        if not rect.has_area():
            continue
        if widget is Panel or widget is PanelContainer:
            var polygon := PackedVector2Array([rect.position,Vector2(rect.end.x,rect.position.y),
                rect.end,Vector2(rect.position.x,rect.end.y)])
            check(Geometry2D.intersect_polygons(board_polygon,polygon).is_empty(),
                "HUD panel overlaps playable board: " + str(widget.get_path()))
        if widget is Label or widget is Button:
            check(root.get_visible_rect().encloses(rect), "Visible text outside viewport: " + str(widget.get_path()))
            var parent = widget.get_parent()
            while parent is Control:
                if parent is PanelContainer or parent is Panel or parent.clip_contents:
                    check(parent.get_global_rect().grow(1.0).encloses(rect),
                        "Text exceeds its HUD panel: " + str(widget.get_path()))
                    break
                parent = parent.get_parent()

func scene_checks() -> void:
    var scene = load(SCENE_PATH).instantiate()
    scene.auto_enemy = false
    root.add_child(scene)
    await process_frame
    await process_frame
    var hud = scene.get_node("HUD")
    check(root.get_visible_rect().size == Vector2(1280,800), "Reference viewport")
    check_hud_geometry(scene,hud)
    var archer_seed := seed_for("A")
    scene.new_battle(archer_seed)
    var r = scene.battle
    var a = r.unit("A")
    var b = r.unit("B")
    for id in IDS:
        var node = scene.unit_node(id)
        check(node is Node3D and node.is_visible_in_tree(), "Visible unit " + id)
    var start := snapshot(r)
    check(scene.reachable_overlay() == r.reachable(a) and not r.reachable(a).is_empty(), "Reachable overlay")
    check(scene.select_action("basic"), "Select longbow")
    var preview := str(scene.preview_for(b.cell)).to_lower()
    var chance := "%.1f" % r.hit_chance(a,b,"basic")
    check((chance in preview or (chance.ends_with(".0") and chance.trim_suffix(".0")+"%" in preview))
        and "%" in preview and "ap" in preview and "2d6" in preview.replace(" ","")
        and "normal" in preview, "Bow preview shows chance, normal mode, AP and dice: " + preview)
    click(scene,scene.cell_to_world(b.cell) + Vector3.UP*0.9)
    check(a.cell == ROSTER["A"][1] and a.ap == 1, "Enemy chest click attacks without moving")
    var after := snapshot(r)
    var first_log := str(r.log)
    scene.restart_same_seed()
    r = scene.battle
    check(start == snapshot(r), "Restart reproduces deployment and initiative")
    scene.select_action("basic")
    click(scene,scene.cell_to_world(r.unit("B").cell) + Vector3.UP*0.9)
    check(after == snapshot(r) and first_log == str(r.log), "Restart reproduces action and rolls")
    a = r.unit("A")
    click(scene,scene.cell_to_world(Vector2i.ZERO))
    check(a.cell == Vector2i.ZERO and r.active != a, "Empty tile moves and zero AP advances turn")
    scene.new_battle(seed_for("C"))
    r = scene.battle
    var c = r.unit("C")
    var k = r.unit("K")
    k.hp = 10
    check(scene.select_action("healing_light"), "Select Healing Light")
    queue(r,[3])
    click(scene,scene.cell_to_world(k.cell) + Vector3.UP*0.9)
    check(k.hp == 17 and c.ap == 2 and c.cell == ROSTER["C"][1], "Ally click heals in place")
    scene.new_battle(seed_for("K"))
    r = scene.battle
    k = r.unit("K")
    scene.select_action("basic")
    var foe = r.unit("S")
    var prior_text := visible_text(hud)
    click(scene,scene.cell_to_world(foe.cell) + Vector3.UP*0.9)
    check(k.ap == 3 and k.cell == ROSTER["K"][1], "Illegal distant attack spends nothing")
    var reason := str(r.target_reason(k,foe,"basic"))
    var feedback := visible_text(hud)
    check(not reason.is_empty() and (feedback != prior_text or reason.to_lower() in feedback.to_lower()),
        "HUD feedback on illegal action")
    var ref_text := str(scene.build_reference())
    var build_path := OS.get_executable_path().get_base_dir().path_join("BUILD.txt")
    var expected_ref := "dev build"
    if FileAccess.file_exists(build_path):
        var commit_pattern := RegEx.create_from_string("(?mi)^Git commit:[ \\t]*([0-9a-f]{7,40})[ \\t]*\\r?$")
        var match_result := commit_pattern.search(FileAccess.get_file_as_string(build_path))
        if match_result != null:
            expected_ref = match_result.get_string(1).left(7)
    check(ref_text == expected_ref, "Expected build_reference() to return " + expected_ref)
    var suffix := "dev build" if expected_ref == "dev build" else "Build " + expected_ref
    check(("Seed %s · %s" % [r.seed, suffix]) in feedback, "Exact on-screen seed/build label")
    var controls := {}
    for button in hud.find_children("*","BaseButton",true,false):
        if button.is_visible_in_tree():
            var label := str(button.get("text")).to_lower().strip_edges()
            controls[label] = button
            check(root.get_visible_rect().encloses(button.get_global_rect()), "Button on screen: " + label)
    for label in ["end turn","restart","new battle"]:
        var found = null
        for key in controls:
            if label in key:
                found = controls[key]
                break
        check(found != null, "Visible HUD button: " + label)
        if label == "end turn" and found != null:
            found.pressed.emit()
            check(r.active != k, "End turn advances while hero still has AP")
    var old_seed = r.seed
    scene.new_battle()
    check(scene.battle.seed != old_seed, "New battle changes seed")
    # A threatened Archer preview should explain why the attack uses the lower die.
    scene.new_battle(archer_seed)
    r = scene.battle
    r.unit("S").cell = r.unit("A").cell + Vector2i.RIGHT
    scene.select_action("basic")
    var threatened := str(scene.preview_for(r.unit("B").cell)).to_lower()
    check("disadvantage" in threatened and ("threat" in threatened or "adjacent" in threatened
        or "engaged" in threatened or "melee" in threatened), "Preview explains ranged disadvantage")
    scene.auto_enemy = true
    scene.new_battle(seed_for("B"))
    var initial_log_size: int = scene.battle.log.size()
    var deadline := Time.get_ticks_msec() + 10000
    while scene.battle.log.size() == initial_log_size and Time.get_ticks_msec() < deadline:
        await create_timer(0.05).timeout
    check(scene.battle.log.size() > initial_log_size, "Automatic enemy turn performs an action")
    scene.auto_enemy = false
    scene.queue_free()
    await process_frame
    completed += 1
