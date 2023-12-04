#!/usr/bin/env python3

from collections import defaultdict
import pygame, sys, os
from pygame.locals import *
from pygame.gfxdraw import *
import random

pygame.init()
window = pygame.display.set_mode((256, 256))
pygame.display.set_caption('RND Visualizer')
screen = pygame.display.get_surface()
pygame.mouse.set_visible(1)

field = defaultdict(int)

while True:
    data = int(input())
    #data = random.randint(0, 0xffff)
    field[data] += 40
    if field[data] > 255:
        field[data] = 255
    x = data & 0xff
    y = data >> 8
    pixel(screen, x, y, Color(field[data], 255, 255 - field[data]))
    pygame.display.flip()
