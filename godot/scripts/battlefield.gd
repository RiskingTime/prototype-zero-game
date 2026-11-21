extends Node3D

# Alpha 0.1: pipeline and mouse-input demonstration only.
# Combat rules from HTML v0.13 have NOT yet been ported.
# Stage 1: fixed orthographic camera at 30° pitch and 45° yaw (2:1 pixel isometric).
# See GODOT_MIGRATION.md, "Camera and art conventions".

const GRID_WIDTH: int = 10
const GRID_DEPTH: int = 8
const CELL_SPACING: float = 1.0

const CAMERA_PITCH_DEG: float = 30.0
const CAMERA_YAW_DEG: float = 45.0
const CAMERA_DISTANCE: float = 30.0
const VIEWPORT_HEIGHT_PX: float = 800.0
# One cell is 128 px wide on screen at 1280×800 (pixel art shown at 2×).
# A cell's diagonal spans that width, so one world unit is 128 / sqrt(2) px.
const PIXELS_PER_UNIT: float = 90.50966799187809
const HIGHLIGHT_RENDER_PRIORITY: int = 10

var selected_cell: Vector2i = Vector2i(3, 3)

var _camera: Camera3D
var _pawn: MeshInstance3D
var _selection: Node3D
var _status: Label


func _ready() -> void:
    _build_lighting_and_camera()
    _build_board()
    _build_pawn_and_selection()
    _build_hud()
    move_to_cell(selected_cell)


func _build_lighting_and_camera() -> void:
    var environment_node := WorldEnvironment.new()
    environment_node.name = "Environment"
    var environment := Environment.new()
    environment.background_mode = Environment.BG_COLOR
    environment.background_color = Color(0.075, 0.10, 0.13)
    environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    environment.ambient_light_color = Color(0.85, 0.91, 1.0)
    environment.ambient_light_energy = 0.65
    environment_node.environment = environment
    add_child(environment_node)

    var sunlight := DirectionalLight3D.new()
    sunlight.name = "Sunlight"
    add_child(sunlight)
    sunlight.rotation_degrees = Vector3(-55.0, -25.0, 0.0)
    sunlight.light_energy = 1.1

    _camera = Camera3D.new()
    _camera.name = "IsometricCamera"
    _camera.projection = Camera3D.PROJECTION_ORTHOGONAL
    _camera.keep_aspect = Camera3D.KEEP_HEIGHT
    _camera.size = VIEWPORT_HEIGHT_PX / PIXELS_PER_UNIT
    add_child(_camera)
    var pitch := deg_to_rad(CAMERA_PITCH_DEG)
    var yaw := deg_to_rad(CAMERA_YAW_DEG)
    var toward_camera := Vector3(cos(pitch) * sin(yaw), sin(pitch), cos(pitch) * cos(yaw))
    _camera.position = toward_camera * CAMERA_DISTANCE
    _camera.look_at(Vector3.ZERO, Vector3.UP)
    _camera.current = true


func _build_board() -> void:
    for z in range(GRID_DEPTH):
        for x in range(GRID_WIDTH):
            var tile := MeshInstance3D.new()
            tile.name = "Tile_%d_%d" % [x, z]
            var box := BoxMesh.new()
            box.size = Vector3(CELL_SPACING - 0.04, 0.16, CELL_SPACING - 0.04)
            tile.mesh = box
            var color := Color(0.22, 0.34, 0.36)
            if (x + z) % 2 == 1:
                color = Color(0.18, 0.29, 0.31)
            tile.material_override = _material(color)
            tile.position = cell_to_world(Vector2i(x, z)) + Vector3(0, -0.08, 0)
            add_child(tile)


func _build_pawn_and_selection() -> void:
    # The selected cell is an outline drawn over units and cover, so it stays visible behind them.
    _selection = Node3D.new()
    _selection.name = "SelectedTile"
    var highlight := _highlight_material(Color(0.92, 0.68, 0.18))
    var inner := CELL_SPACING - 0.07
    var bar_width := 0.06
    for side in range(4):
        var bar := MeshInstance3D.new()
        bar.name = "Edge_%d" % side
        var bar_mesh := BoxMesh.new()
        var along_x := side < 2
        bar_mesh.size = Vector3(inner if along_x else bar_width, 0.01, bar_width if along_x else inner)
        bar.mesh = bar_mesh
        bar.material_override = highlight
        var offset := (inner - bar_width) / 2.0
        if along_x:
            bar.position = Vector3(0.0, 0.0, -offset if side == 0 else offset)
        else:
            bar.position = Vector3(-offset if side == 2 else offset, 0.0, 0.0)
        _selection.add_child(bar)
    add_child(_selection)

    _pawn = MeshInstance3D.new()
    _pawn.name = "Pawn"
    var capsule := CapsuleMesh.new()
    capsule.radius = 0.34
    capsule.height = 1.25
    _pawn.mesh = capsule
    _pawn.material_override = _material(Color(0.29, 0.65, 0.98))
    add_child(_pawn)


