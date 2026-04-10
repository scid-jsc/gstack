extends CharacterBody3D

# Third-person character controller for wuxia RPG

# --- State machine ---
enum State { IDLE, MOVING, ATTACKING, USING_SKILL, DEAD }
var current_state: State = State.IDLE

# --- Child node references ---
@onready var camera_pivot: Node3D = $CameraPivot
@onready var spring_arm: SpringArm3D = $CameraPivot/SpringArm3D
@onready var camera: Camera3D = $CameraPivot/SpringArm3D/Camera3D
@onready var mesh: MeshInstance3D = $Mesh
@onready var collision: CollisionShape3D = $CollisionShape3D
@onready var attack_area: Area3D = $AttackArea
@onready var raycast: RayCast3D = $RayCast3D

# --- Movement ---
const GRAVITY: float = 30.0
const JUMP_VELOCITY: float = 10.0
const ROTATION_SPEED: float = 10.0

# --- Camera ---
var camera_rotation_x: float = 0.0
var camera_rotation_y: float = 0.0
var camera_sensitivity: float = 0.003
var is_rotating_camera: bool = false

# --- Combat ---
var current_target: Node = null
var auto_attack_enabled: bool = false
var basic_attack_cooldown: float = 1.5
var basic_attack_timer: float = 0.0
var skill_cooldowns: Array[float] = [0.0, 0.0, 0.0, 0.0]
var nearby_enemies: Array[Node] = []
var last_tab_index: int = -1

# --- Regen ---
var out_of_combat_timer: float = 0.0
const OUT_OF_COMBAT_THRESHOLD: float = 5.0
var hp_regen_timer: float = 0.0
var mp_regen_timer: float = 0.0

# --- Attack animation ---
var attack_anim_timer: float = 0.0
var original_mesh_scale: Vector3 = Vector3.ONE
var original_mesh_rotation: float = 0.0


func _ready() -> void:
	# Pull starting stats from GameData singleton
	GameData.player_hp = GameData.player_max_hp
	GameData.player_mp = GameData.player_max_mp

	# Camera setup
	spring_arm.spring_length = 5.0
	spring_arm.rotation_degrees.x = -20.0
	camera_rotation_x = deg_to_rad(-20.0)

	# Store original mesh transform for attack animation
	original_mesh_scale = mesh.scale
	original_mesh_rotation = mesh.rotation.y

	# Connect attack area signals
	attack_area.body_entered.connect(_on_attack_area_body_entered)
	attack_area.body_exited.connect(_on_attack_area_body_exited)

	# Capture mouse for camera control
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _physics_process(delta: float) -> void:
	if current_state == State.DEAD:
		return

	# Apply gravity
	if not is_on_floor():
		velocity.y -= GRAVITY * delta

	# Tick cooldowns
	_update_cooldowns(delta)

	# Tick regen
	_update_regen(delta)

	# Update attack animation
	_update_attack_animation(delta)

	# State machine
	match current_state:
		State.IDLE:
			handle_movement(delta)
			handle_combat(delta)
		State.MOVING:
			handle_movement(delta)
			handle_combat(delta)
		State.ATTACKING:
			handle_combat(delta)
			# Allow movement to cancel attack state after a short window
			if basic_attack_timer < basic_attack_cooldown - 0.3:
				handle_movement(delta)
		State.USING_SKILL:
			# Brief lock during skill use, then return to idle
			if attack_anim_timer <= 0.0:
				current_state = State.IDLE

	move_and_slide()


