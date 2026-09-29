"""Builds AN76_Toilets.esp: the seats, the urinals, the list of world toilets, the spawner quest.

    python tools/make_esp.py [out.esp]

A light plugin (ESL) with one master, Fallout4.esm. Advanced Needs 76 is NOT a master: the scripts
reach it by form id at run time, so none of its records are overridden (its permissions forbid
changing its files) and this plugin loads harmlessly without it.

Record layouts are cloned from vanilla: the seat from Fallout4.esm FURN 10C853
NpcChairInstituteToiletSit01, the urinal from ACTI 0248C2 Toilet01, the quest DNAM from
AAF_MainQuest (start game enabled).
"""
import json
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
    'Rumble': ['rumble'],
    'FartShort': ['fart_short'], 'FartLong': ['fart_long'], 'FartWet': ['fart_wet'],
    'Plop': ['plop'], 'Explosive': ['explosive'],
    'Paper': ['paper'], 'ZipDown': ['zip/down'], 'ZipUp': ['zip/up'], 'Stream': ['urinal'],
    'AccidentPoop': ['accident/accident_1'], 'AccidentPee': ['accident/accident_2'], 'Squelch': ['squelch'],
}
SOUND_ROOT = pathlib.Path(__file__).resolve().parents[1] / 'sounds' / 'src'

# Voices: spoken through dialogue (Say) so the face moves with the line, not played as sound effects.
# One topic with one line per clip; the script picks the clip. set -> (clip folder under voice/src, who
# speaks it, subtitle, the text LipGenerator shapes the mouth from, the line's emotion).
# Owner 2026-09-29: a scream is a held open mouth and a fear face, not talking. The fear comes from the
# line's emotion: TRDA's first field, an AnimFaceArchetype keyword, as on 36k vanilla lines. The open
# mouth comes from the .lip, and a scream cannot make one: LipGenerator reads it as noise, and a single
# long vowel gives ONE open-close bell of about half a second (measured, 132-194 byte lips; in game: no
# mouth and no face at all). VOWEL_RUN lines take their lip from a synthetic "ah ah ah..." instead,
# timed to the clip: the bells overlap into an open jaw held at 1.0 for the whole line (measured). The
# gags keep a lip from their own audio -- the owner loved those as they are.
VOWEL_RUN = None
# (Strain, relief, screams and gags were sound effects before 2026-09-29; their SNDR ids stay retired.)
FACE_AFRAID = 0x0FA84B     # AnimFaceArchetypeAfraid
FACE_DISGUST = 0x0C8674    # AnimFaceArchetypeDisgust
FACE_IN_PAIN = 0x100286    # AnimFaceArchetypeInPain
FACE_RELIEVED = 0x18E863   # AnimFaceArchetypeRelieved
VOICE_ROOT = pathlib.Path(__file__).resolve().parents[1] / 'voice' / 'src'
VOICE = {
    'ScreamMale': ('scream_m', 'npc-male', 'AAAAAAH!', VOWEL_RUN, FACE_AFRAID),
    'ScreamFemale': ('scream_f', 'npc-female', 'AAAAAAH!', VOWEL_RUN, FACE_AFRAID),
    'GagMale': ('gag_m', 'npc-male', '*gags*', 'Ugh hhk bleh', FACE_DISGUST),
    'GagFemale': ('gag_f', 'npc-female', '*gags*', 'Ugh hhk bleh', FACE_DISGUST),
    'StrainMale': ('strain_m', 'player-male', 'Nnnngh!', VOWEL_RUN, FACE_IN_PAIN),
    'StrainFemale': ('strain_f', 'player-female', 'Nnnngh!', VOWEL_RUN, FACE_IN_PAIN),
    'ReliefMale': ('relief_m', 'player-male', 'Ahhhh...', VOWEL_RUN, FACE_RELIEVED),
    'ReliefFemale': ('relief_f', 'player-female', 'Ahhhh...', VOWEL_RUN, FACE_RELIEVED),
}
PLAYER_VOICE_TYPES = {'player-male': ['PlayerVoiceMale01'], 'player-female': ['PlayerVoiceFemale01']}


