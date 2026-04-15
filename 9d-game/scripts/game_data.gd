extends Node

# =============================================================================
# GameData Autoload - 9D Cửu Long Tranh Bá
# Stores all game constants and player runtime state
# =============================================================================

# --- Player runtime state ---
var player_name: String = ""
var player_class: String = ""
var player_level: int = 1
var player_exp: int = 0
var player_hp: int = 0
var player_max_hp: int = 0
var player_mp: int = 0
var player_max_mp: int = 0
var player_gold: int = 100
var player_atk: int = 0
var player_def: int = 0
var player_speed: float = 0.0
var player_kill_count: int = 0
var inventory: Array = []
var equipment: Dictionary = {"weapon": "", "armor": ""}

const MAX_LEVEL := 50

# --- 8 Classes ---
const CLASSES := {
	"Thiếu Lâm": {
		"hp": 200, "mp": 80, "atk": 25, "def": 30, "speed": 5.0,
		"color": Color(0.8, 0.6, 0.2),
		"desc": "Thiền tâm bất động, quyền cước vô song",
		"type": "Tank / Cận Chiến",
	},
	"Cái Bang": {
		"hp": 150, "mp": 100, "atk": 35, "def": 20, "speed": 6.0,
		"color": Color(0.55, 0.35, 0.17),
		"desc": "Đả Cẩu Bổng Pháp, thiên hạ vô địch",
		"type": "DPS / Cận Chiến",
	},
	"Đường Môn": {
		"hp": 120, "mp": 120, "atk": 40, "def": 15, "speed": 6.0,
		"color": Color(0.4, 0.2, 0.6),
		"desc": "Ám khí vô hình, độc dược tuyệt kỹ",
		"type": "DPS / Tầm Xa",
	},
	"Thiên Vương": {
		"hp": 250, "mp": 60, "atk": 20, "def": 35, "speed": 4.0,
		"color": Color(0.2, 0.4, 0.7),
		"desc": "Thiên binh thần tướng, bất khả xâm phạm",
		"type": "Tank / Hỗ Trợ",
	},
	"Ngũ Độc": {
		"hp": 110, "mp": 150, "atk": 38, "def": 12, "speed": 5.0,
		"color": Color(0.0, 0.66, 0.42),
		"desc": "Ngũ độc kỳ thuật, vạn vật tương khắc",
		"type": "Pháp Sư / Debuff",
	},
	"Võ Đang": {
		"hp": 140, "mp": 130, "atk": 30, "def": 22, "speed": 6.0,
		"color": Color(0.4, 0.4, 0.8),
		"desc": "Thái Cực sinh lưỡng nghi, nhu khắc cương",
		"type": "Pháp Sư / Cận Chiến",
	},
	"Đào Hoa": {
		"hp": 130, "mp": 140, "atk": 28, "def": 18, "speed": 7.0,
		"color": Color(1.0, 0.41, 0.71),
		"desc": "Đào hoa phiến lạc, mê hoặc chúng sinh",
		"type": "Hỗ Trợ / Debuff",
	},
	"Côn Lôn": {
		"hp": 160, "mp": 110, "atk": 32, "def": 25, "speed": 5.5,
		"color": Color(0.7, 0.7, 0.86),
		"desc": "Côn Lôn kiếm phái, chính khí lẫm liệt",
		"type": "DPS / Cận Chiến",
	},
}

