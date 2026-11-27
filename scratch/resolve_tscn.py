import glob

files = glob.glob(r'D:\RogueFightersArena\fighters\*.tscn') + glob.glob(r'D:\RogueFightersArena\fighters\characters\*.tscn')
for p in files:
    with open(p, 'r', encoding='utf-8') as f:
        lines = f.readlines()
    new_lines = []
    seen_base = False
    for line in lines:
        s = line.strip()
        if s in ('<<<<<<< Updated upstream', '=======', '>>>>>>> Stashed changes'):
            continue
        if 'id="1_base"' in line and 'PackedScene' in line:
            if seen_base:
                continue
            seen_base = True
            line = '[ext_resource type="PackedScene" uid="uid://caueui2bcpaxy" path="res://scenes/fighter/fighter.tscn" id="1_base"]\n'
        new_lines.append(line)
    with open(p, 'w', encoding='utf-8', newline='\n') as f:
        f.write(''.join(new_lines))
print(f'Cleaned {len(files)} tscn files.')
