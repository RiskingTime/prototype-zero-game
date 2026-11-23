extends "res://scripts/battlefield.gd"

# Stage 3: first playable 4-vs-4 encounter with placeholder capsules.
# Rules live in encounter_rules.gd; this script handles the board, input and HUD.

const EncounterRules = preload("res://scripts/encounter_rules.gd")
const REACH_SHADER := preload("res://shaders/reach_cell.gdshader")
const ENEMY_STEP_SECONDS := 0.55
# Reachable-tile colours from the browser build (.cell.move1/2/3 in v0.13).
const MOVE_COLOURS := {1: Color("#4d8a61"), 2: Color("#b08a43"), 3: Color("#a45e46")}
const UNIT_COLOURS := {
    "K": Color(0.29, 0.62, 0.98), "A": Color(0.33, 0.82, 0.86),
    "W": Color(0.55, 0.52, 0.98), "C": Color(0.93, 0.93, 0.98),
    "S": Color(0.86, 0.25, 0.17), "L": Color(0.95, 0.55, 0.22),
    "B": Color(0.78, 0.36, 0.52), "M": Color(0.66, 0.22, 0.72),
}
const HERO_TEXT := Color(0.55, 0.78, 1.0)
const ENEMY_TEXT := Color(1.0, 0.56, 0.48)
const ACTIVE_TEXT := Color(1.0, 0.84, 0.35)

var battle := EncounterRules.new(Vector2i(GRID_WIDTH, GRID_DEPTH))
var selected_action_id := ""
var auto_enemy := true

var _unit_nodes := {}
var _hp_labels := {}
var _overlay := {}
var _overlay_root: Node3D
var _marks_root: Node3D
var _hover_marker: Node3D
var _hover_cell := Vector2i(-1, -1)
var _enemy_timer: Timer
var _seed_rng := RandomNumberGenerator.new()
var _build_reference := ""
var _hint := ""

var _theme: Theme
var _round_label: Label
var _build_label: Label
var _hero_rows: VBoxContainer
var _enemy_rows: VBoxContainer
var _active_label: Label
var _action_bar: HBoxContainer
var _preview_label: Label
var _log_label: Label
var _end_button: Button
var _action_bar_key := ""


func _ready() -> void:
    super._ready()
    $HUD/Instructions.hide()
    _pawn.hide()
    _seed_rng.randomize()
    _build_reference = _read_build_reference()
    _overlay_root = Node3D.new()
    _overlay_root.name = "ReachOverlay"
    add_child(_overlay_root)
    _marks_root = Node3D.new()
    _marks_root.name = "TargetMarks"
    add_child(_marks_root)
    _hover_marker = _outline(Color(1, 1, 1, 0.85), 0.05)
    _hover_marker.name = "HoverMarker"
    _hover_marker.hide()
    add_child(_hover_marker)
    _build_units()
    _enemy_timer = Timer.new()
    _enemy_timer.one_shot = true
    _enemy_timer.timeout.connect(_enemy_step)
    add_child(_enemy_timer)
    _build_encounter_hud()
    new_battle()


# --- Public API ------------------------------------------------------------------------

func new_battle(battle_seed := -1) -> void:
    if battle_seed < 0:
        # A new battle never repeats the current seed.
        battle_seed = _seed_rng.randi_range(1, 999999)
        while battle_seed == battle.seed:
            battle_seed = _seed_rng.randi_range(1, 999999)
    _start(battle_seed)


func restart_same_seed() -> void:
    _start(battle.seed)


func select_action(id: String) -> bool:
    if not _hero_turn() or not battle.actions_for(battle.active).has(id):
        return false
    selected_action_id = id
    _hint = ""
    _refresh()
    return true


# Acts on a cell for the active hero: the selected action if a unit stands there,
# otherwise a move. Returns true if something happened.
func play_cell(cell: Vector2i) -> bool:
    if not _hero_turn():
        return false
    var target = battle.unit_at(cell)
    var done := false
    if target != null:
        if target == battle.active and selected_action_id != "healing_light":
            _hint = "That's %s. Click an empty tile to move or a target to act." % target.name
        else:
            done = battle.use_action(selected_action_id, target)
            if not done:
                _hint = battle.last_error
    else:
        done = battle.move(cell)
        if not done:
            _hint = battle.last_error if cell.x >= 0 else ""
    if done:
        _hint = ""
        if battle.outcome.is_empty() and battle.active.ap == 0:
            end_player_turn()
            return true
    _refresh()
    return done


