Scriptname AN76Toilets:Sounds extends Quest
{The comedy layer over Advanced Needs 76's bathroom: its own sounds stay, and this adds the rumble
when the need hits, straining, farts, plops and a sigh of relief whenever the player goes -- on
AN76's toilets, on ours, or squatting in the wild. It watches AN76's state rather than hooking it:
AN76 puts its "busy" keyword on the player for the whole time, and pooping keeps it on for 23 s
where peeing takes 10. Honours AN76's "sounds" and "silent" switches.}

Sound Property Rumble Auto Const Mandatory
Sound Property StrainMale Auto Const Mandatory
Sound Property StrainFemale Auto Const Mandatory
Sound Property FartShort Auto Const Mandatory
Sound Property FartLong Auto Const Mandatory
Sound Property FartWet Auto Const Mandatory
Sound Property Plop Auto Const Mandatory
Sound Property Explosive Auto Const Mandatory
Sound Property ReliefMale Auto Const Mandatory
Sound Property ReliefFemale Auto Const Mandatory
Sound Property Paper Auto Const Mandatory

Float Property WatchSeconds = 3.0 Auto Const
{How often to look while nothing is happening.}
Float Property BusySeconds = 0.5 Auto Const
{How often to look while the player is going.}

Int Property WATCH_TIMER = 1 AutoReadOnly
Int Property AN76_TOILET_STACK = 0x03B8FF AutoReadOnly     ; GlobalVariable Flashy_NeedsToiletStack
Int Property AN76_BUSY = 0x03B904 AutoReadOnly             ; Keyword Flashy_Keyword_BusyPlayer
Int Property AN76_PAIN = 0x03B90C AutoReadOnly             ; MagicEffect Flashy_ME_BathroomPains
Int Property AN76_PLAY_SOUNDS = 0x03FD6A AutoReadOnly      ; GlobalVariable Flashy_Hygiene_PlaySounds
Int Property AN76_SILENT = 0x023D43 AutoReadOnly           ; GlobalVariable Flashy_NeedsHygieneSilentPoop
Int Property AN76_FOOD_ILL = 0x001F34 AutoReadOnly         ; MagicEffect Flashy_ME_FoodPoisonIllness
Int Property AN76_RAD_ILL = 0x001F32 AutoReadOnly          ; MagicEffect Flashy_ME_RadPoisonIllness

Bool _hadPain = False
Bool _going = False
Float _goingSince = 0.0
Bool _pooping = False
Int _step = 0

Event OnQuestInit()
	Begin()
EndEvent

Event Actor.OnPlayerLoadGame(Actor akSender)
	_going = False
	Begin()
EndEvent

Function Begin()
	RegisterForRemoteEvent(Game.GetPlayer(), "OnPlayerLoadGame")
	StartTimer(WatchSeconds, WATCH_TIMER)
EndFunction

Form Function AN76(Int aiFormID)
	Return Game.GetFormFromFile(aiFormID, "Flashy_PersonalEssentials.esp")
EndFunction

Bool Function SoundsOn()
	GlobalVariable sounds = AN76(AN76_PLAY_SOUNDS) as GlobalVariable
	GlobalVariable silent = AN76(AN76_SILENT) as GlobalVariable
	Return (!sounds || sounds.GetValueInt() == 1) && (!silent || silent.GetValueInt() == 0)
EndFunction

Event OnTimer(Int aiTimerID)
	If aiTimerID != WATCH_TIMER
		Return
	EndIf
	Actor player = Game.GetPlayer()
	Keyword busy = AN76(AN76_BUSY) as Keyword
	MagicEffect pain = AN76(AN76_PAIN) as MagicEffect
	If !busy
		StartTimer(WatchSeconds * 10.0, WATCH_TIMER)   ; AN76 not installed: look rarely
		Return
	EndIf

	Bool hasPain = pain && player.HasMagicEffect(pain)
	If hasPain && !_hadPain && SoundsOn()
		Rumble.Play(player)
	EndIf
	_hadPain = hasPain

	Bool isGoing = player.HasKeyword(busy)
	If isGoing && !_going
		_going = True
		_goingSince = Utility.GetCurrentRealTime()
		_pooping = False
		_step = 0
	EndIf
	If _going
		If isGoing
			Going(player)
		Else
			Finished(player)
			_going = False
		EndIf
	EndIf

	GlobalVariable stack = AN76(AN76_TOILET_STACK) as GlobalVariable
	If _going || (stack && stack.GetValueInt() == 1)
		StartTimer(BusySeconds, WATCH_TIMER)
	Else
		StartTimer(WatchSeconds, WATCH_TIMER)
	EndIf
EndEvent

Bool Function Male(Actor akPlayer)
	Return akPlayer.GetActorBase().GetSex() == 0
EndFunction

Bool Function Sick(Actor akPlayer)
	MagicEffect food = AN76(AN76_FOOD_ILL) as MagicEffect
	MagicEffect rads = AN76(AN76_RAD_ILL) as MagicEffect
	Return (food && akPlayer.HasMagicEffect(food)) || (rads && akPlayer.HasMagicEffect(rads))
EndFunction

; One beat at a time, keyed on seconds since the player started going.
Function Going(Actor akPlayer)
	If !SoundsOn()
		Return
	EndIf
	Float t = Utility.GetCurrentRealTime() - _goingSince
	If _step == 0 && t >= 3.5
		; A pee gets a fart half the time and nothing else; straining waits until it is a poop.
		Int roll = Utility.RandomInt(0, 3)
		If roll == 0
			FartShort.Play(akPlayer)
		ElseIf roll == 1
			FartLong.Play(akPlayer)
		EndIf
		_step = 2
	ElseIf _step == 2 && t >= 11.0
		; Still going past a pee's length: AN76 decided this one is a poop.
		_pooping = True
		If Sick(akPlayer)
			Explosive.Play(akPlayer)
		Else
			Strain(akPlayer)
		EndIf
		_step = 3
	ElseIf _step == 3 && t >= 14.0
		FartWet.Play(akPlayer)
		_step = 4
	ElseIf _step == 4 && t >= 16.5
		Plop.Play(akPlayer)
		_step = 5
	ElseIf _step == 5 && t >= 19.0
		If Utility.RandomInt(0, 2) == 0
			FartShort.Play(akPlayer)
		Else
			Plop.Play(akPlayer)
		EndIf
		_step = 6
	EndIf
EndFunction

Function Strain(Actor akPlayer)
	If Male(akPlayer)
		StrainMale.Play(akPlayer)
	Else
		StrainFemale.Play(akPlayer)
	EndIf
EndFunction

Function Finished(Actor akPlayer)
	If !SoundsOn()
		Return
	EndIf
	If Male(akPlayer)
		ReliefMale.Play(akPlayer)
	Else
		ReliefFemale.Play(akPlayer)
	EndIf
	If _pooping
		Utility.Wait(1.5)
		Paper.Play(akPlayer)
	EndIf
EndFunction
