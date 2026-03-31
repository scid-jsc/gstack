"""Game settings and constants."""

# Screen
SCREEN_WIDTH = 1280
SCREEN_HEIGHT = 720
FPS = 60
TILE_SIZE = 48

# Map
MAP_WIDTH = 200   # tiles
MAP_HEIGHT = 200  # tiles

# Colors - Wuxia theme
BLACK = (0, 0, 0)
WHITE = (255, 255, 255)
RED = (200, 50, 50)
DARK_RED = (139, 0, 0)
GOLD = (218, 165, 32)
BRIGHT_GOLD = (255, 215, 0)
JADE_GREEN = (0, 168, 107)
DARK_GREEN = (0, 100, 0)
BROWN = (139, 90, 43)
DARK_BROWN = (80, 50, 20)
LIGHT_BROWN = (181, 137, 87)
BLUE = (70, 130, 180)
DARK_BLUE = (25, 25, 80)
PURPLE = (128, 0, 128)
ORANGE = (255, 140, 0)
GRAY = (128, 128, 128)
DARK_GRAY = (64, 64, 64)
LIGHT_GRAY = (192, 192, 192)
SKY_BLUE = (135, 206, 235)
FOREST_GREEN = (34, 139, 34)
WATER_BLUE = (64, 164, 223)
SAND = (210, 180, 140)
UI_BG = (20, 15, 10, 200)
UI_BORDER = (180, 140, 60)
UI_DARK = (30, 20, 10)
HP_RED = (220, 50, 50)
MP_BLUE = (50, 100, 220)
EXP_GOLD = (200, 180, 50)
SKILL_CD = (100, 100, 100, 180)

# Character classes
CLASS_THIEU_LAM = "Thiếu Lâm"
CLASS_CAI_BANG = "Cái Bang"
CLASS_DUONG_MON = "Đường Môn"
CLASS_THIEN_VUONG = "Thiên Vương"
CLASS_NGU_DOC = "Ngũ Độc"
CLASS_VO_DANG = "Võ Đang"
CLASS_DAO_HOA = "Đào Hoa"
CLASS_CON_LON = "Côn Lôn"

CLASSES = [
    CLASS_THIEU_LAM, CLASS_CAI_BANG, CLASS_DUONG_MON, CLASS_THIEN_VUONG,
    CLASS_NGU_DOC, CLASS_VO_DANG, CLASS_DAO_HOA, CLASS_CON_LON,
]

# Base stats per class: hp, mp, atk, def, speed, color
CLASS_STATS = {
    CLASS_THIEU_LAM: {
        "hp": 200, "mp": 80, "atk": 25, "def": 30, "speed": 3,
        "color": (200, 150, 50),
        "desc": "Thiền tâm bất động, quyền cước vô song",
        "type": "Tank / Cận Chiến",
    },
    CLASS_CAI_BANG: {
        "hp": 150, "mp": 100, "atk": 35, "def": 20, "speed": 4,
        "color": (139, 90, 43),
        "desc": "Đả Cẩu Bổng Pháp, thiên hạ vô địch",
        "type": "DPS / Cận Chiến",
    },
    CLASS_DUONG_MON: {
        "hp": 120, "mp": 120, "atk": 40, "def": 15, "speed": 4,
        "color": (100, 50, 150),
        "desc": "Ám khí vô hình, độc dược tuyệt kỹ",
        "type": "DPS / Tầm Xa",
    },
    CLASS_THIEN_VUONG: {
        "hp": 250, "mp": 60, "atk": 20, "def": 35, "speed": 2,
        "color": (50, 100, 180),
        "desc": "Thiên binh thần tướng, bất khả xâm phạm",
        "type": "Tank / Hỗ Trợ",
    },
    CLASS_NGU_DOC: {
        "hp": 110, "mp": 150, "atk": 38, "def": 12, "speed": 3,
        "color": (0, 168, 107),
        "desc": "Ngũ độc kỳ thuật, vạn vật tương khắc",
        "type": "Pháp Sư / Debuff",
    },
    CLASS_VO_DANG: {
        "hp": 140, "mp": 130, "atk": 30, "def": 22, "speed": 4,
        "color": (100, 100, 200),
        "desc": "Thái Cực sinh lưỡng nghi, nhu khắc cương",
        "type": "Pháp Sư / Cận Chiến",
    },
    CLASS_DAO_HOA: {
        "hp": 130, "mp": 140, "atk": 28, "def": 18, "speed": 5,
        "color": (255, 105, 180),
        "desc": "Đào hoa phiến lạc, mê hoặc chúng sinh",
        "type": "Hỗ Trợ / Debuff",
    },
    CLASS_CON_LON: {
        "hp": 160, "mp": 110, "atk": 32, "def": 25, "speed": 3,
        "color": (180, 180, 220),
        "desc": "Côn Lôn kiếm phái, chính khí lẫm liệt",
        "type": "DPS / Cận Chiến",
    },
}