def voice_clips(name):
    return sorted((VOICE_ROOT / VOICE[name][0]).glob('*.mp3'))


def voice_types(speaker):
    if speaker in PLAYER_VOICE_TYPES:
        return PLAYER_VOICE_TYPES[speaker]
    table = json.loads((pathlib.Path(__file__).resolve().parent / 'voicetypes.json').read_text())
    return table['male' if speaker == 'npc-male' else 'female']


def voice_lines(ids):
    # [(info form id, clip mp3, lip text, voice type folders)] for tools/make_voice.py.
    out = []
    for name, (_, speaker, _, lip_text, _) in VOICE.items():
        for n, clip in enumerate(voice_clips(name), 1):
            out.append((ids[f'Line_{name}{n}'], clip, lip_text, voice_types(speaker)))
    return out
# Cloned from Fallout4.esm SNDR HC_UIModsComponentsWater / OBJArmorStealthActivate: standard sound
# type, the object sound category, the player's 3D output model; BNAM = no pitch shift, 5% pitch
# variance, priority 128, 1 dB volume variance, no static attenuation.
SNDR_CNAM = bytes.fromhex('0a54ef1e')
SNDR_GNAM = bytes.fromhex('a1720100')
SNDR_ONAM = bytes.fromhex('f3be0a00')
SNDR_BNAM = bytes.fromhex('000580010000')

# MCM settings: global -> default. The MCM page writes these directly (sourceType GlobalValue), as
# AN76's own MCM does; the scripts read them every few seconds.
SETTINGS = [
    ('IconOn', 1.0), ('IconX', 1120.0), ('IconY', 560.0), ('IconScale', 1.0),
    ('SoundsOn', 1.0), ('WorldToilets', 1.0),
    ('IconNudgeX', 0.0), ('IconNudgeY', 0.0),
    ('AccidentsOn', 1.0), ('OrangeHours', 2.0), ('AccidentHours', 4.0),
    ('PanicOn', 1.0), ('PanicSeconds', 60.0), ('AftermathOn', 1.0),
]

# The panic. Measured 2026-09-29, one test each in Diamond City: FO4 has no way to make a CALM NPC run.
# Two vanilla-shaped Flee packages give up outside combat; a running Travel to a marker 25 m away gave up
# (markers off navmesh); the Yao Guai roar's Demoralize landed on all 10 ("afraid True") and moved nobody,
# since fear works through the combat AI. Retired ids: PanicFlee 831, PanicFleeCrowd 859, PanicLink 85A,
# PanicRun 85B, PanicFearEffect 85C, PanicFear 85D.
# Owner's call (poll 2026-09-29): cower and scream, no combat anywhere. The alias holds them with vanilla
# HoldPosition -- the one alias package measured to reach them (14 of 14) -- so nothing walks them out of
# the cower the script plays on them.
PANIC_HOLD_PACKAGE = 0x01D415   # Fallout4.esm PACK HoldPosition, no conditions

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