# --- Skills per class (4 each) ---
const CLASS_SKILLS := {
	"Thiếu Lâm": [
		{"name": "La Hán Quyền", "dmg": 1.5, "mp": 10, "cd": 2.0, "range": 4.0, "type": "damage", "desc": "Đấm mạnh gây sát thương"},
		{"name": "Kim Cang Phục Ma", "dmg": 2.0, "mp": 20, "cd": 5.0, "range": 5.0, "type": "aoe", "desc": "Công kích diện rộng"},
		{"name": "Thiết Bố Sam", "dmg": 0.0, "mp": 25, "cd": 8.0, "range": 0.0, "type": "buff", "desc": "Tăng phòng thủ 50%"},
		{"name": "Nhất Dương Chỉ", "dmg": 3.5, "mp": 40, "cd": 12.0, "range": 5.0, "type": "damage", "desc": "Chiêu sát thương cực mạnh"},
	],
	"Cái Bang": [
		{"name": "Đả Cẩu Bổng", "dmg": 1.8, "mp": 10, "cd": 1.5, "range": 4.5, "type": "damage", "desc": "Đánh nhanh bằng gậy"},
		{"name": "Hàng Long Thập Bát Chưởng", "dmg": 2.5, "mp": 25, "cd": 5.0, "range": 5.0, "type": "aoe", "desc": "18 chưởng liên hoàn"},
		{"name": "Lạc Anh Thần Kiếm", "dmg": 2.0, "mp": 20, "cd": 4.0, "range": 5.0, "type": "damage", "desc": "Kiếm pháp uy lực"},
		{"name": "Kháng Long Hữu Hối", "dmg": 4.0, "mp": 45, "cd": 15.0, "range": 6.0, "type": "damage", "desc": "Tuyệt chiêu Cái Bang"},
	],
	"Đường Môn": [
		{"name": "Ám Khí Liên Phát", "dmg": 1.5, "mp": 8, "cd": 1.2, "range": 15.0, "type": "damage", "desc": "Bắn ám khí liên tiếp"},
		{"name": "Độc Châm", "dmg": 1.8, "mp": 15, "cd": 3.0, "range": 12.0, "type": "damage", "desc": "Kim độc gây trúng độc"},
		{"name": "Bạo Vũ Lê Hoa", "dmg": 2.5, "mp": 25, "cd": 6.0, "range": 14.0, "type": "aoe", "desc": "Mưa ám khí diện rộng"},
		{"name": "Vạn Tiễn Tề Phát", "dmg": 3.8, "mp": 40, "cd": 12.0, "range": 18.0, "type": "damage", "desc": "Vạn mũi tên bắn ra"},
	],
	"Thiên Vương": [
		{"name": "Thiên Vương Chưởng", "dmg": 1.3, "mp": 10, "cd": 2.0, "range": 4.5, "type": "damage", "desc": "Chưởng lực mạnh mẽ"},
		{"name": "Hộ Thể Thần Công", "dmg": 0.0, "mp": 30, "cd": 8.0, "range": 0.0, "type": "buff", "desc": "Tăng HP và phòng thủ"},
		{"name": "Thiên Lôi Chấn", "dmg": 2.0, "mp": 25, "cd": 5.0, "range": 8.0, "type": "aoe", "desc": "Sét đánh kẻ địch"},
		{"name": "Bất Động Minh Vương", "dmg": 3.0, "mp": 45, "cd": 15.0, "range": 6.0, "type": "damage", "desc": "Tuyệt chiêu Thiên Vương"},
	],
	"Ngũ Độc": [
		{"name": "Độc Trùng Thuật", "dmg": 1.6, "mp": 10, "cd": 1.5, "range": 12.0, "type": "damage", "desc": "Triệu hồi trùng độc"},
		{"name": "Ngũ Độc Chướng", "dmg": 2.0, "mp": 20, "cd": 4.0, "range": 13.0, "type": "aoe", "desc": "Sương mù độc diện rộng"},
		{"name": "Hóa Cốt Miên Chưởng", "dmg": 2.5, "mp": 30, "cd": 6.0, "range": 10.0, "type": "damage", "desc": "Chưởng hóa xương cốt"},
		{"name": "Vạn Độc Quy Tông", "dmg": 4.0, "mp": 50, "cd": 15.0, "range": 14.0, "type": "damage", "desc": "Tuyệt chiêu ngũ độc"},
	],
	"Võ Đang": [
		{"name": "Thái Cực Kiếm", "dmg": 1.5, "mp": 10, "cd": 1.8, "range": 5.0, "type": "damage", "desc": "Kiếm pháp Thái Cực"},
		{"name": "Lưỡng Nghi Kiếm Pháp", "dmg": 2.0, "mp": 20, "cd": 4.0, "range": 6.0, "type": "damage", "desc": "Âm dương kiếm khí"},
		{"name": "Thuần Dương Vô Cực", "dmg": 0.0, "mp": 25, "cd": 7.0, "range": 0.0, "type": "heal", "desc": "Hồi phục HP và MP"},
		{"name": "Thái Cực Quyền", "dmg": 3.5, "mp": 40, "cd": 12.0, "range": 5.5, "type": "damage", "desc": "Tuyệt chiêu Võ Đang"},
	],
	"Đào Hoa": [
		{"name": "Đào Hoa Phiến", "dmg": 1.4, "mp": 8, "cd": 1.5, "range": 10.0, "type": "damage", "desc": "Quạt hoa đào"},
		{"name": "Mê Hồn Thuật", "dmg": 1.0, "mp": 20, "cd": 5.0, "range": 10.0, "type": "damage", "desc": "Làm chậm kẻ địch"},
		{"name": "Xuân Phong Hóa Vũ", "dmg": 0.0, "mp": 25, "cd": 7.0, "range": 0.0, "type": "heal", "desc": "Hồi HP cho bản thân"},
		{"name": "Lạc Hoa Phong Vũ", "dmg": 3.5, "mp": 45, "cd": 14.0, "range": 13.0, "type": "aoe", "desc": "Tuyệt chiêu Đào Hoa"},
	],
	"Côn Lôn": [
		{"name": "Côn Lôn Kiếm", "dmg": 1.6, "mp": 10, "cd": 1.6, "range": 5.0, "type": "damage", "desc": "Kiếm pháp cơ bản"},
		{"name": "Phá Quân Kiếm Thức", "dmg": 2.2, "mp": 20, "cd": 4.0, "range": 5.5, "type": "damage", "desc": "Phá giáp kẻ địch"},
		{"name": "Băng Tâm Quyết", "dmg": 0.0, "mp": 20, "cd": 6.0, "range": 0.0, "type": "buff", "desc": "Tăng tốc độ đánh"},
		{"name": "Lục Mạch Thần Kiếm", "dmg": 4.0, "mp": 45, "cd": 14.0, "range": 7.0, "type": "damage", "desc": "Tuyệt chiêu Côn Lôn"},
	],
}