# Skills per class: name, damage_mult, mp_cost, cooldown(ms), range, color, description
CLASS_SKILLS = {
    CLASS_THIEU_LAM: [
        {"name": "La Hán Quyền", "dmg": 1.5, "mp": 10, "cd": 2000, "range": 60, "color": GOLD, "desc": "Đấm mạnh gây sát thương"},
        {"name": "Kim Cang Phục Ma", "dmg": 2.0, "mp": 20, "cd": 5000, "range": 80, "color": ORANGE, "desc": "Công kích diện rộng"},
        {"name": "Thiết Bố Sam", "dmg": 0, "mp": 25, "cd": 8000, "range": 0, "color": BLUE, "desc": "Tăng phòng thủ 50%"},
        {"name": "Nhất Dương Chỉ", "dmg": 3.5, "mp": 40, "cd": 12000, "range": 100, "color": RED, "desc": "Chiêu sát thương cực mạnh"},
    ],
    CLASS_CAI_BANG: [
        {"name": "Đả Cẩu Bổng", "dmg": 1.8, "mp": 10, "cd": 1500, "range": 70, "color": BROWN, "desc": "Đánh nhanh bằng gậy"},
        {"name": "Hàng Long Thập Bát Chưởng", "dmg": 2.5, "mp": 25, "cd": 5000, "range": 90, "color": GOLD, "desc": "18 chưởng liên hoàn"},
        {"name": "Lạc Anh Thần Kiếm", "dmg": 2.0, "mp": 20, "cd": 4000, "range": 80, "color": JADE_GREEN, "desc": "Kiếm pháp uy lực"},
        {"name": "Kháng Long Hữu Hối", "dmg": 4.0, "mp": 45, "cd": 15000, "range": 120, "color": BRIGHT_GOLD, "desc": "Tuyệt chiêu Cái Bang"},
    ],
    CLASS_DUONG_MON: [
        {"name": "Ám Khí Liên Phát", "dmg": 1.5, "mp": 8, "cd": 1200, "range": 200, "color": GRAY, "desc": "Bắn ám khí liên tiếp"},
        {"name": "Độc Châm", "dmg": 1.8, "mp": 15, "cd": 3000, "range": 180, "color": JADE_GREEN, "desc": "Kim độc gây trúng độc"},
        {"name": "Bạo Vũ Lê Hoa", "dmg": 2.5, "mp": 25, "cd": 6000, "range": 220, "color": PURPLE, "desc": "Mưa ám khí diện rộng"},
        {"name": "Vạn Tiễn Tề Phát", "dmg": 3.8, "mp": 40, "cd": 12000, "range": 250, "color": DARK_RED, "desc": "Vạn mũi tên bắn ra"},
    ],
    CLASS_THIEN_VUONG: [
        {"name": "Thiên Vương Chưởng", "dmg": 1.3, "mp": 10, "cd": 2000, "range": 70, "color": BLUE, "desc": "Chưởng lực mạnh mẽ"},
        {"name": "Hộ Thể Thần Công", "dmg": 0, "mp": 30, "cd": 8000, "range": 0, "color": SKY_BLUE, "desc": "Tăng HP và phòng thủ"},
        {"name": "Thiên Lôi Chấn", "dmg": 2.0, "mp": 25, "cd": 5000, "range": 100, "color": BRIGHT_GOLD, "desc": "Sét đánh kẻ địch"},
        {"name": "Bất Động Minh Vương", "dmg": 3.0, "mp": 45, "cd": 15000, "range": 120, "color": GOLD, "desc": "Tuyệt chiêu Thiên Vương"},
    ],
    CLASS_NGU_DOC: [
        {"name": "Độc Trùng Thuật", "dmg": 1.6, "mp": 10, "cd": 1500, "range": 180, "color": JADE_GREEN, "desc": "Triệu hồi trùng độc"},
        {"name": "Ngũ Độc Chướng", "dmg": 2.0, "mp": 20, "cd": 4000, "range": 200, "color": PURPLE, "desc": "Sương mù độc diện rộng"},
        {"name": "Hóa Cốt Miên Chưởng", "dmg": 2.5, "mp": 30, "cd": 6000, "range": 160, "color": DARK_GREEN, "desc": "Chưởng hóa xương cốt"},
        {"name": "Vạn Độc Quy Tông", "dmg": 4.0, "mp": 50, "cd": 15000, "range": 220, "color": (0, 200, 0), "desc": "Tuyệt chiêu ngũ độc"},
    ],
    CLASS_VO_DANG: [
        {"name": "Thái Cực Kiếm", "dmg": 1.5, "mp": 10, "cd": 1800, "range": 80, "color": (150, 150, 255), "desc": "Kiếm pháp Thái Cực"},
        {"name": "Lưỡng Nghi Kiếm Pháp", "dmg": 2.0, "mp": 20, "cd": 4000, "range": 100, "color": WHITE, "desc": "Âm dương kiếm khí"},
        {"name": "Thuần Dương Vô Cực", "dmg": 0, "mp": 25, "cd": 7000, "range": 0, "color": BRIGHT_GOLD, "desc": "Hồi phục HP và MP"},
        {"name": "Thái Cực Quyền", "dmg": 3.5, "mp": 40, "cd": 12000, "range": 110, "color": (200, 200, 255), "desc": "Tuyệt chiêu Võ Đang"},
    ],
    CLASS_DAO_HOA: [
        {"name": "Đào Hoa Phiến", "dmg": 1.4, "mp": 8, "cd": 1500, "range": 150, "color": (255, 150, 200), "desc": "Quạt hoa đào"},
        {"name": "Mê Hồn Thuật", "dmg": 1.0, "mp": 20, "cd": 5000, "range": 160, "color": (255, 100, 150), "desc": "Làm chậm kẻ địch"},
        {"name": "Xuân Phong Hóa Vũ", "dmg": 0, "mp": 25, "cd": 7000, "range": 0, "color": (255, 200, 220), "desc": "Hồi HP cho bản thân"},
        {"name": "Lạc Hoa Phong Vũ", "dmg": 3.5, "mp": 45, "cd": 14000, "range": 200, "color": (255, 50, 100), "desc": "Tuyệt chiêu Đào Hoa"},
    ],
    CLASS_CON_LON: [
        {"name": "Côn Lôn Kiếm", "dmg": 1.6, "mp": 10, "cd": 1600, "range": 75, "color": (200, 200, 240), "desc": "Kiếm pháp cơ bản"},
        {"name": "Phá Quân Kiếm Thức", "dmg": 2.2, "mp": 20, "cd": 4000, "range": 90, "color": (180, 180, 255), "desc": "Phá giáp kẻ địch"},
        {"name": "Băng Tâm Quyết", "dmg": 0, "mp": 20, "cd": 6000, "range": 0, "color": SKY_BLUE, "desc": "Tăng tốc độ đánh"},
        {"name": "Lục Mạch Thần Kiếm", "dmg": 4.0, "mp": 45, "cd": 14000, "range": 130, "color": (220, 220, 255), "desc": "Tuyệt chiêu Côn Lôn"},
    ],
}

