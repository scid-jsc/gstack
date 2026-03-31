#!/usr/bin/env python3
"""
9D Cửu Long Tranh Bá - Desktop Game Clone
A wuxia MMORPG-style game built with Pygame
"""

import pygame
import sys
import os

# Add game directory to path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from settings import *
from game import Game

def main():
    pygame.init()
    pygame.mixer.init()
    pygame.display.set_caption("9D Cửu Long Tranh Bá - Cửu Long Tranh Bá")

    screen = pygame.display.set_mode((SCREEN_WIDTH, SCREEN_HEIGHT))
    clock = pygame.time.Clock()

    game = Game(screen, clock)
    game.run()

    pygame.quit()
    sys.exit()

if __name__ == "__main__":
    main()
