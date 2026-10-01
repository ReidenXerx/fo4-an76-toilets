"""AN76 Toilets' FOMOD installer, written into a release folder (nexus-tools/docs/FOMOD-STANDARD.md, the owner's
house standard of 2026-10-01). Shape and checks from fo4-silhouette tools/fomod_pack.py.

    python tools/fomod_pack.py <release folder> <version> [--draft]

Writes <release folder>/fomod/: ModuleConfig.xml, info.xml, images/*.png and screenshot.png.
- The install is REFUSED unless Advanced Needs 76 (Flashy_PersonalEssentials.esp) and HUDFramework.esm are active
  and the game is 1.10.163 or newer -- the only requirements both Vortex and MO2 can see (rule 2). F4SE and MCM are
  checked in game (Sounds.psc CheckSetup) and named on the first page (rule 4a).
- Every top-level entry of the release folder is installed as it is, read from the folder.
- Pages: "Checking your setup" (ONE Required option holding the whole checklist), then one page per feature, its
  card and text shown without a click (rule 4: one Required option alone in the step's first group).
- Cards: Publisher-bud's renders, D:/F4Output/cards/general/toilets/<card>.png, resized to 1000 px.
  --draft builds without them (no images) to check everything else; a release never uses it.
Validates ModuleConfig.xml against the 5.0 schema and checks every image and source it names exists.
"""
import html
import pathlib
import sys

from PIL import Image

ROOT = pathlib.Path(__file__).resolve().parent.parent
XSD = ROOT.parent / 'fo4-silhouette' / 'tools' / 'fomod' / 'ModuleConfig5.0.xsd'   # the schema Vortex validates with
CARDS = pathlib.Path(r'D:\F4Output\cards\general\toilets')
SCHEMA = 'http://qconsulting.ca/fo3/ModConfig5.0.xsd'   # exactly: Vortex reads the version out of this text
NAME = 'AN76 Toilets'

# (step name, card file, plain-text description). Facts as README.md has them.
FEATURES = [
    ('Holding it: accidents and panic', 'accidents.png',
     'Holding it never hurts: the toilet icon turns orange at 2 game hours and red at 4, and then you go in your '
     'pants where you stand. Sleep and fast travel do not count; waiting does.\n'
     'Everyone within 25 m screams and cowers, then goes back to what they were doing. An accident mid-conversation '
     'ends the conversation. Afterwards you stink until you wash: gnats, aftershock farts, people gag or throw up.'),
    ('NPCs use toilets too', 'npc-toilets.png',
     'Anyone who sits down on a toilet in their own routine -- a settler on a world toilet, the Institute\'s '
     'toilets, Far Harbor\'s outhouses, AN76\'s built toilets -- undresses, goes, sighs and dresses again, with the '
     'sounds of their own sex. Children keep their clothes on. A switch and a chance in MCM.'),
    ('Voices and sounds', 'voices.png',
     'Straining, farts, plops, a sigh of relief and the toilet paper while you go; a stomach rumble when the need '
     'hits. Body sounds in male and female sets. Screams, gags, puking, straining and relief are spoken lines with '
     'lip sync in every vanilla human and ghoul voice type: 8,110 voice files.'),
    ('World toilets and urinals', 'world-toilets.png',
     'The broken, vault and house toilets already in the world become seats you can use, and men can use urinals '
     '(15 vanilla models). AN76\'s own toilets always work.'),
]
EXTRAS = ('And the rest',
          'The toilet icon joins the HUD\'s status-icon row (hunger, thirst, sleep, AN76).\n'
          'Clothes AN76\'s undress leaves off are put back on when you are done.\n'
          'MCM: every part on or off, the hours, the panic, the sounds; a Testing page to try each part at once.')
SETUP = ('Your setup',
         'Advanced Needs 76: found -- the needs this add-on plays out (Nexus 58440).\n'
         'HUDFramework: found -- the toilet icon (Nexus 20309).\n'
         'F4SE: check this yourself -- puts clothes back on and ends a conversation on an accident '
         '(f4se.silverlock.org).\n'
         'MCM: check this yourself -- the settings (Nexus 21497).\n'
         'AN76 Toilets checks F4SE and MCM in game and says what is missing.')


def esc(text):
    return html.escape(text, quote=True)


def option(name, description, image=None, flag='shown'):
    picture = f'\n              <image path="fomod\\images\\{image}"/>' if image else ''
    return f'''            <plugin name="{esc(name)}">
              <description>{esc(description)}</description>{picture}
              <conditionFlags><flag name="{flag}">1</flag></conditionFlags>
              <typeDescriptor><type name="Required"/></typeDescriptor>
            </plugin>'''


