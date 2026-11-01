extends SceneTree

# Headless smoke test: load the battlefield and exercise its only interactive operation.
func _initialize() -> void:
    call_deferred("_verify")


func _verify() -> void:
    var scene := load("res://scenes/battlefield.tscn") as PackedScene
    if scene == null:
        printerr("SMOKE TEST FAILED: Battlefield scene cannot load.")
        quit(1)
        return

    var battlefield := scene.instantiate()
    root.add_child(battlefield)
    if battlefield.get_node_or_null("Pawn") == null:
        printerr("SMOKE TEST FAILED: Placeholder pawn is missing.")
        quit(1)
        return

    var target := Vector2i(0, 0)
    if not battlefield.call("move_to_cell", target):
        printerr("SMOKE TEST FAILED: Move to valid cell rejected.")
        quit(1)
        return
    if battlefield.get("selected_cell") != target:
        printerr("SMOKE TEST FAILED: Selected cell did not change.")
        quit(1)
        return
    if battlefield.call("move_to_cell", Vector2i(-1, 0)):
        printerr("SMOKE TEST FAILED: Invalid move was accepted.")
        quit(1)
        return

    print("SMOKE TEST PASSED: scene, pawn, valid click target, bounds checking.")
    quit(0)
