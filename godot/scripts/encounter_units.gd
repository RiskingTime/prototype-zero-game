extends "res://scripts/encounter_backdrop.gd"

# Battlefield sprites. Each unit keeps its combat ID, cell and rules; only its look changes.
# A camera-facing Sprite3D shows one of eight idle facings (128 x 128 pixel art drawn 1:1 at
# the 1280 x 800 logical size), anchored at the feet on the cell centre. The unit's capsule
# stays as invisible picking geometry, sized to the sprite, so torso clicks keep working.
# Units without art keep their placeholder capsule. The active unit's gold diamond is
# depth-tested here, so a unit standing in front of it hides it. encounter.gd is unchanged.

const FACINGS := ["east", "south-east", "south", "south-west", "west", "north-west", "north", "north-east"]
# One screen pixel per sprite pixel at 1280 x 800: one world unit is 128 / sqrt(2) px.
const SPRITE_PIXEL_SIZE := 1.0 / 90.50966799187809
const SPRITE_CANVAS := 128
const SPRITE_ANCHOR_X := 64
# A vertical world length h appears h * cos(30°) * 90.51 px tall on screen.
const SCREEN_PX_PER_VERTICAL_UNIT := 0.8660254037844386 * 90.50966799187809
const LABEL_GAP_PX := 12.0

# slug: art folder; anchor_y: canvas row of the grounded feet; head_y: top of the figure;
# half_width: torso half-width in canvas px for the pick capsule; scale: on-screen size.
# The Ogre is drawn at 1.25 so it reads larger than the humans (James, Checkpoint 1).
const UNIT_ART := {
    "K": {"slug": "knight", "anchor_y": 118, "head_y": 8, "half_width": 26, "scale": 1.0},
    "A": {"slug": "field_archer", "anchor_y": 118, "head_y": 8, "half_width": 23, "scale": 1.0},
    "W": {"slug": "travelling_wizard", "anchor_y": 118, "head_y": 8, "half_width": 25, "scale": 1.0},
    "C": {"slug": "field_cleric", "anchor_y": 118, "head_y": 8, "half_width": 24, "scale": 1.0},
    "S": {"slug": "ogre_gate_porter", "anchor_y": 118, "head_y": 8, "half_width": 34, "scale": 1.25},
    "L": {"slug": "rampart_sentry", "anchor_y": 121, "head_y": 4, "half_width": 24, "scale": 1.0},
    "B": {"slug": "mossgate_bowman", "anchor_y": 120, "head_y": 6, "half_width": 26, "scale": 1.0},
    "M": {"slug": "ash_examiner", "anchor_y": 117, "head_y": 9, "half_width": 20, "scale": 1.0},
}

var _sprites := {}
var _textures := {}
var _facing := {}
var _seen_cells := {}
var _seen_action := 0


static func facing_for(delta: Vector2) -> String:
    # Grid x runs down-right on screen and grid z down-left; a cell step (dx, dz) appears
    # as (dx - dz, (dx + dz) / 2) in screen proportions (y down).
    var screen := Vector2(delta.x - delta.y, (delta.x + delta.y) * 0.5)
    if screen.length_squared() < 0.0001:
        return ""
    var sector := wrapi(int(round(screen.angle() / (PI / 4.0))), 0, 8)
    return FACINGS[sector]


static func art_path(slug: String, facing: String) -> String:
    return "res://assets/units/%s/%s.png" % [slug, facing]


func unit_sprite(id: String) -> Sprite3D:
    return _sprites.get(id)


func unit_facing(id: String) -> String:
    return _facing.get(id, "")


func _build_units() -> void:
    super._build_units()
    for id in _unit_nodes:
        if UNIT_ART.has(id):
            _dress_unit(id, UNIT_ART[id])
    _depth_test_selection()


# battlefield.gd draws the selected-cell outline over everything (no depth test), which
# suited the capsules. With sprites, units in front of the active unit should cover it.
func _depth_test_selection() -> void:
    var material: StandardMaterial3D = null
    for bar in _selection.get_children():
        if bar is MeshInstance3D and bar.material_override is StandardMaterial3D:
            if material == null:
                material = (bar.material_override as StandardMaterial3D).duplicate()
                material.no_depth_test = false
            bar.material_override = material


