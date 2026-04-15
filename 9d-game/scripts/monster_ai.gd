extends CharacterBody3D
class_name MonsterAI

# ---------------------------------------------------------------------------
# Monster AI controller for 9D Cửu Long Tranh Bá clone
# Attach to a CharacterBody3D. Expects GameData autoload with MONSTERS dict
# and EventBus autoload for game-wide signals.
# ---------------------------------------------------------------------------

enum State { IDLE, PATROL, CHASE, ATTACK, RETURNING, DEAD }

# --- Exported ---
@export var monster_name: String = "Sói Hoang"
@export var monster_level: int = 1
@export var is_boss: bool = false

# --- Stats (loaded from GameData) ---
var max_hp: int = 100
var current_hp: int = 100
var atk: int = 10
var defense: int = 5
var exp_reward: int = 20
var gold_range: Vector2i = Vector2i(5, 15)  # min, max
var aggro_range: float = 12.0
var attack_range: float = 3.0
var attack_cooldown: float = 1.5
var speed: float = 4.0
var patrol_radius: float = 10.0
var leash_range: float = 24.0  # aggro_range * 2

# --- Internal ---
var current_state: State = State.IDLE
var home_position: Vector3 = Vector3.ZERO
var patrol_target: Vector3 = Vector3.ZERO
var idle_timer: float = 0.0
var idle_wait: float = 3.0
var attack_timer: float = 0.0
var boss_aoe_timer: float = 0.0
var respawn_time: float = 30.0
var hit_flash_timer: float = 0.0
var death_shrink_timer: float = 0.0
var _original_scale: Vector3 = Vector3.ONE
var _original_material: Material = null
var _flash_material: StandardMaterial3D = null
var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)

# --- Node references ---
@onready var mesh: MeshInstance3D = $Mesh
@onready var collision: CollisionShape3D = $Collision
@onready var name_label: Label3D = $NameLabel
@onready var hp_bar_bg: MeshInstance3D = $HPBar/Background
@onready var hp_bar_fg: MeshInstance3D = $HPBar/Foreground
@onready var hp_bar_root: Node3D = $HPBar
@onready var respawn_timer: Timer = $RespawnTimer


# ===========================================================================
# Lifecycle
# ===========================================================================

func _ready() -> void:
	add_to_group("monsters")
	home_position = global_position
	_original_scale = scale

	_load_stats()
	_setup_mesh()
	_setup_name_label()
	_setup_hp_bar()
	_setup_flash_material()
	_setup_respawn_timer()

	if is_boss:
		_setup_boss_visuals()

	hp_bar_root.visible = false
	change_state(State.IDLE)


func _physics_process(delta: float) -> void:
	# Gravity
	if not is_on_floor():
		velocity.y -= _gravity * delta

	# Hit flash countdown
	if hit_flash_timer > 0.0:
		hit_flash_timer -= delta
		if hit_flash_timer <= 0.0 and mesh and _original_material:
			mesh.material_override = null

	match current_state:
		State.IDLE:
			idle_tick(delta)
		State.PATROL:
			patrol_tick(delta)
		State.CHASE:
			chase_tick(delta)
		State.ATTACK:
			attack_tick(delta)
		State.RETURNING:
			return_tick(delta)
		State.DEAD:
			dead_tick(delta)

	move_and_slide()


# ===========================================================================
# State machine
# ===========================================================================

func change_state(new_state: State) -> void:
	current_state = new_state
	match new_state:
		State.IDLE:
			idle_wait = randf_range(2.0, 5.0)
			idle_timer = 0.0
			velocity.x = 0.0
			velocity.z = 0.0
		State.PATROL:
			patrol_target = _random_patrol_point()
		State.CHASE:
			pass
		State.ATTACK:
			attack_timer = 0.0
			boss_aoe_timer = 0.0
			velocity.x = 0.0
			velocity.z = 0.0
		State.RETURNING:
			pass
		State.DEAD:
			death_shrink_timer = 0.0
			velocity = Vector3.ZERO
			collision.set_deferred("disabled", true)


