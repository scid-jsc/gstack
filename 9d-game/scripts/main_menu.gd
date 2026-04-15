extends Control

@onready var btn_new: Button = $VBox/BtnNew
@onready var btn_continue: Button = $VBox/BtnContinue
@onready var btn_exit: Button = $VBox/BtnExit

func _ready() -> void:
	btn_continue.disabled = not GameData.has_save()
	btn_new.pressed.connect(_on_new)
	btn_continue.pressed.connect(_on_continue)
	btn_exit.pressed.connect(_on_exit)
	# Fade in
	modulate.a = 0.0
	var tw = create_tween()
	tw.tween_property(self, "modulate:a", 1.0, 0.8)

func _on_new() -> void:
	get_tree().change_scene_to_file("res://scenes/character_select.tscn")

func _on_continue() -> void:
	if GameData.load_game():
		get_tree().change_scene_to_file("res://scenes/game_world.tscn")

func _on_exit() -> void:
	get_tree().quit()
