Scriptname AN76Toilets:PrepStove extends ObjectReference
{A dead kitchen stove that preps food: the same as Advanced Needs 76's own Prep Stove
(Flashy_PrepStoveScript): all the raw meat you carry becomes AN76's prepped meat, all the raw produce
its prepped vegetables, one for one. AN76's forms are reached by id at run time, never by master.}

; Flashy_PersonalEssentials.esp
Int Property AN76_RAW_MEAT = 0x0082CC AutoReadOnly       ; FormList Flashy_List_ProcessableMeat
Int Property AN76_RAW_PRODUCE = 0x0082CD AutoReadOnly    ; FormList Flashy_List_ProcessableProduce
Int Property AN76_PREPPED_MEAT = 0x0082C4 AutoReadOnly   ; MiscObject Flashy_Misc_PreppedMeat
Int Property AN76_PREPPED_VEG = 0x0082C5 AutoReadOnly    ; MiscObject Flashy_Misc_PreppedVeg
Int Property AN76_NO_MEAT = 0x0082CF AutoReadOnly        ; Message Flashy_Message_NoRawMeat
Int Property AN76_NO_PRODUCE = 0x0082CE AutoReadOnly     ; Message Flashy_Message_NoRawProduce

Event OnActivate(ObjectReference akActionRef)
	Actor player = Game.GetPlayer()
	If akActionRef != player
		Return
	EndIf
	Int meat = Prep(player, AN76_RAW_MEAT, AN76_PREPPED_MEAT, AN76_NO_MEAT)
	Int veg = Prep(player, AN76_RAW_PRODUCE, AN76_PREPPED_VEG, AN76_NO_PRODUCE)
	Debug.Trace("AN76 Toilets: prepped on " + GetBaseObject() + " - meat " + meat + ", produce " + veg, 0)
EndEvent

; Everything on the list the player carries becomes that many of the prepped item; nothing: AN76's message.
Int Function Prep(Actor akPlayer, Int aiRaw, Int aiPrepped, Int aiNone)
	FormList raw = AN76(aiRaw) as FormList
	MiscObject prepped = AN76(aiPrepped) as MiscObject
	If !raw || !prepped
		Return 0
	EndIf
	Int count = akPlayer.GetItemCount(raw)
	If count > 0
		akPlayer.RemoveItem(raw, -1, True, None)
		akPlayer.AddItem(prepped, count, False)
	Else
		Message nothing = AN76(aiNone) as Message
		If nothing
			nothing.Show(0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0)
		EndIf
	EndIf
	Return count
EndFunction

Form Function AN76(Int aiFormID)
	Return Game.GetFormFromFile(aiFormID, "Flashy_PersonalEssentials.esp")
EndFunction