func end_player_turn() -> void:
    if not _hero_turn():
        return
    battle.end_turn()
    _turn_changed()


func unit_node(id: String) -> Node3D:
    return _unit_nodes.get(id)


func reachable_overlay() -> Dictionary:
    return _overlay.duplicate()


func build_reference() -> String:
    return _build_reference


func preview_for(cell: Vector2i) -> String:
    if not _hero_turn():
        return ""
    var actor = battle.active
    var target = battle.unit_at(cell)
    if target == null:
        var cost: int = battle.movement_cost(actor, cell)
        if cost > 0:
            return "Move to (%d, %d): %d AP, %d AP left after." % [cell.x, cell.y, cost, actor.ap - cost]
        if battle.reachable(actor).is_empty() or not Rect2i(Vector2i.ZERO, Vector2i(GRID_WIDTH, GRID_DEPTH)).has_point(cell):
            return ""
        return "Out of reach this turn."
    if target == actor and selected_action_id != "healing_light":
        return "%s, %d/%d HP, %d AP." % [actor.name, actor.hp, actor.max_hp, actor.ap]
    var reason: String = battle.target_reason(actor, target, selected_action_id)
    var chosen: Dictionary = battle.action(actor, selected_action_id)
    if not reason.is_empty():
        return reason
    var hp_text := "%d/%d HP" % [target.hp, target.max_hp]
    if chosen["kind"] == "heal":
        return "%s → %s · %d AP · heals 1d6 + %d (at least 1) · %s" % [
            chosen["name"], target.name, chosen["ap"],
            EncounterRules.ability_mod(actor.stats["int"]), hp_text]
    var modes: Dictionary = battle.roll_modes(actor, target, selected_action_id)
    var mode_text := "normal roll"
    if modes["attack"] != "normal":
        mode_text = "%s (%s)" % [modes["attack"].capitalize(), "; ".join(modes["reasons"])]
    var defense_name := "MR" if chosen["type"] == "magic" else "AC"
    var effect := ""
    match chosen["kind"]:
        "basic", "damage":
            effect = "%dd%d %s" % [chosen["dice"].x, chosen["dice"].y, chosen["type"]]
        "push":
            effect = "push %d, 1d6 on collision" % chosen["push"]
        "slow":
            effect = "Slowed for its next turn"
    return "%s → %s · %d AP · %.1f%% to hit · %s · %s · %+d vs %s %+d · %s" % [
        chosen["name"], target.name, chosen["ap"], battle.hit_chance(actor, target, selected_action_id),
        mode_text, effect, battle.attack_bonus(actor, selected_action_id), defense_name,
        battle.defense_for(target, chosen["type"]), hp_text]


# --- Battle flow -----------------------------------------------------------------------

func _start(battle_seed: int) -> void:
    _enemy_timer.stop()
    battle.start(battle_seed)
    _hint = ""
    _turn_changed()


func _hero_turn() -> bool:
    return battle.outcome.is_empty() and battle.active != null and battle.active.team == "hero"


func _turn_changed() -> void:
    if _hero_turn():
        selected_action_id = battle.actions_for(battle.active)[0]
    _refresh()
    _schedule_enemy()


func _schedule_enemy() -> void:
    if auto_enemy and battle.outcome.is_empty() and battle.active.team == "enemy":
        _enemy_timer.start(ENEMY_STEP_SECONDS)


func _enemy_step() -> void:
    if not auto_enemy or not battle.outcome.is_empty() or battle.active.team != "enemy":
        return
    var acted: bool = battle.enemy_step()
    if not battle.outcome.is_empty():
        _refresh()
        return
    if not acted or battle.active.ap == 0:
        battle.end_turn()
        _turn_changed()
        return
    _refresh()
    _schedule_enemy()