# --- Monster definitions ---
const MONSTERS := {
	"Sói Hoang": {
		"hp": 80, "atk": 12, "def": 5, "exp": 20,
		"gold_min": 5, "gold_max": 15,
		"color": Color(0.6, 0.6, 0.6), "speed": 4.0,
		"aggro": 12.0, "respawn": 30.0, "size": 0.6, "level": 1,
	},
	"Cường Đạo": {
		"hp": 120, "atk": 18, "def": 8, "exp": 35,
		"gold_min": 10, "gold_max": 25,
		"color": Color(0.7, 0.4, 0.2), "speed": 4.5,
		"aggro": 14.0, "respawn": 35.0, "size": 0.8, "level": 3,
	},
	"Hổ Dữ": {
		"hp": 200, "atk": 25, "def": 12, "exp": 60,
		"gold_min": 15, "gold_max": 40,
		"color": Color(0.86, 0.63, 0.2), "speed": 5.0,
		"aggro": 15.0, "respawn": 40.0, "size": 0.9, "level": 6,
	},
	"Sơn Tặc Đầu Lĩnh": {
		"hp": 300, "atk": 30, "def": 18, "exp": 100,
		"gold_min": 25, "gold_max": 60,
		"color": Color(0.63, 0.2, 0.2), "speed": 4.0,
		"aggro": 15.0, "respawn": 45.0, "size": 1.0, "level": 10,
	},
	"Yêu Quái": {
		"hp": 400, "atk": 35, "def": 20, "exp": 150,
		"gold_min": 30, "gold_max": 80,
		"color": Color(0.4, 0.0, 0.6), "speed": 5.0,
		"aggro": 16.0, "respawn": 50.0, "size": 1.0, "level": 15,
	},
	"Thiên Ma": {
		"hp": 600, "atk": 45, "def": 25, "exp": 250,
		"gold_min": 50, "gold_max": 120,
		"color": Color(0.3, 0.0, 0.3), "speed": 4.5,
		"aggro": 18.0, "respawn": 60.0, "size": 1.1, "level": 20,
	},
	"Hắc Phong Boss": {
		"hp": 2000, "atk": 60, "def": 35, "exp": 800,
		"gold_min": 200, "gold_max": 500,
		"color": Color(0.12, 0.12, 0.12), "speed": 3.5,
		"aggro": 20.0, "respawn": 120.0, "size": 1.8, "level": 25,
		"boss": true,
	},
	"Long Vương Boss": {
		"hp": 5000, "atk": 80, "def": 50, "exp": 2000,
		"gold_min": 500, "gold_max": 1200,
		"color": Color(0.0, 0.2, 0.6), "speed": 3.0,
		"aggro": 22.0, "respawn": 180.0, "size": 2.2, "level": 35,
		"boss": true,
	},
}

