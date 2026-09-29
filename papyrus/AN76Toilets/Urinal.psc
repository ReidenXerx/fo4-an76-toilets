Scriptname AN76Toilets:Urinal extends ObjectReference
{A usable urinal: a male player steps up to it, faces it and pees standing, with Advanced Needs 76's
own standing animation and sound, then AN76 clears the need (its QuickRemoveNeed). Only spawned for
a male player. Everything of AN76's is looked up by form id at run time.}

Sound Property ZipDown Auto Const Mandatory
Sound Property ZipUp Auto Const Mandatory
Sound Property Stream Auto Const Mandatory
{Our own stream on porcelain, in place of AN76's toilet-water one.}

Float Property StandOff = 42.0 Auto Const
{Units in front of the urinal's wall plane (its model reaches 32 out, local -Y).}
Float Property Seconds = 10.0 Auto Const
{As long as AN76's own pee at its toilets.}

Int Property AN76_BATHROOM_QUEST = 0x03B902 AutoReadOnly
Int Property AN76_TOILET_STACK = 0x03B8FF AutoReadOnly     ; GlobalVariable Flashy_NeedsToiletStack
Int Property AN76_NEXT_PISS = 0x04E8FE AutoReadOnly        ; ActorValue Flashy_NextPiss
Int Property AN76_DONT_NEED = 0x03B913 AutoReadOnly        ; Message Flashy_Message_DontNeedToPee
Int Property AN76_MALE_IDLE = 0x03FD69 AutoReadOnly        ; Idle Flashy_BathroomMaleIdle
Int Property AN76_PEEING = 0x03B915 AutoReadOnly           ; Sound Flashy_Hygiene_Peeing
Int Property AN76_PLAY_SOUNDS = 0x03FD6A AutoReadOnly      ; GlobalVariable Flashy_Hygiene_PlaySounds
Int Property AN76_BUSY = 0x03B904 AutoReadOnly             ; Keyword Flashy_Keyword_BusyPlayer
Int Property LOOSE_IDLE_STOP = 0x029380 AutoReadOnly       ; Fallout4.esm Idle LooseIdleStop

Bool _busy = False
Bool _hit = False

Event OnHit(ObjectReference akTarget, ObjectReference akAggressor, Form akSource, Projectile akProjectile, Bool abPowerAttack, Bool abSneakAttack, Bool abBashAttack, Bool abHitBlocked, String asMaterialName)
	_hit = True
EndEvent

Form Function AN76(Int aiFormID)
	Return Game.GetFormFromFile(aiFormID, "Flashy_PersonalEssentials.esp")
EndFunction

Event OnActivate(ObjectReference akActionRef)
	Actor player = Game.GetPlayer()
	If akActionRef != player || _busy
		Return
	EndIf
	Quest bathroom = AN76(AN76_BATHROOM_QUEST) as Quest
	If !bathroom || !bathroom.IsRunning() || player.IsInPowerArmor() || player.IsInCombat()
		Debug.Trace("AN76 Toilets: urinal refused - bathroom running " + (bathroom && bathroom.IsRunning()) + ", power armor " + player.IsInPowerArmor() + ", combat " + player.IsInCombat(), 0)
		Return
	EndIf
	GlobalVariable stack = AN76(AN76_TOILET_STACK) as GlobalVariable
	ActorValue nextPiss = AN76(AN76_NEXT_PISS) as ActorValue
	If !stack || stack.GetValueInt() != 1 || (nextPiss && Utility.GetCurrentGameTime() <= player.GetValue(nextPiss))
		Debug.Trace("AN76 Toilets: urinal - no need yet (stack " + (stack && stack.GetValueInt()) + ")", 0)
		Message dontNeed = AN76(AN76_DONT_NEED) as Message
		If dontNeed
			dontNeed.Show(0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0)
		EndIf
		Return
	EndIf
	_busy = True
	Debug.Trace("AN76 Toilets: urinal - peeing", 0)
	Pee(player, bathroom)
	Debug.Trace("AN76 Toilets: urinal - done, AN76 QuickRemoveNeed called", 0)
	_busy = False
EndEvent

Function Pee(Actor akPlayer, Quest akBathroom)
	; In front of the urinal, facing it: its model reaches out along local -Y from the wall.
	Float heading = GetAngleZ()
	akPlayer.MoveTo(Self, -StandOff * Math.Sin(heading), -StandOff * Math.Cos(heading), 0.0, False)
	akPlayer.SetAngle(0.0, 0.0, heading)

	Keyword busy = AN76(AN76_BUSY) as Keyword
	If busy
		akPlayer.AddKeyword(busy)
	EndIf
	InputEnableLayer layer = InputEnableLayer.Create()
	layer.DisablePlayerControls(True, True, True, False, True, True, True, False, True, True, False)
	Form held = akPlayer.GetEquippedWeapon(0) as Form
	If held
		akPlayer.UnequipItem(held, False, True)
	EndIf
	Idle standing = AN76(AN76_MALE_IDLE) as Idle
	If standing
		akPlayer.PlayIdle(standing)
	EndIf
	Int instance = 0
	GlobalVariable sounds = AN76(AN76_PLAY_SOUNDS) as GlobalVariable
	Bool audible = !sounds || sounds.GetValueInt() == 1
	If audible
		ZipDown.Play(akPlayer)
		Utility.Wait(0.8)
		instance = Stream.Play(akPlayer)
	EndIf

	; A hit ends it at once, as it does at AN76's own toilets -- and then the need stays.
	_hit = False
	RegisterForHitEvent(akPlayer)
	Float waited = 0.0
	While waited < Seconds && !_hit
		Utility.Wait(0.5)
		waited += 0.5
	EndWhile
	UnregisterForHitEvent(akPlayer)
	If audible
		ZipUp.Play(akPlayer)
	EndIf

	If instance
		Sound.StopInstance(instance)
	EndIf
	Idle stop = Game.GetFormFromFile(LOOSE_IDLE_STOP, "Fallout4.esm") as Idle
	If stop
		akPlayer.PlayIdle(stop)
	EndIf
	layer.Delete()
	If busy
		akPlayer.RemoveKeyword(busy)
	EndIf
	If _hit
		Debug.Trace("AN76 Toilets: urinal - hit, stopped after " + waited + " s", 0)
		Return
	EndIf
	; AN76's own ending: the need cleared, the pain gone, its "done" message, the next-need clock.
	ScriptObject script = akBathroom.CastAs("FlashyEssentials:Flashy_BathroomScript")
	If script
		Var[] args = new Var[1]
		args[0] = False
		script.CallFunction("QuickRemoveNeed", args)
	EndIf
EndFunction