# --- Input -----------------------------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo:
        if event.keycode == KEY_ESCAPE:
            get_tree().quit()
        elif event.keycode >= KEY_1 and event.keycode <= KEY_4 and _hero_turn():
            var actions: Array[String] = battle.actions_for(battle.active)
            var index: int = event.keycode - KEY_1
            if index < actions.size():
                select_action(actions[index])
    elif event is InputEventMouseMotion:
        _set_hover(_cell_under(event.position))
    elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
        play_cell(_cell_under(event.position))


# The cell of the unit under the cursor (nearest to the camera wins), or else the ground cell.
func _cell_under(screen_position: Vector2) -> Vector2i:
    var camera := get_camera()
    var origin := camera.project_ray_origin(screen_position)
    var direction := camera.project_ray_normal(screen_position)
    var end := origin + direction * (camera.far - camera.near)
    var best_depth := INF
    var best_cell := Vector2i(-1, -1)
    for who in battle.units:
        var node: MeshInstance3D = _unit_nodes[who.id]
        if not who.alive() or not node.visible or not _ray_hits_capsule(node, origin, end):
            continue
        var depth := direction.dot(node.global_position - origin)
        if depth < best_depth:
            best_depth = depth
            best_cell = who.cell
    if best_cell != Vector2i(-1, -1):
        return best_cell
    return screen_to_cell(screen_position)


func _ray_hits_capsule(node: MeshInstance3D, ray_origin: Vector3, ray_end: Vector3) -> bool:
    var capsule := node.mesh as CapsuleMesh
    if capsule == null:
        return false
    # A capsule is the volume within its radius of this central segment.
    var axis := Vector3.UP * (capsule.height * 0.5 - capsule.radius)
    var closest := Geometry3D.get_closest_points_between_segments(
        ray_origin, ray_end, node.to_global(-axis), node.to_global(axis))
    return closest[0].distance_squared_to(closest[1]) <= capsule.radius * capsule.radius


func _set_hover(cell: Vector2i) -> void:
    if cell == _hover_cell:
        return
    _hover_cell = cell
    _hint = ""
    _refresh_preview()


# --- Board visuals ---------------------------------------------------------------------

func _build_units() -> void:
    battle.start(1)
    for who in battle.units:
        var node := MeshInstance3D.new()
        node.name = "Unit_" + who.id
        var capsule := CapsuleMesh.new()
        capsule.radius = 0.34
        capsule.height = 1.25
        node.mesh = capsule
        node.material_override = _material(UNIT_COLOURS[who.id])
        add_child(node)
        var letter := _label3d(who.id, 72, 14)
        letter.position = Vector3(0, 0.08, 0)
        node.add_child(letter)
        var hp := _label3d("", 34, 10)
        hp.position = Vector3(0, 0.88, 0)
        node.add_child(hp)
        _unit_nodes[who.id] = node
        _hp_labels[who.id] = hp


func _label3d(text: String, size: int, outline: int) -> Label3D:
    var label := Label3D.new()
    label.text = text
    label.font_size = size
    label.outline_size = outline
    label.outline_modulate = Color(0.05, 0.06, 0.08)
    label.pixel_size = 0.004
    label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    label.no_depth_test = true
    label.render_priority = HIGHLIGHT_RENDER_PRIORITY + 1
    label.outline_render_priority = HIGHLIGHT_RENDER_PRIORITY
    return label


func _outline(color: Color, width: float) -> Node3D:
    var root := Node3D.new()
    var material := _highlight_material(color)
    var inner := CELL_SPACING - 0.07
    for side in range(4):
        var bar := MeshInstance3D.new()
        var bar_mesh := BoxMesh.new()
        var along_x := side < 2
        bar_mesh.size = Vector3(inner if along_x else width, 0.01, width if along_x else inner)
        bar.mesh = bar_mesh
        bar.material_override = material
        var offset := (inner - width) / 2.0
        if along_x:
            bar.position = Vector3(0.0, 0.0, -offset if side == 0 else offset)
        else:
            bar.position = Vector3(-offset if side == 2 else offset, 0.0, 0.0)
        root.add_child(bar)
    return root