# --- IDLE ---
func idle_tick(delta: float) -> void:
	idle_timer += delta
	# Check for player aggro while idling
	var player := get_player()
	if player and distance_to_player() <= aggro_range:
		change_state(State.CHASE)
		return
	if idle_timer >= idle_wait:
		change_state(State.PATROL)


# --- PATROL ---
func patrol_tick(delta: float) -> void:
	# Check for player aggro while patrolling
	var player := get_player()
	if player and distance_to_player() <= aggro_range:
		change_state(State.CHASE)
		return

	var dir := (patrol_target - global_position)
	dir.y = 0.0
	var dist := dir.length()
	if dist < 1.0:
		change_state(State.IDLE)
		return

	dir = dir.normalized()
	# Patrol at half speed
	velocity.x = dir.x * speed * 0.5
	velocity.z = dir.z * speed * 0.5
	face_target(patrol_target, delta)


# --- CHASE ---
func chase_tick(delta: float) -> void:
	var player := get_player()
	if not player:
		change_state(State.RETURNING)
		return

	var dist_home := global_position.distance_to(home_position)
	if dist_home > leash_range:
		change_state(State.RETURNING)
		return

	var dist_player := distance_to_player()
	if dist_player <= attack_range:
		change_state(State.ATTACK)
		return

	# Move toward player at full speed
	var target_pos: Vector3 = player.global_position
	var dir := (target_pos - global_position)
	dir.y = 0.0
	dir = dir.normalized()
	velocity.x = dir.x * speed
	velocity.z = dir.z * speed
	face_target(target_pos, delta)


# --- ATTACK ---
func attack_tick(delta: float) -> void:
	var player := get_player()
	if not player:
		change_state(State.RETURNING)
		return

	var dist_player := distance_to_player()

	# Player moved out of attack range -> chase
	if dist_player > attack_range * 1.3:
		change_state(State.CHASE)
		return

	# Leash check
	var dist_home := global_position.distance_to(home_position)
	if dist_home > leash_range:
		change_state(State.RETURNING)
		return

	# Face the player
	face_target(player.global_position, delta)

	# Normal attack cooldown
	attack_timer += delta
	if attack_timer >= attack_cooldown:
		attack_timer = 0.0
		var damage := int(atk * randf_range(0.8, 1.2))
		_deal_damage_to_player(player, damage)

	# Boss AoE attack every 10 seconds
	if is_boss:
		boss_aoe_timer += delta
		if boss_aoe_timer >= 10.0:
			boss_aoe_timer = 0.0
			_boss_aoe_attack(player)


# --- RETURNING ---
func return_tick(delta: float) -> void:
	var dir := (home_position - global_position)
	dir.y = 0.0
	var dist := dir.length()
	if dist < 1.5:
		# Arrived home, heal to full
		current_hp = max_hp
		_update_hp_bar()
		hp_bar_root.visible = false
		change_state(State.IDLE)
		return

	dir = dir.normalized()
	velocity.x = dir.x * speed
	velocity.z = dir.z * speed
	face_target(home_position, delta)


# --- DEAD ---
func dead_tick(delta: float) -> void:
	# Shrink and fade out over 1 second
	death_shrink_timer += delta
	var t := clampf(death_shrink_timer / 1.0, 0.0, 1.0)
	scale = _original_scale * (1.0 - t * 0.8)
	if mesh:
		var mat: StandardMaterial3D = mesh.get_active_material(0) as StandardMaterial3D
		if mat == null and mesh.material_override:
			mat = mesh.material_override as StandardMaterial3D
		if mat:
			mat.albedo_color.a = 1.0 - t

	if death_shrink_timer >= 1.2:
		visible = false
		hp_bar_root.visible = false
		respawn_timer.start(respawn_time)