# Hides the capsule (it stays as picking geometry), adds the sprite at the feet, resizes the
# capsule to the figure and moves the HP label above the head.
func _dress_unit(id: String, art: Dictionary) -> void:
    var node: MeshInstance3D = _unit_nodes[id]
    node.layers = 0
    var size_scale: float = art["scale"]
    var figure_px: float = (art["anchor_y"] - art["head_y"]) * size_scale
    var height: float = figure_px / SCREEN_PX_PER_VERTICAL_UNIT
    var radius: float = clampf(art["half_width"] * size_scale * SPRITE_PIXEL_SIZE, 0.22, 0.45)
    var capsule := CapsuleMesh.new()
    capsule.radius = radius
    capsule.height = maxf(height, radius * 2.0)
    node.mesh = capsule
    node.set_meta("pick_centre", capsule.height * 0.5)

    var sprite := Sprite3D.new()
    sprite.name = "Sprite"
    sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    sprite.shaded = false
    sprite.double_sided = true
    sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
    sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
    sprite.pixel_size = SPRITE_PIXEL_SIZE * size_scale
    sprite.centered = true
    # Put the feet (SPRITE_ANCHOR_X, anchor_y) on the node origin.
    sprite.offset = Vector2(SPRITE_CANVAS / 2.0 - SPRITE_ANCHOR_X, art["anchor_y"] - SPRITE_CANVAS / 2.0)
    node.add_child(sprite)
    _sprites[id] = sprite
    var textures := {}
    for facing in FACINGS:
        textures[facing] = load(art_path(art["slug"], facing))
    _textures[id] = textures

    for child in node.get_children():
        if child is Label3D and child != _hp_labels[id]:
            child.hide()
    var label_height: float = (figure_px + LABEL_GAP_PX) / SCREEN_PX_PER_VERTICAL_UNIT
    node.set_meta("label_height", label_height)


func _start(battle_seed: int) -> void:
    _facing.clear()
    _seen_cells.clear()
    _seen_action = 0
    super._start(battle_seed)


func _refresh_board() -> void:
    super._refresh_board()
    _update_facings()
    for who in battle.units:
        var node: MeshInstance3D = _unit_nodes[who.id]
        var hp: Label3D = _hp_labels[who.id]
        if UNIT_ART.has(who.id):
            var centre: float = node.get_meta("pick_centre")
            node.position.y = centre
            var sprite: Sprite3D = _sprites[who.id]
            sprite.position = Vector3(0, -centre, 0)
            sprite.texture = _textures[who.id][_facing[who.id]]
            hp.position = Vector3(0, float(node.get_meta("label_height")) - centre, 0)
            hp.text = "%s %s" % [who.id, hp.text]


# Spawn: face the nearest living opponent. Movement: face the step direction. Acting: face
# the target. A unit moved by Force Push keeps facing whoever pushed it.
func _update_facings() -> void:
    var action: Dictionary = battle.last_action
    var count := int(action.get("count", 0))
    var new_action := count != _seen_action
    for who in battle.units:
        var previous = _seen_cells.get(who.id)
        if previous == null or not _facing.has(who.id):
            _facing[who.id] = _face_nearest_opponent(who)
        elif previous != who.cell:
            var pushed: bool = new_action and action.get("target") == who.id and action.get("id") == "force_push"
            if pushed:
                var pusher = battle.unit(action["actor"])
                _facing[who.id] = _towards(who.cell, pusher.cell, _facing[who.id])
            else:
                _facing[who.id] = _towards(previous, who.cell, _facing[who.id])
        _seen_cells[who.id] = who.cell
    if new_action:
        _seen_action = count
        var actor = battle.unit(action.get("actor", ""))
        var target = battle.unit(action.get("target", ""))
        if actor != null and target != null and actor != target:
            _facing[actor.id] = _towards(actor.cell, target.cell, _facing[actor.id])


func _towards(from: Vector2i, to: Vector2i, fallback: String) -> String:
    var facing := facing_for(Vector2(to - from))
    return fallback if facing.is_empty() else facing


func _face_nearest_opponent(who) -> String:
    var best = null
    var best_distance := 9999
    for other in battle.units:
        if other.team == who.team or not other.alive():
            continue
        var distance: int = battle.distance(who.cell, other.cell)
        if distance < best_distance:
            best_distance = distance
            best = other
    if best == null:
        return "south"
    return _towards(who.cell, best.cell, "south")
