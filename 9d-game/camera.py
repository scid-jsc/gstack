"""Camera system for 2D top-down RPG with smooth following and screen shake."""

import random
import pygame
from settings import SCREEN_WIDTH, SCREEN_HEIGHT, MAP_WIDTH, MAP_HEIGHT, TILE_SIZE


class Camera:
    """Camera that smoothly follows a target and supports screen shake."""

    def __init__(self):
        self.x = 0.0
        self.y = 0.0
        self.lerp_speed = 0.08

        # Map boundaries in pixels.
        self.map_pixel_width = MAP_WIDTH * TILE_SIZE
        self.map_pixel_height = MAP_HEIGHT * TILE_SIZE

        # Screen shake state.
        self.shake_offset_x = 0.0
        self.shake_offset_y = 0.0
        self.shake_intensity = 0.0
        self.shake_duration = 0.0
        self.shake_timer = 0.0

    # ------------------------------------------------------------------
    # Coordinate conversion
    # ------------------------------------------------------------------

    def apply(self, world_x, world_y):
        """Convert world coordinates to screen coordinates."""
        screen_x = world_x - self.x + SCREEN_WIDTH // 2 + self.shake_offset_x
        screen_y = world_y - self.y + SCREEN_HEIGHT // 2 + self.shake_offset_y
        return (screen_x, screen_y)

    def apply_rect(self, rect):
        """Convert a world-space pygame.Rect to screen-space."""
        sx, sy = self.apply(rect.x, rect.y)
        return pygame.Rect(sx, sy, rect.width, rect.height)

    # ------------------------------------------------------------------
    # Update
    # ------------------------------------------------------------------

    def update(self, target, dt=1.0):
        """Smoothly move the camera toward *target*.

        *target* must have a ``rect`` attribute (pygame.Rect) whose center
        is treated as the point of interest.

        *dt* is the frame delta in seconds (default 1.0 for frame-rate-
        independent smoothing when multiplied by a fixed timestep).
        """
        target_x = target.rect.centerx
        target_y = target.rect.centery

        # Lerp toward the target.
        smoothing = min(self.lerp_speed * dt * 60, 1.0)
        self.x += (target_x - self.x) * smoothing
        self.y += (target_y - self.y) * smoothing

        # Clamp so the viewport never shows beyond the map edges.
        half_w = SCREEN_WIDTH // 2
        half_h = SCREEN_HEIGHT // 2

        self.x = max(half_w, min(self.x, self.map_pixel_width - half_w))
        self.y = max(half_h, min(self.y, self.map_pixel_height - half_h))

        # Update screen shake.
        self._update_shake(dt)

    # ------------------------------------------------------------------
    # Screen shake
    # ------------------------------------------------------------------

    def start_shake(self, intensity=8.0, duration=0.3):
        """Begin a screen shake effect.

        *intensity* is the maximum pixel offset per frame.
        *duration* is how long the shake lasts in seconds.
        """
        self.shake_intensity = intensity
        self.shake_duration = duration
        self.shake_timer = duration

    def _update_shake(self, dt):
        """Decay the shake over time and compute per-frame offset."""
        if self.shake_timer > 0:
            self.shake_timer -= dt
            # Fade intensity linearly toward zero.
            progress = max(self.shake_timer / self.shake_duration, 0.0)
            current = self.shake_intensity * progress
            self.shake_offset_x = random.uniform(-current, current)
            self.shake_offset_y = random.uniform(-current, current)
        else:
            self.shake_offset_x = 0.0
            self.shake_offset_y = 0.0
