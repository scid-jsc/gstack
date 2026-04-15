extends Node3D

@onready var player: CharacterBody3D = $Player
@onready var monster_container: Node3D = $Monsters
@onready var npc_container: Node3D = $NPCs
@onready var environment_container: Node3D = $Environment
@onready var sun: DirectionalLight3D = $Sun

var monster_scene := preload("res://scenes/monster.tscn")
var npc_scene := preload("res://scenes/npc.tscn")

var day_time: float = 0.0
var day_cycle_speed: float = 0.001  # Full cycle ~17 min
var current_zone: String = ""

func _ready() -> void:
	_setup_player()
	_create_terrain()
	_spawn_monsters()
	_place_npcs()

func _setup_player() -> void:
	# Set player starting position at Tân Thủ Thôn
	player.position = Vector3(0, 1, 0)
	# Set mesh color from class
	var class_data = GameData.get_class_data(GameData.player_class)
	if not class_data.is_empty():
		var mesh_inst: MeshInstance3D = player.get_node("Mesh")
		if mesh_inst:
			var mat = StandardMaterial3D.new()
			mat.albedo_color = class_data["color"]
			mesh_inst.material_override = mat

func _create_terrain() -> void:
	# Ground plane is already in scene, add zone-specific objects
	for zone_name in GameData.ZONES:
		var zone = GameData.ZONES[zone_name]
		var zone_pos: Vector3 = zone["pos"]
		var zone_size: Vector2 = zone["size"]
		# Zone ground coloring (large flat colored plane per zone)
		var ground = MeshInstance3D.new()
		var plane_mesh = PlaneMesh.new()
		plane_mesh.size = zone_size
		ground.mesh = plane_mesh
		ground.position = zone_pos + Vector3(0, 0.01, 0)
		var mat = StandardMaterial3D.new()
		mat.albedo_color = zone["color"]
		mat.albedo_color.a = 0.6
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		ground.material_override = mat
		environment_container.add_child(ground)
		# Zone label (floating text)
		var label3d = Label3D.new()
		label3d.text = zone_name
		label3d.position = zone_pos + Vector3(0, 8, 0)
		label3d.font_size = 48
		label3d.modulate = Color.GOLD
		label3d.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		environment_container.add_child(label3d)
		# Trees for forest zones
		if zone_name in ["Hoàng Sơn", "Mộ Dung Trang", "Tân Thủ Thôn"]:
			_place_trees(zone_pos, zone_size, 30 if zone_name == "Hoàng Sơn" else 15)
		# Buildings for city zones
		if zone_name in ["Lâm An Thành", "Tân Thủ Thôn"]:
			_place_buildings(zone_pos, zone_size, 8 if zone_name == "Lâm An Thành" else 4)
		# Rocks for mountain zones
		if zone_name in ["Tử Cấm Thành", "Giang Hồ Lộ"]:
			_place_rocks(zone_pos, zone_size, 20)
		# Walls for cities
		if zone_name == "Tử Cấm Thành":
			_place_walls(zone_pos, zone_size)

