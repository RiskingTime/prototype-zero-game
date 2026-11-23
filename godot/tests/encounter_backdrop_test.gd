extends SceneTree

# Backdrop acceptance (encounter.tscn → encounter_backdrop.gd, a thin subclass of
# encounter.gd): launch-argument parsing; the default Mossgate painting and the opt-in
# registration guide (BG_CANVAS, CanvasLayer -1, mouse-ignoring TextureRect); the opt-in
# tiled board; guide marks against the live camera within one logical pixel; and pointer
# input in all three modes at three window sizes. Pointer events go through
# Viewport.push_input in window coordinates, so the project's canvas_items/keep stretch is
# exercised for real.

const SCENE_PATH := "res://scenes/encounter.tscn"
const ENCOUNTER_SCRIPT := "res://scripts/encounter_backdrop.gd"
const MARKS_PATH := "res://assets/debug/registration_guide.json"
const PAINTING_PATH := "res://assets/backdrops/mossgate_by_day_2560x1600.png"
const GUIDE_PATH := "res://assets/debug/registration_guide.svg"
const Rules = preload("res://scripts/encounter_rules.gd")
const DEFAULT_BACKGROUND := Color(0.075, 0.10, 0.13)
const WINDOW_SIZES := [Vector2i(1280, 800), Vector2i(1920, 1080), Vector2i(960, 600)]
const POINTER_CELLS := [
    Vector2i(2, 3), Vector2i(0, 2), Vector2i(0, 6), Vector2i(1, 5),  # hero spawns
    Vector2i(7, 4), Vector2i(8, 2), Vector2i(9, 5), Vector2i(9, 1),  # enemy spawns
    Vector2i(0, 0), Vector2i(9, 0), Vector2i(0, 7), Vector2i(9, 7),  # board corners
]

var _failures := 0
var _mark_count := 0


func _initialize() -> void:
    call_deferred("_verify")


func _check(condition: bool, message: String) -> void:
    if not condition:
        _failures += 1
        printerr("ENCOUNTER BACKDROP TEST FAILED: ", message)


func _settle(frames := 2) -> void:
    for i in frames:
        await process_frame


func _open(mode: String, window: Vector2i) -> Node:
    if current_scene != null:
        current_scene.free()
    root.size = window
    var scene := (load(SCENE_PATH) as PackedScene).instantiate()
    scene.backdrop_mode = mode
    root.add_child(scene)
    current_scene = scene
    await _settle()
    return scene


func _tiles(scene: Node) -> Array:
    var result := []
    for child in scene.get_children():
        if String(child.name).begins_with("Tile_"):
            result.append(child)
    return result


func _hero_first_seed() -> int:
    var probe = Rules.new(Vector2i(10, 8))
    for n in range(1, 4000):
        probe.start(n)
        if probe.active.team == "hero":
            return n
    return 1


func _window_point(scene: Node, cell: Vector2i) -> Vector2:
    var base: Vector2 = scene.get_camera().unproject_position(scene.cell_to_world(cell))
    return root.get_final_transform() * base


func _push_motion(p: Vector2) -> void:
    var motion := InputEventMouseMotion.new()
    motion.position = p
    motion.global_position = p
    root.push_input(motion)
    await _settle(1)


func _push_click(p: Vector2) -> void:
    await _push_motion(p)
    for pressed in [true, false]:
        var click := InputEventMouseButton.new()
        click.button_index = MOUSE_BUTTON_LEFT
        click.pressed = pressed
        click.position = p
        click.global_position = p
        root.push_input(click)
        await _settle(1)


func _verify() -> void:
    _parsing()
    await _tiles_mode()
    await _backdrop_mode("", "painting", PAINTING_PATH, "")
    await _backdrop_mode("guide", "guide", GUIDE_PATH, " · Guide backdrop")
    await _registration()
    for mode in ["tiles", "painting", "guide"]:
        await _pointer(mode)
    if current_scene != null:
        current_scene.free()
    if _failures == 0:
        print("ENCOUNTER BACKDROP TEST PASSED: argument parsing, painting (default), guide and tiles wiring and HUD, %d guide marks within 1 px, pointer input in all three modes at %d window sizes." % [_mark_count, WINDOW_SIZES.size()])
    quit(0 if _failures == 0 else 1)


