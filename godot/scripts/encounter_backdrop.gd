extends "res://scripts/encounter.gd"

# Painted backdrops for the encounter, drawn behind the board as the environment's 2D canvas
# background, so the 3D camera, the art and the pointer share one 1280x800 logical canvas.
# A normal launch shows the approved Mossgate painting. "--backdrop=guide" shows the
# registration guide and "--backdrop=tiles" shows the original tiled board instead.
# encounter.gd is unchanged.

const BACKDROP_PAINTING := "painting"
const BACKDROP_GUIDE := "guide"
const BACKDROP_TILES := "tiles"
const BACKDROP_GUIDE_ARGUMENT := "--backdrop=guide"
const BACKDROP_TILES_ARGUMENT := "--backdrop=tiles"
const BACKDROP_TEXTURES := {
    BACKDROP_PAINTING: "res://assets/backdrops/mossgate_by_day_2560x1600.png",
    BACKDROP_GUIDE: "res://assets/debug/registration_guide.svg",
}
const BACKDROP_BUILD_SUFFIX := {
    BACKDROP_PAINTING: "",
    BACKDROP_GUIDE: " · Guide backdrop",
    BACKDROP_TILES: " · Tiled board",
}
const BACKDROP_RECT := Rect2(0, 0, 1280, 800)
const BACKDROP_LAYER := -1

# "" resolves from the launch arguments in _ready(); tests set it before adding the scene.
var backdrop_mode := ""


func _ready() -> void:
    if backdrop_mode.is_empty():
        backdrop_mode = backdrop_mode_from_args(OS.get_cmdline_user_args(), OS.get_cmdline_args())
    super._ready()
    if BACKDROP_TEXTURES.has(backdrop_mode):
        _apply_backdrop(BACKDROP_TEXTURES[backdrop_mode])


# "--backdrop=guide" or "--backdrop=tiles" may be passed after "--" / "++" (user arguments)
# or on its own (engine arguments). Anything else shows the painting.
static func backdrop_mode_from_args(user_args: PackedStringArray, engine_args: PackedStringArray) -> String:
    if user_args.has(BACKDROP_GUIDE_ARGUMENT) or engine_args.has(BACKDROP_GUIDE_ARGUMENT):
        return BACKDROP_GUIDE
    if user_args.has(BACKDROP_TILES_ARGUMENT) or engine_args.has(BACKDROP_TILES_ARGUMENT):
        return BACKDROP_TILES
    return BACKDROP_PAINTING


func _refresh_hud() -> void:
    super._refresh_hud()
    _build_label.text += BACKDROP_BUILD_SUFFIX.get(backdrop_mode, "")


# Draws the art as the canvas background (layers up to -1), hides the tile meshes and backs
# the turn-order header with a panel so it stays readable over the art. The art never takes
# mouse input, so hover and clicks still reach the battlefield.
func _apply_backdrop(texture_path: String) -> void:
    var environment := ($Environment as WorldEnvironment).environment
    environment.background_mode = Environment.BG_CANVAS
    environment.background_canvas_max_layer = BACKDROP_LAYER

    var layer := CanvasLayer.new()
    layer.name = "Backdrop"
    layer.layer = BACKDROP_LAYER
    add_child(layer)
    var art := TextureRect.new()
    art.name = "Art"
    art.texture = load(texture_path)
    art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    art.stretch_mode = TextureRect.STRETCH_SCALE
    art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
    art.mouse_filter = Control.MOUSE_FILTER_IGNORE
    art.position = BACKDROP_RECT.position
    art.size = BACKDROP_RECT.size
    layer.add_child(art)

    for child in get_children():
        if String(child.name).begins_with("Tile_"):
            child.hide()

    var header := $HUD/TurnOrder as Control
    var backing := Panel.new()
    backing.name = "TurnOrderPanel"
    backing.mouse_filter = Control.MOUSE_FILTER_IGNORE
    backing.add_theme_stylebox_override("panel", _theme.get_stylebox("panel", "PanelContainer"))
    $HUD.add_child(backing)
    $HUD.move_child(backing, header.get_index())
    header.resized.connect(_fit_header_panel)
    _fit_header_panel()


func _fit_header_panel() -> void:
    var backing := get_node_or_null("HUD/TurnOrderPanel") as Panel
    if backing == null:
        return
    var header := $HUD/TurnOrder as Control
    var rect := Rect2(header.position, header.size).grow(6)
    backing.position = rect.position
    backing.size = rect.size
