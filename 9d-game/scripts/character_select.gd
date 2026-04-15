extends Control

@onready var grid: GridContainer = $HSplit/Left/Scroll/Grid
@onready var name_input: LineEdit = $HSplit/Right/NameInput
@onready var btn_start: Button = $HSplit/Right/BtnStart
@onready var btn_back: Button = $HSplit/Right/BtnBack
@onready var info_label: RichTextLabel = $HSplit/Right/InfoLabel
@onready var skills_label: RichTextLabel = $HSplit/Right/SkillsLabel

var selected_class: String = ""
var class_panels: Dictionary = {}

func _ready() -> void:
	btn_start.pressed.connect(_on_start)
	btn_back.pressed.connect(_on_back)
	_build_class_panels()

func _build_class_panels() -> void:
	for child in grid.get_children():
		child.queue_free()
	for class_name_str in GameData.CLASSES:
		var data = GameData.CLASSES[class_name_str]
		var panel = PanelContainer.new()
		panel.custom_minimum_size = Vector2(250, 180)
		var vbox = VBoxContainer.new()
		# Color header
		var color_rect = ColorRect.new()
		color_rect.color = data["color"]
		color_rect.custom_minimum_size = Vector2(0, 30)
		vbox.add_child(color_rect)
		# Name
		var lbl_name = Label.new()
		lbl_name.text = class_name_str
		lbl_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl_name.add_theme_font_size_override("font_size", 20)
		vbox.add_child(lbl_name)
		# Type
		var lbl_type = Label.new()
		lbl_type.text = data["type"]
		lbl_type.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl_type.add_theme_color_override("font_color", Color(0.8, 0.8, 0.5))
		vbox.add_child(lbl_type)
		# Stats
		var lbl_stats = Label.new()
		lbl_stats.text = "HP:%d  MP:%d  ATK:%d  DEF:%d" % [data["hp"], data["mp"], data["atk"], data["def"]]
		lbl_stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl_stats.add_theme_font_size_override("font_size", 12)
		vbox.add_child(lbl_stats)
		# Desc
		var lbl_desc = Label.new()
		lbl_desc.text = data["desc"]
		lbl_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl_desc.autowrap_mode = TextServer.AUTOWRAP_WORD
		lbl_desc.add_theme_font_size_override("font_size", 12)
		lbl_desc.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		vbox.add_child(lbl_desc)
		panel.add_child(vbox)
		# Click handler
		panel.gui_input.connect(_on_panel_input.bind(class_name_str))
		panel.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		grid.add_child(panel)
		class_panels[class_name_str] = panel
	# Select first class by default
	if not GameData.CLASSES.is_empty():
		_select_class(GameData.CLASSES.keys()[0])

func _on_panel_input(event: InputEvent, class_name_str: String) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_select_class(class_name_str)

func _select_class(class_name_str: String) -> void:
	selected_class = class_name_str
	# Highlight selected panel
	for cn in class_panels:
		var p: PanelContainer = class_panels[cn]
		if cn == class_name_str:
			var sb = StyleBoxFlat.new()
			sb.bg_color = Color(0.2, 0.15, 0.08)
			sb.border_color = Color(0.85, 0.65, 0.2)
			sb.border_width_left = 3
			sb.border_width_right = 3
			sb.border_width_top = 3
			sb.border_width_bottom = 3
			sb.corner_radius_top_left = 6
			sb.corner_radius_top_right = 6
			sb.corner_radius_bottom_left = 6
			sb.corner_radius_bottom_right = 6
			p.add_theme_stylebox_override("panel", sb)
		else:
			var sb = StyleBoxFlat.new()
			sb.bg_color = Color(0.12, 0.1, 0.08)
			sb.corner_radius_top_left = 4
			sb.corner_radius_top_right = 4
			sb.corner_radius_bottom_left = 4
			sb.corner_radius_bottom_right = 4
			p.add_theme_stylebox_override("panel", sb)
	# Update info
	var data = GameData.CLASSES[class_name_str]
	info_label.text = "[b]%s[/b]\n%s\n\n%s\n\nHP: %d | MP: %d\nATK: %d | DEF: %d\nSpeed: %.1f" % [
		class_name_str, data["type"], data["desc"],
		data["hp"], data["mp"], data["atk"], data["def"], data["speed"]
	]
	# Update skills
	var skills = GameData.get_skills(class_name_str)
	var stxt = "[b]Kỹ Năng:[/b]\n"
	for i in range(skills.size()):
		var s = skills[i]
		stxt += "\n[color=gold][%d][/color] %s\n" % [i + 1, s["name"]]
		stxt += "   %s | DMG: x%.1f | MP: %d | CD: %.1fs\n" % [s["desc"], s["dmg"], s["mp"], s["cd"]]
	skills_label.text = stxt

func _on_start() -> void:
	var pname = name_input.text.strip_edges()
	if pname.is_empty():
		name_input.placeholder_text = "Hãy nhập tên nhân vật!"
		return
	if selected_class.is_empty():
		return
	GameData.init_player(pname, selected_class)
	get_tree().change_scene_to_file("res://scenes/game_world.tscn")

func _on_back() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