# Monster types: name, hp, atk, def, exp, gold, color, speed, aggro_range, respawn_time
MONSTERS = {
    "Sói Hoang": {
        "hp": 80, "atk": 12, "def": 5, "exp": 20, "gold": (5, 15),
        "color": (150, 150, 150), "speed": 2, "aggro": 150, "respawn": 5000,
        "size": 20, "level": 1,
    },
    "Cường Đạo": {
        "hp": 120, "atk": 18, "def": 8, "exp": 35, "gold": (10, 25),
        "color": (180, 100, 50), "speed": 2, "aggro": 180, "respawn": 6000,
        "size": 24, "level": 3,
    },
    "Hổ Dữ": {
        "hp": 200, "atk": 25, "def": 12, "exp": 60, "gold": (15, 40),
        "color": (220, 160, 50), "speed": 3, "aggro": 200, "respawn": 8000,
        "size": 28, "level": 6,
    },
    "Sơn Tặc Đầu Lĩnh": {
        "hp": 300, "atk": 30, "def": 18, "exp": 100, "gold": (25, 60),
        "color": (160, 50, 50), "speed": 2, "aggro": 200, "respawn": 10000,
        "size": 30, "level": 10,
    },
    "Yêu Quái": {
        "hp": 400, "atk": 35, "def": 20, "exp": 150, "gold": (30, 80),
        "color": (100, 0, 150), "speed": 3, "aggro": 220, "respawn": 12000,
        "size": 32, "level": 15,
    },
    "Thiên Ma": {
        "hp": 600, "atk": 45, "def": 25, "exp": 250, "gold": (50, 120),
        "color": (80, 0, 80), "speed": 2, "aggro": 250, "respawn": 15000,
        "size": 36, "level": 20,
    },
    "Hắc Phong Boss": {
        "hp": 2000, "atk": 60, "def": 35, "exp": 800, "gold": (200, 500),
        "color": (30, 30, 30), "speed": 1, "aggro": 300, "respawn": 60000,
        "size": 48, "level": 25, "boss": True,
    },
    "Long Vương Boss": {
        "hp": 5000, "atk": 80, "def": 50, "exp": 2000, "gold": (500, 1200),
        "color": (0, 50, 150), "speed": 1, "aggro": 350, "respawn": 120000,
        "size": 56, "level": 35, "boss": True,
    },
}