func _place_trees(center: Vector3, size: Vector2, count: int) -> void:
	for i in range(count):
		var tree_root = Node3D.new()
		var offset = Vector3(
			randf_range(-size.x / 2.5, size.x / 2.5),
			0,
			randf_range(-size.y / 2.5, size.y / 2.5)
		)
		tree_root.position = center + offset
		# Trunk
		var trunk = MeshInstance3D.new()
		var trunk_mesh = CylinderMesh.new()
		trunk_mesh.top_radius = 0.15
		trunk_mesh.bottom_radius = 0.25
		trunk_mesh.height = randf_range(2.0, 4.0)
		trunk.mesh = trunk_mesh
		trunk.position.y = trunk_mesh.height / 2.0
		var trunk_mat = StandardMaterial3D.new()
		trunk_mat.albedo_color = Color(0.4, 0.25, 0.1)
		trunk.material_override = trunk_mat
		tree_root.add_child(trunk)
		# Canopy
		var canopy = MeshInstance3D.new()
		var canopy_mesh = SphereMesh.new()
		var canopy_size = randf_range(1.5, 3.0)
		canopy_mesh.radius = canopy_size
		canopy_mesh.height = canopy_size * 1.5
		canopy.mesh = canopy_mesh
		canopy.position.y = trunk_mesh.height + canopy_size * 0.5
		var canopy_mat = StandardMaterial3D.new()
		canopy_mat.albedo_color = Color(
			randf_range(0.1, 0.3),
			randf_range(0.4, 0.7),
			randf_range(0.05, 0.2)
		)
		canopy.material_override = canopy_mat
		tree_root.add_child(canopy)
		# Collision
		var body = StaticBody3D.new()
		body.collision_layer = 4  # Environment
		var col = CollisionShape3D.new()
		var shape = CylinderShape3D.new()
		shape.radius = 0.3
		shape.height = trunk_mesh.height
		col.shape = shape
		col.position.y = trunk_mesh.height / 2.0
		body.add_child(col)
		tree_root.add_child(body)
		environment_container.add_child(tree_root)

func _place_buildings(center: Vector3, size: Vector2, count: int) -> void:
	for i in range(count):
		var building = Node3D.new()
		var offset = Vector3(
			randf_range(-size.x / 3, size.x / 3),
			0,
			randf_range(-size.y / 3, size.y / 3)
		)
		building.position = center + offset
		var bw = randf_range(3.0, 6.0)
		var bh = randf_range(3.0, 6.0)
		var bd = randf_range(3.0, 6.0)
		# Walls
		var walls = MeshInstance3D.new()
		var wall_mesh = BoxMesh.new()
		wall_mesh.size = Vector3(bw, bh, bd)
		walls.mesh = wall_mesh
		walls.position.y = bh / 2.0
		var wall_mat = StandardMaterial3D.new()
		wall_mat.albedo_color = Color(
			randf_range(0.6, 0.8),
			randf_range(0.5, 0.7),
			randf_range(0.3, 0.5)
		)
		walls.material_override = wall_mat
		building.add_child(walls)
		# Roof (pyramid-like using prism)
		var roof = MeshInstance3D.new()
		var roof_mesh = PrismMesh.new()
		roof_mesh.size = Vector3(bw + 1.0, 2.0, bd + 1.0)
		roof.mesh = roof_mesh
		roof.position.y = bh + 1.0
		var roof_mat = StandardMaterial3D.new()
		roof_mat.albedo_color = Color(0.5, 0.15, 0.1)
		roof.material_override = roof_mat
		building.add_child(roof)
		# Collision
		var body = StaticBody3D.new()
		body.collision_layer = 4
		var col = CollisionShape3D.new()
		var shape = BoxShape3D.new()
		shape.size = Vector3(bw, bh, bd)
		col.shape = shape
		col.position.y = bh / 2.0
		body.add_child(col)
		building.add_child(body)
		environment_container.add_child(building)

func _place_rocks(center: Vector3, size: Vector2, count: int) -> void:
	for i in range(count):
		var rock = MeshInstance3D.new()
		var rock_mesh = BoxMesh.new()
		var rs = randf_range(0.5, 2.5)
		rock_mesh.size = Vector3(rs * randf_range(0.8, 1.5), rs, rs * randf_range(0.8, 1.5))
		rock.mesh = rock_mesh
		var offset = Vector3(
			randf_range(-size.x / 2.5, size.x / 2.5),
			rs / 2.0,
			randf_range(-size.y / 2.5, size.y / 2.5)
		)
		rock.position = center + offset
		rock.rotation.y = randf_range(0, TAU)
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(
			randf_range(0.35, 0.55),
			randf_range(0.35, 0.5),
			randf_range(0.35, 0.45)
		)
		rock.material_override = mat
		environment_container.add_child(rock)