func _unhandled_input(event: InputEvent) -> void:
	if current_state == State.DEAD:
		return

	# Camera rotation with right mouse button
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_RIGHT:
			is_rotating_camera = mouse_event.pressed
			if is_rotating_camera:
				Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			else:
				Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

		# Left click: select target
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			_handle_left_click(mouse_event)

	if event is InputEventMouseMotion and is_rotating_camera:
		var motion := event as InputEventMouseMotion
		camera_rotation_y -= motion.relative.x * camera_sensitivity
		camera_rotation_x -= motion.relative.y * camera_sensitivity
		camera_rotation_x = clampf(camera_rotation_x, deg_to_rad(-80.0), deg_to_rad(10.0))
		camera_pivot.rotation.y = camera_rotation_y
		spring_arm.rotation.x = camera_rotation_x

	# Jump
	if event.is_action_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Toggle auto-attack (R key)
	if event is InputEventKey:
		var key_event := event as InputEventKey
		if key_event.pressed and not key_event.echo:
			match key_event.keycode:
				KEY_R:
					auto_attack_enabled = not auto_attack_enabled
					if auto_attack_enabled:
						EventBus.chat_message.emit("Auto-attack ON", Color.YELLOW)
					else:
						EventBus.chat_message.emit("Auto-attack OFF", Color.YELLOW)
				KEY_TAB:
					tab_target()
				KEY_1:
					use_skill(0)
				KEY_2:
					use_skill(1)
				KEY_3:
					use_skill(2)
				KEY_4:
					use_skill(3)


func handle_movement(delta: float) -> void:
	var input_dir := Vector2.ZERO
	input_dir.x = Input.get_axis("move_left", "move_right")
	input_dir.y = Input.get_axis("move_forward", "move_back")

	if input_dir.length() < 0.1:
		# Decelerate
		velocity.x = move_toward(velocity.x, 0.0, GameData.player_speed * delta * 8.0)
		velocity.z = move_toward(velocity.z, 0.0, GameData.player_speed * delta * 8.0)
		if current_state == State.MOVING:
			current_state = State.IDLE
		return

	# Direction relative to camera
	var cam_basis := camera_pivot.global_transform.basis
	var forward := -cam_basis.z
	forward.y = 0.0
	forward = forward.normalized()
	var right := cam_basis.x
	right.y = 0.0
	right = right.normalized()

	var direction := (forward * (-input_dir.y) + right * input_dir.x).normalized()
	velocity.x = direction.x * GameData.player_speed
	velocity.z = direction.z * GameData.player_speed

	# Rotate character to face movement direction
	var target_angle := atan2(direction.x, direction.z)
	rotation.y = lerp_angle(rotation.y, target_angle, ROTATION_SPEED * delta)

	if current_state != State.ATTACKING and current_state != State.USING_SKILL:
		current_state = State.MOVING


func handle_combat(delta: float) -> void:
	# Validate current target still exists
	if current_target != null and not is_instance_valid(current_target):
		clear_target()

	# Auto-attack logic
	if auto_attack_enabled and current_target != null and basic_attack_timer <= 0.0:
		if _is_target_in_range():
			basic_attack()


func basic_attack() -> void:
	if basic_attack_timer > 0.0:
		return
	if current_target == null or not is_instance_valid(current_target):
		return
	if not _is_target_in_range():
		EventBus.chat_message.emit("Target out of range", Color.RED)
		return

	# Face target
	_face_target()

	# Reset combat timer (regen stops)
	out_of_combat_timer = 0.0

	# Calculate damage
	var damage: int = GameData.player_attack
	var is_crit := randf() < 0.15
	if is_crit:
		damage = int(damage * 1.5)

	# Apply damage to target
	if current_target.has_method("take_damage"):
		current_target.take_damage(damage)
	EventBus.monster_damaged.emit(current_target, damage)
	EventBus.show_damage_number.emit(current_target.global_position + Vector3.UP * 2.0, damage, is_crit)

	# Start cooldown and animation
	basic_attack_timer = basic_attack_cooldown
	_play_attack_animation()
	current_state = State.ATTACKING