func _tile_fill(color: Color) -> MeshInstance3D:
    var fill := MeshInstance3D.new()
    var plane := PlaneMesh.new()
    plane.size = Vector2(CELL_SPACING - 0.12, CELL_SPACING - 0.12)
    fill.mesh = plane
    var material := ShaderMaterial.new()
    material.shader = REACH_SHADER
    material.set_shader_parameter("ap_color", color)
    fill.material_override = material
    return fill


func _refresh_board() -> void:
    for who in battle.units:
        var node: MeshInstance3D = _unit_nodes[who.id]
        node.visible = who.alive()
        node.position = cell_to_world(who.cell) + Vector3(0, 0.72, 0)
        var hp_label: Label3D = _hp_labels[who.id]
        hp_label.text = "%d/%d%s" % [who.hp, who.max_hp, " SLOW" if battle.is_slowed(who) else ""]
    _selection.visible = battle.outcome.is_empty() and battle.active != null
    if _selection.visible:
        _selection.position = cell_to_world(battle.active.cell) + Vector3(0, 0.01, 0)
    for child in _overlay_root.get_children():
        child.queue_free()
    for child in _marks_root.get_children():
        child.queue_free()
    _overlay = {}
    if not _hero_turn():
        return
    _overlay = battle.reachable(battle.active)
    for cell in _overlay:
        var fill := _tile_fill(MOVE_COLOURS[_overlay[cell]])
        fill.position = cell_to_world(cell) + Vector3(0, 0.012, 0)
        _overlay_root.add_child(fill)
    var chosen: Dictionary = battle.action(battle.active, selected_action_id)
    var mark_colour := Color(0.45, 0.95, 0.55) if chosen.get("kind") == "heal" else Color(1.0, 0.36, 0.3)
    for who in battle.units:
        if battle.target_reason(battle.active, who, selected_action_id).is_empty():
            var mark := _outline(mark_colour, 0.07)
            mark.position = cell_to_world(who.cell) + Vector3(0, 0.02, 0)
            _marks_root.add_child(mark)


# --- HUD -------------------------------------------------------------------------------

func _build_theme() -> Theme:
    var result := Theme.new()
    result.set_font_size("font_size", "Label", 15)
    result.set_font_size("font_size", "Button", 14)
    var panel := StyleBoxFlat.new()
    panel.bg_color = Color(0.06, 0.08, 0.1, 0.92)
    panel.border_color = Color(0.25, 0.32, 0.36)
    panel.set_border_width_all(1)
    panel.set_corner_radius_all(6)
    panel.set_content_margin_all(8)
    result.set_stylebox("panel", "PanelContainer", panel)
    var states := {
        "normal": [Color(0.17, 0.24, 0.3), Color(0.42, 0.56, 0.66)],
        "hover": [Color(0.24, 0.33, 0.41), Color(0.62, 0.76, 0.86)],
        "pressed": [Color(0.55, 0.42, 0.12), Color(1.0, 0.84, 0.35)],
        "hover_pressed": [Color(0.6, 0.46, 0.14), Color(1.0, 0.88, 0.45)],
        "disabled": [Color(0.12, 0.14, 0.16), Color(0.22, 0.25, 0.28)],
        "focus": [Color(0, 0, 0, 0), Color(0.62, 0.76, 0.86)],
    }
    for state in states:
        var box := StyleBoxFlat.new()
        box.bg_color = states[state][0]
        box.border_color = states[state][1]
        box.set_border_width_all(2 if state != "focus" else 1)
        box.set_corner_radius_all(5)
        box.content_margin_left = 10
        box.content_margin_right = 10
        box.content_margin_top = 3
        box.content_margin_bottom = 3
        result.set_stylebox(state, "Button", box)
    result.set_color("font_disabled_color", "Button", Color(0.45, 0.48, 0.5))
    result.set_color("font_pressed_color", "Button", Color(1, 1, 1))
    return result


func _panel(parent: Node) -> PanelContainer:
    var card := PanelContainer.new()
    card.theme = _theme
    card.mouse_filter = Control.MOUSE_FILTER_STOP
    parent.add_child(card)
    return card


func _label(parent: Node, size := 15, colour := Color(0.88, 0.9, 0.92)) -> Label:
    var label := Label.new()
    label.add_theme_font_size_override("font_size", size)
    label.add_theme_color_override("font_color", colour)
    label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    parent.add_child(label)
    return label


