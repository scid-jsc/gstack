extends Control

@onready var player_name_label: Label = $TopLeft/PlayerInfo/NameLabel
@onready var hp_bar: ProgressBar = $TopLeft/PlayerInfo/HPBar
@onready var hp_label: Label = $TopLeft/PlayerInfo/HPBar/HPLabel
@onready var mp_bar: ProgressBar = $TopLeft/PlayerInfo/MPBar
@onready var mp_label: Label = $TopLeft/PlayerInfo/MPBar/MPLabel
@onready var exp_bar: ProgressBar = $TopLeft/PlayerInfo/EXPBar
@onready var level_label: Label = $TopLeft/PlayerInfo/LevelLabel
@onready var zone_label: Label = $TopLeft/PlayerInfo/ZoneLabel
@onready var skill_bar: HBoxContainer = $Bottom/SkillBar
@onready var chat_log: RichTextLabel = $BottomLeft/ChatLog
@onready var target_frame: PanelContainer = $TopCenter/TargetFrame
@onready var target_name_label: Label = $TopCenter/TargetFrame/VBox/TargetName
@onready var target_hp_bar: ProgressBar = $TopCenter/TargetFrame/VBox/TargetHP
@onready var target_hp_label: Label = $TopCenter/TargetFrame/VBox/TargetHP/TargetHPLabel

var skill_buttons: Array[PanelContainer] = []
var skill_cooldown_overlays: Array[ColorRect] = []
var skill_cooldown_timers: Array[float] = [0.0, 0.0, 0.0, 0.0]
var skill_cooldown_max: Array[float] = [0.0, 0.0, 0.0, 0.0]
var current_zone: String = ""

func _ready() -> void:
	target_frame.visible = false
	_build_skill_bar()
	_connect_signals()
	add_chat("Chào mừng đến với 9D Cửu Long Tranh Bá!", Color.GOLD)
	add_chat("WASD di chuyển, Click chuột chọn mục tiêu, 1-4 dùng kỹ năng", Color.WHITE)

func _connect_signals() -> void:
	EventBus.player_damaged.connect(_on_player_damaged)
	EventBus.player_healed.connect(_on_player_healed)
	EventBus.player_died.connect(_on_player_died)
	EventBus.player_respawned.connect(_on_player_respawned)
	EventBus.player_leveled_up.connect(_on_player_leveled_up)
	EventBus.monster_killed.connect(_on_monster_killed)
	EventBus.item_picked_up.connect(_on_item_picked_up)
	EventBus.gold_picked_up.connect(_on_gold_picked_up)
	EventBus.skill_used.connect(_on_skill_used)
	EventBus.skill_cooldown_started.connect(_on_skill_cd)
	EventBus.target_changed.connect(_on_target_changed)
	EventBus.zone_changed.connect(_on_zone_changed)
	EventBus.chat_message.connect(_on_chat_message)
	EventBus.show_notification.connect(_on_notification)

func _build_skill_bar() -> void:
	for child in skill_bar.get_children():
		child.queue_free()
	skill_buttons.clear()
	skill_cooldown_overlays.clear()
	var skills = GameData.get_skills(GameData.player_class)
	for i in range(4):
		var panel = PanelContainer.new()
		panel.custom_minimum_size = Vector2(100, 60)
		var sb = StyleBoxFlat.new()
		sb.bg_color = Color(0.15, 0.1, 0.05)
		sb.border_color = Color(0.7, 0.55, 0.2)
		sb.border_width_left = 2
		sb.border_width_right = 2
		sb.border_width_top = 2
		sb.border_width_bottom = 2
		sb.corner_radius_top_left = 4
		sb.corner_radius_top_right = 4
		sb.corner_radius_bottom_left = 4
		sb.corner_radius_bottom_right = 4
		panel.add_theme_stylebox_override("panel", sb)
		var vbox = VBoxContainer.new()
		var key_lbl = Label.new()
		key_lbl.text = "[%d]" % (i + 1)
		key_lbl.add_theme_font_size_override("font_size", 10)
		key_lbl.add_theme_color_override("font_color", Color.GOLD)
		key_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(key_lbl)
		var name_lbl = Label.new()
		if i < skills.size():
			name_lbl.text = skills[i]["name"]
		else:
			name_lbl.text = "---"
		name_lbl.add_theme_font_size_override("font_size", 12)
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(name_lbl)
		var mp_lbl = Label.new()
		if i < skills.size():
			mp_lbl.text = "MP: %d" % skills[i]["mp"]
		mp_lbl.add_theme_font_size_override("font_size", 10)
		mp_lbl.add_theme_color_override("font_color", Color(0.4, 0.6, 1.0))
		mp_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(mp_lbl)
		panel.add_child(vbox)
		# Cooldown overlay
		var cd_overlay = ColorRect.new()
		cd_overlay.color = Color(0.0, 0.0, 0.0, 0.6)
		cd_overlay.visible = false
		cd_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
		cd_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_child(cd_overlay)
		skill_bar.add_child(panel)
		skill_buttons.append(panel)
		skill_cooldown_overlays.append(cd_overlay)

