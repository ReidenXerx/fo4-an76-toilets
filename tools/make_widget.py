"""The HUD icon: a HUDFramework widget SWF, written byte by byte (no Flash compiler on this machine).

    python tools/make_widget.py [out_root]     # writes <out_root>/Interface/AN76Toilets.swf

WHAT IT IS. A 40x40 px SWF whose main timeline has four frames: 1 empty, 2 a yellow toilet, 3 orange,
4 red. Its document class AN76ToiletWidget extends flash.display.MovieClip and implements
hudframework.IHUDWidget (HUDFramework refuses a widget whose document class does not). Papyrus sends
SendMessage(id, 1, stage, ...); processMessage(command, params) does gotoAndStop(int(params[0]) + 1),
so stage 0 hides it and 1..3 show the colours. The interface is NOT defined here: the widget is loaded
where HUDFramework's own classes are visible, and naming it resolves to theirs.

The AS3 is hand-assembled ABC (major 46, minor 16), the same shape Flex emits for such a class: the
script initializer pushes the MovieClip superclass chain as scopes, newclass, pops, initproperty.
"""
import pathlib
import struct
import sys

CLASS = 'AN76ToiletWidget'
SIZE = 40          # px
TWIPS = 20
COLOURS = [(255, 214, 0), (255, 140, 26), (230, 48, 38)]    # yellow, orange, red (vanilla icon hues)

# The toilet, front view, in px; each polygon clockwise on screen (y down), so its fill is on the right.
POLYGONS = [
    [(6, 2), (34, 2), (34, 14), (6, 14)],            # tank
    [(2, 16), (38, 16), (38, 20), (2, 20)],          # seat rim
    [(4, 21), (36, 21), (30, 30), (10, 30)],         # bowl
    [(13, 31), (27, 31), (29, 38), (11, 38)],        # pedestal
]


# ---------------------------------------------------------------- ABC
def u30(v):
    out = bytearray()
    while True:
        b = v & 0x7F
        v >>= 7
        if v:
            out.append(b | 0x80)
        else:
            out.append(b)
            return bytes(out)


def abc_string(s):
    raw = s.encode('utf-8')
    return u30(len(raw)) + raw