func use_skill(index: int) -> void:
	if index < 0 or index >= 4:
		return
	if current_state == State.DEAD:
		return

	# Check cooldown
	if skill_cooldowns[index] > 0.0:
		EventBus.chat_message.emit("Skill on cooldown", Color.RED)
		return

	# Read skill data from GameData
	if index >= GameData.player_skills.size():
		EventBus.chat_message.emit("No skill in slot " + str(index + 1), Color.RED)
		return

	var skill: Dictionary = GameData.player_skills[index]
	var skill_name: String = skill.get("name", "Unknown")
	var mp_cost: int = skill.get("mp_cost", 0)
	var damage: int = skill.get("damage", 0)
	var cooldown: float = skill.get("cooldown", 3.0)
	var skill_range: float = skill.get("range", 5.0)

	# Check MP
	if GameData.player_mp < mp_cost:
		EventBus.chat_message.emit("Not enough MP", Color.RED)
		return

	# Need a target for offensive skills
	if current_target == null or not is_instance_valid(current_target):
		EventBus.chat_message.emit("No target selected", Color.RED)
		return

	# Range check
	var dist := global_position.distance_to(current_target.global_position)
	if dist > skill_range:
		EventBus.chat_message.emit("Target out of range", Color.RED)
		return

	# Face target
	_face_target()

	# Reset combat timer
	out_of_combat_timer = 0.0

	# Consume MP
	GameData.player_mp -= mp_cost

	# Calculate damage with variance
	var final_damage: int = damage + GameData.player_attack / 2
	var is_crit := randf() < 0.2
	if is_crit:
		final_damage = int(final_damage * 1.8)

	# Apply damage
	if current_target.has_method("take_damage"):
		current_target.take_damage(final_damage)
	EventBus.monster_damaged.emit(current_target, final_damage)
	EventBus.show_damage_number.emit(current_target.global_position + Vector3.UP * 2.0, final_damage, is_crit)

	# Start cooldown
	skill_cooldowns[index] = cooldown
	EventBus.skill_cooldown_started.emit(index, cooldown)
	EventBus.skill_used.emit(index, skill_name)

	# Animation and state
	_play_attack_animation()
	current_state = State.USING_SKILL


func take_damage(amount: int) -> void:
	if current_state == State.DEAD:
		return

	# Apply defense reduction
	var reduced := maxi(1, amount - GameData.player_defense / 2)
	GameData.player_hp -= reduced
	out_of_combat_timer = 0.0

	EventBus.player_damaged.emit(reduced)
	EventBus.show_damage_number.emit(global_position + Vector3.UP * 2.0, reduced, false)

	# Flash mesh red briefly
	_flash_damage()

	if GameData.player_hp <= 0:
		GameData.player_hp = 0
		die()


func die() -> void:
	current_state = State.DEAD
	auto_attack_enabled = false
	clear_target()
	velocity = Vector3.ZERO

	# Visual feedback: fall over
	var tween := create_tween()
	tween.tween_property(mesh, "rotation_degrees:x", -90.0, 0.5)

	EventBus.player_died.emit()
	EventBus.chat_message.emit("You have been defeated!", Color.RED)

	# Auto-respawn after 5 seconds
	get_tree().create_timer(5.0).timeout.connect(respawn)


func respawn() -> void:
	# Teleport to spawn point
	global_position = Vector3(0.0, 1.0, 0.0)
	velocity = Vector3.ZERO

	# Restore half HP and MP
	GameData.player_hp = GameData.player_max_hp / 2
	GameData.player_mp = GameData.player_max_mp / 2

	# Reset mesh rotation
	mesh.rotation_degrees.x = 0.0
	mesh.scale = original_mesh_scale

	# Reset state
	current_state = State.IDLE
	out_of_combat_timer = OUT_OF_COMBAT_THRESHOLD

	EventBus.player_respawned.emit()
	EventBus.chat_message.emit("You have respawned", Color.GREEN)


func select_target(target: Node) -> void:
	if target == current_target:
		return
	current_target = target
	last_tab_index = nearby_enemies.find(target)
	EventBus.target_changed.emit(target)


func clear_target() -> void:
	current_target = null
	auto_attack_enabled = false
	last_tab_index = -1
	EventBus.target_changed.emit(null)


func tab_target() -> void:
	if nearby_enemies.is_empty():
		EventBus.chat_message.emit("No targets nearby", Color.GRAY)
		return

	# Remove invalid entries
	nearby_enemies = nearby_enemies.filter(func(e: Node) -> bool: return is_instance_valid(e))
	if nearby_enemies.is_empty():
		clear_target()
		return

	# Cycle to next
	last_tab_index = (last_tab_index + 1) % nearby_enemies.size()
	select_target(nearby_enemies[last_tab_index])


