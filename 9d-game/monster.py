"""Monster and enemy system for 9D wuxia RPG."""

import math
import random
import pygame

from settings import MONSTERS, TILE_SIZE, RED, WHITE, BLACK, GOLD, BRIGHT_GOLD, HP_RED, DARK_RED


class Monster:
    """A single monster/enemy in the game world."""

    def __init__(self, name, x, y, monster_data):
        self.name = name

        # Copy stats from monster_data
        self.hp = monster_data["hp"]
        self.max_hp = self.hp
        self.atk = monster_data["atk"]
        self.defense = monster_data["def"]
        self.exp = monster_data["exp"]
        self.gold_range = monster_data["gold"]
        self.color = monster_data["color"]
        self.speed = monster_data["speed"]
        self.aggro_range = monster_data["aggro"]
        self.respawn_time = monster_data["respawn"]
        self.size = monster_data["size"]
        self.level = monster_data["level"]
        self.is_boss = monster_data.get("boss", False)

        # Position (floats for smooth movement)
        self.x = float(x)
        self.y = float(y)

        # State
        self.alive = True
        self.state = "idle"  # idle, patrol, chase, attack, returning

        # Patrol
        self.home_x = self.x
        self.home_y = self.y
        self.patrol_target_x = self.x
        self.patrol_target_y = self.y
        self.patrol_timer = 0.0
        self.patrol_wait = random.uniform(2.0, 5.0)

        # Attack
        self.attack_cooldown = 1500  # ms
        self.last_attack_time = 0

        # Targeting
        self.target = None  # player reference when aggro'd

        # Death / respawn
        self.death_time = 0
        self.loot = None  # generated on death

        # Visual
        self.hit_flash_timer = 0.0  # seconds remaining for white flash
        self.anim_timer = 0.0

        # Boss AoE warning
        self.aoe_warning_timer = 0.0
        self.aoe_warning_active = False

    # ------------------------------------------------------------------ update
    def update(self, dt, player):
        """Update monster AI and state. dt is in seconds."""
        self.anim_timer += dt

        if not self.alive:
            # Check respawn
            now = pygame.time.get_ticks()
            if now - self.death_time >= self.respawn_time:
                self.respawn()
            return

        # Decay hit flash
        if self.hit_flash_timer > 0:
            self.hit_flash_timer = max(0.0, self.hit_flash_timer - dt)

        # ------ State machine ------

        # Always check aggro first (unless returning)
        if self.state in ("idle", "patrol"):
            if player.alive if hasattr(player, "alive") else True:
                dist = self.distance_to((player.x, player.y))
                if dist <= self.aggro_range:
                    self.state = "chase"
                    self.target = player

        if self.state == "idle":
            self.patrol_timer += dt
            if self.patrol_timer >= self.patrol_wait:
                self._pick_patrol_target()
                self.state = "patrol"
                self.patrol_timer = 0.0

        elif self.state == "patrol":
            dx = self.patrol_target_x - self.x
            dy = self.patrol_target_y - self.y
            dist = math.hypot(dx, dy)
            if dist < 4.0:
                # Reached patrol point, wait
                self.state = "idle"
                self.patrol_timer = 0.0
                self.patrol_wait = random.uniform(2.0, 5.0)
            else:
                # Move toward patrol target at half speed
                move_speed = self.speed * 0.5 * 60.0 * dt
                if dist > 0:
                    self.x += (dx / dist) * move_speed
                    self.y += (dy / dist) * move_speed

        elif self.state == "chase":
            if self.target is None:
                self.state = "returning"
                return

            px, py = self.target.x, self.target.y
            dist = self.distance_to((px, py))

            # Lost aggro - too far from home
            if self.distance_to((self.home_x, self.home_y)) > self.aggro_range * 1.5:
                self.state = "returning"
                self.target = None
                return

            # Player dead
            player_alive = self.target.alive if hasattr(self.target, "alive") else True
            if not player_alive:
                self.state = "returning"
                self.target = None
                return

            # Within attack range
            if dist <= 40.0:
                self.state = "attack"
            else:
                # Move toward player
                dx = px - self.x
                dy = py - self.y
                move_speed = self.speed * 60.0 * dt
                if dist > 0:
                    self.x += (dx / dist) * move_speed
                    self.y += (dy / dist) * move_speed

        elif self.state == "attack":
            if self.target is None:
                self.state = "returning"
                return

            player_alive = self.target.alive if hasattr(self.target, "alive") else True
            if not player_alive:
                self.state = "returning"
                self.target = None
                return

            dist = self.distance_to((self.target.x, self.target.y))
            if dist > 50.0:
                # Player moved away, chase again
                self.state = "chase"
                return

            # Attack on cooldown
            now = pygame.time.get_ticks()
            if now - self.last_attack_time >= self.attack_cooldown:
                damage = self.atk * (0.8 + random.random() * 0.4)
                damage = int(damage)
                if hasattr(self.target, "take_damage"):
                    self.target.take_damage(damage)
                self.last_attack_time = now

            # Boss: occasional AoE warning
            if self.is_boss:
                self.aoe_warning_timer += dt
                if self.aoe_warning_timer >= 8.0:
                    self.aoe_warning_active = True
                    self.aoe_warning_timer = 0.0
                if self.aoe_warning_active:
                    # AoE fires after brief warning
                    self.aoe_warning_timer += dt
                    if self.aoe_warning_timer >= 1.5:
                        # Deal AoE damage to nearby player
                        if dist <= 120.0:
                            aoe_damage = int(self.atk * 1.5)
                            if hasattr(self.target, "take_damage"):
                                self.target.take_damage(aoe_damage)
                        self.aoe_warning_active = False
                        self.aoe_warning_timer = 0.0

        elif self.state == "returning":
            dx = self.home_x - self.x
            dy = self.home_y - self.y
            dist = math.hypot(dx, dy)
            if dist < 8.0:
                self.x = self.home_x
                self.y = self.home_y
                self.state = "idle"
                self.patrol_timer = 0.0
                # Heal when returning home
                self.hp = self.max_hp
            else:
                move_speed = self.speed * 60.0 * dt
                if dist > 0:
                    self.x += (dx / dist) * move_speed
                    self.y += (dy / dist) * move_speed

    # ----------------------------------------------------------- take_damage
    def take_damage(self, amount):
        """Reduce HP accounting for defense. Returns actual damage dealt."""
        actual = max(1, int(amount - self.defense * 0.3))
        self.hp -= actual
        self.hit_flash_timer = 0.15  # flash white for 150ms
        if self.hp <= 0:
            self.hp = 0
            self.die()
        return actual

    # ------------------------------------------------------------------- die
    def die(self):
        """Handle monster death: set flags, generate loot."""
        self.alive = False
        self.death_time = pygame.time.get_ticks()
        self.state = "idle"
        self.target = None

        # Generate gold loot
        gold_min, gold_max = self.gold_range
        gold_amount = random.randint(gold_min, gold_max)

        self.loot = {
            "gold": gold_amount,
            "items": [],
            "exp": self.exp,
        }

        # Item drop table
        roll = random.random()
        if roll < 0.30:
            self.loot["items"].append("Tiểu Hoàn Đan")

        # Weapon/armor drops based on level
        if roll < 0.15:
            if self.level < 5:
                item = random.choice(["Kiếm Sắt", "Áo Vải"])
            elif self.level < 10:
                item = random.choice(["Kiếm Thép", "Áo Da"])
            elif self.level < 20:
                item = random.choice(["Kiếm Huyền Thiết", "Giáp Sắt"])
            else:
                item = random.choice(["Thanh Long Đao", "Huyền Thiết Giáp"])
            self.loot["items"].append(item)

    # --------------------------------------------------------------- respawn
    def respawn(self):
        """Reset monster to full HP at home position."""
        self.hp = self.max_hp
        self.x = self.home_x
        self.y = self.home_y
        self.alive = True
        self.state = "idle"
        self.target = None
        self.loot = None
        self.patrol_timer = 0.0
        self.patrol_wait = random.uniform(2.0, 5.0)
        self.hit_flash_timer = 0.0
        self.aoe_warning_timer = 0.0
        self.aoe_warning_active = False

    # ------------------------------------------------------------------ draw
    def draw(self, surface, camera):
        """Draw the monster on screen relative to camera."""
        if not self.alive:
            # Brief loot sparkle after death
            if self.loot is not None:
                elapsed = pygame.time.get_ticks() - self.death_time
                if elapsed < 2000:
                    sx = self.x - camera.x
                    sy = self.y - camera.y
                    # Sparkle effect
                    alpha = max(0, 255 - int(elapsed * 255 / 2000))
                    sparkle_size = 3 + int(math.sin(elapsed * 0.01) * 2)
                    color = (
                        min(255, BRIGHT_GOLD[0]),
                        min(255, BRIGHT_GOLD[1]),
                        min(255, BRIGHT_GOLD[2]),
                    )
                    for i in range(4):
                        angle = (elapsed * 0.005) + (i * math.pi / 2)
                        ox = math.cos(angle) * 8
                        oy = math.sin(angle) * 8
                        pygame.draw.circle(
                            surface, color,
                            (int(sx + ox), int(sy + oy)),
                            sparkle_size,
                        )
            return

        # Screen position
        sx = self.x - camera.x
        sy = self.y - camera.y

        # Cull off-screen
        margin = self.size * 2 + 40
        sw, sh = surface.get_size()
        if sx < -margin or sx > sw + margin or sy < -margin or sy > sh + margin:
            return

        # Determine draw color (flash white when hit)
        draw_color = WHITE if self.hit_flash_timer > 0 else self.color

        # Boss aura
        if self.is_boss:
            pulse = 0.5 + 0.5 * math.sin(self.anim_timer * 3.0)
            aura_radius = int(self.size * 1.6 + pulse * 6)
            aura_color = (
                min(255, int(self.color[0] * 0.4 + 60)),
                min(255, int(self.color[1] * 0.4 + 30)),
                min(255, int(self.color[2] * 0.4 + 60)),
            )
            aura_surf = pygame.Surface((aura_radius * 2, aura_radius * 2), pygame.SRCALPHA)
            aura_alpha = int(60 + pulse * 40)
            pygame.draw.circle(
                aura_surf,
                (*aura_color, aura_alpha),
                (aura_radius, aura_radius),
                aura_radius,
            )
            surface.blit(
                aura_surf,
                (int(sx) - aura_radius, int(sy) - aura_radius),
            )

            # AoE warning circle
            if self.aoe_warning_active:
                warn_radius = 120
                warn_surf = pygame.Surface((warn_radius * 2, warn_radius * 2), pygame.SRCALPHA)
                warn_alpha = int(40 + 40 * math.sin(self.anim_timer * 10.0))
                pygame.draw.circle(
                    warn_surf,
                    (255, 50, 50, warn_alpha),
                    (warn_radius, warn_radius),
                    warn_radius,
                )
                pygame.draw.circle(
                    warn_surf,
                    (255, 100, 100, warn_alpha + 30),
                    (warn_radius, warn_radius),
                    warn_radius,
                    2,
                )
                surface.blit(
                    warn_surf,
                    (int(sx) - warn_radius, int(sy) - warn_radius),
                )

        # Draw monster shape based on type
        self._draw_shape(surface, int(sx), int(sy), draw_color)

        # Draw name and level above
        self._draw_nameplate(surface, int(sx), int(sy))

        # Draw HP bar (only when damaged or in combat)
        if self.hp < self.max_hp or self.state in ("chase", "attack"):
            self._draw_hp_bar(surface, int(sx), int(sy))

    def _draw_shape(self, surface, sx, sy, color):
        """Draw the monster shape based on its type."""
        s = self.size
        name_lower = self.name.lower()

        if "sói" in name_lower or "wolf" in name_lower:
            # Wolf: oval/diamond shape
            points = [
                (sx, sy - s),           # top
                (sx + s, sy),           # right
                (sx, sy + int(s * 0.6)),  # bottom
                (sx - s, sy),           # left
            ]
            pygame.draw.polygon(surface, color, points)
            pygame.draw.polygon(surface, BLACK, points, 2)
            # Eyes
            pygame.draw.circle(surface, RED, (sx - 4, sy - 4), 2)
            pygame.draw.circle(surface, RED, (sx + 4, sy - 4), 2)

        elif "đạo" in name_lower or "tặc" in name_lower:
            # Bandit: humanoid (circle head + rect body)
            head_r = max(4, s // 3)
            pygame.draw.circle(surface, color, (sx, sy - s // 2), head_r)
            pygame.draw.circle(surface, BLACK, (sx, sy - s // 2), head_r, 1)
            # Body
            body_rect = pygame.Rect(sx - s // 3, sy - s // 4, s * 2 // 3, s)
            pygame.draw.rect(surface, color, body_rect)
            pygame.draw.rect(surface, BLACK, body_rect, 1)
            # Weapon line
            pygame.draw.line(surface, (180, 180, 180), (sx + s // 3, sy), (sx + s, sy - s // 2), 2)

        elif "hổ" in name_lower or "tiger" in name_lower:
            # Tiger: larger oval with stripes
            body = pygame.Rect(sx - s, sy - s // 2, s * 2, s)
            pygame.draw.ellipse(surface, color, body)
            pygame.draw.ellipse(surface, BLACK, body, 2)
            # Stripes
            stripe_color = (
                max(0, color[0] - 60),
                max(0, color[1] - 60),
                max(0, color[2] - 20),
            )
            for i in range(3):
                offset = -s // 2 + (i + 1) * s // 2
                pygame.draw.line(
                    surface, stripe_color,
                    (sx + offset - 3, sy - s // 3),
                    (sx + offset + 3, sy + s // 3),
                    2,
                )
            # Eyes
            pygame.draw.circle(surface, BRIGHT_GOLD, (sx - s // 3, sy - 3), 3)
            pygame.draw.circle(surface, BRIGHT_GOLD, (sx + s // 3, sy - 3), 3)
            pygame.draw.circle(surface, BLACK, (sx - s // 3, sy - 3), 1)
            pygame.draw.circle(surface, BLACK, (sx + s // 3, sy - 3), 1)

        elif "yêu" in name_lower or "ma" in name_lower or "thiên" in name_lower:
            # Demons: pointed/angular shape
            points = [
                (sx, sy - int(s * 1.2)),     # top spike
                (sx + s // 2, sy - s // 3),  # right upper
                (sx + s, sy + s // 3),       # right lower
                (sx + s // 3, sy + s),       # bottom right
                (sx - s // 3, sy + s),       # bottom left
                (sx - s, sy + s // 3),       # left lower
                (sx - s // 2, sy - s // 3),  # left upper
            ]
            pygame.draw.polygon(surface, color, points)
            pygame.draw.polygon(surface, DARK_RED, points, 2)
            # Glowing eyes
            glow = int(128 + 127 * math.sin(self.anim_timer * 5.0))
            eye_color = (glow, min(255, glow // 2), 0)
            pygame.draw.circle(surface, eye_color, (sx - 5, sy - s // 4), 3)
            pygame.draw.circle(surface, eye_color, (sx + 5, sy - s // 4), 3)

        elif "boss" in name_lower:
            # Boss: large imposing shape with glow
            # Main body - large circle
            pygame.draw.circle(surface, color, (sx, sy), s)
            pygame.draw.circle(surface, BLACK, (sx, sy), s, 2)
            # Crown / horns
            horn_color = BRIGHT_GOLD if "long" in name_lower else DARK_RED
            pygame.draw.polygon(surface, horn_color, [
                (sx - s // 2, sy - s),
                (sx - s // 3, sy - int(s * 1.5)),
                (sx - s // 6, sy - s),
            ])
            pygame.draw.polygon(surface, horn_color, [
                (sx + s // 6, sy - s),
                (sx + s // 3, sy - int(s * 1.5)),
                (sx + s // 2, sy - s),
            ])
            # Eyes
            glow = int(128 + 127 * math.sin(self.anim_timer * 4.0))
            pygame.draw.circle(surface, (glow, 0, 0), (sx - s // 3, sy - s // 4), 4)
            pygame.draw.circle(surface, (glow, 0, 0), (sx + s // 3, sy - s // 4), 4)

        else:
            # Default: simple circle with outline
            pygame.draw.circle(surface, color, (sx, sy), s)
            pygame.draw.circle(surface, BLACK, (sx, sy), s, 2)

    def _draw_nameplate(self, surface, sx, sy):
        """Draw monster name and level above."""
        font = pygame.font.Font(None, 18 if not self.is_boss else 22)
        label = f"[Lv.{self.level}] {self.name}"

        if self.is_boss:
            name_color = BRIGHT_GOLD
        else:
            name_color = WHITE

        text_surf = font.render(label, True, name_color)
        text_rect = text_surf.get_rect(centerx=sx, bottom=sy - self.size - 14)
        surface.blit(text_surf, text_rect)

    def _draw_hp_bar(self, surface, sx, sy):
        """Draw HP bar below the nameplate."""
        bar_w = max(30, self.size * 2)
        bar_h = 4 if not self.is_boss else 6
        bar_x = sx - bar_w // 2
        bar_y = sy - self.size - 10

        # Background
        pygame.draw.rect(surface, BLACK, (bar_x - 1, bar_y - 1, bar_w + 2, bar_h + 2))

        # HP fill
        hp_ratio = max(0.0, self.hp / self.max_hp)
        fill_w = int(bar_w * hp_ratio)
        if hp_ratio > 0.5:
            hp_color = HP_RED
        elif hp_ratio > 0.25:
            hp_color = (220, 140, 30)
        else:
            hp_color = DARK_RED

        pygame.draw.rect(surface, hp_color, (bar_x, bar_y, fill_w, bar_h))
        pygame.draw.rect(surface, (80, 80, 80), (bar_x, bar_y, bar_w, bar_h), 1)

    # ------------------------------------------------------------- helpers
    def _pick_patrol_target(self):
        """Pick a random patrol point within 100px of home."""
        angle = random.uniform(0, 2 * math.pi)
        radius = random.uniform(20, 100)
        self.patrol_target_x = self.home_x + math.cos(angle) * radius
        self.patrol_target_y = self.home_y + math.sin(angle) * radius

    def get_rect(self):
        """Return collision rectangle."""
        s = self.size
        return pygame.Rect(int(self.x) - s, int(self.y) - s, s * 2, s * 2)

    def get_center(self):
        """Return center position as tuple."""
        return (self.x, self.y)

    def distance_to(self, pos):
        """Distance from this monster to a world position."""
        return math.hypot(self.x - pos[0], self.y - pos[1])


class MonsterSpawner:
    """Manages spawning and updating all monsters in the world."""

    def __init__(self, world=None):
        self.monsters = []
        self.world = world

    def spawn_monsters_for_zone(self, zone):
        """Spawn monsters for a given zone.

        zone should have:
          - zone.rect: pygame.Rect (world coordinates)
          - zone.monster_types: list of monster name strings (keys in MONSTERS)
          - zone.level_range: (min_level, max_level) tuple
        """
        for monster_name in zone.monster_types:
            if monster_name not in MONSTERS:
                continue

            mdata = MONSTERS[monster_name]
            is_boss = mdata.get("boss", False)

            if is_boss:
                count = 1
            else:
                # Weaker monsters spawn in larger groups
                if mdata["level"] <= 3:
                    count = random.randint(5, 8)
                elif mdata["level"] <= 10:
                    count = random.randint(4, 6)
                else:
                    count = random.randint(3, 5)

            for _ in range(count):
                # Random position within zone rect, padded inward
                pad = TILE_SIZE * 2
                zr = zone.rect
                x = random.randint(zr.left + pad, max(zr.left + pad, zr.right - pad))
                y = random.randint(zr.top + pad, max(zr.top + pad, zr.bottom - pad))

                # Avoid spawning on map objects if world provides collision info
                if self.world and hasattr(self.world, "is_blocked"):
                    attempts = 0
                    while self.world.is_blocked(x, y) and attempts < 20:
                        x = random.randint(zr.left + pad, max(zr.left + pad, zr.right - pad))
                        y = random.randint(zr.top + pad, max(zr.top + pad, zr.bottom - pad))
                        attempts += 1

                # Boss spawns at zone center
                if is_boss:
                    x = zr.centerx
                    y = zr.centery

                monster = Monster(monster_name, x, y, mdata)
                self.monsters.append(monster)

    def update(self, dt, player):
        """Update all monsters."""
        for monster in self.monsters:
            monster.update(dt, player)

    def get_nearby_monsters(self, pos, radius):
        """Return alive monsters within radius of pos."""
        result = []
        for m in self.monsters:
            if m.alive and m.distance_to(pos) <= radius:
                result.append(m)
        return result

    def get_alive_monsters(self):
        """Return all alive monsters."""
        return [m for m in self.monsters if m.alive]

    def draw(self, surface, camera):
        """Draw all visible alive monsters (and death sparkles)."""
        for monster in self.monsters:
            monster.draw(surface, camera)