def build_abc():
    strings = ['', 'flash.display', 'flash.events', 'hudframework', CLASS, 'MovieClip', 'IHUDWidget',
               'processMessage', 'stop', 'gotoAndStop', 'Object', 'EventDispatcher', 'DisplayObject',
               'InteractiveObject', 'DisplayObjectContainer', 'Sprite', 'String', 'Array', 'void']
    si = {s: i + 1 for i, s in enumerate(strings)}
    # namespaces (index from 1)
    namespaces = [(0x16, si['']), (0x16, si['flash.display']), (0x16, si['flash.events']),
                  (0x16, si['hudframework']), (0x18, si[CLASS])]
    PUB, DISP, EVT, HUD, PROT = 1, 2, 3, 4, 5
    ns_sets = [[PUB]]
    multinames = []

    def qname(ns, name):
        multinames.append(bytes([0x07]) + u30(ns) + u30(si[name]))
        return len(multinames)

    MN_CLASS = qname(PUB, CLASS)
    MN_MOVIECLIP = qname(DISP, 'MovieClip')
    MN_IHUD = qname(HUD, 'IHUDWidget')
    MN_PROCESS = qname(PUB, 'processMessage')
    MN_STOP = qname(PUB, 'stop')
    MN_GOTO = qname(PUB, 'gotoAndStop')
    multinames.append(bytes([0x1B]) + u30(1))            # MultinameL [public]: array index access
    MN_INDEX = len(multinames)
    chain = [qname(PUB, 'Object'), qname(EVT, 'EventDispatcher'), qname(DISP, 'DisplayObject'),
             qname(DISP, 'InteractiveObject'), qname(DISP, 'DisplayObjectContainer'), qname(DISP, 'Sprite')]
    MN_STRING = qname(PUB, 'String')
    MN_ARRAY = qname(PUB, 'Array')
    MN_VOID = qname(PUB, 'void')

    cpool = u30(0) + u30(0) + u30(0)                   # int, uint, double: none
    cpool += u30(len(strings) + 1) + b''.join(abc_string(s) for s in strings)
    cpool += u30(len(namespaces) + 1) + b''.join(bytes([k]) + u30(n) for k, n in namespaces)
    cpool += u30(len(ns_sets) + 1) + b''.join(u30(len(s)) + b''.join(u30(n) for n in s) for s in ns_sets)
    cpool += u30(len(multinames) + 1) + b''.join(multinames)

    # methods: 0 iinit, 1 processMessage(String, Array):void, 2 cinit, 3 script init
    methods = [
        u30(0) + u30(0) + u30(0) + b'\x00',
        u30(2) + u30(MN_VOID) + u30(MN_STRING) + u30(MN_ARRAY) + u30(0) + b'\x00',
        u30(0) + u30(0) + u30(0) + b'\x00',
        u30(0) + u30(0) + u30(0) + b'\x00',
    ]
    method_block = u30(len(methods)) + b''.join(methods)
    metadata = u30(0)

    # instance + class
    trait_process = u30(MN_PROCESS) + bytes([0x01]) + u30(0) + u30(1)   # Trait_Method, disp 0, method 1
    instance = (u30(MN_CLASS) + u30(MN_MOVIECLIP) + bytes([0x09]) + u30(PROT)
                + u30(1) + u30(MN_IHUD) + u30(0) + u30(1) + trait_process)
    cls = u30(2) + u30(0)
    classes = u30(1) + instance + cls
    # script: one Trait_Class slot for the class
    script = u30(3) + u30(1) + u30(MN_CLASS) + bytes([0x04]) + u30(1) + u30(0)
    scripts = u30(1) + script

    def body(method, max_stack, locals_, init_scope, max_scope, code):
        return (u30(method) + u30(max_stack) + u30(locals_) + u30(init_scope) + u30(max_scope)
                + u30(len(code)) + code + u30(0) + u30(0))

    iinit = (b'\xD0\x30'                                  # getlocal0, pushscope
             + b'\xD0\x49' + u30(0)                       # getlocal0, constructsuper 0
             + b'\xD0\x4F' + u30(MN_STOP) + u30(0)        # getlocal0, callpropvoid stop 0
             + b'\x47')                                   # returnvoid
    process = (b'\xD0\x30'
               + b'\xD0'                                  # getlocal0 (receiver)
               + b'\xD2'                                  # getlocal2 (params)
               + b'\x24\x00'                              # pushbyte 0
               + b'\x66' + u30(MN_INDEX)                  # getproperty [params[0]]
               + b'\x73'                                  # convert_i
               + b'\xC0'                                  # increment_i -> frame
               + b'\x4F' + u30(MN_GOTO) + u30(1)          # callpropvoid gotoAndStop 1
               + b'\x47')
    cinit = b'\xD0\x30\x47'
    sinit = b'\xD0\x30' + b'\x65\x00'                     # getlocal0, pushscope, getscopeobject 0
    for mn in chain:
        sinit += b'\x60' + u30(mn) + b'\x30'              # getlex, pushscope
    sinit += b'\x60' + u30(MN_MOVIECLIP)                  # getlex MovieClip (base)
    sinit += b'\x58' + u30(0)                             # newclass 0
    sinit += b'\x1D' * len(chain)                         # popscope x6
    sinit += b'\x68' + u30(MN_CLASS)                      # initproperty
    sinit += b'\x47'
    bodies = [body(0, 1, 1, 0, 1, iinit), body(1, 3, 3, 0, 1, process),
              body(2, 1, 1, 0, 1, cinit), body(3, 3, 1, 0, 8, sinit)]
    return (struct.pack('<HH', 16, 46) + cpool + method_block + metadata + classes + scripts
            + u30(len(bodies)) + b''.join(bodies))