func _build_hud() -> void:
    var layer := CanvasLayer.new()
    layer.name = "HUD"
    add_child(layer)

    var card := PanelContainer.new()
    card.name = "Instructions"
    card.position = Vector2(20, 20)
    card.custom_minimum_size = Vector2(480, 0)
    card.mouse_filter = Control.MOUSE_FILTER_IGNORE
    layer.add_child(card)

    var stack := VBoxContainer.new()
    stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
    card.add_child(stack)

    var heading := Label.new()
    heading.text = "PROTOTYPE ZERO  |  GODOT ALPHA 0.1"
    heading.add_theme_font_size_override("font_size", 22)
    heading.mouse_filter = Control.MOUSE_FILTER_IGNORE
    stack.add_child(heading)

    var instructions := Label.new()
    instructions.text = "WINDOWS PIPELINE TEST  -  Click a tile to move the blue placeholder. ESC quits."
    instructions.mouse_filter = Control.MOUSE_FILTER_IGNORE
    stack.add_child(instructions)

    _status = Label.new()
    _status.name = "Status"
    _status.mouse_filter = Control.MOUSE_FILTER_IGNORE
    stack.add_child(_status)


func move_to_cell(cell: Vector2i) -> bool:
    if cell.x < 0 or cell.x >= GRID_WIDTH or cell.y < 0 or cell.y >= GRID_DEPTH:
        return false
    selected_cell = cell
    var world_pos := cell_to_world(cell)
    _selection.position = world_pos + Vector3(0, 0.01, 0)
    _pawn.position = world_pos + Vector3(0, 0.72, 0)
    if _status != null:
        _status.text = "Selected tile: (%d, %d)  |  No combat implemented yet." % [cell.x, cell.y]
    return true


func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey:
        var key := event as InputEventKey
        if key.pressed and key.keycode == KEY_ESCAPE:
            get_tree().quit()
            return

    if event is InputEventMouseButton:
        var click := event as InputEventMouseButton
        if click.pressed and click.button_index == MOUSE_BUTTON_LEFT:
            move_to_cell(screen_to_cell(click.position))


func get_camera() -> Camera3D:
    return _camera


# Grid cell under a screen position, found by casting a ray onto the ground plane (y = 0).
# The result can be off the board; move_to_cell rejects it. Returns (-1, -1) if the ray misses.
func screen_to_cell(screen_position: Vector2) -> Vector2i:
    var ray_origin := _camera.project_ray_origin(screen_position)
    var ray_direction := _camera.project_ray_normal(screen_position)
    var hit = Plane(Vector3.UP, 0.0).intersects_ray(ray_origin, ray_direction)
    if not (hit is Vector3):
        return Vector2i(-1, -1)
    var cell_x := int(round(hit.x / CELL_SPACING + float(GRID_WIDTH - 1) / 2.0))
    var cell_z := int(round(hit.z / CELL_SPACING + float(GRID_DEPTH - 1) / 2.0))
    return Vector2i(cell_x, cell_z)


# World position of a cell's centre on the ground plane. The board is centred on the origin.
func cell_to_world(cell: Vector2i) -> Vector3:
    return Vector3(
        (float(cell.x) - float(GRID_WIDTH - 1) / 2.0) * CELL_SPACING,
        0.0,
        (float(cell.y) - float(GRID_DEPTH - 1) / 2.0) * CELL_SPACING
    )


func _material(color: Color) -> StandardMaterial3D:
    var result := StandardMaterial3D.new()
    result.albedo_color = color
    result.metallic = 0.06
    result.roughness = 0.82
    return result


# Unshaded, drawn without depth testing and after other transparent objects, so it shows through units and cover.
func _highlight_material(color: Color) -> StandardMaterial3D:
    var result := StandardMaterial3D.new()
    result.albedo_color = color
    result.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    result.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    result.no_depth_test = true
    result.render_priority = HIGHLIGHT_RENDER_PRIORITY
    return result