func _build_encounter_hud() -> void:
    _theme = _build_theme()
    var hud: CanvasLayer = $HUD

    var heroes := _panel(hud)
    heroes.name = "HeroPanel"
    heroes.position = Vector2(12, 12)
    heroes.custom_minimum_size = Vector2(250, 0)
    _hero_rows = VBoxContainer.new()
    _hero_rows.add_theme_constant_override("separation", 1)
    heroes.add_child(_hero_rows)

    var enemies := _panel(hud)
    enemies.name = "EnemyPanel"
    enemies.custom_minimum_size = Vector2(250, 0)
    enemies.set_anchors_preset(Control.PRESET_TOP_RIGHT)
    enemies.position = Vector2(1280 - 262, 12)
    _enemy_rows = VBoxContainer.new()
    _enemy_rows.add_theme_constant_override("separation", 1)
    enemies.add_child(_enemy_rows)

    var header := VBoxContainer.new()
    header.name = "TurnOrder"
    header.mouse_filter = Control.MOUSE_FILTER_IGNORE
    header.position = Vector2(300, 8)
    header.size = Vector2(680, 0)
    hud.add_child(header)
    _round_label = _label(header, 14)
    _round_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _round_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    _round_label.custom_minimum_size = Vector2(680, 0)
    _build_label = _label(header, 12, Color(0.62, 0.68, 0.72))
    _build_label.name = "BuildSeed"
    _build_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _build_label.custom_minimum_size = Vector2(680, 0)

    # Bottom panel: one row of controls, then the preview and the latest log entry, each
    # across the full width so a long preview (several threats) stays readable.
    var bottom := _panel(hud)
    bottom.name = "BottomPanel"
    bottom.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
    bottom.offset_left = 12
    bottom.offset_right = -12
    bottom.offset_top = -100
    bottom.offset_bottom = -8
    var rows := VBoxContainer.new()
    rows.add_theme_constant_override("separation", 5)
    bottom.add_child(rows)

    var controls := HBoxContainer.new()
    controls.add_theme_constant_override("separation", 6)
    rows.add_child(controls)
    _active_label = _label(controls, 15, ACTIVE_TEXT)
    _active_label.name = "Active"
    _active_label.custom_minimum_size = Vector2(150, 0)
    _active_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    _action_bar = HBoxContainer.new()
    _action_bar.name = "Actions"
    _action_bar.add_theme_constant_override("separation", 6)
    controls.add_child(_action_bar)
    var spacer := Control.new()
    spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
    controls.add_child(spacer)
    _end_button = _button(controls, "End turn", end_player_turn)
    _end_button.name = "EndTurn"
    var restart := _button(controls, "Restart (same seed)", restart_same_seed)
    restart.name = "Restart"
    var fresh := _button(controls, "New battle", func() -> void: new_battle())
    fresh.name = "NewBattle"

    _preview_label = _label(rows, 14)
    _preview_label.name = "Preview"
    _preview_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _preview_label.clip_text = true
    _preview_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS

    _log_label = _label(rows, 13, Color(0.74, 0.78, 0.8))
    _log_label.name = "Log"
    _log_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _log_label.clip_text = true
    _log_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS


func _button(parent: Node, text: String, callback: Callable) -> Button:
    var button := Button.new()
    button.text = text
    button.theme = _theme
    button.focus_mode = Control.FOCUS_NONE
    button.pressed.connect(callback)
    parent.add_child(button)
    return button


func _refresh() -> void:
    _refresh_board()
    _refresh_hud()
    _refresh_preview()