# --- Items ---
const ITEMS := {
	"Tiểu Hoàn Đan": {"type": "consumable", "hp": 50, "mp": 0, "price": 20, "desc": "Hồi 50 HP"},
	"Trung Hoàn Đan": {"type": "consumable", "hp": 150, "mp": 0, "price": 60, "desc": "Hồi 150 HP"},
	"Đại Hoàn Đan": {"type": "consumable", "hp": 400, "mp": 0, "price": 150, "desc": "Hồi 400 HP"},
	"Tiểu Lam Đan": {"type": "consumable", "hp": 0, "mp": 30, "price": 20, "desc": "Hồi 30 MP"},
	"Trung Lam Đan": {"type": "consumable", "hp": 0, "mp": 80, "price": 60, "desc": "Hồi 80 MP"},
	"Đại Lam Đan": {"type": "consumable", "hp": 0, "mp": 200, "price": 150, "desc": "Hồi 200 MP"},
	"Kiếm Sắt": {"type": "weapon", "atk": 5, "price": 100, "desc": "+5 ATK"},
	"Kiếm Thép": {"type": "weapon", "atk": 12, "price": 300, "desc": "+12 ATK"},
	"Kiếm Huyền Thiết": {"type": "weapon", "atk": 25, "price": 800, "desc": "+25 ATK"},
	"Thanh Long Đao": {"type": "weapon", "atk": 40, "price": 2000, "desc": "+40 ATK"},
	"Áo Vải": {"type": "armor", "def": 3, "price": 80, "desc": "+3 DEF"},
	"Áo Da": {"type": "armor", "def": 8, "price": 250, "desc": "+8 DEF"},
	"Giáp Sắt": {"type": "armor", "def": 15, "price": 600, "desc": "+15 DEF"},
	"Huyền Thiết Giáp": {"type": "armor", "def": 30, "price": 1800, "desc": "+30 DEF"},
}