func _process(delta: float) -> void:
	_update_bars()
	_update_cooldowns(delta)
	_update_target_frame()

func _update_bars() -> void:
	player_name_label.text = "%s [%s]" % [GameData.player_name, GameData.player_class]
	hp_bar.max_value = GameData.player_max_hp
	hp_bar.value = GameData.player_hp
	hp_label.text = "%d / %d" % [GameData.player_hp, GameData.player_max_hp]
	mp_bar.max_value = GameData.player_max_mp
	mp_bar.value = GameData.player_mp
	mp_label.text = "%d / %d" % [GameData.player_mp, GameData.player_max_mp]
	var exp_needed = GameData.exp_for_level(GameData.player_level)
	exp_bar.max_value = exp_needed
	exp_bar.value = GameData.player_exp
	level_label.text = "Lv.%d  EXP: %d/%d" % [GameData.player_level, GameData.player_exp, exp_needed]
	zone_label.text = current_zone

func _update_cooldowns(delta: float) -> void:
	for i in range(4):
		if skill_cooldown_timers[i] > 0:
			skill_cooldown_timers[i] -= delta
			skill_cooldown_overlays[i].visible = true
		else:
			skill_cooldown_timers[i] = 0.0
			skill_cooldown_overlays[i].visible = false

func _update_target_frame() -> void:
	# Updated externally via signal
	pass

func add_chat(text: String, color: Color = Color.WHITE) -> void:
	chat_log.push_color(color)
	chat_log.append_text(text + "\n")
	chat_log.pop()

# --- Signal handlers ---

func _on_player_damaged(amount: int) -> void:
	add_chat("Bạn nhận %d sát thương!" % amount, Color.RED)

func _on_player_healed(amount: int) -> void:
	add_chat("Hồi phục %d HP!" % amount, Color.GREEN)

func _on_player_died() -> void:
	add_chat("Bạn đã bị hạ! Nhấn F để hồi sinh.", Color.RED)

func _on_player_respawned() -> void:
	add_chat("Đã hồi sinh tại Tân Thủ Thôn.", Color.YELLOW)

func _on_player_leveled_up(new_level: int) -> void:
	add_chat("CHÚC MỪNG! Lên cấp %d!" % new_level, Color.GOLD)

func _on_monster_killed(monster: Node) -> void:
	if monster and monster.has_method("get_monster_name"):
		var mname = monster.get_monster_name()
		add_chat("Hạ gục %s! +%d EXP" % [mname, monster.exp_reward], Color.YELLOW)

func _on_item_picked_up(item_name: String, count: int) -> void:
	add_chat("Nhận được: %s x%d" % [item_name, count], Color.AQUA)

func _on_gold_picked_up(amount: int) -> void:
	add_chat("+%d Vàng" % amount, Color.GOLD)

func _on_skill_used(skill_index: int, skill_name: String) -> void:
	add_chat("Sử dụng: %s" % skill_name, Color(0.8, 0.7, 0.3))

func _on_skill_cd(skill_index: int, cooldown: float) -> void:
	if skill_index >= 0 and skill_index < 4:
		skill_cooldown_timers[skill_index] = cooldown
		skill_cooldown_max[skill_index] = cooldown

func _on_target_changed(target: Node) -> void:
	if target == null:
		target_frame.visible = false
		return
	target_frame.visible = true
	if target is MonsterAI:
		target_name_label.text = "%s Lv.%d" % [target.monster_name, target.monster_level]
		target_hp_bar.max_value = target.max_hp
		target_hp_bar.value = target.current_hp
		target_hp_label.text = "%d / %d" % [target.current_hp, target.max_hp]

func _on_zone_changed(zone_name: String) -> void:
	current_zone = zone_name
	add_chat("Đến khu vực: %s" % zone_name, Color(0.6, 0.8, 1.0))

func _on_chat_message(text: String, color: Color) -> void:
	add_chat(text, color)

func _on_notification(text: String) -> void:
	add_chat("[!] %s" % text, Color.YELLOW)
