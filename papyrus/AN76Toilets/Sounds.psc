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

String Property WidgetSWF = "AN76Toilets.swf" Auto Const
{The toilet icon, a HUDFramework widget in Interface\.}
Float Property WidgetX = 1120.0 Auto Const
Float Property WidgetY = 560.0 Auto Const
{On the 1280x720 HUD, beside the status icons.}
Int Property WIDGET_SET_STAGE = 1 AutoReadOnly
Int Property AN76_PAIN_INTERVAL = 0x030A43 AutoReadOnly    ; GlobalVariable Flashy_Needs_ToiletPainTimer (s)

GlobalVariable Property IconOn Auto Const Mandatory
GlobalVariable Property IconX Auto Const Mandatory
GlobalVariable Property IconY Auto Const Mandatory
GlobalVariable Property IconScale Auto Const Mandatory
GlobalVariable Property IconNudgeX Auto Const Mandatory
GlobalVariable Property IconNudgeY Auto Const Mandatory
Int Property WIDGET_SET_NUDGE = 2 AutoReadOnly
GlobalVariable Property SoundsSetting Auto Const Mandatory
{MCM: the comedy sounds on or off.}

AN76Toilets:Accident Property Accident Auto Const Mandatory
{The accident, the aftermath and the panic.}
GlobalVariable Property AccidentsOn Auto Const Mandatory
{MCM: holding it never hurts but ends in an accident (on), or AN76's own pain and damage (off).}
GlobalVariable Property OrangeHours Auto Const Mandatory
GlobalVariable Property AccidentHours Auto Const Mandatory
{MCM: game hours of holding it, sleep left out.}

Float Property WatchSeconds = 3.0 Auto Const
{How often to look while nothing is happening.}
Float Property BusySeconds = 0.5 Auto Const
{How often to look while the player is going.}

Int Property WATCH_TIMER = 1 AutoReadOnly
Int Property AN76_TOILET_STACK = 0x03B8FF AutoReadOnly     ; GlobalVariable Flashy_NeedsToiletStack
Int Property AN76_NEXT_PISS = 0x04E8FE AutoReadOnly        ; ActorValue Flashy_NextPiss (game days)
Int Property AN76_BUSY = 0x03B904 AutoReadOnly             ; Keyword Flashy_Keyword_BusyPlayer
Int Property AN76_PAIN = 0x03B90C AutoReadOnly             ; MagicEffect Flashy_ME_BathroomPains
Int Property AN76_PLAY_SOUNDS = 0x03FD6A AutoReadOnly      ; GlobalVariable Flashy_Hygiene_PlaySounds
Int Property AN76_SILENT = 0x023D43 AutoReadOnly           ; GlobalVariable Flashy_NeedsHygieneSilentPoop
Int Property AN76_FOOD_ILL = 0x001F34 AutoReadOnly         ; MagicEffect Flashy_ME_FoodPoisonIllness
Int Property AN76_RAD_ILL = 0x001F32 AutoReadOnly          ; MagicEffect Flashy_ME_RadPoisonIllness
Int Property AN76_PAIN_POTION = 0x03B906 AutoReadOnly      ; Potion Flashy_Hygiene_BathroomPain
Int Property AN76_PAIN_REMOVER = 0x03B907 AutoReadOnly     ; Potion Flashy_Hygiene_BathroomPainRemover

Bool _hadPain = False
Int _lastStack = -1
Float _painSince = 0.0
Int _stage = -1
Int _wantedStage = 0
Float _appliedX = -1.0
Float _appliedY = -1.0
Float _appliedScale = -1.0
Float _appliedNudgeX = -9999.0
Float _appliedNudgeY = -9999.0
Bool _going = False
Float _goingSince = 0.0
Bool _pooping = False
Int _step = 0
Bool _urgent = False        ; AN76's need has hit (its pain fired) and has not been relieved
Bool _painTaken = False     ; we took AN76's pain away (accidents on)
Float _heldHours = 0.0      ; game hours held, sleep left out
Float _lastTick = 0.0       ; game days
Bool _sleeping = False

Event OnQuestInit()
	Begin()
EndEvent

Event Actor.OnPlayerLoadGame(Actor akSender)
	If !OnOwnRecord()
		Return
	EndIf
	_going = False
	Begin()
	Status()
EndEvent

; One line on every load: what AN76 and HUDFramework look like from here.
Function Status()
	GlobalVariable stack = AN76(AN76_TOILET_STACK) as GlobalVariable
	MagicEffect pain = AN76(AN76_PAIN) as MagicEffect
	HUDFramework hud = HUD()
	String need = "no AN76"
	If stack
		need = "need " + stack.GetValueInt()
	EndIf
	String icon = "no HUDFramework"
	If hud
		icon = "icon registered " + hud.IsWidgetRegistered(WidgetSWF) + ", loaded " + hud.IsWidgetLoaded(WidgetSWF)
	EndIf
	Debug.Trace("AN76 Toilets: loaded - " + need + ", pain " + (pain && Game.GetPlayer().HasMagicEffect(pain)) + ", holding " + _urgent + " (" + _heldHours + " game hours), " + icon + ", icon stage " + _stage + ", " + Cooldown(), 0)
EndFunction

Function Begin()
	RegisterForRemoteEvent(Game.GetPlayer(), "OnPlayerLoadGame")
	RegisterForPlayerSleep()
	SetupWidget()
	StartTimer(WatchSeconds, WATCH_TIMER)
EndFunction

; ---- the HUD icon --------------------------------------------------------------------------

HUDFramework Function HUD()
	If Game.IsPluginInstalled("HUDFramework.esm") || Game.IsPluginInstalled("HUDFramework.esp")
		Return HUDFramework.GetInstance()
	EndIf
	Return None
EndFunction

Function SetupWidget()
	_stage = -1
	HUDFramework hud = HUD()
	If hud && !hud.IsWidgetRegistered(WidgetSWF)
		hud.RegisterWidget(Self, WidgetSWF, IconX.GetValue(), IconY.GetValue(), True, True)
		Debug.Trace("AN76 Toilets: toilet icon registered with HUDFramework", 0)
	EndIf
EndFunction

; HUDFramework calls this by name whenever the widget (re)loads.
Function HUD_WidgetLoaded(String asWidgetID)
	Debug.Trace("AN76 Toilets: HUDFramework loaded widget " + asWidgetID, 0)
	_appliedX = -1.0
	If asWidgetID == WidgetSWF
		Int stage = _stage
		_stage = -1
		ShowStage(stage)
	EndIf
EndFunction

; MCM layout, applied when it changes. The icon joins the HUD's status-effect row by itself (the
; widget reads the row every frame); the nudge and size are relative to that slot. X and Y are only the
; fallback for a HUD with no such row.
Function ApplyLayout()
	Float x = IconX.GetValue()
	Float y = IconY.GetValue()
	Float s = IconScale.GetValue()
	Float nx = IconNudgeX.GetValue()
	Float ny = IconNudgeY.GetValue()
	If x == _appliedX && y == _appliedY && s == _appliedScale && nx == _appliedNudgeX && ny == _appliedNudgeY
		Return
	EndIf
	HUDFramework hud = HUD()
	If hud && hud.IsWidgetRegistered(WidgetSWF)
		hud.SetWidgetPosition(WidgetSWF, x, y, False)
		hud.SetWidgetScale(WidgetSWF, 1.0, 1.0, False)
		hud.SendMessage(WidgetSWF, WIDGET_SET_NUDGE, nx, ny, s, 0.0, 0.0, 0.0)
		Debug.Trace("AN76 Toilets: icon nudge " + nx + ", " + ny + " size x" + s + " (fallback position " + x + ", " + y + ")", 0)
		_appliedX = x
		_appliedY = y
		_appliedScale = s
		_appliedNudgeX = nx
		_appliedNudgeY = ny
	EndIf
