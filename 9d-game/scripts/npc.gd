extends StaticBody3D

@export var npc_name: String = ""
@export var npc_type: String = "shop_potion"

@onready var mesh: MeshInstance3D = $Mesh
@onready var name_label: Label3D = $NameLabel
@onready var interact_area: Area3D = $InteractArea

var dialog: String = ""
var shop_items: Array = []
var bob_time: float = 0.0
var player_nearby: bool = false
var interact_hint: Label3D = null

func _ready() -> void:
	add_to_group("npcs")
	collision_layer = 8  # Layer 4
	# Load data
	if GameData.NPCS.has(npc_name):
		var data = GameData.NPCS[npc_name]
		dialog = data.get("dialog", "")
		shop_items = data.get("items", [])
	# Set appearance
	name_label.text = npc_name
	name_label.modulate = Color.GOLD
	var mat = StandardMaterial3D.new()
	match npc_type:
		"shop_weapon":
			mat.albedo_color = Color(0.8, 0.6, 0.2)
		"shop_armor":
			mat.albedo_color = Color(0.6, 0.6, 0.7)
		"shop_potion":
			mat.albedo_color = Color(0.2, 0.8, 0.4)
		"trainer":
			mat.albedo_color = Color(0.3, 0.5, 0.9)
		"quest":
			mat.albedo_color = Color(0.9, 0.8, 0.2)
		_:
			mat.albedo_color = Color(0.8, 0.7, 0.5)
	mat.emission_enabled = true
	mat.emission = mat.albedo_color * 0.3
	mat.emission_energy_multiplier = 0.5
	mesh.material_override = mat
	# Interact hint
	interact_hint = Label3D.new()
	interact_hint.text = "[F] Nói chuyện"
	interact_hint.position = Vector3(0, 2.8, 0)
	interact_hint.font_size = 16
	interact_hint.modulate = Color.YELLOW
	interact_hint.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	interact_hint.visible = false
	add_child(interact_hint)
	# Connect signals
	interact_area.body_entered.connect(_on_body_entered)
	interact_area.body_exited.connect(_on_body_exited)

func _process(delta: float) -> void:
	# Idle bobbing
	bob_time += delta * 2.0
	mesh.position.y = sin(bob_time) * 0.1

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		player_nearby = true
		interact_hint.visible = true

func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		player_nearby = false
		interact_hint.visible = false

func interact() -> void:
	if not player_nearby:
		return
	EventBus.npc_interact.emit(npc_name)
	# Show dialog in chat
	EventBus.chat_message.emit("%s: %s" % [npc_name, dialog], Color.YELLOW)
	# Handle shop interaction
	if npc_type.begins_with("shop_") and not shop_items.is_empty():
		_open_shop()

func _open_shop() -> void:
	# Simple shop: buy cheapest item player can afford
	EventBus.chat_message.emit("=== Cửa Hàng %s ===" % npc_name, Color.GOLD)
	for item_name in shop_items:
		var data = GameData.get_item_data(item_name)
		if not data.is_empty():
			EventBus.chat_message.emit("  %s - %d Vàng - %s" % [item_name, data["price"], data["desc"]], Color.WHITE)
	EventBus.chat_message.emit("(Nhấn 1-6 để mua, ESC thoát)", Color.GRAY)

func _unhandled_input(event: InputEvent) -> void:
	if not player_nearby:
		return
	if event.is_action_pressed("interact"):
		interact()
