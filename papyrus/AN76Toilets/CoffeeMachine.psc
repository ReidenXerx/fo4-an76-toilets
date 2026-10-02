Scriptname AN76Toilets:CoffeeMachine extends ObjectReference
{An espresso machine in the world brews Advanced Needs 76's Silt Bean coffee, as its own Siltbean Coffee
Machine does (Flashy_CoffeeMachineScript): you stand at it with the vanilla coffee-drinking animation
and drink one. NPCs may stand at it too in their own routine; only the player gets the coffee.}

Int Property AN76_SILT_BEAN_COFFEE = 0x003647 AutoReadOnly   ; Potion Flashy_Consumable_SiltBeanCoffee

Event OnActivate(ObjectReference akActionRef)
	Actor player = Game.GetPlayer()
	If akActionRef != player
		Return
	EndIf
	Potion coffee = Game.GetFormFromFile(AN76_SILT_BEAN_COFFEE, "Flashy_PersonalEssentials.esp") as Potion
	If coffee
		player.EquipItem(coffee, False, True)
	EndIf
	Debug.Trace("AN76 Toilets: coffee from " + GetBaseObject() + " - " + (coffee != None), 0)
EndEvent