# --- Zones ---
const ZONES := {
	"Tân Thủ Thôn": {
		"pos": Vector3(0, 0, 0), "size": Vector2(80, 80),
		"color": Color(0.3, 0.7, 0.3),
		"monsters": ["Sói Hoang"],
		"level_range": Vector2i(1, 5),
		"desc": "Làng tân thủ, nơi bắt đầu hành trình",
	},
	"Lâm An Thành": {
		"pos": Vector3(-100, 0, -100), "size": Vector2(60, 60),
		"color": Color(0.7, 0.6, 0.4),
		"monsters": [],
		"level_range": Vector2i(1, 50),
		"desc": "Thành phố lớn, nơi mua bán trao đổi",
	},
	"Hoàng Sơn": {
		"pos": Vector3(100, 0, -50), "size": Vector2(100, 100),
		"color": Color(0.2, 0.5, 0.2),
		"monsters": ["Cường Đạo", "Hổ Dữ", "Sơn Tặc Đầu Lĩnh"],
		"level_range": Vector2i(3, 15),
		"desc": "Núi rừng hiểm trở, quái vật hoành hành",
	},
	"Giang Hồ Lộ": {
		"pos": Vector3(0, 0, 120), "size": Vector2(120, 80),
		"color": Color(0.6, 0.5, 0.3),
		"monsters": ["Cường Đạo", "Yêu Quái", "Hắc Phong Boss"],
		"level_range": Vector2i(10, 25),
		"desc": "Con đường giang hồ, hiểm nguy rình rập",
	},
	"Tử Cấm Thành": {
		"pos": Vector3(150, 0, 100), "size": Vector2(80, 80),
		"color": Color(0.5, 0.2, 0.2),
		"monsters": ["Thiên Ma", "Yêu Quái", "Long Vương Boss"],
		"level_range": Vector2i(20, 40),
		"desc": "Tử Cấm Thành, nơi ẩn chứa bí mật",
	},
	"Mộ Dung Trang": {
		"pos": Vector3(-120, 0, 80), "size": Vector2(70, 70),
		"color": Color(0.4, 0.3, 0.5),
		"monsters": ["Hổ Dữ", "Sơn Tặc Đầu Lĩnh", "Thiên Ma"],
		"level_range": Vector2i(8, 22),
		"desc": "Mộ Dung thế gia, cao thủ tứ phương",
	},
}

# --- NPCs ---
const NPCS := {
	"Vương Ngũ": {
		"type": "shop_potion", "zone": "Tân Thủ Thôn",
		"pos": Vector3(10, 0, 5),
		"items": ["Tiểu Hoàn Đan", "Trung Hoàn Đan", "Đại Hoàn Đan", "Tiểu Lam Đan", "Trung Lam Đan", "Đại Lam Đan"],
		"dialog": "Đan dược thượng hạng, mua đi bạn hiền!",
	},
	"Trần Đại Sư": {
		"type": "trainer", "zone": "Tân Thủ Thôn",
		"pos": Vector3(-10, 0, 8),
		"items": [],
		"dialog": "Ta sẽ truyền thụ võ công cho ngươi.",
	},
	"Trương Tam Phong": {
		"type": "shop_weapon", "zone": "Lâm An Thành",
		"pos": Vector3(-90, 0, -95),
		"items": ["Kiếm Sắt", "Kiếm Thép", "Kiếm Huyền Thiết", "Thanh Long Đao"],
		"dialog": "Thần binh lợi khí, bạn muốn xem gì?",
	},
	"Lý Tứ Hải": {
		"type": "shop_armor", "zone": "Lâm An Thành",
		"pos": Vector3(-95, 0, -85),
		"items": ["Áo Vải", "Áo Da", "Giáp Sắt", "Huyền Thiết Giáp"],
		"dialog": "Giáp phục bảo vệ, không lo hiểm nguy!",
	},
	"Lão Tiền Trang": {
		"type": "quest", "zone": "Lâm An Thành",
		"pos": Vector3(-85, 0, -90),
		"items": [],
		"dialog": "Giang hồ đang loạn, anh hùng hãy giúp ta!",
	},
}

# =============================================================================
# Functions
# =============================================================================

func exp_for_level(level: int) -> int:
	return int(100.0 * pow(level, 1.5))

func get_class_data(class_name_str: String) -> Dictionary:
	if CLASSES.has(class_name_str):
		return CLASSES[class_name_str]
	return {}

func get_skills(class_name_str: String) -> Array:
	if CLASS_SKILLS.has(class_name_str):
		return CLASS_SKILLS[class_name_str]
	return []

func get_monster_data(m_name: String) -> Dictionary:
	if MONSTERS.has(m_name):
		return MONSTERS[m_name]
	return {}

func get_item_data(item_name: String) -> Dictionary:
	if ITEMS.has(item_name):
		return ITEMS[item_name]
	return {}

func init_player(p_name: String, char_class: String) -> void:
	player_name = p_name
	player_class = char_class
	player_level = 1
	player_exp = 0
	player_gold = 100
	player_kill_count = 0
	inventory = [
		{"name": "Tiểu Hoàn Đan", "count": 5},
		{"name": "Tiểu Lam Đan", "count": 3},
	]
	equipment = {"weapon": "", "armor": ""}
	recalc_stats()
	player_hp = player_max_hp
	player_mp = player_max_mp