# Items
ITEM_TYPES = {
    "Tiểu Hoàn Đan": {"type": "consumable", "hp": 50, "price": 20, "desc": "Hồi 50 HP"},
    "Trung Hoàn Đan": {"type": "consumable", "hp": 150, "price": 60, "desc": "Hồi 150 HP"},
    "Đại Hoàn Đan": {"type": "consumable", "hp": 400, "price": 150, "desc": "Hồi 400 HP"},
    "Tiểu Lam Đan": {"type": "consumable", "mp": 30, "price": 20, "desc": "Hồi 30 MP"},
    "Trung Lam Đan": {"type": "consumable", "mp": 80, "price": 60, "desc": "Hồi 80 MP"},
    "Đại Lam Đan": {"type": "consumable", "mp": 200, "price": 150, "desc": "Hồi 200 MP"},
    "Kiếm Sắt": {"type": "weapon", "atk": 5, "price": 100, "desc": "Vũ khí cơ bản +5 ATK"},
    "Kiếm Thép": {"type": "weapon", "atk": 12, "price": 300, "desc": "Vũ khí tốt +12 ATK"},
    "Kiếm Huyền Thiết": {"type": "weapon", "atk": 25, "price": 800, "desc": "Vũ khí mạnh +25 ATK"},
    "Thanh Long Đao": {"type": "weapon", "atk": 40, "price": 2000, "desc": "Thần binh +40 ATK"},
    "Áo Vải": {"type": "armor", "def": 3, "price": 80, "desc": "Giáp cơ bản +3 DEF"},
    "Áo Da": {"type": "armor", "def": 8, "price": 250, "desc": "Giáp tốt +8 DEF"},
    "Giáp Sắt": {"type": "armor", "def": 15, "price": 600, "desc": "Giáp mạnh +15 DEF"},
    "Huyền Thiết Giáp": {"type": "armor", "def": 30, "price": 1800, "desc": "Thần giáp +30 DEF"},
}

# Level thresholds
def exp_for_level(level):
    """EXP needed to reach next level."""
    return int(100 * (level ** 1.5))

MAX_LEVEL = 50
