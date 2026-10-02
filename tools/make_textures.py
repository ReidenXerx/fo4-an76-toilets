"""The pee puddle decal: a wet, yellowish stain the engine stamps on the floor and fades by itself.

    python tools/make_textures.py [out_root]    # writes <out_root>/Textures/AN76Toilets/PeePuddle_{d,n}.dds

Drawn here, not painted: an irregular puddle from a few overlapping blobs and a soft noise edge, a
little darker at the rim where it dries first, mostly see-through so the floor shows through it.
Uncompressed BGRA with mipmaps (a decal shimmers without them). Shipped loose: the general BA2 does not
carry textures.
"""
import pathlib
import struct
import sys

import numpy as np

SIZE = 256
SEED = 76


def puddle():
    rng = np.random.default_rng(SEED)
    y, x = np.mgrid[0:SIZE, 0:SIZE] / (SIZE - 1) * 2.0 - 1.0
    # The body: a few offset blobs, so the outline is not a circle.
    field = np.zeros((SIZE, SIZE))
    # A main pool, a run where it spread, and a few splash drops beside it.
    for cx, cy, r in [(-0.08, 0.02, 0.34), (0.22, 0.18, 0.22), (-0.3, -0.2, 0.2), (0.12, -0.28, 0.17),
                      (0.42, 0.34, 0.12), (0.55, 0.45, 0.07), (-0.55, 0.3, 0.06), (-0.12, 0.55, 0.05),
                      (0.5, -0.5, 0.045), (-0.6, -0.5, 0.04)]:
        field += np.exp(-((x - cx) ** 2 + (y - cy) ** 2) / (2 * r * r))

    def value_noise(cells):
        coarse = rng.random((cells + 1, cells + 1))
        idx = np.linspace(0, cells, SIZE)
        i0 = np.floor(idx).astype(int).clip(0, cells - 1)
        t = idx - i0
        t = t * t * (3 - 2 * t)
        rows = coarse[i0] * (1 - t)[:, None] + coarse[i0 + 1] * t[:, None]
        return rows[:, i0] * (1 - t)[None, :] + rows[:, i0 + 1] * t[None, :]

    # A ragged edge: two octaves of value noise.
    field += (value_noise(10) - 0.5) * 0.45 + (value_noise(28) - 0.5) * 0.2
    # Edge: smooth step around the threshold; nothing reaches the texture border.
    inside = np.clip((field - 0.6) / 0.14, 0.0, 1.0)
    inside = inside * inside * (3 - 2 * inside)
    border = np.minimum.reduce([x + 1, 1 - x, y + 1, 1 - y])
    inside *= np.clip(border / 0.08, 0.0, 1.0)
    rim = np.clip(1.0 - np.abs(inside - 0.45) / 0.35, 0.0, 1.0)      # strongest just inside the edge
    alpha = inside * 0.42 + rim * 0.18
    r = 205 - rim * 55
    g = 172 - rim * 60
    b = 52 - rim * 25
    rgba = np.stack([r, g, b, alpha * 255], axis=-1)
    return np.clip(rgba, 0, 255).astype(np.uint8)


def flat_normal():
    img = np.zeros((SIZE, SIZE, 4), np.uint8)
    img[..., 0], img[..., 1], img[..., 2], img[..., 3] = 128, 128, 255, 255
    return img


def mips(img):
    out = [img]
    while out[-1].shape[0] > 1:
        a = out[-1].astype(np.float32)
        a = (a[0::2, 0::2] + a[1::2, 0::2] + a[0::2, 1::2] + a[1::2, 1::2]) / 4.0
        out.append(np.round(a).astype(np.uint8))
    return out


def dds(img):
    levels = mips(img)
    h, w = img.shape[:2]
    flags = 0x1 | 0x2 | 0x4 | 0x8 | 0x1000 | 0x20000          # caps height width pitch pixelformat mipmapcount
    pf = struct.pack('<II4sIIIII', 32, 0x41, b'\0\0\0\0', 32, 0x00FF0000, 0x0000FF00, 0x000000FF, 0xFF000000)
    head = struct.pack('<4sIIIIIII', b'DDS ', 124, flags, h, w, w * 4, 0, len(levels)) + b'\0' * 44
    head += pf + struct.pack('<IIIII', 0x1000 | 0x8 | 0x400000, 0, 0, 0, 0)
    body = b''.join(lv[..., [2, 1, 0, 3]].tobytes() for lv in levels)   # RGBA -> BGRA
    return head + body


def main():
    root = pathlib.Path(sys.argv[1] if len(sys.argv) > 1 else 'build/data')
    out = root / 'Textures' / 'AN76Toilets'
    out.mkdir(parents=True, exist_ok=True)
    (out / 'PeePuddle_d.dds').write_bytes(dds(puddle()))
    (out / 'PeePuddle_n.dds').write_bytes(dds(flat_normal()))
    print(f'{out}: PeePuddle_d.dds, PeePuddle_n.dds ({SIZE}x{SIZE}, mipmapped)')


if __name__ == '__main__':
    main()
