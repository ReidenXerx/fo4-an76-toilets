Scriptname AN76Toilets:Accident extends Quest
{Held it too long: the accident, the aftermath and the panic.

Called by the sound watcher (AN76Toilets:Sounds) once the player has held AN76's need past the MCM limit.
The need is cleared through AN76's own QuickRemoveNeed, so its timers, cooldown and "busy" state stay its
own. The panic: everyone nearby who is not a companion, not hostile, not fighting and not in a scene or
talking to the player drops into vanilla's cower, screaming, held still by an alias package; then the
package is taken away, they stand up and go back to whatever they were doing. Nothing on them is changed
for good. (They do not run: FO4 cannot make a calm NPC flee without combat, measured 2026-09-29.)}

RefCollectionAlias Property Panicked Auto Const Mandatory
{The people cowering: vanilla HoldPosition keeps them where they are while the cower plays.}

Sound Property AccidentPoop Auto Const Mandatory
Sound Property AccidentPee Auto Const Mandatory
Topic[] Property ScreamMaleLines Auto Const Mandatory
Topic[] Property ScreamFemaleLines Auto Const Mandatory
Topic[] Property GagMaleLines Auto Const Mandatory
Topic[] Property GagFemaleLines Auto Const Mandatory
{Voices: spoken lines with lip sync, one topic per clip, in every vanilla human and ghoul voice type.
An NPC with a voice type from another mod shows the subtitle without the audio.}
Topic[] Property PukeMaleLines Auto Const Mandatory
Topic[] Property PukeFemaleLines Auto Const Mandatory
{Someone close throws up instead of just gagging, now and then.}
Sound Property FartShort Auto Const Mandatory
Sound Property FartWet Auto Const Mandatory
{Aftershocks while the soiled player walks. (Owner 2026-09-29: flies out; the squelch sounded like sex.)}
Sound Property AccidentPoopF Auto Const Mandatory
Sound Property AccidentPeeF Auto Const Mandatory
Sound Property FartShortF Auto Const Mandatory
Sound Property FartWetF Auto Const Mandatory
{The same for a female player (owner 2026-09-30: every body sound by sex).}
Int Property PukePercent = 30 Auto Const
{Chance that the one gagging near a soiled player throws up instead.}

GlobalVariable Property PanicOn Auto Const Mandatory
GlobalVariable Property PanicSeconds Auto Const Mandatory
GlobalVariable Property AftermathOn Auto Const Mandatory
GlobalVariable Property LeftoversOn Auto Const Mandatory
{MCM (2026-10-02): what an accident leaves on the floor, and the puke of whoever throws up.}
ImpactDataSet Property PeePuddle Auto Const Mandatory
{Our decal: a wet yellow stain stamped on whatever floor is under the player; the engine fades it.}