EndFunction

; 0 hidden, 1 yellow (you need to go), 2 orange (a pain interval has passed), 3 red (three have).
Function ShowStage(Int aiStage)
	If aiStage < 0
		aiStage = 0
	EndIf
	_wantedStage = aiStage
	If IconOn.GetValueInt() == 0
		aiStage = 0
	EndIf
	If aiStage == _stage
		Return
	EndIf
	HUDFramework hud = HUD()
	If hud
		hud.SendMessage(WidgetSWF, WIDGET_SET_STAGE, aiStage as Float, 0.0, 0.0, 0.0, 0.0, 0.0)
	EndIf
	Debug.Trace("AN76 Toilets: icon stage " + _stage + " -> " + aiStage, 0)
	_stage = aiStage
EndFunction

Int Function Urgency(Bool abPain)
	If AccidentsOn.GetValueInt() == 1
		If !_urgent
			Return 0
		ElseIf _heldHours < OrangeHours.GetValue()
			Return 1
		ElseIf _heldHours < AccidentHours.GetValue()
			Return 2
		EndIf
		Return 3
	EndIf
	If !abPain
		Return 0
	EndIf
	Float interval = 120.0
	GlobalVariable painInterval = AN76(AN76_PAIN_INTERVAL) as GlobalVariable
	If painInterval && painInterval.GetValue() > 0.0
		interval = painInterval.GetValue()
	EndIf
	Float held = Utility.GetCurrentRealTime() - _painSince
	If held < interval
		Return 1
	ElseIf held < interval * 3.0
		Return 2
	EndIf
	Return 3