# 1. "--backdrop=guide" or "--backdrop=tiles" selects that mode from either argument list;
#    anything else is the painting.
func _parsing() -> void:
    var script = load(ENCOUNTER_SCRIPT)
    var none := PackedStringArray()
    _check(script.backdrop_mode_from_args(none, none) == "painting", "No arguments → painting.")
    _check(script.backdrop_mode_from_args(PackedStringArray(["--backdrop=guide"]), none) == "guide", "User argument → guide.")
    _check(script.backdrop_mode_from_args(none, PackedStringArray(["--script", "x", "--backdrop=guide"])) == "guide", "Bare engine argument → guide.")
    _check(script.backdrop_mode_from_args(PackedStringArray(["--backdrop=tiles"]), none) == "tiles", "User argument → tiles.")
    _check(script.backdrop_mode_from_args(none, PackedStringArray(["--backdrop=tiles"])) == "tiles", "Bare engine argument → tiles.")
    _check(script.backdrop_mode_from_args(PackedStringArray(["--backdrop=painting"]), PackedStringArray(["--backdrop"])) == "painting", "Other values → painting.")


# 2. "--backdrop=tiles" is the original tiled board: no backdrop nodes, same background, all tiles.
func _tiles_mode() -> void:
    var scene := await _open("tiles", Vector2i(1280, 800))
    var environment := (scene.get_node("Environment") as WorldEnvironment).environment
    _check(environment.background_mode == Environment.BG_COLOR, "Tiles mode keeps the colour background.")
    _check(environment.background_color.is_equal_approx(DEFAULT_BACKGROUND), "Tiles background colour is unchanged.")
    _check(scene.get_node_or_null("Backdrop") == null, "Tiles mode has no Backdrop layer.")
    _check(scene.get_node_or_null("HUD/TurnOrderPanel") == null, "Tiles mode has no header panel.")
    var tiles := _tiles(scene)
    _check(tiles.size() == 80, "80 tile meshes (got %d)." % tiles.size())
    _check(tiles.all(func(t): return t.visible), "All tiles are visible in tiles mode.")
    var build := scene.get_node("HUD/TurnOrder/BuildSeed") as Label
    _check(build.text.ends_with(" · Tiled board"), "Tiles build line ends with the marker (got '%s')." % build.text)


# 3. Backdrop wiring (painting by default, guide on request): canvas background, layer -1
#    TextureRect over the logical canvas, tiles hidden, units and selection still drawn,
#    header panel, build line marker.
func _backdrop_mode(requested: String, expected: String, texture_path: String, suffix: String) -> void:
    var scene := await _open(requested, Vector2i(1280, 800))
    _check(scene.backdrop_mode == expected, "Requested '%s' resolves to %s (got %s)." % [requested, expected, scene.backdrop_mode])
    var environment := (scene.get_node("Environment") as WorldEnvironment).environment
    _check(environment.background_mode == Environment.BG_CANVAS, "%s mode uses BG_CANVAS." % expected)
    var layer := scene.get_node_or_null("Backdrop") as CanvasLayer
    _check(layer != null, "%s mode adds the Backdrop layer." % expected)
    if layer == null:
        return
    _check(layer.layer == -1 and layer.layer <= environment.background_canvas_max_layer, "Backdrop layer -1 is within the canvas background (max %d)." % environment.background_canvas_max_layer)
    var art := layer.get_node_or_null("Art") as TextureRect
    _check(art != null and art.texture != null, "%s TextureRect has a texture." % expected)
    if art == null or art.texture == null:
        return
    _check(art.texture.resource_path == texture_path, "%s uses %s (got %s)." % [expected, texture_path, art.texture.resource_path])
    _check(art.texture.get_size() == Vector2(2560, 1600), "%s texture is 2560x1600 (got %s)." % [expected, art.texture.get_size()])
    _check(art.get_global_rect().is_equal_approx(Rect2(0, 0, 1280, 800)), "%s covers the 1280x800 logical canvas (got %s)." % [expected, art.get_global_rect()])
    _check(art.stretch_mode == TextureRect.STRETCH_SCALE and art.expand_mode == TextureRect.EXPAND_IGNORE_SIZE, "%s is scaled to its rect." % expected)
    _check(art.mouse_filter == Control.MOUSE_FILTER_IGNORE, "%s ignores the mouse." % expected)
    _check(art.texture_filter == CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS and art.texture.get_image().has_mipmaps(), "%s is drawn with mipmaps." % expected)
    var tiles := _tiles(scene)
    _check(tiles.size() == 80 and tiles.all(func(t): return not t.visible), "All tiles are hidden in %s mode." % expected)
    for who in scene.battle.units:
        _check(scene.unit_node(who.id).visible, "%s is visible over the %s." % [who.name, expected])
    _check(scene.get_node("SelectedTile").visible, "The active unit's selection outline is visible.")
    var header := scene.get_node("HUD/TurnOrder") as Control
    var backing := scene.get_node_or_null("HUD/TurnOrderPanel") as Panel
    _check(backing != null and backing.visible, "%s mode backs the header with a panel." % expected)
    if backing != null:
        _check(backing.get_index() < header.get_index(), "The header panel is drawn behind the header text.")
        _check(backing.mouse_filter == Control.MOUSE_FILTER_IGNORE, "The header panel passes the mouse through, like the header.")
        for label in header.get_children():
            _check(backing.get_global_rect().encloses((label as Control).get_global_rect()), "The header panel encloses %s." % label.name)
    var build := scene.get_node("HUD/TurnOrder/BuildSeed") as Label
    if suffix.is_empty():
        _check(not build.text.contains("Guide") and not build.text.contains("Tiled"), "%s build line has no mode marker (got '%s')." % [expected, build.text])
    else:
        _check(build.text.ends_with(suffix), "%s build line ends with '%s' (got '%s')." % [expected, suffix, build.text])
    var font := build.get_theme_font("font")
    var width := font.get_string_size(build.text, HORIZONTAL_ALIGNMENT_LEFT, -1, build.get_theme_font_size("font_size")).x
    _check(width <= build.size.x, "The %s build line fits its label (%.0f of %.0f px)." % [expected, width, build.size.x])