func _place_walls(center: Vector3, size: Vector2) -> void:
	var wall_h = 5.0
	var wall_thick = 1.0
	var half_x = size.x / 2.0
	var half_y = size.y / 2.0
	var wall_data = [
		[Vector3(center.x, wall_h / 2, center.z - half_y), Vector3(size.x, wall_h, wall_thick)],
		[Vector3(center.x, wall_h / 2, center.z + half_y), Vector3(size.x, wall_h, wall_thick)],
		[Vector3(center.x - half_x, wall_h / 2, center.z), Vector3(wall_thick, wall_h, size.y)],
		[Vector3(center.x + half_x, wall_h / 2, center.z), Vector3(wall_thick, wall_h, size.y)],
	]
	for wd in wall_data:
		var wall = MeshInstance3D.new()
		var mesh = BoxMesh.new()
		mesh.size = wd[1]
		wall.mesh = mesh
		wall.position = wd[0]
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(0.5, 0.35, 0.25)
		wall.material_override = mat
		var body = StaticBody3D.new()
		body.collision_layer = 4
		var col = CollisionShape3D.new()
		var shape = BoxShape3D.new()
		shape.size = wd[1]
		col.shape = shape
		body.add_child(col)
		wall.add_child(body)
		environment_container.add_child(wall)

func _spawn_monsters() -> void:
	for zone_name in GameData.ZONES:
		var zone = GameData.ZONES[zone_name]
		var zone_pos: Vector3 = zone["pos"]
		var zone_size: Vector2 = zone["size"]
		for monster_type in zone["monsters"]:
			var mdata = GameData.get_monster_data(monster_type)
			if mdata.is_empty():
				continue
			var is_boss = mdata.get("boss", false)
			var count = 1 if is_boss else randi_range(5, 10)
			for i in range(count):
				var inst = monster_scene.instantiate()
				inst.monster_name = monster_type
				inst.monster_level = mdata["level"]
				inst.is_boss = is_boss
				if is_boss:
					inst.position = zone_pos + Vector3(0, 1, 0)
				else:
					inst.position = zone_pos + Vector3(
						randf_range(-zone_size.x / 3, zone_size.x / 3),
						1,
						randf_range(-zone_size.y / 3, zone_size.y / 3)
					)
				monster_container.add_child(inst)

func _place_npcs() -> void:
	for npc_name in GameData.NPCS:
		var npc_data = GameData.NPCS[npc_name]
		var inst = npc_scene.instantiate()
		inst.npc_name = npc_name
		inst.npc_type = npc_data["type"]
		inst.position = npc_data["pos"] + Vector3(0, 1, 0)
		npc_container.add_child(inst)

func _process(delta: float) -> void:
	_update_day_night(delta)
	_check_zone()

func _update_day_night(delta: float) -> void:
	day_time += delta * day_cycle_speed
	if day_time > 1.0:
		day_time -= 1.0
	# Rotate sun
	var angle = day_time * TAU
	sun.rotation.x = -angle + PI / 4
	# Adjust light energy (dim at night)
	var energy = 0.3 + 0.7 * maxf(0, sin(angle))
	sun.light_energy = energy
	# Adjust color temperature
	var t = sin(angle)
	if t > 0:
		sun.light_color = Color(1.0, 0.95 + t * 0.05, 0.85 + t * 0.15)
	else:
		sun.light_color = Color(0.3, 0.3, 0.5)

func _check_zone() -> void:
	var ppos = player.position
	var new_zone = "Hoang Dã"
	for zone_name in GameData.ZONES:
		var zone = GameData.ZONES[zone_name]
		var zpos: Vector3 = zone["pos"]
		var zsize: Vector2 = zone["size"]
		if abs(ppos.x - zpos.x) < zsize.x / 2.0 and abs(ppos.z - zpos.z) < zsize.y / 2.0:
			new_zone = zone_name
			break
	if new_zone != current_zone:
		current_zone = new_zone
		EventBus.zone_changed.emit(current_zone)