func _refresh_hud() -> void:
    for rows in [_hero_rows, _enemy_rows]:
        for child in rows.get_children():
            rows.remove_child(child)
            child.queue_free()
    _label(_hero_rows, 14, HERO_TEXT).text = "Heroes"
    _label(_enemy_rows, 14, ENEMY_TEXT).text = "Enemies"
    for who in battle.units:
        var rows := _hero_rows if who.team == "hero" else _enemy_rows
        var marker := "▶ " if who == battle.active and battle.outcome.is_empty() else "   "
        var status := "defeated" if not who.alive() else "%d/%d HP%s" % [
            who.hp, who.max_hp, ", Slowed" if battle.is_slowed(who) else ""]
        var colour := ACTIVE_TEXT if marker != "   " else (Color(0.5, 0.52, 0.55) if not who.alive() else Color(0.88, 0.9, 0.92))
        _label(rows, 14, colour).text = "%s%s  %s  %s" % [marker, who.id, who.name, status]

    var names: Array[String] = []
    for who in battle.order:
        if who.alive():
            var entry := "%s %d/%d" % [who.name, who.hp, who.max_hp]
            names.append("[%s]" % entry if who == battle.active else entry)
    if battle.outcome.is_empty():
        _round_label.text = "Round %d turn order: %s" % [battle.round_number, " › ".join(names)]
        _round_label.add_theme_font_size_override("font_size", 14)
        _round_label.add_theme_color_override("font_color", Color(0.88, 0.9, 0.92))
    else:
        _round_label.text = "%s in round %d" % [battle.outcome.to_upper(), battle.round_number]
        _round_label.add_theme_font_size_override("font_size", 26)
        _round_label.add_theme_color_override("font_color", ACTIVE_TEXT)
    _build_label.text = "Seed %d · %s" % [battle.seed,
        _build_reference if _build_reference == "dev build" else "Build " + _build_reference]

    var actor = battle.active
    _refresh_action_bar()
    if not battle.outcome.is_empty():
        _active_label.text = "%s. Restart with the same seed or start a new battle." % battle.outcome
    elif _hero_turn():
        _active_label.text = "%s · %d/3 AP%s" % [
            actor.name, actor.ap, " · Slowed" if battle.is_slowed(actor) else ""]
    else:
        _active_label.text = "%s is acting…" % actor.name
    _end_button.disabled = not _hero_turn()

    # The latest result; the side panels and turn order show the rest of the state.
    _log_label.text = battle.log.back() if not battle.log.is_empty() else ""


# Rebuilds the action buttons only when the acting hero changes, so a button is never
# freed while it is emitting its own pressed signal.
func _refresh_action_bar() -> void:
    var actions: Array[String] = []
    if _hero_turn():
        actions = battle.actions_for(battle.active)
    var key := "%s|%s" % [battle.active.id if _hero_turn() else "", ",".join(actions)]
    if key != _action_bar_key:
        _action_bar_key = key
        for child in _action_bar.get_children():
            _action_bar.remove_child(child)
            child.queue_free()
        var group := ButtonGroup.new()
        var index := 1
        for id in actions:
            var chosen: Dictionary = battle.action(battle.active, id)
            var button := _button(_action_bar, "%d  %s (%d AP)" % [index, chosen["name"], chosen["ap"]],
                select_action.bind(id))
            button.name = "Action_" + id
            button.toggle_mode = true
            button.button_group = group
            index += 1
    for id in actions:
        var button: Button = _action_bar.get_node("Action_" + id)
        button.set_pressed_no_signal(id == selected_action_id)
        button.disabled = battle.active.ap < battle.action(battle.active, id)["ap"]


func _refresh_preview() -> void:
    if _hover_marker == null:
        return
    var on_board := Rect2i(Vector2i.ZERO, Vector2i(GRID_WIDTH, GRID_DEPTH)).has_point(_hover_cell)
    _hover_marker.visible = on_board and _hero_turn()
    if _hover_marker.visible:
        _hover_marker.position = cell_to_world(_hover_cell) + Vector3(0, 0.03, 0)
    if _preview_label == null:
        return
    if not _hint.is_empty():
        _preview_label.text = _hint
    elif on_board:
        _preview_label.text = preview_for(_hover_cell)
    else:
        _preview_label.text = ""


func _read_build_reference() -> String:
    var path := OS.get_executable_path().get_base_dir().path_join("BUILD.txt")
    if FileAccess.file_exists(path):
        var text := FileAccess.get_file_as_string(path)
        for line in text.split("\n"):
            if line.begins_with("Git commit:"):
                var sha := line.trim_prefix("Git commit:").strip_edges()
                if sha.length() >= 7:
                    return sha.substr(0, 7)
    return "dev build"
