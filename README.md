# AN76 Toilets

Fallout 4. An add-on for **Advanced Needs 76**'s Bathroom Needs: comedy bathroom sounds and voices, a toilet icon
on the HUD, accidents when you hold it too long, usable world toilets and urinals, and NPCs who use toilets too.

## What it does

- **Sounds and voices.** Straining, farts, plops, a sigh of relief and the toilet paper while you go; a stomach
  rumble when the need hits. Body sounds follow your sex (male and female sets). Voices are spoken lines with lip
  sync: scream, gag, puke, strain and relief in every vanilla human and ghoul voice type -- 8,110 voice files.
- **The toilet icon.** Joins the HUD's status-icon row (hunger, thirst, sleep, AN76), yellow when you need to go,
  orange after a while, red when it can no longer wait. Needs HUDFramework.
- **Holding it: accidents.** With accidents on (the default), holding it never hurts. The clock turns orange at 2
  game hours and red at 4, and then you go in your pants where you stand. Sleep and fast travel do not count;
  waiting does. Both hours are MCM sliders.
- **Panic.** Everyone within 25 m screams and cowers, then goes back to what they were doing (FO4 cannot make a calm
  NPC run, so they cower). An accident mid-conversation ends the conversation, and the one you were talking to
  panics too. Not your companion, and nobody fighting, hostile or in a quest scene.
- **The aftermath.** You stink (AN76's body odour, with its bathing on) until you wash: gnats where it happened,
  aftershock farts as you walk, people near you gag, pull a face or throw up.
- **Clothes put back on.** If AN76's "go naked" leaves something off after you are done, it is put back on.
- **World toilets and urinals.** The broken, vault and house toilets already in the world become seats you can use,
  and men can use urinals (15 vanilla models). AN76's own toilets always work.
- **NPCs use toilets too.** Anyone who sits down on a toilet in their own routine -- a settler on a world toilet, the
  Institute's toilets, Far Harbor's outhouses, AN76's built toilets -- undresses, goes, sighs and dresses again,
  with the sounds of their own sex. Children keep their clothes on. An MCM chance and a switch.
- **MCM** for every part, and a **Testing** page to try each one without waiting.

## Requirements

- **Advanced Needs 76** (Nexus 58440), with its Bathroom Needs on. Once per save, after you leave Vault 111, this
  add-on starts AN76, its needs system, Bathroom Needs and camping if they are not running; anything you turn off
  in AN76's MCM afterwards stays off.
- **HUDFramework** (Nexus 20309).
- **F4SE**: the clothes safety net and ending a conversation use it. Missing, the add-on says so in game.
- **MCM** (Nexus 21497) for the settings; without it they keep their defaults.

Fallout 4 1.10.163, next-gen 1.10.984 and the Anniversary Edition 1.11.x (pure Papyrus with F4SE script functions). Install with Vortex or Mod Organizer 2; the installer checks
the requirements. Manual installs are not supported.

## Known

- Underground Hideout's toilet activator covers its whole bathroom, so its toilet cannot be used through this
  add-on.

## Build

Python 3 with ffmpeg on PATH, the Creation Kit's Papyrus compiler, F4SE's script sources, FFDec for the icon,
LipGenerator and xwmaencode from the game's Tools folder, Archive2 for the BA2.

```
python tools/make_esp.py && python tools/make_sounds.py && python tools/make_mcm.py && python tools/make_voice.py && python tools/check_esp.py
powershell -File scripts/build-papyrus.ps1
pwsh scripts/make-release.ps1
```

## Licence

PolyForm Noncommercial 1.0.0, see `LICENSE`.
