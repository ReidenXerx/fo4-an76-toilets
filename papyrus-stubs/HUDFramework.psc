; IMPORT-ONLY: the signatures of HUDFramework's API (HUDFramework 1.0f, Nexus 20309), so our
; scripts compile. Never compiled or shipped: the real HUDFramework.pex comes with HUDFramework.
ScriptName HUDFramework Extends Quest

HUDFramework Function GetInstance() Global
	Return None
EndFunction

Function RegisterWidget(ScriptObject akOwner, String asSWF, Float afX, Float afY, Bool abLoadNow, Bool abAutoLoad)
EndFunction

Bool Function IsWidgetRegistered(String asWidgetID)
	Return False
EndFunction

Bool Function IsWidgetLoaded(String asWidgetID)
	Return False
EndFunction

Function LoadWidget(String asWidgetID)
EndFunction

Function SetWidgetPosition(String asWidgetID, Float afX, Float afY, Bool abTemporary)
EndFunction

Function SendMessage(String asWidgetID, Int aiCommand, Float arg1, Float arg2, Float arg3, Float arg4, Float arg5, Float arg6)
EndFunction
