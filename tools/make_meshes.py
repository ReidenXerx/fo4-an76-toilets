"""The seat and urinal meshes: each world toilet's own vanilla model with every visible shape hidden.

    python tools/make_meshes.py [out_root]      # writes <out_root>/Meshes/AN76Toilets/*.nif

WHY. Nothing in the vanilla game is both invisible and collidable (the generic marker mesh is an
editor triangle with no collision), and the crosshair only lands on something with collision. A copy
of the toilet's own model with its geometry hidden (NiAVObject flag bit 0, "hidden") keeps the
toilet's exact collision and draws nothing. The spawner places it on the toilet, 2% larger, so the
crosshair meets it before the toilet's own collision.
"""
import pathlib
import struct
import sys
import zlib

DATA = pathlib.Path(r'D:\GOGGames\Fallout 4 GOTY\Data')
ARCHIVE = 'Fallout4 - Meshes.ba2'

# vanilla model -> our file name
MODELS = {
    r'meshes\setdressing\building\toiletbroken01.nif': 'ToiletBroken01.nif',
    r'meshes\setdressing\building\toiletbroken02.nif': 'ToiletBroken02.nif',
    r'meshes\setdressing\building\toiletbroken03.nif': 'ToiletBroken03.nif',
    r'meshes\setdressing\vault\vault_toilet_01.nif': 'VaultToilet01.nif',
    r'meshes\setdressing\playerhouse\playerhouse_toilet01.nif': 'HouseToilet01.nif',
    r'meshes\setdressing\playerhouse_ruin\playerhouse_ruin_toilet01.nif': 'HouseRuinToilet01.nif',
    r'meshes\setdressing\building\urinalbroken01.nif': 'UrinalBroken01.nif',
    r'meshes\setdressing\building\stalls\brstallurinal01.nif': 'StallUrinal01.nif',
    r'meshes\setdressing\building\stalls\brstallurinal02.nif': 'StallUrinal02.nif',
    r'meshes\setdressing\building\stalls\brstallurinal03.nif': 'StallUrinal03.nif',
    # World kitchens (2026-10-02): the dead stoves prep food, the espresso machines brew coffee.
    r'meshes\setdressing\playerhouse_ruin\playerhouse_ruin_kitchenstove01.nif': 'KitchenStoveRuin01.nif',
    r'meshes\setdressing\playerhouse\playerhouse_kitchenstove01.nif': 'KitchenStove01.nif',
    r'meshes\setdressing\expressomachine\expresso_machine01.nif': 'EspressoMachine01.nif',
}
GEOMETRY = {'BSTriShape', 'BSSubIndexTriShape', 'BSMeshLODTriShape', 'NiTriShape', 'BSDynamicTriShape'}


def extract(names):
    b = (DATA / ARCHIVE).read_bytes()
    magic, ver, typ, n, nto = struct.unpack('<4sI4sIQ', b[:24])
    ents, o = [], 24
    for _ in range(n):
        _h, _ext, _dh, _fl, off, ps, us, _al = struct.unpack('<I4sIIQIII', b[o:o + 36])
        o += 36
        ents.append((off, ps, us))
    p, out = nto, {}
    for i in range(n):
        ln = struct.unpack('<H', b[p:p + 2])[0]
        nm = b[p + 2:p + 2 + ln].decode('latin1').lower()
        p += 2 + ln
        if nm in names:
            off, ps, us = ents[i]
            raw = b[off:off + (ps or us)]
            out[nm] = zlib.decompress(raw) if ps else raw
    return out


def hide_geometry(d):
    """Set the hidden bit on every geometry block. Returns (bytes, shapes hidden, collision blocks)."""
    d = bytearray(d)
    i = d.index(b'\n') + 1
    _ver, _endian, _uv, nb = struct.unpack('<IBII', d[i:i + 13])
    i += 13
    bsv = struct.unpack('<I', d[i:i + 4])[0]
    i += 4
    for _ in range(3 if bsv < 131 else 2):
        i += 1 + d[i]
    i += 1 + d[i]
    nt = struct.unpack('<H', d[i:i + 2])[0]
    i += 2
    types = []
    for _ in range(nt):
        ln = struct.unpack('<I', d[i:i + 4])[0]
        i += 4
        types.append(d[i:i + ln].decode())
        i += ln
    tidx = struct.unpack('<%dH' % nb, d[i:i + 2 * nb])
    i += 2 * nb
    sizes = struct.unpack('<%dI' % nb, d[i:i + 4 * nb])
    i += 4 * nb
    ns = struct.unpack('<I', d[i:i + 4])[0]
    i += 8
    for _ in range(ns):
        ln = struct.unpack('<I', d[i:i + 4])[0]
        i += 4 + ln
    ng = struct.unpack('<I', d[i:i + 4])[0]
    i += 4 + 4 * ng
    hidden = collision = 0
    off = i
    for k in range(nb):
        t = types[tidx[k]]
        if t in GEOMETRY:
            # NiObjectNET: name (int), extra data count + refs, controller ref; then NiAVObject flags (u32)
            ne = struct.unpack('<I', d[off + 4:off + 8])[0]
            flags_at = off + 8 + 4 * ne + 4
            flags = struct.unpack('<I', d[flags_at:flags_at + 4])[0]
            struct.pack_into('<I', d, flags_at, flags | 1)
            hidden += 1
        if t.startswith('bhk'):
            collision += 1
        off += sizes[k]
    if off > len(d):
        raise ValueError('block walk ran past the file')
    return bytes(d), hidden, collision


def main():
    root = pathlib.Path(sys.argv[1] if len(sys.argv) > 1 else 'build/data')
    out_dir = root / 'Meshes' / 'AN76Toilets'
    out_dir.mkdir(parents=True, exist_ok=True)
    found = extract(set(MODELS))
    missing = sorted(set(MODELS) - set(found))
    if missing:
        raise SystemExit('not in the archive: ' + ', '.join(missing))
    for src, name in MODELS.items():
        data, hidden, collision = hide_geometry(found[src])
        if hidden == 0 or collision == 0:
            raise SystemExit(f'{src}: {hidden} shapes hidden, {collision} collision blocks - refusing a mesh that shows or cannot be hit')
        (out_dir / name).write_bytes(data)
        print(f'{name}: {hidden} shape(s) hidden, {collision} collision block(s)')


if __name__ == '__main__':
    main()
