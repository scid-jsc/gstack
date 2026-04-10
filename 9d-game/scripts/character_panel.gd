extends Control

@onready var info_label: RichTextLabel = $Panel/VBox/Info

var is_open: bool = false

func _ready() -> void:
	visible = false

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_character"):
		toggle()
	elif event.is_action_pressed("cancel") and is_open:
		close()

func toggle() -> void:
	is_open = not is_open
	visible = is_open
	if is_open:
		_refresh()

func close() -> void:
	is_open = false
	visible = false

func _refresh() -> void:
	var exp_needed = GameData.exp_for_level(GameData.player_level)
	var weapon_bonus = ""
	var armor_bonus = ""
	if GameData.equipment["weapon"] != "":
		var wd = GameData.get_item_data(GameData.equipment["weapon"])
		weapon_bonus = " (+%d)" % wd.get("atk", 0)
	if GameData.equipment["armor"] != "":
		var ad = GameData.get_item_data(GameData.equipment["armor"])
		armor_bonus = " (+%d)" % ad.get("def", 0)
	info_label.text = """[center][b][color=gold]═══ Thông Tin Nhân Vật ═══[/color][/b][/center]

[b]Tên:[/b] %s
[b]Môn Phái:[/b] %s
[b]Cấp Độ:[/b] %d / %d

[color=gold]━━━ Chỉ Số ━━━[/color]
[color=red]HP:[/color] %d / %d
[color=cyan]MP:[/color] %d / %d
[color=orange]ATK:[/color] %d%s
[color=steelblue]DEF:[/color] %d%s
[color=green]Speed:[/color] %.1f

[color=gold]━━━ Kinh Nghiệm ━━━[/color]
EXP: %d / %d

[color=gold]━━━ Thành Tích ━━━[/color]
Số lần hạ gục: %d
Vàng: %d
""" % [
		GameData.player_name, GameData.player_class,
		GameData.player_level, GameData.MAX_LEVEL,
		GameData.player_hp, GameData.player_max_hp,
		GameData.player_mp, GameData.player_max_mp,
		GameData.player_atk, weapon_bonus,
		GameData.player_def, armor_bonus,
		GameData.player_speed,
		GameData.player_exp, exp_needed,
		GameData.player_kill_count, GameData.player_gold,
	]
