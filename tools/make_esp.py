"""Builds AN76_Toilets.esp: the seats, the urinals, the list of world toilets, the spawner quest.

    python tools/make_esp.py [out.esp]

A light plugin (ESL) with one master, Fallout4.esm. Advanced Needs 76 is NOT a master: the scripts
reach it by form id at run time, so none of its records are overridden (its permissions forbid
changing its files) and this plugin loads harmlessly without it.

Record layouts are cloned from vanilla: the seat from Fallout4.esm FURN 10C853
NpcChairInstituteToiletSit01, the urinal from ACTI 0248C2 Toilet01, the quest DNAM from
AAF_MainQuest (start game enabled).
"""
import pathlib
import struct
import sys

AUTHOR = 'AN76 Toilets'
MASTER = 'Fallout4.esm'
TES4_LIGHT = 0x200
FIRST_ID = 0x01000800

KW_CHAIR_SIT = 0x00030BB2          # AnimFurnChairSitAnims
KW_ALLOW_EATING = 0x00144A65       # AnimFurnAllowEating
KW_RELAXATION = 0x0018F692         # FurnitureClassRelaxation

# Seat markers: (x, y, z, heading) in the toilet's own space. ToiletBroken01 is Advanced Needs 76's
# own measured marker for that model (its Postwar Toilet); the rest are first estimates from each
# model's bounds, to be tuned in game.
PI = 3.14159265
SEATS = [
    # key, mesh, obnd, marker, flushable
    ('Broken01', 'ToiletBroken01.nif', (-34, -32, 0, 23, 30, 70), (-2.0, -8.0, 3.0, 3.0194), False),
    ('Broken02', 'ToiletBroken02.nif', (-53, -45, 0, 17, 29, 47), (-12.0, -8.0, 3.0, 3.0194), False),
    ('Broken03', 'ToiletBroken03.nif', (-17, -32, 0, 23, 18, 34), (3.0, -8.0, 3.0, 3.0194), False),
    ('Vault', 'VaultToilet01.nif', (-18, -25, 0, 17, 35, 65), (0.0, -5.0, 3.0, PI), True),
    ('House', 'HouseToilet01.nif', (-18, -25, 0, 17, 35, 65), (0.0, -5.0, 3.0, PI), True),
    ('HouseRuin', 'HouseRuinToilet01.nif', (-18, -25, 0, 17, 35, 65), (0.0, -5.0, 3.0, PI), False),
]
URINALS = [
    ('Broken', 'UrinalBroken01.nif', (-16, -32, 30, 16, 0, 127)),
    ('Stall01', 'StallUrinal01.nif', (-4, -45, 32, 4, -16, 104)),
    ('Stall02', 'StallUrinal02.nif', (-4, -45, 32, 4, -16, 104)),
    ('Stall03', 'StallUrinal03.nif', (-4, -44, 32, 4, -16, 104)),
]
# Sound sets: property name -> clip folder(s) under Sound\FX\AN76Toilets (one clip is picked at random).
SOUNDS = {
    'Rumble': ['rumble'], 'StrainMale': ['strain_m'], 'StrainFemale': ['strain_f'],
    'FartShort': ['fart_short'], 'FartLong': ['fart_long'], 'FartWet': ['fart_wet'],
    'Plop': ['plop'], 'Explosive': ['explosive'], 'ReliefMale': ['relief_m'], 'ReliefFemale': ['relief_f'],
    'Paper': ['paper'], 'ZipDown': ['zip/down'], 'ZipUp': ['zip/up'], 'Stream': ['urinal'],
}
SOUND_ROOT = pathlib.Path(__file__).resolve().parents[1] / 'sounds' / 'src'
# Cloned from Fallout4.esm SNDR HC_UIModsComponentsWater / OBJArmorStealthActivate: standard sound
# type, the object sound category, the player's 3D output model; BNAM = no pitch shift, 5% pitch
# variance, priority 128, 1 dB volume variance, no static attenuation.
SNDR_CNAM = bytes.fromhex('0a54ef1e')
SNDR_GNAM = bytes.fromhex('a1720100')
SNDR_ONAM = bytes.fromhex('f3be0a00')
SNDR_BNAM = bytes.fromhex('000580010000')

