"""The MCM page: <out>/MCM/Config/AN76_Toilets/config.json

    python tools/make_mcm.py [out_root]

Every control writes one of the plugin's globals directly (sourceType GlobalValue, the way Advanced
Needs 76's own MCM works). The form ids come from make_esp.build(), so the page and the plugin cannot
drift apart.
"""
import json
import pathlib
import sys

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import make_esp  # noqa: E402

PLUGIN = 'AN76_Toilets.esp'


def form(ids, key):
    return f'{PLUGIN}|{ids[key] & 0xFFF:X}'


def build():
    _, ids = make_esp.build()

    def switcher(text, key, help_text):
        return {'text': text, 'type': 'switcher', 'help': help_text,
                'valueOptions': {'sourceType': 'GlobalValue', 'sourceForm': form(ids, key)}}

    def slider(text, key, lo, hi, step, help_text):
        return {'text': text, 'type': 'slider', 'help': help_text,
                'valueOptions': {'min': lo, 'max': hi, 'step': step,
                                 'sourceType': 'GlobalValue', 'sourceForm': form(ids, key)}}

    content = [
        {'type': 'spacer', 'numLines': 2},
        {'text': "<p align='center'><font size='28'><b>AN76 TOILETS</b></font><br>"
                 "<font size='12'>An add-on for Advanced Needs 76's Bathroom Needs</font></p>",
         'html': True, 'type': 'text'},
        {'type': 'spacer', 'numLines': 1},
        {'text': "Once per save, after you leave Vault 111, this add-on starts Advanced Needs 76 itself, "
                 "its needs system, Bathroom Needs and camping, if they are not already running. "
                 "Anything you turn off in AN76's MCM afterwards stays off.",
         'type': 'text'},
        {'text': 'Toilet icon', 'type': 'section'},
        switcher('Show the toilet icon', 'Setting_IconOn',
                 'A toilet beside the status icons while you need to go: yellow, then orange once the '
                 'pain has lasted one of AN76\'s pain intervals, red after three. Needs HUDFramework.'),
        {'text': 'The icon joins the status icons row by itself (hunger, thirst, sleep, AN76), in the next '
                 'free slot, at their size, on the vanilla HUD and FallUI alike.', 'type': 'text'},
        slider('Nudge left / right', 'Setting_IconNudgeX', -100.0, 100.0, 1.0,
               'Pixels from its slot in the status row. Default 0.'),
        slider('Nudge up / down', 'Setting_IconNudgeY', -100.0, 100.0, 1.0,
               'Pixels from its slot in the status row. Default 0.'),
        slider('Icon size', 'Setting_IconScale', 0.5, 3.0, 0.1,
               'Relative to the status icons. Default 1.0.'),
        slider('Fallback position X', 'Setting_IconX', 0.0, 1280.0, 10.0,
               'Only for a HUD with no status icons row: left to right on the 1280 x 720 HUD.'),
        slider('Fallback position Y', 'Setting_IconY', 0.0, 720.0, 10.0,
               'Only for a HUD with no status icons row: top to bottom on the 1280 x 720 HUD.'),
        {'text': 'Holding it', 'type': 'section'},
        switcher('Accidents instead of pain', 'Setting_AccidentsOn',
                 "Holding it never hurts: the icon turns orange, and when it would turn red you go in your "
                 "pants, right where you stand. Off: AN76's own pain and damage."),
        slider('Orange after (game hours)', 'Setting_OrangeHours', 0.5, 12.0, 0.5,
               'Game hours since the need hit. Sleep does not count. Default 2.'),
        slider('Accident after (game hours)', 'Setting_AccidentHours', 1.0, 24.0, 0.5,
               'Game hours since the need hit. Sleep does not count. Default 4.'),
        switcher('Panic', 'Setting_PanicOn',
                 'Everyone within 25 m screams and runs from you, then goes back to what they were doing. '
                 'Not your companion, and nobody fighting, hostile, in a scene or talking to you.'),
        slider('Panic length (seconds)', 'Setting_PanicSeconds', 10.0, 180.0, 5.0, 'Default 60.'),
        switcher('Aftermath', 'Setting_AftermathOn',
                 "You stink: AN76's body odour until you bathe or swim (with AN76's bathing on; otherwise "
                 "6 game hours). Gnats where it happened, flies buzzing, and people near you gag and pull a face."),
        {'text': 'Sounds', 'type': 'section'},
        switcher('Bathroom sounds', 'Setting_SoundsOn',
                 'The stomach rumble when the need hits; straining, farts, plops and a sigh of relief '
                 'while you go; zipper and stream at urinals. AN76\'s own sound switches also apply.'),
        {'text': 'World toilets', 'type': 'section'},
        switcher('Use the toilets already in the world', 'Setting_WorldToilets',
                 'Broken, vault and house toilets become seats, and men can use urinals. '
                 'AN76\'s own toilets always work.'),
    ]
    return {
        'modName': 'AN76_Toilets',
        'displayName': 'AN76 Toilets',
        'minMcmVersion': 2,
        'pluginRequirements': [PLUGIN],
        'content': content,
    }


def main():
    root = pathlib.Path(sys.argv[1] if len(sys.argv) > 1 else 'build/data')
    out = root / 'MCM' / 'Config' / 'AN76_Toilets' / 'config.json'
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(build(), indent=2), encoding='utf-8')
    print(f'{out}: MCM page, {len(build()["content"])} entries')


if __name__ == '__main__':
    main()
