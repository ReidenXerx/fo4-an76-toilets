"""The bathroom sound pack, game-ready: sounds/src/<set>/<clip>.mp3 -> <out>/Sound/FX/AN76Toilets/<set>/<clip>.wav

    python tools/make_sounds.py [out_root]

The sources are ElevenLabs sound effects (owner-approved plan, 2026-09-29; generated effects, no
voice clone). Converted to what the game plays from a loose file: PCM 16-bit, 44.1 kHz, mono (the
sounds come from the player, a 3D source), loudness-matched so a fart is not twice as loud as a sigh.
"""
import pathlib
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parents[1]
SRC = ROOT / 'sounds' / 'src'


def main():
    out_root = pathlib.Path(sys.argv[1] if len(sys.argv) > 1 else ROOT / 'build' / 'data')
    out = out_root / 'Sound' / 'FX' / 'AN76Toilets'
    count = 0
    for mp3 in sorted(SRC.rglob('*.mp3')):
        wav = out / mp3.relative_to(SRC).with_suffix('.wav')
        wav.parent.mkdir(parents=True, exist_ok=True)
        cmd = ['ffmpeg', '-y', '-loglevel', 'error', '-i', str(mp3), '-ac', '1', '-ar', '44100',
               '-af', 'loudnorm=I=-16:TP=-1.5:LRA=11', '-c:a', 'pcm_s16le', str(wav)]
        subprocess.run(cmd, check=True)
        count += 1
    print(f'{count} clips -> {out}')


if __name__ == '__main__':
    main()
