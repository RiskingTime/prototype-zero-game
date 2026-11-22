extends AspectRatioContainer


func _ready() -> void:
	$Artwork/NewGame.pressed.connect(_start_game)
	$Artwork/Settings.pressed.connect(_open_character_creation)


func _start_game() -> void:
	get_tree().change_scene_to_file("res://scenes/encounter.tscn")


func _open_character_creation() -> void:
	get_tree().change_scene_to_file("res://scenes/character_creation.tscn")