# ===========================================================================
# Combat
# ===========================================================================

func take_damage(amount: int, attacker: Node) -> void:
	if current_state == State.DEAD:
		return

	var actual_damage := maxi(1, amount - defense)
	current_hp -= actual_damage
	current_hp = maxi(0, current_hp)

	# Show HP bar
	hp_bar_root.visible = true
	_update_hp_bar()

	# Hit flash
	if mesh and _flash_material:
		mesh.material_override = _flash_material
		hit_flash_timer = 0.12

	# Damage number signal
	EventBus.show_damage_number.emit(global_position + Vector3.UP * 2.5, actual_damage, false)
	EventBus.monster_damaged.emit(self, actual_damage)

	if current_hp <= 0:
		die()
		return

	# Aggro on attacker if idle/patrolling
	if current_state == State.IDLE or current_state == State.PATROL:
		change_state(State.CHASE)


func die() -> void:
	change_state(State.DEAD)
	EventBus.monster_killed.emit(self)
	drop_loot()

	# Give EXP to player
	var player := get_player()
	if player and player.has_method("gain_exp"):
		player.gain_exp(exp_reward)


func drop_loot() -> void:
	var gold_multiplier := 3 if is_boss else 1
	var gold_amount := randi_range(gold_range.x, gold_range.y) * gold_multiplier
	EventBus.gold_picked_up.emit(gold_amount)
	EventBus.show_notification.emit("+" + str(gold_amount) + " vàng")

	# 30% chance: Tiểu Hoàn Đan
	if randf() < 0.30:
		EventBus.item_picked_up.emit("Tiểu Hoàn Đan", 1)
		EventBus.show_notification.emit("Nhận được Tiểu Hoàn Đan!")

	# 15% chance: weapon/armor based on level
	if randf() < 0.15:
		var gear_name := _random_gear_drop()
		EventBus.item_picked_up.emit(gear_name, 1)
		EventBus.show_notification.emit("Nhận được " + gear_name + "!")

	# Boss: guaranteed rare drop
	if is_boss:
		var rare_name := _boss_rare_drop()
		EventBus.item_picked_up.emit(rare_name, 1)
		EventBus.show_notification.emit("BOSS DROP: " + rare_name + "!")


func respawn() -> void:
	current_hp = max_hp
	global_position = home_position
	scale = _original_scale
	visible = true
	collision.set_deferred("disabled", false)
	hp_bar_root.visible = false

	# Restore mesh appearance
	if mesh:
		mesh.material_override = null
		var mat: StandardMaterial3D = mesh.get_active_material(0) as StandardMaterial3D
		if mat:
			mat.albedo_color.a = 1.0

	change_state(State.IDLE)


# ===========================================================================
# Boss special
# ===========================================================================

func _boss_aoe_attack(player: Node) -> void:
	var aoe_range := attack_range * 2.5
	var aoe_damage := int(atk * 2.0 * randf_range(0.9, 1.1))

	EventBus.show_notification.emit(monster_name + " thi triển tuyệt chiêu!")

	# Damage player if in AoE range
	if player and global_position.distance_to(player.global_position) <= aoe_range:
		_deal_damage_to_player(player, aoe_damage)


# ===========================================================================
# Helpers
# ===========================================================================

func get_player() -> Node:
	return get_tree().get_first_node_in_group("player")


func distance_to_player() -> float:
	var player := get_player()
	if not player:
		return INF
	return global_position.distance_to(player.global_position)


func face_target(target_pos: Vector3, delta: float) -> void:
	var dir := target_pos - global_position
	dir.y = 0.0
	if dir.length_squared() < 0.001:
		return
	var target_angle := atan2(dir.x, dir.z)
	rotation.y = lerp_angle(rotation.y, target_angle, 10.0 * delta)


func _deal_damage_to_player(player: Node, damage: int) -> void:
	if player.has_method("take_damage"):
		player.take_damage(damage, self)
	EventBus.player_damaged.emit(damage)