Float Property PanicRadius = 1750.0 Auto Const
{25 m.}
Int Property MaxPanicked = 24 Auto Const
Float Property GagRadius = 450.0 Auto Const
{About 6 m: close enough to smell you.}
Float Property StinkSeconds = 3.0 Auto Const
{The aftermath's tick: a squelch when the player has walked, a gag every GagTicks ticks.}
Int Property GagTicks = 5 AutoReadOnly

Int Property PANIC_TIMER = 1 AutoReadOnly
Int Property STINK_TIMER = 2 AutoReadOnly
Int Property FACE_TIMER = 3 AutoReadOnly
Int Property DEBUG_PANIC_TIMER = 10 AutoReadOnly
Int Property DEBUG_SOIL_TIMER = 11 AutoReadOnly
Int Property DEBUG_SCREAM_TIMER = 12 AutoReadOnly
Int Property DEBUG_PUKE_TIMER = 13 AutoReadOnly
Int Property DEBUG_STAIN_TIMER = 14 AutoReadOnly
Int Property DEBUG_PILE_TIMER = 15 AutoReadOnly
Int Property AN76_BATHING_POTION = 0x03303C AutoReadOnly ; Potion Flashy_Hygiene_BathingPotion

; Fallout4.esm
Int Property KW_HUMAN = 0x02CB72 AutoReadOnly           ; Keyword ActorTypeHuman
Int Property KW_GHOUL = 0x0EAFB7 AutoReadOnly           ; Keyword ActorTypeGhoul
Int Property IDLE_COWER = 0x22C668 AutoReadOnly        ; Idle cowerStart (RaiderRootBehavior: humans)
Int Property IDLE_STOP = 0x029380 AutoReadOnly         ; Idle LooseIdleStop
Int Property IDLE_RETCH = 0x0EA85C AutoReadOnly        ; Idle MTCoughing: bent over, heaving
Int Property FACE_AFRAID = 0x0FA84B AutoReadOnly        ; Keyword AnimFaceArchetypeAfraid
Int Property FACE_DISGUST = 0x0C8674 AutoReadOnly       ; Keyword AnimFaceArchetypeDisgust
Int Property FACE_IN_PAIN = 0x100286 AutoReadOnly       ; Keyword AnimFaceArchetypeInPain
Int Property COMPANION_FACTION = 0x023C01 AutoReadOnly  ; Faction CurrentCompanionFaction
; Flashy_PersonalEssentials.esp
Int Property AN76_BATHROOM_QUEST = 0x03B902 AutoReadOnly
Int Property AN76_TOILET_STACK = 0x03B8FF AutoReadOnly  ; GlobalVariable Flashy_NeedsToiletStack
Int Property AN76_PAIN_REMOVER = 0x03B907 AutoReadOnly  ; Potion Flashy_Hygiene_BathroomPainRemover
Int Property AN76_NEXT_PISS = 0x04E8FE AutoReadOnly     ; ActorValue Flashy_NextPiss (game days)
Int Property AN76_BATHING_ON = 0x033032 AutoReadOnly    ; GlobalVariable Flashy_NeedsHygieneBathing
Int Property AN76_NEXT_BATH = 0x033038 AutoReadOnly     ; ActorValue Flashy_Hygiene_NextBath (game days)
Int Property AN76_BODY_ODOUR = 0x03303D AutoReadOnly    ; Potion Flashy_Hygiene_BodyOdour
Int Property AN76_ODOUR_EFFECT = 0x03303A AutoReadOnly  ; MagicEffect Flashy_ME_BodyOdour
Int Property AN76_GNATS = 0x03FD6F AutoReadOnly         ; Activator Flashy_Acti_GnatSwarm (deletes itself)
Int Property AN76_POOP = 0x03FD6D AutoReadOnly          ; Activator Flashy_Acti_PoopBrown (deleted on unload)
Int Property AN76_POOP_SICK = 0x03FD6E AutoReadOnly     ; Activator Flashy_Acti_PoopGreen (deleted on unload)
Int Property AN76_VOMIT = 0x001EF7 AutoReadOnly         ; Activator Flashy_Vomit (deletes itself after 2 min)

Bool _sounds = True
Bool _soiled = False
Bool _odour = False
Float _soiledUntil = 0.0
Float _panicUntil = 0.0
Actor _gagger = None
Actor _talker = None     ; whoever the player was talking to when it happened: the conversation ends
Int _stinkTick = 0
Float _lastX = 0.0
Float _lastY = 0.0
Bool _panicLogged = False

Event OnQuestInit()
	RegisterForRemoteEvent(Game.GetPlayer(), "OnPlayerLoadGame")
EndEvent

Event Actor.OnPlayerLoadGame(Actor akSender)
	If !OnOwnRecord()
		Return
	EndIf
	; The panic clock is real time, which starts over with the game: end a panic a save caught instead of
	; leaving people running.
	If Panicked.GetCount() > 0
		EndPanic()
	EndIf
	If _soiled
		StartTimer(StinkSeconds, STINK_TIMER)
	EndIf
EndEvent

; Only ever run on our own quest (see AN76Toilets:Sounds.OnOwnRecord).
Bool Function OnOwnRecord()
	If Game.GetFormFromFile(0x000832, "AN76_Toilets.esp") == Self as Form
		Return True
	EndIf
	Debug.Trace("AN76 Toilets: a stray accident instance on " + Self + " - stopped", 0)
	UnregisterForAllEvents()
	Return False
EndFunction

Form Function AN76(Int aiFormID)
	Return Game.GetFormFromFile(aiFormID, "Flashy_PersonalEssentials.esp")
EndFunction

Form Function Vanilla(Int aiFormID)
	Return Game.GetFormFromFile(aiFormID, "Fallout4.esm")
EndFunction

; aiFace: a Fallout4.esm AnimFaceArchetype keyword, or 0 to give the face back to the game.
Function Face(Actor akActor, Int aiFace)
	If !akActor
		Return
	EndIf
	If aiFace == 0
		akActor.ChangeAnimFaceArchetype(None)
	Else
		akActor.ChangeAnimFaceArchetype(Vanilla(aiFace) as Keyword)
	EndIf
EndFunction

; The body's sound by the player's sex.
Sound Function Body(Actor akPlayer, Sound akMale, Sound akFemale)
	If akPlayer.GetActorBase().GetSex() == 1
		Return akFemale
	EndIf
	Return akMale
EndFunction

; ---- the accident --------------------------------------------------------------------------

; abPoop: which one it was. abSounds: the sound watcher's verdict on the MCM and AN76's sound switches.
; abSick: AN76's sick poop (the green pile).
Function Trigger(Bool abPoop, Bool abSounds, Bool abSick = False)
	If !OnOwnRecord()
		Return
	EndIf
	Actor player = Game.GetPlayer()
	_sounds = abSounds
	; Mid-conversation (a trader, anyone): the talk ends the moment it happens, as if the player had walked
	; off, and whoever it was panics with the rest. F4SE's UI closes the menus; walking away from a
	; conversation is something the game always allows, so no quest is left half-way.
	_talker = player.GetDialogueTarget()
	If _talker || UI.IsMenuOpen("DialogueMenu") || UI.IsMenuOpen("BarterMenu")
		UI.CloseMenu("BarterMenu")
		UI.CloseMenu("DialogueMenu")
		Debug.Trace("AN76 Toilets: accident mid-conversation with " + _talker + " - conversation ended", 0)
	EndIf
	Debug.Trace("AN76 Toilets: ACCIDENT - poop " + abPoop + ", panic " + PanicOn.GetValueInt() + ", aftermath " + AftermathOn.GetValueInt(), 0)
	InputEnableLayer layer = None
	If !player.IsInCombat()
		layer = InputEnableLayer.Create()
		layer.EnableMovement(False)
	EndIf
	Face(player, FACE_IN_PAIN)
	If abSounds
		If abPoop
			Body(player, AccidentPoop, AccidentPoopF).Play(player)
		Else
			Body(player, AccidentPee, AccidentPeeF).Play(player)
		EndIf
	EndIf
	If abPoop
		Debug.Notification("You couldn't hold it any longer. You've filled your pants.")
	Else
		Debug.Notification("You couldn't hold it any longer. You've wet yourself.")
	EndIf
	ClearNeed(player)
	If LeftoversOn.GetValueInt() == 1
		LeaveBehind(player, abPoop, abSick)
	EndIf
	Utility.Wait(1.0)
	If PanicOn.GetValueInt() == 1
		Panic(player)
	EndIf
	If AftermathOn.GetValueInt() == 1
		Soil(player)
	EndIf
	Utility.Wait(2.0)
	If layer
		layer.EnableMovement(True)
		layer.Delete()
	EndIf
	Face(player, FACE_DISGUST)
	StartTimer(8.0, FACE_TIMER)
	_talker = None
EndFunction

; AN76's QuickRemoveNeed: the need, its timers, the "busy" keyword and the 6-hour cooldown, all its own.
Function ClearNeed(Actor akPlayer)
	Quest main = AN76(AN76_BATHROOM_QUEST) as Quest
	If main && main.IsRunning()
		Var[] args = new Var[1]
		args[0] = False
		main.CastAs("FlashyEssentials:Flashy_BathroomScript").CallFunction("QuickRemoveNeed", args)
		Return
	EndIf
	; AN76's Xbox bathroom script has no QuickRemoveNeed: do what it does.
	GlobalVariable stack = AN76(AN76_TOILET_STACK) as GlobalVariable
	If stack
		stack.SetValueInt(0)
	EndIf
	Potion remover = AN76(AN76_PAIN_REMOVER) as Potion
	If remover
		akPlayer.EquipItem(remover, False, True)
	EndIf
	ActorValue nextPiss = AN76(AN76_NEXT_PISS) as ActorValue
	If nextPiss
		akPlayer.SetValue(nextPiss, Utility.GetCurrentGameTime() + 0.25)
	EndIf
EndFunction

; ---- the panic -----------------------------------------------------------------------------

Function Panic(Actor akPlayer)
	; An alias package only applies while its quest runs; a script runs either way, so check.
	If !IsRunning()
		Debug.Trace("AN76 Toilets: the accident quest was not running - starting it for the panic", 0)
		Start()
	EndIf
	Int added = PanicAmong(akPlayer.FindAllReferencesWithKeyword(Vanilla(KW_HUMAN), PanicRadius), akPlayer)
	added += PanicAmong(akPlayer.FindAllReferencesWithKeyword(Vanilla(KW_GHOUL), PanicRadius), akPlayer)
	Debug.Trace("AN76 Toilets: panic - " + added + " people run from the player for " + PanicSeconds.GetValue() + " s", 0)
	If Panicked.GetCount() > 0
		_panicUntil = Utility.GetCurrentRealTime() + PanicSeconds.GetValue()
		_panicLogged = False
		StartTimer(3.0, PANIC_TIMER)
	EndIf
EndFunction

Int Function PanicAmong(ObjectReference[] akRefs, Actor akPlayer)
	Int added = 0
	Int i = 0
	While i < akRefs.Length && Panicked.GetCount() < MaxPanicked
		Actor a = akRefs[i] as Actor
		If WillPanic(a, akPlayer)
			Panicked.AddRef(a)
			Face(a, FACE_AFRAID)
			a.EvaluatePackage(False)
			Debug.Trace("AN76 Toilets: " + a + " cowers " + a.PlayIdle(Vanilla(IDLE_COWER) as Idle), 0)
			If added < 6
				Scream(a)
				Utility.Wait(Utility.RandomFloat(0.05, 0.3))
			EndIf
			added += 1
		EndIf
		i += 1
	EndWhile
	Return added
EndFunction

; Companions stay, and so does anyone the game is using: fighting, hostile, in a scene, talking to the
; player. A scene's package outranks ours anyway; leaving them out keeps their faces too.
Bool Function WillPanic(Actor akActor, Actor akPlayer)
	If !akActor || akActor == akPlayer || akActor.IsDead() || akActor.IsDisabled()
		Return False
	EndIf
	If akActor.IsUnconscious() || akActor.IsBleedingOut() || akActor.IsInCombat() || akActor.IsHostileToActor(akPlayer)
		Return False
	EndIf
	; Asleep, sitting or lying on furniture, or in power armor: a cower from there freezes or T-poses them.
	; No 3D: nobody there to see it.
	If !akActor.Is3DLoaded() || akActor.GetSleepState() != 0 || akActor.GetSitState() != 0 || akActor.IsInPowerArmor()
		Return False
	EndIf
	If akActor.IsPlayerTeammate() || akActor.IsInFaction(Vanilla(COMPANION_FACTION) as Faction)
		Return False
	EndIf
	If Panicked.Find(akActor) >= 0
		Return False
	EndIf
	; The one the player was talking to: that conversation is over now. A scene still keeps anyone.
	If akActor.IsInScene() || (akActor != _talker && akActor.IsInDialogueWithPlayer())
		Return False
	EndIf
	Return True
EndFunction

Function Scream(Actor akActor)
	If !_sounds
		Return
	EndIf
	If akActor.GetLeveledActorBase().GetSex() == 1
		Speak(akActor, ScreamFemaleLines)
	Else
		Speak(akActor, ScreamMaleLines)
	EndIf
EndFunction

Function Speak(Actor akActor, Topic[] akLines)
	akActor.Say(akLines[Utility.RandomInt(0, akLines.Length - 1)], None, False, None)
EndFunction

; Three seconds in: what each panicked NPC is actually running, and how far from the player.
Function LogPanic()
	Actor player = Game.GetPlayer()
	Int i = 0
	While i < Panicked.GetCount()
		Actor a = Panicked.GetAt(i) as Actor
		If a
			Debug.Trace("AN76 Toilets: panic 3 s in - " + a + " package " + a.GetCurrentPackage() + ", in combat " + a.IsInCombat() + ", " + (a.GetDistance(player) as Int) + " from the player", 0)
		EndIf
		i += 1
	EndWhile
EndFunction

Function EndPanic()
	Actor[] calm = new Actor[0]
	Int i = 0
	While i < Panicked.GetCount()
		Actor a = Panicked.GetAt(i) as Actor
		If a
			calm.Add(a)
		EndIf
		i += 1
	EndWhile
	Panicked.RemoveAll()
	i = 0
	While i < calm.Length
		calm[i].PlayIdle(Vanilla(IDLE_STOP) as Idle)
		Face(calm[i], 0)
		calm[i].EvaluatePackage(False)
		i += 1
	EndWhile
	Debug.Trace("AN76 Toilets: panic over - " + calm.Length + " people go back to what they were doing", 0)
EndFunction

; ---- the aftermath -------------------------------------------------------------------------

Function Soil(Actor akPlayer)
	GlobalVariable bathing = AN76(AN76_BATHING_ON) as GlobalVariable
	Potion odour = AN76(AN76_BODY_ODOUR) as Potion
	ActorValue nextBath = AN76(AN76_NEXT_BATH) as ActorValue
	_odour = False
	If bathing && bathing.GetValueInt() == 1 && odour && nextBath
		; AN76's own body odour: it stays until a bath or a swim, and AN76 cleans it the way it always does.
		akPlayer.SetValue(nextBath, Utility.GetCurrentGameTime())
		akPlayer.EquipItem(odour, False, True)
		_odour = True
	EndIf
	; Without AN76's bathing there is nothing to wash it off with: it wears off in 6 game hours.
	_soiledUntil = Utility.GetCurrentGameTime() + 0.25
	Form gnats = AN76(AN76_GNATS)
	If gnats
		akPlayer.PlaceAtMe(gnats, 1, False, False, True)
	EndIf
	_soiled = True
	StartTimer(StinkSeconds, STINK_TIMER)
	Debug.Trace("AN76 Toilets: soiled - AN76 body odour " + _odour + ", gnats " + (gnats != None), 0)
EndFunction

; What the accident leaves where it happened (owner 2026-10-02): a poop, AN76's own pile -- the green one
; when AN76 says you are sick, placed the way AN76 places it after going outdoors; it deletes itself
; when the area unloads. A pee: our wet stain, a decal on the floor under you that the engine fades.
Function LeaveBehind(Actor akPlayer, Bool abPoop, Bool abSick)
	If abPoop
		Int pile = AN76_POOP
		If abSick
			pile = AN76_POOP_SICK
		EndIf
		Form f = AN76(pile)
		If f
			akPlayer.PlaceAtMe(f, 1, False, False, True)
		EndIf
		Debug.Trace("AN76 Toilets: left AN76's pile (sick " + abSick + ", found " + (f != None) + ")", 0)
	Else
		; From the pelvis straight down, so the stain lands on whatever floor is under you.
		Bool stamped = akPlayer.PlayImpactEffect(PeePuddle, "Pelvis", 0.0, 0.0, -1.0, 200.0, False, False)
		Debug.Trace("AN76 Toilets: left a wet stain - " + stamped, 0)
	EndIf
EndFunction

; AN76's pile of puke on the floor just in front of whoever threw up; it deletes itself after 2 minutes.
Function PukePile(Actor akActor)
	Form vomit = AN76(AN76_VOMIT)
	If !vomit
		Return
	EndIf
	ObjectReference pile = akActor.PlaceAtMe(vomit, 1, False, False, True)
	If pile
		Float a = akActor.GetAngleZ()
		pile.MoveTo(akActor, 35.0 * Math.Sin(a), 35.0 * Math.Cos(a), 0.0, False)
	EndIf
EndFunction

Bool Function StillSoiled(Actor akPlayer)
	If _odour
		MagicEffect odour = AN76(AN76_ODOUR_EFFECT) as MagicEffect
		Return odour && akPlayer.HasMagicEffect(odour)
	EndIf
	Return Utility.GetCurrentGameTime() < _soiledUntil
EndFunction

; Every few seconds while soiled: squelching when the player has walked, and now and then someone close
; by gags and pulls a face.
Function Stink()
	Actor player = Game.GetPlayer()
	_stinkTick += 1
	If _stinkTick % GagTicks == 2
		UnGag()
	EndIf
	If !_soiled
		UnGag()
		Return
	EndIf
	If !StillSoiled(player)
		_soiled = False
		UnGag()
		Debug.Notification("You're clean again.")
		Debug.Trace("AN76 Toilets: clean again", 0)
		Return
	EndIf
	If AftermathOn.GetValueInt() == 1
		Float moved = Math.Sqrt(Math.Pow(player.GetPositionX() - _lastX, 2.0) + Math.Pow(player.GetPositionY() - _lastY, 2.0))
		_lastX = player.GetPositionX()
		_lastY = player.GetPositionY()
		If _sounds && moved > 120.0 && moved < 3000.0 && Utility.RandomInt(0, 2) == 0
			If Utility.RandomInt(0, 1) == 0
				Body(player, FartShort, FartShortF).Play(player)
			Else
				Body(player, FartWet, FartWetF).Play(player)
			EndIf
		EndIf
		Actor near = None
		If _stinkTick % GagTicks == 0
			near = SomeoneNear(player)
		EndIf
		If near
			If Utility.RandomInt(1, 100) <= PukePercent
				Puke(near, True)
			Else
				Face(near, FACE_DISGUST)
				If _sounds
					If near.GetLeveledActorBase().GetSex() == 1
						Speak(near, GagFemaleLines)
					Else
						Speak(near, GagMaleLines)
					EndIf
				EndIf
			EndIf
			_gagger = near
		EndIf
	EndIf
	StartTimer(StinkSeconds, STINK_TIMER)
EndFunction

; The last one who gagged gets their face back.
Function UnGag()
	If _gagger
		Face(_gagger, 0)
		_gagger = None
	EndIf
EndFunction

; Throws up: the disgust face, the heave (bent over, unless they are cowering), the sound.
Function Puke(Actor akActor, Bool abBendOver)
	Face(akActor, FACE_DISGUST)
	If abBendOver
		akActor.PlayIdle(Vanilla(IDLE_RETCH) as Idle)
	EndIf
	If _sounds
		If akActor.GetLeveledActorBase().GetSex() == 1
			Speak(akActor, PukeFemaleLines)
		Else
			Speak(akActor, PukeMaleLines)
		EndIf
	EndIf
	If LeftoversOn.GetValueInt() == 1
		PukePile(akActor)
	EndIf
	Debug.Trace("AN76 Toilets: " + akActor + " throws up", 0)
EndFunction

; Companions included: they are the ones standing next to you.
Actor Function SomeoneNear(Actor akPlayer)
	ObjectReference[] refs = akPlayer.FindAllReferencesWithKeyword(Vanilla(KW_HUMAN), GagRadius)
	If refs.Length == 0
		Return None
	EndIf
	Int start = Utility.RandomInt(0, refs.Length - 1)
	Int i = 0
	While i < refs.Length
		Actor a = refs[(start + i) % refs.Length] as Actor
		If a && a != akPlayer && a.Is3DLoaded() && !a.IsDead() && !a.IsDisabled() && !a.IsUnconscious() && !a.IsBleedingOut() && a.GetSleepState() == 0 && !a.IsInCombat() && !a.IsHostileToActor(akPlayer) && !a.IsInScene() && Panicked.Find(a) < 0
			Return a
		EndIf
		i += 1
	EndWhile
	Return None
EndFunction

Event OnTimer(Int aiTimerID)
	If !OnOwnRecord()
		Return
	EndIf
	If aiTimerID == PANIC_TIMER
		If Panicked.GetCount() == 0
			Return
		EndIf
		Float left = _panicUntil - Utility.GetCurrentRealTime()
		If left <= 0.0
			EndPanic()
			Return
		EndIf
		If !_panicLogged
			_panicLogged = True
			LogPanic()
		EndIf
		; Shot at or killed mid-panic: let go of them so the fight (or the body) is the game's again.
		Int i = Panicked.GetCount() - 1
		While i >= 0
			Actor p = Panicked.GetAt(i) as Actor
			If p && (p.IsDead() || p.IsInCombat())
				Panicked.RemoveRef(p)
				Face(p, 0)
				p.EvaluatePackage(False)
			EndIf
			i -= 1
		EndWhile
		If Panicked.GetCount() == 0
			Return
		EndIf
		; Someone screams again, now and then.
		If Utility.RandomInt(0, 1) == 0
			Actor a = Panicked.GetAt(Utility.RandomInt(0, Panicked.GetCount() - 1)) as Actor
			If a && a.Is3DLoaded() && !a.IsDead()
				; Close enough to smell it: sometimes they throw up instead.
				If a.GetDistance(Game.GetPlayer()) < 700.0 && Utility.RandomInt(0, 3) == 0
					Puke(a, False)
					Face(a, FACE_AFRAID)
				Else
					Scream(a)
				EndIf
			EndIf
		EndIf
		Float nextIn = 2.0
		If nextIn > left
			nextIn = left
		EndIf
		StartTimer(nextIn, PANIC_TIMER)
	ElseIf aiTimerID == STINK_TIMER
		Stink()
	ElseIf aiTimerID == FACE_TIMER
		Face(Game.GetPlayer(), 0)
	ElseIf aiTimerID == DEBUG_PANIC_TIMER
		_sounds = True
		Panic(Game.GetPlayer())
	ElseIf aiTimerID == DEBUG_SOIL_TIMER
		_sounds = True
		Soil(Game.GetPlayer())
	ElseIf aiTimerID == DEBUG_PUKE_TIMER
		Actor near = SomeoneNear(Game.GetPlayer())
		If near
			_sounds = True
			Puke(near, True)
			Utility.Wait(4.0)
			Face(near, 0)
		Else
			Debug.Notification("AN76 Toilets debug: nobody within 6 m.")
		EndIf
	ElseIf aiTimerID == DEBUG_STAIN_TIMER
		LeaveBehind(Game.GetPlayer(), False, False)
	ElseIf aiTimerID == DEBUG_PILE_TIMER
		LeaveBehind(Game.GetPlayer(), True, Utility.RandomInt(0, 1) == 0)
	ElseIf aiTimerID == DEBUG_SCREAM_TIMER
		Actor near = SomeoneNear(Game.GetPlayer())
		If near
			_sounds = True
			Face(near, FACE_AFRAID)
			Scream(near)
			Utility.Wait(3.0)
			Face(near, 0)
		Else
			Debug.Notification("AN76 Toilets debug: nobody within 6 m.")
		EndIf
	EndIf
EndEvent

; ---- debug: the MCM's Debug page (timers run once the menu is closed) ---------------------------

Function DebugPanic()
	StartTimer(0.5, DEBUG_PANIC_TIMER)
	Debug.Notification("AN76 Toilets debug: panic when you close the menu.")
EndFunction

Function DebugCalm()
	EndPanic()
	Debug.Notification("AN76 Toilets debug: everyone calmed down.")
EndFunction

Function DebugSoil()
	StartTimer(0.5, DEBUG_SOIL_TIMER)
	Debug.Notification("AN76 Toilets debug: soiled when you close the menu.")
EndFunction

; Washes the player the way AN76's bath does, so AN76's own body odour goes too.
Function DebugClean()
	If _odour
		Potion bath = AN76(AN76_BATHING_POTION) as Potion
		If bath
			Game.GetPlayer().EquipItem(bath, False, True)
		EndIf
	EndIf
	_soiledUntil = 0.0
	_odour = False
	_soiled = False
	UnGag()
	Debug.Notification("AN76 Toilets debug: clean.")
EndFunction

Function DebugStain()
	StartTimer(0.5, DEBUG_STAIN_TIMER)
	Debug.Notification("AN76 Toilets debug: a wet stain under you when you close the menu.")
EndFunction

Function DebugPile()
	StartTimer(0.5, DEBUG_PILE_TIMER)
	Debug.Notification("AN76 Toilets debug: AN76's pile at your feet when you close the menu.")
EndFunction

Function DebugPuke()
	StartTimer(0.5, DEBUG_PUKE_TIMER)
	Debug.Notification("AN76 Toilets debug: the nearest person throws up when you close the menu.")
EndFunction

Function DebugScream()
	StartTimer(0.5, DEBUG_SCREAM_TIMER)
	Debug.Notification("AN76 Toilets debug: the nearest person screams when you close the menu.")
EndFunction

String Function DebugLine()
	String line = "Panicking: " + Panicked.GetCount()
	If Panicked.GetCount() > 0
		line += " (" + ((_panicUntil - Utility.GetCurrentRealTime()) as Int) + " s left)"
	EndIf
	line += "\nSoiled: " + _soiled + ", AN76 body odour " + _odour
	Return line
EndFunction
