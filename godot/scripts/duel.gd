extends "res://scripts/battlefield.gd"

const DuelRules = preload("res://scripts/duel_rules.gd")
var battle := DuelRules.new(Vector2i(GRID_WIDTH, GRID_DEPTH))
var _foe: MeshInstance3D
var _turn_label: Label
var _log_label: Label
var _end_button: Button
var _enemy_timer: Timer


func _ready() -> void:
    super._ready()
    $HUD/Instructions.hide()
    _foe = MeshInstance3D.new()
    _foe.mesh = _pawn.mesh
    _foe.material_override = _material(Color(0.82, 0.25, 0.17))
    add_child(_foe)
    _enemy_timer = Timer.new()
    _enemy_timer.one_shot = true
    _enemy_timer.timeout.connect(_enemy_step)
    add_child(_enemy_timer)
    _build_duel_hud()
    restart()


func _build_duel_hud() -> void:
    var card := PanelContainer.new()
    $HUD.add_child(card)
    card.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
    card.offset_left = 20
    card.offset_right = -20
    card.offset_top = -102
    card.offset_bottom = -10
    var layout := HBoxContainer.new()
    card.add_child(layout)
    var details := VBoxContainer.new()
    details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    layout.add_child(details)
    _turn_label = Label.new()
    details.add_child(_turn_label)
    var help := Label.new()
    help.text = "Click an empty tile to move. Click the enemy while adjacent to attack. Esc quits."
    details.add_child(help)
    _log_label = Label.new()
    details.add_child(_log_label)
    _end_button = Button.new()
    _end_button.text = "End turn"
    _end_button.pressed.connect(end_player_turn)
    layout.add_child(_end_button)
    var restart_button := Button.new()
    restart_button.text = "Restart duel"
    restart_button.pressed.connect(restart)
    layout.add_child(restart_button)


func restart() -> void:
    _enemy_timer.stop()
    battle.restart()
    _refresh()
    _schedule_enemy()


func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
        get_tree().quit()
    elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
        play_cell(screen_to_cell(event.position))


func play_cell(cell: Vector2i) -> void:
    if battle.active != battle.hero or not battle.outcome.is_empty():
        return
    var attacking := cell == battle.enemy.cell
    var valid := battle.attack() if attacking else battle.move(cell)
    if not valid:
        _log_label.text = "Attack requires adjacency and 1 AP." if attacking else "That tile is out of reach."
        return
    _refresh()
    if battle.ap == 0:
        end_player_turn()


func end_player_turn() -> void:
    if battle.active != battle.hero or not battle.outcome.is_empty():
        return
    battle.end_turn()
    _refresh()
    _schedule_enemy()


func _enemy_step() -> void:
    if not battle.enemy_action() or battle.ap == 0:
        battle.end_turn()
    _refresh()
    _schedule_enemy()


func _schedule_enemy() -> void:
    if battle.active == battle.enemy and battle.outcome.is_empty():
        _enemy_timer.start(0.55)


func _refresh() -> void:
    move_to_cell(battle.hero.cell)
    _pawn.visible = battle.hero.hp > 0
    _selection.visible = _pawn.visible
    _foe.visible = battle.enemy.hp > 0
    _foe.position = cell_to_world(battle.enemy.cell) + Vector3(0, 0.72, 0)
    var turn := "%s turn · %d/%d AP" % [battle.active.title, battle.ap, DuelRules.MAX_AP]
    if not battle.outcome.is_empty():
        turn = battle.outcome
    _turn_label.text = "Round %d · %s | Knight %d/%d HP | Sword Brute %d/%d HP" % [
        battle.round_number, turn, battle.hero.hp, battle.hero.max_hp, battle.enemy.hp, battle.enemy.max_hp]
    _log_label.text = "\n".join(battle.log.slice(-2))
    _end_button.disabled = battle.active != battle.hero or not battle.outcome.is_empty()