func _random_patrol_point() -> Vector3:
	var angle := randf() * TAU
	var radius := randf_range(3.0, patrol_radius)
	return home_position + Vector3(cos(angle) * radius, 0.0, sin(angle) * radius)


func _random_gear_drop() -> String:
	var weapons := [
		"Kiếm Sắt", "Đao Đồng", "Thương Gỗ", "Quạt Trúc", "Cung Ngắn"
	]
	var armors := [
		"Giáp Vải", "Giáp Da", "Hộ Uyển", "Giày Bố", "Mũ Vải"
	]
	var tier_prefix := ""
	if monster_level >= 30:
		tier_prefix = "Tinh Luyện "
	elif monster_level >= 20:
		tier_prefix = "Thượng Đẳng "
	elif monster_level >= 10:
		tier_prefix = "Trung Đẳng "

	if randf() < 0.5:
		return tier_prefix + weapons[randi() % weapons.size()]
	else:
		return tier_prefix + armors[randi() % armors.size()]


func _boss_rare_drop() -> String:
	var rare_items := [
		"Huyền Thiết Kiếm",
		"Long Lân Giáp",
		"Thiên Sơn Tuyết Liên",
		"Cửu Dương Thần Công Bí Kíp",
		"Hỏa Kỳ Lân Đan",
	]
	return rare_items[randi() % rare_items.size()]


# ===========================================================================
# Setup / initialization
# ===========================================================================

func _load_stats() -> void:
	# Load from GameData autoload if available
	if Engine.has_singleton("GameData") or get_node_or_null("/root/GameData"):
		var game_data := get_node_or_null("/root/GameData")
		if game_data and game_data.has_method("get_monster_data"):
			var data: Dictionary = game_data.get_monster_data(monster_name)
			if data.is_empty():
				push_warning("MonsterAI: No data for '%s' in GameData" % monster_name)
				_apply_default_stats()
				return
			max_hp = data.get("max_hp", 100)
			atk = data.get("atk", 10)
			defense = data.get("defense", 5)
			exp_reward = data.get("exp_reward", 20)
			speed = data.get("speed", 4.0)
			aggro_range = data.get("aggro_range", 12.0)
			attack_range = data.get("attack_range", 3.0)
			attack_cooldown = data.get("attack_cooldown", 1.5)
			patrol_radius = data.get("patrol_radius", 10.0)
			respawn_time = data.get("respawn_time", 30.0)
			var gr_min: int = data.get("gold_min", 5)
			var gr_max: int = data.get("gold_max", 15)
			gold_range = Vector2i(gr_min, gr_max)
		else:
			_apply_default_stats()
	else:
		_apply_default_stats()

	# Scale stats by level
	max_hp = int(max_hp * (1.0 + (monster_level - 1) * 0.15))
	atk = int(atk * (1.0 + (monster_level - 1) * 0.12))
	defense = int(defense * (1.0 + (monster_level - 1) * 0.1))
	exp_reward = int(exp_reward * (1.0 + (monster_level - 1) * 0.2))

	# Boss multipliers
	if is_boss:
		max_hp *= 5
		atk = int(atk * 1.8)
		defense = int(defense * 1.5)
		exp_reward *= 5
		respawn_time = 120.0

	current_hp = max_hp
	leash_range = aggro_range * 2.0


func _apply_default_stats() -> void:
	max_hp = 100
	atk = 10
	defense = 5
	exp_reward = 20
	speed = 4.0
	aggro_range = 12.0
	attack_range = 3.0
	attack_cooldown = 1.5
	patrol_radius = 10.0
	gold_range = Vector2i(5, 15)
	respawn_time = 30.0


func _setup_mesh() -> void:
	if not mesh:
		return
	# Color by monster type / level tier
	var mat := StandardMaterial3D.new()
	mat.albedo_color = _get_monster_color()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mesh.material_override = mat
	_original_material = mat

	# Boss is larger
	if is_boss:
		mesh.scale *= 1.8


