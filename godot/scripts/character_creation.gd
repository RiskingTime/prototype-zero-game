extends CenterContainer


func _ready() -> void:
	$Panel/Back.grab_focus()


func _return_to_menu() -> void:
	get_tree().change_scene_to_file("res://scenes/opening_screen.tscn")
