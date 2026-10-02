"""Checks the built plugin against the built data: every sound path (ANAM), our models (MODL) and our
textures (TX00/TX01) exist. A model outside AN76Toilets\\ is the game's own (an impact effect) and lives
in its archives, so it is not ours to check.

    python tools/check_esp.py [data_root]
"""
import pathlib
import sys

root = pathlib.Path(sys.argv[1] if len(sys.argv) > 1 else 'build/data')
b = (root / 'AN76_Toilets.esp').read_bytes()
missing, seen, vanilla = [], 0, 0
for tag, prefix in ((b'ANAM', ''), (b'MODL', 'Meshes/'), (b'TX00', 'Textures/'), (b'TX01', 'Textures/')):
    i = b.find(tag)
    while i >= 0:
        end = b.find(b'\x00', i + 6)
        if tag == b'ANAM' and not b[i + 6:i + 10] == b'Data':
            i = b.find(tag, i + 4)   # a package parameter type or a quest's alias count, not a sound
            continue
        path = b[i + 6:end].decode('ascii')
        rel = path.replace('\\', '/')
        if rel.lower().startswith('data/'):
            rel = rel[5:]
        if tag != b'ANAM' and not rel.lower().startswith('an76toilets/'):
            vanilla += 1
            i = b.find(tag, end)
            continue
        f = root / (prefix + rel)
        seen += 1
        if not f.exists():
            missing.append(str(f))
        i = b.find(tag, end)
print(f'{seen} paths checked, {len(missing)} missing ({vanilla} vanilla paths left to the game)')
for m in missing:
    print('MISSING', m)
sys.exit(1 if missing else 0)
