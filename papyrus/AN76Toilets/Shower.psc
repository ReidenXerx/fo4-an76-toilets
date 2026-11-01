Scriptname AN76Toilets:Shower extends ObjectReference
{A usable shower or bathtub (1.3.0): a wash, then Advanced Needs 76's own bath -- exactly what its Fragrant
Soap at open water does (its perk fragment PRKF_Flashy_Perk_HygieneBath): the Bathed effect, the next-bath
clock two days out, its "Bathed" message and the player's line. Only the soap is not used up.

The wash (owner 2026-11-01: an animation and the game's own sounds): an invisible vanilla furniture marker is
placed where you stand, facing the shower, and you step into it -- standing and rubbing your hands under a
shower, kneeling at a bathtub; a splash, then running water at the shower while you wash. Moving away stops
it, and then there is no bath. Taking the marker away at the end stands you up. Everything of AN76's is looked
up by form id.}

Sound Property Water Auto Const Mandatory
{The running water while you wash: a shower's stream, or a tap for a bathtub.}
Sound Property Splash Auto Const Mandatory
{Fallout4.esm PHYWaterSplash, as the water starts.}
Furniture Property WashMarker Auto Const Mandatory
{Fallout4.esm NPCHandWarmingStanding (showers) or NPCHandWarmingKneeling (bathtubs): the hands rubbed together.}
Float Property WashSeconds = 10.0 Auto Const

Int Property AN76_BATHED_POTION = 0x03303C AutoReadOnly   ; Potion Flashy_Hygiene_BathingPotion ("Bathed")
Int Property AN76_NEXT_BATH = 0x033038 AutoReadOnly       ; ActorValue Flashy_Hygiene_NextBath
Int Property AN76_BATHED_MESSAGE = 0x033041 AutoReadOnly  ; Message Flashy_Message_Bathed
Int Property AN76_BATHED_TOPIC = 0x03B8F6 AutoReadOnly    ; Keyword Flashy_Topic_Bathed (the player's line)
Int Property AN76_BUSY = 0x03B904 AutoReadOnly            ; Keyword Flashy_Keyword_BusyPlayer

Bool _busy = False

Form Function AN76(Int aiFormID)
	Return Game.GetFormFromFile(aiFormID, "Flashy_PersonalEssentials.esp")
EndFunction

Event OnActivate(ObjectReference akActionRef)
	Actor player = Game.GetPlayer()
	If akActionRef != player || _busy
		Return
	EndIf
	Potion bathed = AN76(AN76_BATHED_POTION) as Potion
	ActorValue nextBath = AN76(AN76_NEXT_BATH) as ActorValue
	If !bathed || !nextBath || player.IsInPowerArmor() || player.IsInCombat() || player.GetSitState() != 0
		Debug.Trace("AN76 Toilets: wash refused - AN76 found " + (bathed && nextBath) + ", power armor " + player.IsInPowerArmor() + ", combat " + player.IsInCombat() + ", sit state " + player.GetSitState(), 0)
		Return
	EndIf
	_busy = True
	Bool clean = Wash(player)
	If clean
		; AN76's own bath, in its own order.
		player.SetValue(nextBath, Utility.GetCurrentGameTime() + 2.0)
		player.EquipItem(bathed as Form, False, True)
		Message done = AN76(AN76_BATHED_MESSAGE) as Message
		If done
			done.Show(0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0)
		EndIf
		Keyword line = AN76(AN76_BATHED_TOPIC) as Keyword
		If line
			player.SayCustom(line, player, False, player as ObjectReference)
		EndIf
		Debug.Trace("AN76 Toilets: washed at " + GetBaseObject() + " - AN76's Bathed, next bath in 2 days", 0)
	Else
		Debug.Notification("You stopped before you were clean.")
		Debug.Trace("AN76 Toilets: wash at " + GetBaseObject() + " stopped early - no bath", 0)
	EndIf
	_busy = False
EndEvent

; True when the whole wash ran. The player stands in the sink furniture where they are, turned to the shower.
Bool Function Wash(Actor akPlayer)
	ObjectReference marker = akPlayer.PlaceAtMe(WashMarker, 1, False, True, True)
	If !marker
		Return False
	EndIf
	marker.SetAngle(0.0, 0.0, akPlayer.GetAngleZ() + akPlayer.GetHeadingAngle(Self as ObjectReference))
	marker.Enable(False)
	Keyword busy = AN76(AN76_BUSY) as Keyword
	If busy
		akPlayer.AddKeyword(busy)
	EndIf
	marker.Activate(akPlayer as ObjectReference, False)
	Float waited = 0.0
	While akPlayer.GetSitState() == 0 && waited < 3.0
		Utility.Wait(0.25)
		waited += 0.25
	EndWhile
	Bool inside = akPlayer.GetSitState() != 0
	Int instance = 0
	If inside
		Splash.Play(Self as ObjectReference)
		instance = Water.Play(Self as ObjectReference)
		waited = 0.0
		While waited < WashSeconds && akPlayer.GetSitState() != 0 && !akPlayer.IsInCombat()
			Utility.Wait(0.5)
			waited += 0.5
		EndWhile
	EndIf
	If instance
		Sound.StopInstance(instance)
	EndIf
	Bool clean = inside && waited >= WashSeconds
	marker.Disable(False)
	marker.Delete()
	If busy
		akPlayer.RemoveKeyword(busy)
	EndIf
	Debug.Trace("AN76 Toilets: wash - in the furniture " + inside + ", " + waited + " s of " + WashSeconds, 0)
	Return clean
EndFunction