EndFunction

Form Function AN76(Int aiFormID)
	Return Game.GetFormFromFile(aiFormID, "Flashy_PersonalEssentials.esp")
EndFunction

Bool Function SoundsOn()
	GlobalVariable sounds = AN76(AN76_PLAY_SOUNDS) as GlobalVariable
	GlobalVariable silent = AN76(AN76_SILENT) as GlobalVariable
	Return SoundsSetting.GetValueInt() == 1 && (!sounds || sounds.GetValueInt() == 1) && (!silent || silent.GetValueInt() == 0)
EndFunction

; Only ever run on our own quest. A save made while a build had renumbered the plugin can hold an
; instance of this script on some other record (2026-09-29: on an MCM global); such an instance says so
; once and stops for good instead of running with its properties empty.
Bool Function OnOwnRecord()
	If Game.GetFormFromFile(0x00081A, "AN76_Toilets.esp") == Self as Form
		Return True
	EndIf
	Debug.Trace("AN76 Toilets: a stray sounds instance on " + Self + " - stopped", 0)
	UnregisterForAllEvents()
	Return False
EndFunction

Event OnTimer(Int aiTimerID)
	If !OnOwnRecord()
		Return
	EndIf
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

	GlobalVariable stack = AN76(AN76_TOILET_STACK) as GlobalVariable
	Bool hasPain = pain && player.HasMagicEffect(pain)
	If hasPain && !_hadPain
		Debug.Trace("AN76 Toilets: AN76's bathroom pain started - you need to go", 0)
		_painSince = Utility.GetCurrentRealTime()
		If SoundsOn()
			Rumble.Play(player)
		EndIf
		If !_urgent
			_urgent = True
			_heldHours = 0.0
			_lastTick = Utility.GetCurrentGameTime()
		EndIf
	EndIf
	_hadPain = hasPain
	If _urgent && (!stack || stack.GetValueInt() == 0)
		Debug.Trace("AN76 Toilets: relieved after holding it " + _heldHours + " game hours", 0)
		_urgent = False
		_painTaken = False
		_heldHours = 0.0
	EndIf
	If _urgent
		Hold()
		If AccidentsOn.GetValueInt() == 1
			If hasPain
				TakePainAway(player)
			EndIf
		ElseIf _painTaken && !hasPain
			GivePainBack(player)
		EndIf
	EndIf
	ApplyLayout()

	Bool isGoing = player.HasKeyword(busy)
	Int stage = Urgency(hasPain)
	If stage >= 3 && AccidentsOn.GetValueInt() == 1 && !isGoing && !_going && !player.IsInScene()
		ShowStage(3)
		HadAccident(player)
		stage = 0
	EndIf
	ShowStage(stage)

	If isGoing && !_going
		Debug.Trace("AN76 Toilets: going (sounds " + SoundsOn() + ", sick " + Sick(player) + ")", 0)
		_going = True
		_goingSince = Utility.GetCurrentRealTime()
		_pooping = False
		_step = 0
	EndIf
	If _going
		If isGoing
			Going(player)
		Else
			Debug.Trace("AN76 Toilets: finished after " + ((Utility.GetCurrentRealTime() - _goingSince) as Int) + " s, poop " + _pooping, 0)
			Finished(player)
			_going = False
		EndIf
	EndIf

	If stack && stack.GetValueInt() != _lastStack
		If stack.GetValueInt() == 1
			Debug.Trace("AN76 Toilets: AN76 took a meal - need pending, its 1-3 game hour timer is running", 0)
		ElseIf _lastStack == 1
			Debug.Trace("AN76 Toilets: AN76's need cleared (" + Cooldown() + ")", 0)
		EndIf
		_lastStack = stack.GetValueInt()
	EndIf
	If _going || (stack && stack.GetValueInt() == 1)
		StartTimer(BusySeconds, WATCH_TIMER)
	Else
		StartTimer(WatchSeconds, WATCH_TIMER)
	EndIf
