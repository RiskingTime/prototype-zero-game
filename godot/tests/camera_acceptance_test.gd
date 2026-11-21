extends SceneTree

const Battlefield = preload("res://scripts/battlefield.gd")
const VIEW_SIZE := Vector2(1280, 800)
const COLS := 10
const ROWS := 8
var board: Battlefield
var camera: Camera3D
var failures := 0


func _initialize() -> void:
    call_deferred("_verify")


func _check(number: int, ok: bool, detail: String) -> void:
    if ok:
        print("CAMERA AC%d PASSED: %s" % [number, detail])
    else:
        failures += 1
        printerr("CAMERA AC%d FAILED: %s" % [number, detail])


func _verify() -> void:
    var scene := load("res://scenes/battlefield.tscn") as PackedScene
    if scene != null:
        board = scene.instantiate() as Battlefield
    if board == null:
        printerr("CAMERA ACCEPTANCE FAILED: Cannot instantiate battlefield.")
        quit(1)
        return
    root.add_child(board)
    await process_frame
    await process_frame  # Let the HUD containers complete layout.
    camera = board.get_camera()
    if camera == null or root.get_camera_3d() != camera or root.get_visible_rect().size != VIEW_SIZE:
        printerr("CAMERA ACCEPTANCE FAILED: Expected active battlefield camera at 1280 x 800.")
        quit(1)
        return

    var back := camera.global_basis.z.normalized()
    var pitch := rad_to_deg(asin(back.y))
    var yaw := rad_to_deg(atan2(back.x, back.z))
    var target_error := camera.unproject_position(Vector3.ZERO).distance_to(VIEW_SIZE / 2)
    _check(1, camera.projection == Camera3D.PROJECTION_ORTHOGONAL
        and absf(pitch - 30) <= 0.01 and absf(yaw - 45) <= 0.01
        and not camera.is_position_behind(Vector3.ZERO) and target_error <= 0.1,
        "pitch %.4f, yaw %.4f, origin %.3f px from centre" % [pitch, yaw, target_error])

    var grid_ok := is_equal_approx(board.CELL_SPACING, 1.0)
    var mismatches: Array[Vector2i] = []
    for z in range(ROWS):
        for x in range(COLS):
            var cell := Vector2i(x, z)
            var world := board.cell_to_world(cell)
            var expected := Vector3(x - (COLS - 1) * 0.5, 0, z - (ROWS - 1) * 0.5)
            grid_ok = grid_ok and world.is_equal_approx(expected)
            if board.screen_to_cell(camera.unproject_position(world)) != cell:
                mismatches.append(cell)
    _check(2, grid_ok, "10 x 8 cell centres on a centred unit grid")

    var half_x := (board.cell_to_world(Vector2i.RIGHT) - board.cell_to_world(Vector2i.ZERO)) / 2
    var half_z := (board.cell_to_world(Vector2i.DOWN) - board.cell_to_world(Vector2i.ZERO)) / 2
    var first := board.cell_to_world(Vector2i.ZERO)
    var footprint := _quad(first, half_x, half_z)
    var bounds := Rect2(footprint[0], Vector2.ZERO)
    for p in footprint:
        bounds = bounds.expand(p)
    _check(3, absf(bounds.size.x - 128) <= 1 and absf(bounds.size.y - 64) <= 1,
        "projected cell footprint %s px" % bounds.size)

    var last := board.cell_to_world(Vector2i(COLS - 1, ROWS - 1))
    var corners := _quad((first + last) / 2, COLS * half_x, ROWS * half_z)
    _check_framing(corners, first)
    _check(5, mismatches.is_empty(), "%d/80 round trips correct. Mismatches %s"
        % [COLS * ROWS - mismatches.size(), mismatches])

    var target := Vector2i(7, 5)
    var started_elsewhere := board.selected_cell != target
    _click(camera.unproject_position(board.cell_to_world(target)))
    var selected := board.selected_cell == target
    # Inside the viewport but outside the board and HUD.
    _click(Vector2(1240, 740))
    _check(6, started_elsewhere and selected and board.selected_cell == target,
        "left click selected target=%s, selection after off-board click=%s" % [selected, board.selected_cell])

    var outline := board.get_node_or_null("SelectedTile")
    var good_edges := 0
    if outline != null:
        for child in outline.get_children():
            var edge := child as MeshInstance3D
            if edge != null and edge.mesh != null and edge.mesh.get_surface_count() > 0:
                var material := edge.get_active_material(0) as BaseMaterial3D
                if material != null and material.no_depth_test:
                    good_edges += 1
    _check(7, outline != null and outline.get_child_count() == 4 and good_edges == 4,
        "%d outline edges use a material with depth testing disabled" % good_edges)

    if failures > 0:
        printerr("CAMERA ACCEPTANCE FAILED: %d failed criteria." % failures)
        quit(1)
    else:
        print("CAMERA ACCEPTANCE PASSED: criteria 1-7.")
        quit(0)


func _quad(centre: Vector3, dx: Vector3, dz: Vector3) -> PackedVector2Array:
    var points := PackedVector2Array()
    for corner: Vector3 in [centre - dx - dz, centre + dx - dz, centre + dx + dz, centre - dx + dz]:
        points.append(camera.unproject_position(corner))
    return points


func _margin(p: Vector2) -> float:
    return minf(minf(p.x, VIEW_SIZE.x - p.x), minf(p.y, VIEW_SIZE.y - p.y))


func _check_framing(corners: PackedVector2Array, back_cell: Vector3) -> void:
    var pawn := board.get_node_or_null("Pawn") as MeshInstance3D
    var card := board.get_node_or_null("HUD/Instructions") as Control
    if pawn == null or pawn.mesh == null or card == null or not board.move_to_cell(Vector2i.ZERO):
        _check(4, false, "Cannot measure pawn on back cell and HUD card.")
        return
    var box := pawn.get_aabb()
    var top := box.get_center() + Vector3.UP * box.size.y / 2
    var pawn_margin := _margin(camera.unproject_position(pawn.to_global(top)))
    var pawn_on_back := Vector2(pawn.global_position.x, pawn.global_position.z).is_equal_approx(
        Vector2(back_cell.x, back_cell.z))
    var board_margin := INF
    for corner in corners:
        board_margin = minf(board_margin, _margin(corner))
    var rect := card.get_global_rect()
    var hud := PackedVector2Array([rect.position, Vector2(rect.end.x, rect.position.y),
        rect.end, Vector2(rect.position.x, rect.end.y)])
    var clear := Geometry2D.intersect_polygons(corners, hud).is_empty()
    _check(4, pawn_on_back and pawn_margin >= 8 and board_margin >= 8
        and card.is_visible_in_tree() and rect.has_area() and clear,
        "board margin %.2f px, pawn top margin %.2f px, HUD clear=%s" % [board_margin, pawn_margin, clear])


func _click(point: Vector2) -> void:
    for pressed: bool in [true, false]:
        var event := InputEventMouseButton.new()
        event.position = point
        event.global_position = point
        event.button_index = MOUSE_BUTTON_LEFT
        event.pressed = pressed
        event.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
        root.push_input(event, true)