func _on_attack_area_body_entered(body: Node) -> void:
	# Monsters are on collision layer 2
	if body != self and body.get_collision_layer_value(2):
		if body not in nearby_enemies:
			nearby_enemies.append(body)


func _on_attack_area_body_exited(body: Node) -> void:
	nearby_enemies.erase(body)
	if body == current_target:
		EventBus.chat_message.emit("Target moved out of range", Color.GRAY)


# --- Private helpers ---

func _handle_left_click(event: InputEventMouseButton) -> void:
	# Raycast from mouse position into 3D world
	var mouse_pos := event.position
	var from := camera.project_ray_origin(mouse_pos)
	var to := from + camera.project_ray_normal(mouse_pos) * 100.0

	var space_state := get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = 2  # Layer 2 = monsters
	query.exclude = [self.get_rid()]

	var result := space_state.intersect_ray(query)
	if result.is_empty():
		clear_target()
		return

	var collider := result.get("collider", null)
	if collider != null and collider is Node:
		select_target(collider as Node)
		# If already in range, attack
		if _is_target_in_range() and basic_attack_timer <= 0.0:
			basic_attack()


func _is_target_in_range() -> bool:
	if current_target == null or not is_instance_valid(current_target):
		return false
	var dist := global_position.distance_to(current_target.global_position)
	return dist <= 3.5  # Melee range


func _face_target() -> void:
	if current_target == null or not is_instance_valid(current_target):
		return
	var dir := (current_target.global_position - global_position)
	dir.y = 0.0
	if dir.length_squared() > 0.01:
		var target_angle := atan2(dir.x, dir.z)
		rotation.y = target_angle


func _update_cooldowns(delta: float) -> void:
	if basic_attack_timer > 0.0:
		basic_attack_timer -= delta
		if basic_attack_timer <= 0.0:
			basic_attack_timer = 0.0
			if current_state == State.ATTACKING:
				current_state = State.IDLE

	for i in range(skill_cooldowns.size()):
		if skill_cooldowns[i] > 0.0:
			skill_cooldowns[i] -= delta
			if skill_cooldowns[i] < 0.0:
				skill_cooldowns[i] = 0.0


func _update_regen(delta: float) -> void:
	out_of_combat_timer += delta

	if out_of_combat_timer < OUT_OF_COMBAT_THRESHOLD:
		hp_regen_timer = 0.0
		mp_regen_timer = 0.0
		return

	# HP regen: 1 per 2 seconds
	if GameData.player_hp < GameData.player_max_hp:
		hp_regen_timer += delta
		if hp_regen_timer >= 2.0:
			hp_regen_timer -= 2.0
			GameData.player_hp = mini(GameData.player_hp + 1, GameData.player_max_hp)
			EventBus.player_healed.emit(1)

	# MP regen: 1 per 3 seconds
	if GameData.player_mp < GameData.player_max_mp:
		mp_regen_timer += delta
		if mp_regen_timer >= 3.0:
			mp_regen_timer -= 3.0
			GameData.player_mp = mini(GameData.player_mp + 1, GameData.player_max_mp)


func _play_attack_animation() -> void:
	attack_anim_timer = 0.3
	# Quick scale pulse + Y rotation snap
	var tween := create_tween()
	tween.tween_property(mesh, "scale", original_mesh_scale * 1.2, 0.1)
	tween.tween_property(mesh, "scale", original_mesh_scale, 0.2)


func _update_attack_animation(delta: float) -> void:
	if attack_anim_timer > 0.0:
		attack_anim_timer -= delta


func _flash_damage() -> void:
	# Brief red flash on the mesh material
	var mat := mesh.get_surface_override_material(0)
	if mat == null:
		mat = mesh.mesh.surface_get_material(0) if mesh.mesh else null
	if mat is StandardMaterial3D:
		var original_color: Color = mat.albedo_color
		mat.albedo_color = Color.RED
		var tween := create_tween()
		tween.tween_property(mat, "albedo_color", original_color, 0.2)