EndEvent

; ---- holding it ----------------------------------------------------------------------------

; Game hours the player has been holding it, sleep left out: the clock stops at bedtime and runs again
; on waking (owner, 2026-09-29: a 12-hour sleep must not end in an accident). Waiting and fast travel count.
Function Hold()
	Float now = Utility.GetCurrentGameTime()
	If !_sleeping && _lastTick > 0.0 && now > _lastTick
		_heldHours += (now - _lastTick) * 24.0
	EndIf
	_lastTick = now
EndFunction

Event OnPlayerSleepStart(Float afSleepStartTime, Float afDesiredSleepEndTime, ObjectReference akBed)
	If _urgent
		Hold()
		Debug.Trace("AN76 Toilets: asleep - the hold clock stops at " + _heldHours + " game hours", 0)
	EndIf
	_sleeping = True
EndEvent

Event OnPlayerSleepStop(Bool abInterrupted, ObjectReference akBed)
	_sleeping = False
	_lastTick = Utility.GetCurrentGameTime()
	If _urgent
		Debug.Trace("AN76 Toilets: awake - the hold clock runs again from " + _heldHours + " game hours", 0)
	EndIf
EndEvent

; AN76's pain is a spell that hurts every interval. With accidents on, holding it never hurts, it only gets
; more urgent; the need itself stays, so AN76 still wants a toilet and its message still shows.
Function TakePainAway(Actor akPlayer)
	Potion remover = AN76(AN76_PAIN_REMOVER) as Potion
	If remover
		akPlayer.EquipItem(remover, False, True)
		_painTaken = True
		Debug.Trace("AN76 Toilets: AN76's pain taken away - holding it (" + _heldHours + " of " + AccidentHours.GetValue() + " game hours)", 0)
	EndIf
EndFunction

; Accidents switched off while holding it: AN76's pain comes back, as if it had never been taken.
Function GivePainBack(Actor akPlayer)
	Potion painPotion = AN76(AN76_PAIN_POTION) as Potion
	If painPotion
		akPlayer.EquipItem(painPotion, False, True)
		Debug.Trace("AN76 Toilets: accidents off - AN76's pain is back", 0)
	EndIf
	_painTaken = False
EndFunction

Function HadAccident(Actor akPlayer)
	Bool poop = Sick(akPlayer) || Utility.RandomInt(0, 1) == 0
	Debug.Trace("AN76 Toilets: held it " + _heldHours + " game hours, the limit is " + AccidentHours.GetValue() + " - accident", 0)
	_urgent = False
	_painTaken = False
	_heldHours = 0.0
	Accident.Trigger(poop, SoundsOn())
EndFunction

; AN76 ignores anything eaten before NextPiss (game days): 6 game hours after the last visit, or
; after its Bathroom Needs started.
String Function Cooldown()
	ActorValue nextPiss = AN76(AN76_NEXT_PISS) as ActorValue
	If !nextPiss
		Return "no cooldown value"
	EndIf
	Float now = Utility.GetCurrentGameTime()
	Float until = Game.GetPlayer().GetValue(nextPiss)
	If until > now
		Return "AN76 cooldown: meals ignored for " + (((until - now) * 24.0) as Int) + " more game hours"
	EndIf
	Return "AN76 cooldown over: the next meal starts the need"
EndFunction

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