# 4. Every guide mark matches the live camera within one logical pixel.
func _registration() -> void:
    var scene := await _open("guide", Vector2i(1280, 800))
    var marks = JSON.parse_string(FileAccess.get_file_as_string(MARKS_PATH))
    _check(marks is Dictionary, "Marks file parses.")
    if not marks is Dictionary:
        return
    var texture_size := Vector2(marks["texture_size"][0], marks["texture_size"][1])
    var logical_size := Vector2(marks["logical_size"][0], marks["logical_size"][1])
    _check(texture_size == Vector2(2560, 1600) and logical_size == Vector2(1280, 800), "Marks file describes the 2560x1600 guide on the 1280x800 canvas.")
    var camera: Camera3D = scene.get_camera()
    for mark in marks["marks"]:
        var world := Vector3(mark["world"][0], mark["world"][1], mark["world"][2])
        var logical := Vector2(mark["logical"][0], mark["logical"][1])
        var live := camera.unproject_position(world)
        var error := live.distance_to(logical)
        _check(error <= 1.0, "%s: guide %s vs live %s (%.2f px)." % [mark["name"], logical, live, error])
    _mark_count = marks["marks"].size()
    _check(_mark_count >= 93, "All vertex, centre, cell and spawn marks are present (%d)." % _mark_count)


# 5. Hover and clicks reach the battlefield in every mode at every window size.
func _pointer(mode: String) -> void:
    var seed := _hero_first_seed()
    for window in WINDOW_SIZES:
        var scene := await _open(mode, window)
        scene.auto_enemy = false
        scene.new_battle(seed)
        await _settle()
        for cell in POINTER_CELLS:
            await _push_motion(_window_point(scene, cell))
            _check(scene._hover_cell == cell, "%s mode at %s: hovering %s reaches %s." % [mode, window, cell, scene._hover_cell])
        var hero = scene.battle.active
        _check(hero.team == "hero", "Seed %d starts on a hero turn." % seed)
        var target := Vector2i(-1, -1)
        var options: Array = scene.reachable_overlay().keys()
        options.sort()
        for cell in options:
            var base: Vector2 = scene.get_camera().unproject_position(scene.cell_to_world(cell))
            if scene._cell_under(base) == cell:
                target = cell
                break
        _check(target != Vector2i(-1, -1), "%s mode at %s: a reachable cell is clickable." % [mode, window])
        await _push_click(_window_point(scene, target))
        _check(scene.battle.unit(hero.id).cell == target, "%s mode at %s: clicking %s moves %s there (now %s)." % [mode, window, target, hero.name, scene.battle.unit(hero.id).cell])
