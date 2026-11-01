extends Node3D

# Alpha 0.1: pipeline and mouse-input demonstration only.
# Combat rules from HTML v0.13 have NOT yet been ported.

const GRID_WIDTH: int = 10
const GRID_DEPTH: int = 8
const CELL_SPACING: float = 1.1

var selected_cell: Vector2i = Vector2i(3, 3)

var _camera: Camera3D
var _pawn: MeshInstance3D
var _selection: MeshInstance3D
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
    _camera.size = 14.5
    _camera.position = Vector3(10.0, 13.0, 12.0)
    add_child(_camera)
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
            tile.position = _cell_world_position(Vector2i(x, z)) + Vector3(0, -0.08, 0)
            add_child(tile)


func _build_pawn_and_selection() -> void:
    _selection = MeshInstance3D.new()
    _selection.name = "SelectedTile"
    var selection_mesh := BoxMesh.new()
    selection_mesh.size = Vector3(CELL_SPACING - 0.07, 0.05, CELL_SPACING - 0.07)
    _selection.mesh = selection_mesh
    _selection.material_override = _material(Color(0.92, 0.68, 0.18))
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
    var world_pos := _cell_world_position(cell)
    _selection.position = world_pos + Vector3(0, 0.035, 0)
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
            var ray_origin := _camera.project_ray_origin(click.position)
            var ray_direction := _camera.project_ray_normal(click.position)
            var hit = Plane(Vector3.UP, 0.0).intersects_ray(ray_origin, ray_direction)
            if hit is Vector3:
                var cell_x := int(round(hit.x / CELL_SPACING + float(GRID_WIDTH - 1) / 2.0))
                var cell_z := int(round(hit.z / CELL_SPACING + float(GRID_DEPTH - 1) / 2.0))
                move_to_cell(Vector2i(cell_x, cell_z))


func _cell_world_position(cell: Vector2i) -> Vector3:
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
