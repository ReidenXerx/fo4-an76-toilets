"""The voices, game-ready: voice/src/<set>/<clip>.mp3 -> <out>/Sound/Voice/AN76_Toilets.esp/<VoiceType>/<id>_1.fuz

    python tools/make_voice.py [out_root]

Screams, gags, straining and relief are spoken lines (Say), not sound effects, so the speaker's mouth
moves. Each clip becomes one .fuz: lip data from Bethesda's LipGenerator (ships with the game, takes a
44.1 kHz mono wav) plus the xWMA audio from xwmaencode. That same .fuz is copied into every voice type
that may say it: the NPC lines into all vanilla human and ghoul voice types of the matching sex
(tools/voicetypes.json), the player's into PlayerVoiceMale01 / PlayerVoiceFemale01.

The file name is the line's (INFO) form id masked to its low 24 bits, the same for a light plugin.
LipGenerator is not deterministic and writes a temp file into its own folder, so it runs one clip at a
time from a private copy. The per-clip .fuz is cached in build/voice/ by clip, lip text and bitrate.
"""
import hashlib
import pathlib
import shutil
import struct
import subprocess
import sys

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import make_esp  # noqa: E402

ROOT = pathlib.Path(__file__).resolve().parents[1]
GAME_TOOLS = pathlib.Path(r'D:\GOGGames\Fallout 4 GOTY\Tools')
LIPGEN = GAME_TOOLS / 'LipGen' / 'LipGenerator'
XWMAENCODE = GAME_TOOLS / 'Audio' / 'xwmaencode.exe'
CACHE = ROOT / 'build' / 'voice'


def lipgen_copy():
    private = CACHE / 'lipgen'
    if not (private / 'LipGenerator.exe').is_file():
        private.mkdir(parents=True, exist_ok=True)
        for name in ('LipGenerator.exe', 'FonixData.cdf'):
            shutil.copy2(LIPGEN / name, private / name)
    return private / 'LipGenerator.exe'


def make_fuz(clip, lip_text, out):
    work = CACHE / 'work'
    work.mkdir(parents=True, exist_ok=True)
    wav = work / 'line.wav'
    for f in (wav, wav.with_suffix('.lip'), work / 'line.xwm'):
        f.unlink(missing_ok=True)
    subprocess.run(['ffmpeg', '-y', '-loglevel', 'error', '-i', str(clip), '-ac', '1', '-ar', '44100',
                    '-af', 'loudnorm=I=-16:TP=-1.5:LRA=11', '-c:a', 'pcm_s16le', str(wav)], check=True)
    lipgen = lipgen_copy()
    subprocess.run([str(lipgen), str(wav), lip_text, '-Language:USEnglish'], cwd=str(lipgen.parent),
                   capture_output=True)
    lip = wav.with_suffix('.lip')
    if not lip.is_file() or lip.stat().st_size == 0:
        raise SystemExit(f'LipGenerator wrote no .lip for {clip}')
    xwm = work / 'line.xwm'
    # 32 kbps, as vanilla voice: 2,170 copies of 18 lines, so the size matters more than the last bit.
    subprocess.run([str(XWMAENCODE), '-b', '32000', str(wav), str(xwm)], capture_output=True)
    # xwmaencode can exit 0 having written nothing, or non-zero having worked: check the file.
    if not xwm.is_file() or xwm.read_bytes()[:4] != b'RIFF':
        raise SystemExit(f'xwmaencode made no audio for {clip}')
    lip_data = lip.read_bytes()
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_bytes(b'FUZE' + struct.pack('<II', 1, len(lip_data)) + lip_data + xwm.read_bytes())


def main():
    out_root = pathlib.Path(sys.argv[1] if len(sys.argv) > 1 else ROOT / 'build' / 'data')
    voice_dir = out_root / 'Sound' / 'Voice' / 'AN76_Toilets.esp'
    _, ids = make_esp.build()
    made = copies = 0
    for info_id, clip, lip_text, voice_types in make_esp.voice_lines(ids):
        name = f'{info_id & 0xFFFFFF:08X}_1.fuz'
        stamp = hashlib.sha1(f'{clip.name}|{lip_text}|32000'.encode()).hexdigest()[:10]
        cached = CACHE / 'fuz' / f'{name[:-4]}-{stamp}.fuz'
        if not cached.is_file() or cached.stat().st_mtime < clip.stat().st_mtime:
            make_fuz(clip, lip_text, cached)
            made += 1
        data = cached.read_bytes()
        for vt in voice_types:
            target = voice_dir / vt / name
            if not target.is_file() or target.read_bytes() != data:
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_bytes(data)
            copies += 1
    print(f'{made} voice lines rendered, {copies} voice files under {voice_dir}')


if __name__ == '__main__':
    main()