# vanilla base (Fallout4.esm) -> our spawn key
TARGETS = [
    (0x02CD27, 'Seat_Broken01'), (0x034A3F, 'Seat_Broken01'),
    (0x02CD29, 'Seat_Broken02'), (0x034A40, 'Seat_Broken02'),
    (0x02CD2A, 'Seat_Broken03'), (0x034A41, 'Seat_Broken03'),
    (0x0B6E0C, 'Seat_Vault'),
    (0x050AAE, 'Seat_House'),
    (0x091932, 'Seat_HouseRuin'), (0x0248C2, 'Seat_HouseRuin'),
    (0x0305A8, 'Urinal_Broken'), (0x034A3B, 'Urinal_Broken'),
    (0x08025D, 'Urinal_Stall01'), (0x08025E, 'Urinal_Stall02'), (0x08025F, 'Urinal_Stall03'),
]


def field(sig, data):
    if len(data) > 0xFFFF:
        raise ValueError(f'{sig} too large')
    return sig.encode('ascii') + struct.pack('<H', len(data)) + data


def zstring(text):
    return text.encode('ascii') + b'\0'


def wstring(text):
    raw = text.encode('ascii')
    return struct.pack('<H', len(raw)) + raw


def record(sig, form_id, blob, flags=0):
    return (sig.encode('ascii') + struct.pack('<III', len(blob), flags, form_id)
            + struct.pack('<IHH', 0, 131, 0) + blob)


def group(label, blob):
    return (b'GRUP' + struct.pack('<I', 24 + len(blob)) + label.encode('ascii')
            + struct.pack('<I', 0) + struct.pack('<IHH', 0, 0, 0) + blob)


def obj(form_id):
    return struct.pack('<HhI', 0, -1, form_id)


def vmad(script, props):
    """props: list of (name, type, payload bytes). Types: 1 object, 5 bool, 11 object array."""
    out = struct.pack('<hhH', 6, 2, 1) + wstring(script) + struct.pack('<BH', 0, len(props))
    for name, typ, payload in props:
        out += wstring(name) + struct.pack('<BB', typ, 1) + payload
    return out


def obnd(b):
    return struct.pack('<6h', *b)