# ---------------------------------------------------------------- SWF
class Bits:
    def __init__(self):
        self.bits = []

    def u(self, value, n):
        for i in range(n - 1, -1, -1):
            self.bits.append((value >> i) & 1)

    def s(self, value, n):
        self.u(value & ((1 << n) - 1), n)

    def bytes(self):
        bits = self.bits + [0] * (-len(self.bits) % 8)
        return bytes(int(''.join(map(str, bits[i:i + 8])), 2) for i in range(0, len(bits), 8))


def sbits(*values):
    n = 1
    for v in values:
        while not (-(1 << (n - 1)) <= v < (1 << (n - 1))):
            n += 1
    return n


def rect(x0, x1, y0, y1):
    b = Bits()
    n = sbits(x0, x1, y0, y1)
    b.u(n, 5)
    for v in (x0, x1, y0, y1):
        b.s(v, n)
    return b.bytes()


def tag(code, payload):
    if len(payload) < 63:
        return struct.pack('<H', (code << 6) | len(payload)) + payload
    return struct.pack('<HI', (code << 6) | 0x3F, len(payload)) + payload


def shape(shape_id, colour):
    edge = SIZE * TWIPS
    payload = struct.pack('<H', shape_id) + rect(0, edge, 0, edge)
    payload += b'\x01' + b'\x00' + bytes(colour)          # one solid fill
    payload += b'\x00'                                    # no line styles
    b = Bits()
    b.u(1, 4)                                             # NumFillBits
    b.u(0, 4)                                             # NumLineBits
    for poly in POLYGONS:
        pts = [(x * TWIPS, y * TWIPS) for x, y in poly]
        x0, y0 = pts[0]
        b.u(0, 1)                                         # style change record
        b.u(0, 1); b.u(0, 1); b.u(1, 1); b.u(0, 1); b.u(1, 1)   # newStyles, line, fill1, fill0, moveTo
        n = sbits(x0, y0)
        b.u(n, 5); b.s(x0, n); b.s(y0, n)
        b.u(1, 1)                                         # FillStyle1 = 1 (fill on the right)
        cur = pts[0]
        for nxt in pts[1:] + [pts[0]]:
            dx, dy = nxt[0] - cur[0], nxt[1] - cur[1]
            n = max(sbits(dx, dy), 2)
            b.u(1, 1); b.u(1, 1)                          # edge record, straight
            b.u(n - 2, 4)
            b.u(1, 1)                                     # general line
            b.s(dx, n); b.s(dy, n)
            cur = nxt
    b.u(0, 6)                                             # end of shape
    return tag(2, payload + b.bytes())


def build_swf():
    body = tag(69, struct.pack('<I', 0x08))               # FileAttributes: ActionScript 3
    body += tag(82, struct.pack('<I', 1) + b'\x00' + build_abc())   # DoABC, lazy
    body += tag(76, struct.pack('<HH', 1, 0) + CLASS.encode() + b'\x00')   # SymbolClass 0 -> class
    for i, colour in enumerate(COLOURS):
        body += shape(i + 1, colour)
    body += tag(1, b'')                                   # frame 1: empty
    for i in range(len(COLOURS)):
        if i:
            body += tag(28, struct.pack('<H', 1))         # RemoveObject2 depth 1
        body += tag(26, bytes([0x02]) + struct.pack('<HH', 1, i + 1))   # PlaceObject2 depth 1, char
        body += tag(1, b'')                               # frames 2..4
    body += tag(0, b'')
    head = rect(0, SIZE * TWIPS, 0, SIZE * TWIPS) + struct.pack('<HH', 30 << 8, 1 + len(COLOURS))
    total = 8 + len(head) + len(body)
    return b'FWS' + bytes([10]) + struct.pack('<I', total) + head + body


def main():
    root = pathlib.Path(sys.argv[1] if len(sys.argv) > 1 else 'build/data')
    out = root / 'Interface' / 'AN76Toilets.swf'
    out.parent.mkdir(parents=True, exist_ok=True)
    data = build_swf()
    out.write_bytes(data)
    print(f'{out}: {len(data)} bytes, 4 frames, document class {CLASS}')


if __name__ == '__main__':
    main()
