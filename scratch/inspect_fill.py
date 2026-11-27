from PIL import Image, ImageStat
import sys, os
path = r'd:\RogueFightersArena\assets\ui\settings\slider_track_fill.png'
im = Image.open(path).convert('RGBA')
# define red threshold
red_pixels = [(x,y) for x in range(im.width) for y in range(im.height) if im.getpixel((x,y))[0] > 150 and im.getpixel((x,y))[1] < 80 and im.getpixel((x,y))[2] < 80]
if red_pixels:
    xs, ys = zip(*red_pixels)
    bbox = (min(xs), min(ys), max(xs), max(ys))
    print('Red bbox:', bbox)
    print('Image size:', im.size)
else:
    print('No red found')