def build():
    ids, nxt = {}, FIRST_ID

    def new_id(key):
        nonlocal nxt
        ids[key] = nxt
        nxt += 1
        return ids[key]

    furn = b''
    for key, mesh, bounds, (x, y, z, h), flushable in SEATS:
        fid = new_id('Seat_' + key)
        blob = field('EDID', zstring('AN76T_Seat_' + key))
        blob += field('VMAD', vmad('AN76Toilets:Seat', [('Flushable', 5, struct.pack('<B', 1 if flushable else 0))]))
        blob += field('OBND', obnd(bounds))
        blob += field('FULL', zstring('Toilet'))
        blob += field('MODL', zstring('AN76Toilets\\' + mesh))
        blob += field('KSIZ', struct.pack('<I', 3))
        blob += field('KWDA', struct.pack('<3I', KW_CHAIR_SIT, KW_ALLOW_EATING, KW_RELAXATION))
        blob += field('PNAM', struct.pack('<I', 0))
        blob += field('FNAM', struct.pack('<H', 0))
        blob += field('MNAM', bytes.fromhex('01000041'))
        blob += field('WBDT', b'\x00')
        blob += field('SNAM', struct.pack('<4fIi', x, y, z, h, 0, -1))
        furn += record('FURN', fid, blob)

    sndr = b''
    for name, folders in SOUNDS.items():
        fid = new_id('Sound_' + name)
        blob = field('EDID', zstring('AN76T_Sound_' + name))
        blob += field('CNAM', SNDR_CNAM)
        blob += field('GNAM', SNDR_GNAM)
        clips = []
        for folder in folders:
            src = SOUND_ROOT / folder
            files = sorted(src.glob('*.mp3')) if src.is_dir() else [src.with_suffix('.mp3')]
            for f in files:
                rel = f.relative_to(SOUND_ROOT).with_suffix('.wav')
                clips.append('Data\\Sound\\FX\\AN76Toilets\\' + str(rel).replace('/', '\\'))
        if not clips:
            raise SystemExit(f'no clips for sound {name}')
        for c in clips:
            blob += field('ANAM', zstring(c))
        blob += field('ONAM', SNDR_ONAM)
        blob += field('LNAM', struct.pack('<I', 0))
        blob += field('BNAM', SNDR_BNAM)
        sndr += record('SNDR', fid, blob)

    acti = b''
    for key, mesh, bounds in URINALS:
        fid = new_id('Urinal_' + key)
        blob = field('EDID', zstring('AN76T_Urinal_' + key))
        blob += field('VMAD', vmad('AN76Toilets:Urinal', [
            ('ZipDown', 1, obj(ids['Sound_ZipDown'])),
            ('ZipUp', 1, obj(ids['Sound_ZipUp'])),
            ('Stream', 1, obj(ids['Sound_Stream'])),
        ]))
        blob += field('OBND', obnd(bounds))
        blob += field('FULL', zstring('Urinal'))
        blob += field('MODL', zstring('AN76Toilets\\' + mesh))
        blob += field('PNAM', bytes.fromhex('cc4c3300'))
        blob += field('ATTX', zstring('Use'))
        blob += field('FNAM', struct.pack('<H', 0))
        acti += record('ACTI', fid, blob)

    flst_id = new_id('TargetList')
    flst = field('EDID', zstring('AN76T_WorldToilets'))
    for base, _ in TARGETS:
        flst += field('LNAM', struct.pack('<I', base))
    flst_rec = record('FLST', flst_id, flst)

    quest_id = new_id('Quest')
    targets = struct.pack('<I', len(TARGETS)) + b''.join(obj(b) for b, _ in TARGETS)
    spawns = struct.pack('<I', len(TARGETS)) + b''.join(obj(ids[k]) for _, k in TARGETS)
    urinal_ids = [ids['Urinal_' + k] for k, _, _ in URINALS]
    urinals = struct.pack('<I', len(urinal_ids)) + b''.join(obj(u) for u in urinal_ids)
    quest = field('EDID', zstring('AN76T_Spawner'))
    quest += field('VMAD', vmad('AN76Toilets:Spawner', [
        ('Targets', 11, targets),
        ('Spawns', 11, spawns),
        ('Urinals', 11, urinals),
        ('TargetList', 1, obj(flst_id)),
    ]))
    quest += field('DNAM', bytes.fromhex('110064670000000000000000'))
    quest += field('NEXT', b'')
    quest_rec = record('QUST', quest_id, quest)

    sounds_quest_id = new_id('SoundsQuest')
    sq = field('EDID', zstring('AN76T_Sounds'))
    sq += field('VMAD', vmad('AN76Toilets:Sounds', [
        (n, 1, obj(ids['Sound_' + n])) for n in
        ('Rumble', 'StrainMale', 'StrainFemale', 'FartShort', 'FartLong', 'FartWet', 'Plop',
         'Explosive', 'ReliefMale', 'ReliefFemale', 'Paper')]))
    sq += field('DNAM', bytes.fromhex('110064670000000000000000'))
    sq += field('NEXT', b'')
    quest_rec += record('QUST', sounds_quest_id, sq)

    for fid in ids.values():
        if not 0x800 <= (fid & 0xFFFFFF) <= 0xFFF:
            raise SystemExit(f'{fid:08X} is outside 0x800-0xFFF, the range a light plugin holds')

    header = field('HEDR', struct.pack('<fiI', 1.0, len(ids), nxt))
    header += field('CNAM', zstring(AUTHOR))
    header += field('MAST', zstring(MASTER))
    header += field('DATA', struct.pack('<Q', 0))
    body = (group('SNDR', sndr) + group('ACTI', acti) + group('FURN', furn) + group('FLST', flst_rec)
            + group('QUST', quest_rec))
    return record('TES4', 0, header, flags=TES4_LIGHT) + body, ids


def main():
    out = pathlib.Path(sys.argv[1] if len(sys.argv) > 1 else 'build/data/AN76_Toilets.esp')
    out.parent.mkdir(parents=True, exist_ok=True)
    data, ids = build()
    out.write_bytes(data)
    print(f'{out}: {len(data)} bytes, light, {len(ids)} records, {len(TARGETS)} world toilet bases')


if __name__ == '__main__':
    main()