func _get_monster_color() -> Color:
	if is_boss:
		return Color(0.8, 0.1, 0.1, 1.0)  # Red for bosses
	if monster_level >= 30:
		return Color(0.6, 0.0, 0.8, 1.0)  # Purple - high level
	if monster_level >= 20:
		return Color(0.9, 0.5, 0.0, 1.0)  # Orange
	if monster_level >= 10:
		return Color(0.2, 0.4, 0.9, 1.0)  # Blue
	return Color(0.3, 0.7, 0.3, 1.0)       # Green - low level


func _setup_name_label() -> void:
	if not name_label:
		return
	var display_level := " Lv." + str(monster_level)
	var prefix := "[BOSS] " if is_boss else ""
	name_label.text = prefix + monster_name + display_level
	name_label.font_size = 48 if is_boss else 32
	name_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	name_label.no_depth_test = true
	if is_boss:
		name_label.modulate = Color(1.0, 0.3, 0.3)
	else:
		name_label.modulate = Color(1.0, 0.9, 0.6)


func _setup_hp_bar() -> void:
	# HP bar is two flat quads: red background, green foreground
	# Positioned above the monster, billboard-facing the camera
	if not hp_bar_bg or not hp_bar_fg:
		return
	hp_bar_root.billboard = BaseMaterial3D.BILLBOARD_ENABLED if hp_bar_root is GeometryInstance3D else 0

	# Background (red)
	var bg_mat := StandardMaterial3D.new()
	bg_mat.albedo_color = Color(0.6, 0.1, 0.1, 0.9)
	bg_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	bg_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bg_mat.no_depth_test = true
	hp_bar_bg.material_override = bg_mat

	# Foreground (green)
	var fg_mat := StandardMaterial3D.new()
	fg_mat.albedo_color = Color(0.1, 0.8, 0.1, 0.9)
	fg_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	fg_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	fg_mat.no_depth_test = true
	hp_bar_fg.material_override = fg_mat

	_update_hp_bar()


func _update_hp_bar() -> void:
	if not hp_bar_fg:
		return
	var ratio := float(current_hp) / float(max_hp) if max_hp > 0 else 0.0
	ratio = clampf(ratio, 0.0, 1.0)
	hp_bar_fg.scale.x = ratio

	# Shift color from green -> yellow -> red
	var fg_mat := hp_bar_fg.material_override as StandardMaterial3D
	if fg_mat:
		if ratio > 0.5:
			fg_mat.albedo_color = Color(0.1, 0.8, 0.1, 0.9)
		elif ratio > 0.25:
			fg_mat.albedo_color = Color(0.9, 0.8, 0.0, 0.9)
		else:
			fg_mat.albedo_color = Color(0.9, 0.1, 0.1, 0.9)

	# Hide HP bar at full health
	if ratio >= 1.0:
		hp_bar_root.visible = false


func _setup_flash_material() -> void:
	_flash_material = StandardMaterial3D.new()
	_flash_material.albedo_color = Color.WHITE
	_flash_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_flash_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA


func _setup_respawn_timer() -> void:
	if not respawn_timer:
		return
	respawn_timer.one_shot = true
	if not respawn_timer.timeout.is_connected(_on_respawn_timer_timeout):
		respawn_timer.timeout.connect(_on_respawn_timer_timeout)


func _setup_boss_visuals() -> void:
	# Create a pulsing glow tween for the boss mesh
	if not mesh:
		return
	var tween := create_tween().set_loops()
	tween.tween_property(mesh, "scale", mesh.scale * 1.08, 0.8).set_trans(Tween.TRANS_SINE)
	tween.tween_property(mesh, "scale", mesh.scale, 0.8).set_trans(Tween.TRANS_SINE)


# ===========================================================================
# Signals
# ===========================================================================

func _on_respawn_timer_timeout() -> void:
	respawn()