def child_group(form_id, group_type, blob):
    # A GRUP labelled with a form id: type 10 = a quest's children, 7 = a topic's children.
    return (b'GRUP' + struct.pack('<III', 24 + len(blob), form_id, group_type)
            + struct.pack('<IHH', 0, 0, 0) + blob)


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
    # Form ids are PERMANENT: a save binds running scripts and placed references to them, so a record
    # that moves takes a save's script instances with it onto whatever now holds its old id (2026-09-29:
    # the spawner ran attached to an MCM global). tools/formids.json is the only source; a new record
    # appends after the highest id, an existing one never moves.
    table_path = pathlib.Path(__file__).resolve().parent / 'formids.json'
    table = json.loads(table_path.read_text())
    ids = {}

    def new_id(key):
        if key not in table:
            table[key] = f'{max(int(v, 16) for v in table.values()) + 1:03X}'
            table_path.write_text(json.dumps(table, indent=1) + '\n')
            print(f'new form id {table[key]} for {key} (commit tools/formids.json)')
        ids[key] = FIRST_ID & 0xFF000000 | int(table[key], 16)
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

    glob = b''
    for name, default in SETTINGS:
        gid = new_id('Setting_' + name)
        blob = field('EDID', zstring('AN76T_' + name))
        blob += field('FNAM', b'f')
        blob += field('FLTV', struct.pack('<f', default))
        glob += record('GLOB', gid, blob)

    an76_list_id = new_id('AN76Toilets')
    an76_list = record('FLST', an76_list_id, field('EDID', zstring('AN76T_AN76Toilets')))

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
        ('AN76ToiletList', 1, obj(an76_list_id)),
        ('WorldToiletsOn', 1, obj(ids['Setting_WorldToilets'])),
    ]))
    quest += field('DNAM', bytes.fromhex('110064670000000000000000'))
    quest += field('NEXT', b'')
    quest_rec = record('QUST', quest_id, quest)

    accident_id = new_id('AccidentQuest')

    # The voices: one Dialogue Branch owning a topic per clip, each with one line, all in the accident
    # quest (start-game enabled, so Say finds them). Shapes from fo4-rapport tools/make_dialogue.py,
    # verified spoken in game there; a topic outside a branch resolves and stays silent.
    branch_id = new_id('VoiceBranch')
    topics = {}
    dialogue = b''
    for name, (_, _, subtitle, _, emotion) in VOICE.items():
        topics[name] = []
        for n, _clip in enumerate(voice_clips(name), 1):
            tid, iid = new_id(f'Topic_{name}{n}'), new_id(f'Line_{name}{n}')
            topics[name].append(tid)
            dial = field('EDID', zstring(f'AN76T_{name}{n}'))
            dial += field('PNAM', struct.pack('<f', 50.0))
            dial += field('BNAM', struct.pack('<I', branch_id))
            dial += field('QNAM', struct.pack('<I', accident_id))
            dial += field('DATA', struct.pack('<I', 0))
            dial += field('SNAM', b'CUST')
            dial += field('TIFC', struct.pack('<I', 1))
            info = field('ENAM', struct.pack('<I', 2))
            info += field('TRDA', struct.pack('<I', emotion) + bytes.fromhex('01000000' '00010000' 'ffffffff' 'ffffffff'))
            info += field('NAM1', zstring(subtitle))
            for sig in ('NAM2', 'NAM3', 'NAM4', 'NAM0'):
                info += field(sig, b'\0')
            info += field('INAM', struct.pack('<I', 1))
            dialogue += record('DIAL', tid, dial) + child_group(tid, 7, record('INFO', iid, info))
    first_topic = topics[next(iter(VOICE))][0]
    branch = field('EDID', zstring('AN76T_Voices'))
    branch += field('QNAM', struct.pack('<I', accident_id))
    branch += field('TNAM', struct.pack('<I', 0))
    branch += field('DNAM', struct.pack('<I', 1))
    branch += field('SNAM', struct.pack('<I', first_topic))
    dialogue = record('DLBR', branch_id, branch) + dialogue

    def topic_array(name):
        return struct.pack('<I', len(topics[name])) + b''.join(obj(t) for t in topics[name])

    sounds_quest_id = new_id('SoundsQuest')
    sq = field('EDID', zstring('AN76T_Sounds'))
    sq += field('VMAD', vmad('AN76Toilets:Sounds', [
        (n, 1, obj(ids['Sound_' + n])) for n in
        ('Rumble', 'FartShort', 'FartLong', 'FartWet', 'Plop', 'Explosive', 'Paper')] + [
        (n + 'Lines', 11, topic_array(n)) for n in ('StrainMale', 'StrainFemale', 'ReliefMale', 'ReliefFemale')] + [
        ('IconOn', 1, obj(ids['Setting_IconOn'])), ('IconX', 1, obj(ids['Setting_IconX'])),
        ('IconNudgeX', 1, obj(ids['Setting_IconNudgeX'])), ('IconNudgeY', 1, obj(ids['Setting_IconNudgeY'])),
        ('IconY', 1, obj(ids['Setting_IconY'])), ('IconScale', 1, obj(ids['Setting_IconScale'])),
        ('SoundsSetting', 1, obj(ids['Setting_SoundsOn'])),
        ('Accident', 1, obj(accident_id)),
        ('AccidentsOn', 1, obj(ids['Setting_AccidentsOn'])),
        ('OrangeHours', 1, obj(ids['Setting_OrangeHours'])),
        ('AccidentHours', 1, obj(ids['Setting_AccidentHours']))]))
    sq += field('DNAM', bytes.fromhex('110064670000000000000000'))
    sq += field('NEXT', b'')
    quest_rec += record('QUST', sounds_quest_id, sq)


    aq = field('EDID', zstring('AN76T_Accident'))
    aq += field('VMAD', vmad('AN76Toilets:Accident', [
        ('Panicked', 1, struct.pack('<HhI', 0, 0, accident_id)),
        ] + [
        (n, 1, obj(ids['Sound_' + n])) for n in
        ('AccidentPoop', 'AccidentPee', 'Squelch')] + [
        (n + 'Lines', 11, topic_array(n)) for n in ('ScreamMale', 'ScreamFemale', 'GagMale', 'GagFemale')] + [
        (n, 1, obj(ids['Setting_' + n])) for n in ('PanicOn', 'PanicSeconds', 'AftermathOn')]))
    aq += field('DNAM', bytes.fromhex('110064670000000000000000'))
    aq += field('NEXT', b'')
    # One reference collection, alias 0 "Panicked": empty until the script adds people; optional, may
    # hold reserved references; HoldPosition keeps them still while they cower.
    aq += field('ANAM', struct.pack('<I', 1))
    aq += field('ALCS', struct.pack('<I', 0))
    aq += field('ALMI', b'\x00')
    aq += field('ALST', struct.pack('<I', 0))
    aq += field('ALID', zstring('Panicked'))
    aq += field('FNAM', struct.pack('<I', 0x202))
    aq += field('ALPC', struct.pack('<I', PANIC_HOLD_PACKAGE))
    aq += field('VTCK', struct.pack('<I', 0))
    aq += field('ALED', b'')
    quest_rec += record('QUST', accident_id, aq) + child_group(accident_id, 10, dialogue)

    for fid in ids.values():
        if not 0x800 <= (fid & 0xFFFFFF) <= 0xFFF:
            raise SystemExit(f'{fid:08X} is outside 0x800-0xFFF, the range a light plugin holds')

    header = field('HEDR', struct.pack('<fiI', 1.0, len(ids), max(ids.values()) + 1))
    header += field('CNAM', zstring(AUTHOR))
    header += field('MAST', zstring(MASTER))
    header += field('DATA', struct.pack('<Q', 0))
    body = (group('GLOB', glob) + group('SNDR', sndr) + group('ACTI', acti) + group('FURN', furn)
            + group('FLST', flst_rec + an76_list) + group('QUST', quest_rec))
    return record('TES4', 0, header, flags=TES4_LIGHT) + body, ids


def main():
    out = pathlib.Path(sys.argv[1] if len(sys.argv) > 1 else 'build/data/AN76_Toilets.esp')
    out.parent.mkdir(parents=True, exist_ok=True)
    data, ids = build()
    out.write_bytes(data)
    print(f'{out}: {len(data)} bytes, light, {len(ids)} records, {len(TARGETS)} world toilet bases')


if __name__ == '__main__':
    main()
