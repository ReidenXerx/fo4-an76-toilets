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
Sound Property Squelch Auto Const Mandatory
{Soggy pants, while the player walks. (Owner, 2026-09-29: the flies went.)}

GlobalVariable Property PanicOn Auto Const Mandatory
GlobalVariable Property PanicSeconds Auto Const Mandatory
GlobalVariable Property AftermathOn Auto Const Mandatory

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
Int Property AN76_BATHING_POTION = 0x03303C AutoReadOnly ; Potion Flashy_Hygiene_BathingPotion

; Fallout4.esm
Int Property KW_HUMAN = 0x02CB72 AutoReadOnly           ; Keyword ActorTypeHuman
Int Property KW_GHOUL = 0x0EAFB7 AutoReadOnly           ; Keyword ActorTypeGhoul
Int Property IDLE_COWER = 0x22C668 AutoReadOnly        ; Idle cowerStart (RaiderRootBehavior: humans)
Int Property IDLE_STOP = 0x029380 AutoReadOnly         ; Idle LooseIdleStop
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

Bool _sounds = True
Bool _soiled = False
Bool _odour = False
Float _soiledUntil = 0.0
Float _panicUntil = 0.0
Actor _gagger = None
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

; ---- the accident --------------------------------------------------------------------------

; abPoop: which one it was. abSounds: the sound watcher's verdict on the MCM and AN76's sound switches.
Function Trigger(Bool abPoop, Bool abSounds)
	If !OnOwnRecord()
		Return
	EndIf
	Actor player = Game.GetPlayer()
	_sounds = abSounds
	Debug.Trace("AN76 Toilets: ACCIDENT - poop " + abPoop + ", panic " + PanicOn.GetValueInt() + ", aftermath " + AftermathOn.GetValueInt(), 0)
	InputEnableLayer layer = None
	If !player.IsInCombat()
		layer = InputEnableLayer.Create()
		layer.EnableMovement(False)
	EndIf
	Face(player, FACE_IN_PAIN)
	If abSounds
		If abPoop
			AccidentPoop.Play(player)
		Else
			AccidentPee.Play(player)
		EndIf
	EndIf
	If abPoop
		Debug.Notification("You couldn't hold it any longer. You've filled your pants.")
	Else
		Debug.Notification("You couldn't hold it any longer. You've wet yourself.")
	EndIf
	ClearNeed(player)
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
	If akActor.IsPlayerTeammate() || akActor.IsInFaction(Vanilla(COMPANION_FACTION) as Faction)
		Return False
	EndIf
	If akActor.IsInScene() || akActor.IsInDialogueWithPlayer() || Panicked.Find(akActor) >= 0
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
	If _gagger && _stinkTick % GagTicks == 2
		Face(_gagger, 0)
		_gagger = None
	EndIf
	If !_soiled
		Return
	EndIf
	If !StillSoiled(player)
		_soiled = False
		Debug.Notification("You're clean again.")
		Debug.Trace("AN76 Toilets: clean again", 0)
		Return
	EndIf
	If AftermathOn.GetValueInt() == 1
		Float moved = Math.Sqrt(Math.Pow(player.GetPositionX() - _lastX, 2.0) + Math.Pow(player.GetPositionY() - _lastY, 2.0))
		_lastX = player.GetPositionX()
		_lastY = player.GetPositionY()
		If _sounds && moved > 120.0 && moved < 3000.0
			Squelch.Play(player)
		EndIf
		Actor near = None
		If _stinkTick % GagTicks == 0
			near = SomeoneNear(player)
		EndIf
		If near
			Face(near, FACE_DISGUST)
			If _sounds
				If near.GetLeveledActorBase().GetSex() == 1
					Speak(near, GagFemaleLines)
				Else
					Speak(near, GagMaleLines)
				EndIf
			EndIf
			_gagger = near
		EndIf
	EndIf
	StartTimer(StinkSeconds, STINK_TIMER)
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
		If a && a != akPlayer && !a.IsDead() && !a.IsDisabled() && !a.IsInCombat() && !a.IsHostileToActor(akPlayer) && !a.IsInScene() && Panicked.Find(a) < 0
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
		; Someone screams again, now and then.
		If Utility.RandomInt(0, 1) == 0
			Actor a = Panicked.GetAt(Utility.RandomInt(0, Panicked.GetCount() - 1)) as Actor
			If a && a.Is3DLoaded() && !a.IsDead()
				Scream(a)
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
	Debug.Notification("AN76 Toilets debug: clean.")
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
