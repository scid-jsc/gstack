"""Player character for 2D top-down wuxia RPG (9D clone)."""

import math
import random
import pygame

from settings import (
    CLASS_STATS,
    CLASS_SKILLS,
    TILE_SIZE,
    exp_for_level,
    MAX_LEVEL,
    ITEM_TYPES,
    GOLD,
    WHITE,
    BLACK,
    RED,
    HP_RED,
    MP_BLUE,
    BRIGHT_GOLD,
)

# Spawn point for Tan Thu Thon (starter village) -- centre of the map region.
SPAWN_X = 100 * TILE_SIZE
SPAWN_Y = 100 * TILE_SIZE

# Animation constants
ANIM_BOB_SPEED = 8.0        # walking bob frequency
ANIM_BOB_AMP = 2.0          # walking bob amplitude (pixels)
ANIM_ATTACK_FLASH = 0.15    # seconds of attack flash
ANIM_SKILL_GLOW = 0.4       # seconds of skill glow

# Regen intervals (seconds)
HP_REGEN_INTERVAL = 2.0
MP_REGEN_INTERVAL = 3.0

# Combat grace period -- seconds after last hit before regen kicks in.
COMBAT_TIMEOUT = 5.0


class Player:
    """Playable wuxia character."""

    # ------------------------------------------------------------------
    # Initialisation
    # ------------------------------------------------------------------

    def __init__(self, name: str, char_class: str, x: float, y: float):
        self.name = name
        self.char_class = char_class

        # Base stats from class definition.
        stats = CLASS_STATS[char_class]
        self.base_hp: int = stats["hp"]
        self.base_mp: int = stats["mp"]
        self.base_atk: int = stats["atk"]
        self.base_def: int = stats["def"]
        self.base_speed: int = stats["speed"]
        self.color: tuple = stats["color"]

        # Skills list (dicts).
        self.skills: list = list(CLASS_SKILLS[char_class])

        # World position (float pixels).
        self.x: float = float(x)
        self.y: float = float(y)

        # Velocity components.
        self.vx: float = 0.0
        self.vy: float = 0.0

        # Facing direction in radians (0 = right, pi/2 = down).
        self.facing: float = 0.0

        # Level / experience.
        self.level: int = 1
        self.exp: int = 0

        # Derived stats -- set by _recalc_stats().
        self.max_hp: int = 0
        self.max_mp: int = 0
        self.atk: int = 0
        self.defense: int = 0
        self.speed: float = 0.0
        self._recalc_stats()

        # Current resources.
        self.hp: int = self.max_hp
        self.mp: int = self.max_mp

        # Inventory: list of {"name": str, "count": int}.
        self.inventory: list = []

        # Equipment slots.
        self.equipment: dict = {"weapon": None, "armor": None}

        # Currency.
        self.gold: int = 100

        # Skill cooldowns: skill_name -> last_used pygame.time tick (ms).
        self.skill_cooldowns: dict = {s["name"]: 0 for s in self.skills}

        # Targeting.
        self.target = None          # reference to a Monster (or None)
        self.auto_attack: bool = False

        # Basic-attack timing.
        self.attack_cd: int = 1000  # milliseconds
        self.last_attack_time: int = 0

        # Buff timers: buff_name -> expire_time (pygame ticks ms).
        self.buff_timers: dict = {}

        # Animation state: "idle" | "walking" | "attacking" | "skill"
        self.anim_state: str = "idle"
        self.anim_timer: float = 0.0
        self._skill_glow_color: tuple | None = None

        # Alive flag.
        self.alive: bool = True

        # Statistics.
        self.kill_count: int = 0

        # Regen accumulators (seconds).
        self._hp_regen_acc: float = 0.0
        self._mp_regen_acc: float = 0.0

        # Track last-damage time for combat regen gating.
        self._last_combat_time: float = 0.0

        # Internal rect used for camera / collision.
        self.rect: pygame.Rect = pygame.Rect(int(self.x) - 16, int(self.y) - 16, 32, 32)

    # ------------------------------------------------------------------
    # Stat helpers
    # ------------------------------------------------------------------

    def _recalc_stats(self):
        """Recalculate derived stats from base + level + equipment."""
        self.max_hp = self.base_hp + self.level * 15
        self.max_mp = self.base_mp + self.level * 8
        self.atk = self.base_atk + self.level * 3 + self._equip_bonus("atk")
        self.defense = self.base_def + self.level * 2 + self._equip_bonus("def")
        self.speed = self.base_speed

    def _equip_bonus(self, stat: str) -> int:
        """Sum equipment bonus for *stat* ('atk' or 'def')."""
        total = 0
        for slot in ("weapon", "armor"):
            item_name = self.equipment.get(slot)
            if item_name and item_name in ITEM_TYPES:
                total += ITEM_TYPES[item_name].get(stat, 0)
        return total

    # ------------------------------------------------------------------
    # Main update
    # ------------------------------------------------------------------

    def update(self, dt: float, keys, world):
        """Per-frame update.

        *dt*   -- frame delta in seconds.
        *keys* -- pygame key-state array (pygame.key.get_pressed()).
        *world* -- the World object (used for collision queries).
        """
        if not self.alive:
            return

        # --- Movement input ---
        dx, dy = 0.0, 0.0
        if keys[pygame.K_w] or keys[pygame.K_UP]:
            dy -= 1.0
        if keys[pygame.K_s] or keys[pygame.K_DOWN]:
            dy += 1.0
        if keys[pygame.K_a] or keys[pygame.K_LEFT]:
            dx -= 1.0
        if keys[pygame.K_d] or keys[pygame.K_RIGHT]:
            dx += 1.0

        # Normalise diagonal movement.
        length = math.hypot(dx, dy)
        if length > 0:
            dx /= length
            dy /= length
            self.facing = math.atan2(dy, dx)

        move_speed = self.speed * TILE_SIZE * dt
        new_x = self.x + dx * move_speed
        new_y = self.y + dy * move_speed

        # Collision detection with world objects.
        test_rect = pygame.Rect(int(new_x) - 16, int(new_y) - 16, 32, 32)
        if world is not None and hasattr(world, "collides"):
            if not world.collides(test_rect):
                self.x = new_x
                self.y = new_y
        else:
            self.x = new_x
            self.y = new_y

        # Sync rect.
        self.rect.x = int(self.x) - 16
        self.rect.y = int(self.y) - 16

        # --- Animation state ---
        if length > 0:
            self.anim_state = "walking"
        elif self.anim_state == "walking":
            self.anim_state = "idle"

        # Decay attack / skill animation timers.
        if self.anim_state in ("attacking", "skill"):
            self.anim_timer -= dt
            if self.anim_timer <= 0:
                self.anim_state = "idle"
                self.anim_timer = 0.0
                self._skill_glow_color = None

        # --- Regen (out of combat) ---
        now_sec = pygame.time.get_ticks() / 1000.0
        if now_sec - self._last_combat_time > COMBAT_TIMEOUT:
            self._hp_regen_acc += dt
            self._mp_regen_acc += dt
            if self._hp_regen_acc >= HP_REGEN_INTERVAL:
                ticks = int(self._hp_regen_acc / HP_REGEN_INTERVAL)
                self.hp = min(self.hp + ticks, self.max_hp)
                self._hp_regen_acc -= ticks * HP_REGEN_INTERVAL
            if self._mp_regen_acc >= MP_REGEN_INTERVAL:
                ticks = int(self._mp_regen_acc / MP_REGEN_INTERVAL)
                self.mp = min(self.mp + ticks, self.max_mp)
                self._mp_regen_acc -= ticks * MP_REGEN_INTERVAL
        else:
            self._hp_regen_acc = 0.0
            self._mp_regen_acc = 0.0

        # --- Buff expiry ---
        now_ms = pygame.time.get_ticks()
        expired = [b for b, t in self.buff_timers.items() if now_ms >= t]
        for b in expired:
            del self.buff_timers[b]

        # --- Auto-attack ---
        if self.auto_attack and self.target is not None:
            if hasattr(self.target, "alive") and not self.target.alive:
                self.target = None
            elif self.target is not None:
                self.basic_attack()

        # Deselect dead target.
        if self.target is not None and hasattr(self.target, "alive") and not self.target.alive:
            self.target = None

    # ------------------------------------------------------------------
    # Combat
    # ------------------------------------------------------------------

    def use_skill(self, skill_index: int):
        """Attempt to use a skill by its index (0-based).

        Returns ``(damage, skill_dict)`` on success, or ``None`` if the
        skill cannot be used right now.
        """
        if not self.alive:
            return None
        if skill_index < 0 or skill_index >= len(self.skills):
            return None

        skill = self.skills[skill_index]
        now_ms = pygame.time.get_ticks()

        # Cooldown check.
        last_used = self.skill_cooldowns.get(skill["name"], 0)
        if now_ms - last_used < skill["cd"]:
            return None

        # MP check.
        if self.mp < skill["mp"]:
            return None

        # Consume MP and set cooldown.
        self.mp -= skill["mp"]
        self.skill_cooldowns[skill["name"]] = now_ms

        # Mark combat time.
        self._last_combat_time = now_ms / 1000.0

        # Buff-type skills (dmg == 0).
        if skill["dmg"] == 0:
            self._apply_buff(skill, now_ms)
            self.anim_state = "skill"
            self.anim_timer = ANIM_SKILL_GLOW
            self._skill_glow_color = skill.get("color", BRIGHT_GOLD)
            return (0, skill)

        # Damage calculation.
        damage = self.atk * skill["dmg"] * (1.0 + self.level * 0.05)
        damage = int(damage)

        self.anim_state = "skill"
        self.anim_timer = ANIM_SKILL_GLOW
        self._skill_glow_color = skill.get("color", BRIGHT_GOLD)

        return (damage, skill)

    def _apply_buff(self, skill, now_ms: int):
        """Apply a buff-type skill effect."""
        name = skill["name"]
        duration_ms = skill["cd"]  # buff lasts until cooldown expires

        # Specific buff effects.
        if "phòng thủ" in skill["desc"].lower() or "Thiết Bố Sam" in name:
            self.buff_timers["defense_up"] = now_ms + duration_ms
        elif "HP" in skill["desc"] or "Hồi" in skill["desc"]:
            # Heal-type buff: restore some HP/MP immediately.
            heal_hp = int(self.max_hp * 0.3)
            heal_mp = int(self.max_mp * 0.2)
            self.hp = min(self.hp + heal_hp, self.max_hp)
            self.mp = min(self.mp + heal_mp, self.max_mp)
        elif "tốc" in skill["desc"].lower() or "Băng Tâm" in name:
            self.buff_timers["attack_speed_up"] = now_ms + duration_ms
        elif "Hộ Thể" in name:
            # Thien Vuong defensive: boost HP and def.
            self.buff_timers["defense_up"] = now_ms + duration_ms
            heal_hp = int(self.max_hp * 0.2)
            self.hp = min(self.hp + heal_hp, self.max_hp)
        else:
            # Generic buff fallback.
            self.buff_timers[name] = now_ms + duration_ms

    def basic_attack(self):
        """Attempt a basic (auto) attack against the current target.

        Returns the damage dealt (int) or ``None`` if on cooldown / no
        target.
        """
        if not self.alive or self.target is None:
            return None

        now_ms = pygame.time.get_ticks()
        effective_cd = self.attack_cd
        if "attack_speed_up" in self.buff_timers:
            effective_cd = int(effective_cd * 0.6)

        if now_ms - self.last_attack_time < effective_cd:
            return None

        self.last_attack_time = now_ms
        self._last_combat_time = now_ms / 1000.0

        # Damage formula.
        target_def = getattr(self.target, "defense", getattr(self.target, "def_stat", 0))
        raw = self.atk * (0.8 + random.random() * 0.4)
        damage = int(raw - target_def * 0.5)
        damage = max(1, damage)

        # Animation.
        self.anim_state = "attacking"
        self.anim_timer = ANIM_ATTACK_FLASH

        return damage

    # ------------------------------------------------------------------
    # Experience / levelling
    # ------------------------------------------------------------------

    def gain_exp(self, amount: int) -> bool:
        """Add experience. Returns ``True`` if a level-up occurred."""
        if self.level >= MAX_LEVEL:
            return False

        self.exp += amount
        levelled = False

        while self.level < MAX_LEVEL and self.exp >= exp_for_level(self.level):
            self.exp -= exp_for_level(self.level)
            self.level += 1
            levelled = True
            self._recalc_stats()
            # Full restore on level-up.
            self.hp = self.max_hp
            self.mp = self.max_mp

        return levelled

    # ------------------------------------------------------------------
    # Taking damage / death / respawn
    # ------------------------------------------------------------------

    def take_damage(self, amount: int):
        """Receive *amount* raw damage, reduced by defense and buffs."""
        if not self.alive:
            return

        self._last_combat_time = pygame.time.get_ticks() / 1000.0

        # Defense reduction.
        reduced = amount - self.defense * 0.3

        # Buff reduction (defense_up halves remaining damage).
        if "defense_up" in self.buff_timers:
            reduced *= 0.5

        damage = max(1, int(reduced))
        self.hp -= damage

        if self.hp <= 0:
            self.hp = 0
            self.alive = False

    def respawn(self):
        """Respawn at Tan Thu Thon with half resources."""
        self.alive = True
        self.hp = self.max_hp // 2
        self.mp = self.max_mp // 2
        self.x = float(SPAWN_X)
        self.y = float(SPAWN_Y)
        self.rect.x = int(self.x) - 16
        self.rect.y = int(self.y) - 16
        self.target = None
        self.auto_attack = False
        self.anim_state = "idle"
        self.anim_timer = 0.0

    # ------------------------------------------------------------------
    # Inventory / equipment
    # ------------------------------------------------------------------

    def use_item(self, item_name: str) -> bool:
        """Consume an item from inventory. Returns True on success."""
        slot = self._find_inventory_slot(item_name)
        if slot is None:
            return False
        if item_name not in ITEM_TYPES:
            return False

        info = ITEM_TYPES[item_name]
        if info.get("type") != "consumable":
            return False

        # Apply effect.
        if "hp" in info:
            self.hp = min(self.hp + info["hp"], self.max_hp)
        if "mp" in info:
            self.mp = min(self.mp + info["mp"], self.max_mp)

        # Reduce stack.
        slot["count"] -= 1
        if slot["count"] <= 0:
            self.inventory.remove(slot)

        return True

    def equip_item(self, item_name: str) -> bool:
        """Equip a weapon or armor from inventory. Returns True on success."""
        if item_name not in ITEM_TYPES:
            return False
        info = ITEM_TYPES[item_name]
        itype = info.get("type")
        if itype not in ("weapon", "armor"):
            return False

        slot = "weapon" if itype == "weapon" else "armor"

        # Unequip current item back to inventory.
        prev = self.equipment[slot]
        if prev is not None:
            self.add_item(prev)

        # Remove new item from inventory.
        inv_slot = self._find_inventory_slot(item_name)
        if inv_slot is not None:
            inv_slot["count"] -= 1
            if inv_slot["count"] <= 0:
                self.inventory.remove(inv_slot)

        self.equipment[slot] = item_name
        self._recalc_stats()
        return True

    def add_item(self, item_name: str, count: int = 1):
        """Add item(s) to inventory, stacking if already present."""
        for slot in self.inventory:
            if slot["name"] == item_name:
                slot["count"] += count
                return
        self.inventory.append({"name": item_name, "count": count})

    def add_gold(self, amount: int):
        """Add (or subtract) gold."""
        self.gold += amount

    def _find_inventory_slot(self, item_name: str):
        """Return the inventory dict for *item_name*, or None."""
        for slot in self.inventory:
            if slot["name"] == item_name and slot["count"] > 0:
                return slot
        return None

    # ------------------------------------------------------------------
    # Drawing
    # ------------------------------------------------------------------

    def draw(self, surface: pygame.Surface, camera):
        """Draw the player character on *surface* using *camera* offsets."""
        sx, sy = camera.apply(self.x, self.y)
        sx, sy = int(sx), int(sy)

        now_sec = pygame.time.get_ticks() / 1000.0

        if not self.alive:
            self._draw_dead(surface, sx, sy)
            return

        # Walking bob offset.
        bob = 0.0
        if self.anim_state == "walking":
            bob = math.sin(now_sec * ANIM_BOB_SPEED) * ANIM_BOB_AMP

        body_y = int(sy + bob)

        # Skill glow effect (drawn behind the character).
        if self.anim_state == "skill" and self._skill_glow_color is not None:
            glow_radius = 24 + int(8 * math.sin(now_sec * 12))
            glow_surf = pygame.Surface((glow_radius * 2, glow_radius * 2), pygame.SRCALPHA)
            alpha = int(120 * (self.anim_timer / ANIM_SKILL_GLOW)) if ANIM_SKILL_GLOW > 0 else 0
            alpha = max(0, min(255, alpha))
            glow_col = (*self._skill_glow_color[:3], alpha)
            pygame.draw.circle(glow_surf, glow_col, (glow_radius, glow_radius), glow_radius)
            surface.blit(glow_surf, (sx - glow_radius, body_y - glow_radius))

        # Attack flash: briefly brighten the colour.
        draw_color = self.color
        if self.anim_state == "attacking":
            draw_color = (
                min(255, self.color[0] + 80),
                min(255, self.color[1] + 80),
                min(255, self.color[2] + 80),
            )

        # Body rectangle.
        body_rect = pygame.Rect(sx - 8, body_y - 4, 16, 20)
        pygame.draw.rect(surface, draw_color, body_rect)
        pygame.draw.rect(surface, BLACK, body_rect, 1)

        # Head circle.
        head_y = body_y - 12
        pygame.draw.circle(surface, draw_color, (sx, head_y), 8)
        pygame.draw.circle(surface, BLACK, (sx, head_y), 8, 1)

        # Direction indicator (small line showing facing).
        dir_len = 14
        end_x = sx + int(math.cos(self.facing) * dir_len)
        end_y = body_y + int(math.sin(self.facing) * dir_len)
        pygame.draw.line(surface, WHITE, (sx, body_y), (end_x, end_y), 2)

        # --- UI above character ---
        # HP bar.
        bar_w = 32
        bar_h = 4
        bar_x = sx - bar_w // 2
        bar_y = head_y - 22

        hp_ratio = self.hp / self.max_hp if self.max_hp > 0 else 0
        pygame.draw.rect(surface, BLACK, (bar_x - 1, bar_y - 1, bar_w + 2, bar_h + 2))
        pygame.draw.rect(surface, (60, 0, 0), (bar_x, bar_y, bar_w, bar_h))
        if hp_ratio > 0:
            fill_color = HP_RED if hp_ratio < 0.3 else (50, 200, 50)
            pygame.draw.rect(surface, fill_color, (bar_x, bar_y, int(bar_w * hp_ratio), bar_h))

        # Name label.
        font = pygame.font.SysFont(None, 18)
        name_surf = font.render(self.name, True, BRIGHT_GOLD)
        name_rect = name_surf.get_rect(centerx=sx, bottom=bar_y - 2)
        surface.blit(name_surf, name_rect)

    def _draw_dead(self, surface: pygame.Surface, sx: int, sy: int):
        """Draw the character in a dead (fallen) state."""
        gray = (100, 100, 100)
        # Fallen body: horizontal rectangle.
        body_rect = pygame.Rect(sx - 12, sy - 2, 24, 10)
        pygame.draw.rect(surface, gray, body_rect)
        pygame.draw.rect(surface, BLACK, body_rect, 1)
        # Small head circle.
        pygame.draw.circle(surface, gray, (sx - 14, sy + 3), 5)
        pygame.draw.circle(surface, BLACK, (sx - 14, sy + 3), 5, 1)
        # Name (dimmed).
        font = pygame.font.SysFont(None, 18)
        name_surf = font.render(self.name, True, (120, 120, 120))
        name_rect = name_surf.get_rect(centerx=sx, bottom=sy - 10)
        surface.blit(name_surf, name_rect)

    # ------------------------------------------------------------------
    # Geometry helpers
    # ------------------------------------------------------------------

    def get_rect(self) -> pygame.Rect:
        """Return the player's collision rectangle in world space."""
        return pygame.Rect(int(self.x) - 16, int(self.y) - 16, 32, 32)

    def get_center(self) -> tuple:
        """Return the player's centre position as ``(x, y)``."""
        return (self.x, self.y)