def page(step, group, opt):
    return f'''    <installStep name="{esc(step)}">
      <optionalFileGroups order="Explicit">
        <group name="{esc(group)}" type="SelectAll">
          <plugins order="Explicit">
{opt}
          </plugins>
        </group>
      </optionalFileGroups>
    </installStep>'''


def module_config(entries, images):
    installs = []
    for e in entries:
        kind = 'folder' if e.is_dir() else 'file'
        installs.append(f'    <{kind} source="{esc(e.name)}" destination="{esc(e.name)}" priority="0"/>')
    pages = [page('Checking your setup', 'Requirements', option(SETUP[0], SETUP[1], flag='setup'))]
    pages += [page(n, n, option(n, d, img if images else None)) for n, img, d in FEATURES]
    pages.append(page(EXTRAS[0], EXTRAS[0], option(EXTRAS[0], EXTRAS[1])))
    module_image = f'\n  <moduleImage path="fomod\\images\\{FEATURES[0][1]}"/>' if images else ''
    return f'''<?xml version="1.0" encoding="UTF-8"?>
<!-- GENERATED by tools/fomod_pack.py (nexus-tools/docs/FOMOD-STANDARD.md). Edit the tool, not this file. -->
<config xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="{SCHEMA}">
  <moduleName>{esc(NAME)}</moduleName>{module_image}
  <moduleDependencies operator="And">
    <gameDependency version="1.10.163.0"/>
    <fileDependency file="Flashy_PersonalEssentials.esp" state="Active"/>
    <fileDependency file="HUDFramework.esm" state="Active"/>
  </moduleDependencies>
  <requiredInstallFiles>
{chr(10).join(installs)}
  </requiredInstallFiles>
  <installSteps order="Explicit">
{chr(10).join(pages)}
  </installSteps>
</config>
'''


def main():
    args = [a for a in sys.argv[1:] if not a.startswith('--')]
    draft = '--draft' in sys.argv
    if len(args) != 2:
        sys.exit(__doc__)
    out, version = pathlib.Path(args[0]), args[1]
    entries = sorted((e for e in out.iterdir() if e.name.lower() != 'fomod'), key=lambda e: e.name.lower())
    if not entries:
        sys.exit(f'{out} holds nothing to install')
    fomod = out / 'fomod'
    (fomod / 'images').mkdir(parents=True, exist_ok=True)
    images = not draft
    if images:
        for _n, card, _d in FEATURES:
            src = CARDS / card
            if not src.exists():
                sys.exit(f'no card {src} -- Publisher-bud renders them; --draft builds without')
            pic = Image.open(src).convert('RGB')
            pic.resize((1000, round(1000 * pic.height / pic.width)), Image.LANCZOS).save(fomod / 'images' / card)
        first = Image.open(fomod / 'images' / FEATURES[0][1])
        first.save(fomod / 'screenshot.png')   # MO2 shows this, not moduleImage
    (fomod / 'ModuleConfig.xml').write_text(module_config(entries, images), encoding='utf-8-sig')
    (fomod / 'info.xml').write_text(f'''<?xml version="1.0" encoding="UTF-8"?>
<fomod>
  <Name>{esc(NAME)}</Name>
  <Author>Dudu'sButt</Author>
  <Version>{esc(version)}</Version>
  <Website>https://github.com/ReidenXerx/fo4-an76-toilets</Website>
  <Description>An add-on for Advanced Needs 76's Bathroom Needs: sounds, voices, accidents, panic, toilets for everyone.</Description>
</fomod>
''', encoding='utf-8-sig')

    from lxml import etree
    schema = etree.XMLSchema(etree.parse(str(XSD)))
    doc = etree.parse(str(fomod / 'ModuleConfig.xml'))
    if not schema.validate(doc):
        sys.exit('ModuleConfig.xml fails the 5.0 schema:\n' + '\n'.join(str(e) for e in schema.error_log))
    for el in doc.iter('image', 'moduleImage'):
        if not (out / el.get('path').replace('\\', '/')).exists():
            sys.exit(f'the installer shows {el.get("path")}, which is not in the release')
    for el in doc.iter('file', 'folder'):
        if not (out / el.get('source')).exists():
            sys.exit(f'the installer installs {el.get("source")}, which is not in the release')
    print(f'fomod: {len(entries)} entries installed as they are, the setup page, {len(FEATURES)} feature pages + the '
          f'rest{" (DRAFT: no cards)" if draft else ""}; valid against {XSD.name}')


if __name__ == '__main__':
    main()
