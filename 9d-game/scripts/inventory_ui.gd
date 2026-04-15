extends Control

@onready var item_grid: GridContainer = $Panel/VBox/Scroll/ItemGrid
@onready var weapon_label: Label = $Panel/VBox/Equipment/WeaponLabel
@onready var armor_label: Label = $Panel/VBox/Equipment/ArmorLabel
@onready var gold_label: Label = $Panel/VBox/GoldLabel

var is_open: bool = false

func _ready() -> void:
	visible = false
	EventBus.inventory_changed.connect(_refresh)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_inventory"):
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
	# Equipment
	if GameData.equipment["weapon"] != "":
		var wd = GameData.get_item_data(GameData.equipment["weapon"])
		weapon_label.text = "Vũ Khí: %s (%s)" % [GameData.equipment["weapon"], wd.get("desc", "")]
	else:
		weapon_label.text = "Vũ Khí: (trống)"
	if GameData.equipment["armor"] != "":
		var ad = GameData.get_item_data(GameData.equipment["armor"])
		armor_label.text = "Giáp: %s (%s)" % [GameData.equipment["armor"], ad.get("desc", "")]
	else:
		armor_label.text = "Giáp: (trống)"
	gold_label.text = "Vàng: %d" % GameData.player_gold
	# Items
	for child in item_grid.get_children():
		child.queue_free()
	for item in GameData.inventory:
		var btn = Button.new()
		var data = GameData.get_item_data(item["name"])
		btn.text = "%s x%d" % [item["name"], item["count"]]
		btn.custom_minimum_size = Vector2(180, 36)
		if data.get("type", "") == "consumable":
			btn.pressed.connect(_use_item.bind(item["name"]))
			btn.tooltip_text = "%s (Click để dùng)" % data.get("desc", "")
		else:
			btn.pressed.connect(_equip_item.bind(item["name"]))
			btn.tooltip_text = "%s (Click để trang bị)" % data.get("desc", "")
		item_grid.add_child(btn)

func _use_item(item_name: String) -> void:
	if GameData.use_item(item_name):
		var data = GameData.get_item_data(item_name)
		var healed = data.get("hp", 0)
		if healed > 0:
			EventBus.player_healed.emit(healed)
		EventBus.inventory_changed.emit()
		_refresh()

func _equip_item(item_name: String) -> void:
	GameData.equip_item(item_name)
	EventBus.equipment_changed.emit()
	EventBus.inventory_changed.emit()
	_refresh()
