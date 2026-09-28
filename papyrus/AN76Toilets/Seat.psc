Scriptname AN76Toilets:Seat extends ObjectReference
{A usable seat on a world toilet: the same contract as Advanced Needs 76's own toilets
(Flashy_ToiletUseScript). Sitting down calls its EnterToilet, getting up its ExitToilet.
Called by name at run time, so AN76 is never a master and none of its files are touched.}

Bool Property Flushable Auto Const
{A toilet with water in it: the flush plays when you get up.}

Int Property AN76_BATHROOM_QUEST = 0x03B902 AutoReadOnly
Int Property AN76_XBOX_BATHROOM_QUEST = 0x00A2C6 AutoReadOnly

Event OnActivate(ObjectReference akActionRef)
	If akActionRef == Game.GetPlayer()
		ScriptObject bathroom = Bathroom()
		If bathroom
			Debug.Trace("AN76 Toilets: sat on " + GetBaseObject() + " - AN76 EnterToilet (xbox " + Xbox() + ")", 0)
			bathroom.CallFunction("EnterToilet", new Var[0])
		Else
			Debug.Trace("AN76 Toilets: sat on " + GetBaseObject() + " but AN76's Bathroom Needs are not running", 0)
		EndIf
	EndIf
EndEvent

Event OnExitFurniture(ObjectReference akActionRef)
	If akActionRef == Game.GetPlayer()
		ScriptObject bathroom = Bathroom()
		If bathroom
			Debug.Trace("AN76 Toilets: got up - AN76 ExitToilet (flush " + Flushable + ")", 0)
			If Xbox()
				Var[] args = new Var[1]
				args[0] = Flushable
				bathroom.CallFunction("ExitToilet", args)
			Else
				Var[] args = new Var[2]
				args[0] = Flushable
				args[1] = Self as ObjectReference
				bathroom.CallFunction("ExitToilet", args)
			EndIf
		EndIf
	EndIf
EndEvent

Bool Function Xbox()
	Quest main = Game.GetFormFromFile(AN76_BATHROOM_QUEST, "Flashy_PersonalEssentials.esp") as Quest
	Quest xbox = Game.GetFormFromFile(AN76_XBOX_BATHROOM_QUEST, "Flashy_PersonalEssentials.esp") as Quest
	Return !(main && main.IsRunning()) && xbox && xbox.IsRunning()
EndFunction

ScriptObject Function Bathroom()
	Quest main = Game.GetFormFromFile(AN76_BATHROOM_QUEST, "Flashy_PersonalEssentials.esp") as Quest
	If main && main.IsRunning()
		Return main.CastAs("FlashyEssentials:Flashy_BathroomScript")
	EndIf
	Quest xbox = Game.GetFormFromFile(AN76_XBOX_BATHROOM_QUEST, "Flashy_PersonalEssentials.esp") as Quest
	If xbox && xbox.IsRunning()
		Return xbox.CastAs("FlashyEssentials:Flashy_XboxBathroomScript")
	EndIf
	Return None
EndFunction