func recalc_stats() -> void:
	var base = get_class_data(player_class)
	if base.is_empty():
		return
	player_max_hp = base["hp"] + player_level * 15
	player_max_mp = base["mp"] + player_level * 8
	player_atk = base["atk"] + player_level * 3
	player_def = base["def"] + player_level * 2
	player_speed = base["speed"]
	# Equipment bonuses
	if equipment["weapon"] != "":
		var w = get_item_data(equipment["weapon"])
		if not w.is_empty():
			player_atk += w.get("atk", 0)
	if equipment["armor"] != "":
		var a = get_item_data(equipment["armor"])
		if not a.is_empty():
			player_def += a.get("def", 0)

func gain_exp(amount: int) -> bool:
	player_exp += amount
	var leveled := false
	while player_level < MAX_LEVEL and player_exp >= exp_for_level(player_level):
		player_exp -= exp_for_level(player_level)
		player_level += 1
		recalc_stats()
		player_hp = player_max_hp
		player_mp = player_max_mp
		leveled = true
	return leveled

func add_item(item_name: String, count: int = 1) -> void:
	for item in inventory:
		if item["name"] == item_name:
			item["count"] += count
			return
	inventory.append({"name": item_name, "count": count})

func remove_item(item_name: String, count: int = 1) -> bool:
	for i in range(inventory.size()):
		if inventory[i]["name"] == item_name:
			inventory[i]["count"] -= count
			if inventory[i]["count"] <= 0:
				inventory.remove_at(i)
			return true
	return false

func use_item(item_name: String) -> bool:
	var data = get_item_data(item_name)
	if data.is_empty() or data["type"] != "consumable":
		return false
	for item in inventory:
		if item["name"] == item_name and item["count"] > 0:
			player_hp = mini(player_hp + data.get("hp", 0), player_max_hp)
			player_mp = mini(player_mp + data.get("mp", 0), player_max_mp)
			remove_item(item_name)
			return true
	return false

func equip_item(item_name: String) -> void:
	var data = get_item_data(item_name)
	if data.is_empty():
		return
	var slot = ""
	if data["type"] == "weapon":
		slot = "weapon"
	elif data["type"] == "armor":
		slot = "armor"
	else:
		return
	# Unequip current
	if equipment[slot] != "":
		add_item(equipment[slot])
	# Equip new
	remove_item(item_name)
	equipment[slot] = item_name
	recalc_stats()

func unequip_item(slot: String) -> void:
	if equipment.has(slot) and equipment[slot] != "":
		add_item(equipment[slot])
		equipment[slot] = ""
		recalc_stats()

func save_game() -> void:
	var save_data := {
		"name": player_name,
		"class": player_class,
		"level": player_level,
		"exp": player_exp,
		"hp": player_hp,
		"mp": player_mp,
		"gold": player_gold,
		"kills": player_kill_count,
		"inventory": inventory,
		"equipment": equipment,
	}
	var file = FileAccess.open("user://savegame.json", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data, "\t"))

func load_game() -> bool:
	if not FileAccess.file_exists("user://savegame.json"):
		return false
	var file = FileAccess.open("user://savegame.json", FileAccess.READ)
	if not file:
		return false
	var json = JSON.new()
	if json.parse(file.get_as_text()) != OK:
		return false
	var data = json.data
	player_name = data.get("name", "")
	player_class = data.get("class", "")
	player_level = data.get("level", 1)
	player_exp = data.get("exp", 0)
	player_gold = data.get("gold", 100)
	player_kill_count = data.get("kills", 0)
	inventory = data.get("inventory", [])
	equipment = data.get("equipment", {"weapon": "", "armor": ""})
	recalc_stats()
	player_hp = data.get("hp", player_max_hp)
	player_mp = data.get("mp", player_max_mp)
	return true

func has_save() -> bool:
	return FileAccess.file_exists("user://savegame.json")
