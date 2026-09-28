"""Checks the built plugin against the built data: every sound path (ANAM) and model (MODL) exists.

    python tools/check_esp.py [data_root]
"""
import pathlib
import sys

root = pathlib.Path(sys.argv[1] if len(sys.argv) > 1 else 'build/data')
b = (root / 'AN76_Toilets.esp').read_bytes()
missing, seen = [], 0
for tag, prefix in ((b'ANAM', ''), (b'MODL', 'Meshes/')):
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
        f = root / (prefix + rel)
        seen += 1
        if not f.exists():
            missing.append(str(f))
        i = b.find(tag, end)
print(f'{seen} paths checked, {len(missing)} missing')
for m in missing:
    print('MISSING', m)
sys.exit(1 if missing else 0)
