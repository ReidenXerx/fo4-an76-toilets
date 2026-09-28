Scriptname AN76Toilets:Spawner extends Quest
{Makes the world's toilets and urinals usable while Advanced Needs 76's Bathroom Needs are on.

Every few seconds, near the player: each vanilla toilet or urinal (a static nothing can activate)
gets one of our spawns on top of it -- a seat for a toilet, an activator for a urinal -- built from
that toilet's own model with the geometry hidden, 2% larger so the crosshair finds it first. Spawns
far from the player, or whose toilet has gone, are deleted. Nothing is ever written into a cell, so
precombines and other mods' cell edits are untouched.

Advanced Needs 76 is a soft dependency (GetFormFromFile): without it, or with its Bathroom Needs
off, nothing is spawned and anything spawned is removed.}

Form[] Property Targets Auto Const Mandatory
{Vanilla toilet and urinal bases, index-aligned with Spawns.}
Form[] Property Spawns Auto Const Mandatory
{Our seat (FURN) or urinal (ACTI) for the target at the same index.}
Form[] Property Urinals Auto Const Mandatory
{The spawns that are urinals: spawned only for a male player.}
FormList Property TargetList Auto Const Mandatory
{The same bases as Targets, as the list FindAllReferencesOfType searches for.}

Float Property Radius = 1500.0 Auto Const
Float Property TickSeconds = 3.0 Auto Const
Float Property ScaleUp = 1.02 Auto Const
Float Property MaxTilt = 10.0 Auto Const
{Degrees. A toilet lying on its side is scenery.}
Int Property MaxSpawns = 48 Auto Const

Int Property TICK_TIMER = 1 AutoReadOnly
Int Property AN76_BATHROOM_QUEST = 0x03B902 AutoReadOnly
Int Property AN76_ESSENTIALS_QUEST = 0x001EE2 AutoReadOnly   ; Flashy_EssentialsMain (the mod itself)
Int Property AN76_NEEDS_QUEST = 0x001EDD AutoReadOnly        ; Flashy_NeedsMain (the needs system)
Int Property AN76_CAMPING_QUEST = 0x007B72 AutoReadOnly      ; Flashy_CampingSystem
Int Property AN76_TOILET_ON = 0x03B8FB AutoReadOnly          ; GlobalVariable Flashy_NeedsHygieneToilet
Int Property MQ102_ID = 0x01CC2A AutoReadOnly                 ; Fallout4.esm MQ102, AN76's own "left the vault" test

ObjectReference[] _for
ObjectReference[] _spawned
Int _lastState = -1   ; -1 unknown, 0 AN76's bathroom off, 1 on
Bool _bootstrapped = False

Event OnQuestInit()
	Begin()
EndEvent

Event Actor.OnPlayerLoadGame(Actor akSender)
	_lastState = -1   ; say the bathroom state again on every load
	Begin()
EndEvent

Function Begin()
	RegisterForRemoteEvent(Game.GetPlayer(), "OnPlayerLoadGame")
	If _for == None
		_for = new ObjectReference[0]
		_spawned = new ObjectReference[0]
	EndIf
	StartTimer(TickSeconds, TICK_TIMER)
EndFunction

Event OnTimer(Int aiTimerID)
	If aiTimerID == TICK_TIMER
		Tick()
		StartTimer(TickSeconds, TICK_TIMER)
	EndIf
EndEvent

Bool Function BathroomOn()
	Quest bathroom = Game.GetFormFromFile(AN76_BATHROOM_QUEST, "Flashy_PersonalEssentials.esp") as Quest
	Return bathroom != None && bathroom.IsRunning()
EndFunction

; ONCE per save (owner, 2026-09-29): anyone installing this add-on wants AN76 itself, its needs
; system, its Bathroom Needs and its camping running, so they are started for them -- the same way
; AN76's own MCM buttons start them. Never again after that: a module the player turns off later
; stays off.
Function Bootstrap()
	Quest essentials = Game.GetFormFromFile(AN76_ESSENTIALS_QUEST, "Flashy_PersonalEssentials.esp") as Quest
	If !essentials
		Return   ; AN76 not installed: try again on a later tick
	EndIf
	Quest mq102 = Game.GetFormFromFile(MQ102_ID, "Fallout4.esm") as Quest
	If mq102 && mq102.GetStage() <= 2
		Return   ; still in the game's opening, as AN76 itself waits
	EndIf
	String started = ""
	If !essentials.IsRunning()
		essentials.Start()
		started += " the mod itself,"
	EndIf
	Quest needs = Game.GetFormFromFile(AN76_NEEDS_QUEST, "Flashy_PersonalEssentials.esp") as Quest
	If needs && !needs.IsRunning()
		needs.Start()
		started += " Advanced Needs,"
	EndIf
	Quest bathroom = Game.GetFormFromFile(AN76_BATHROOM_QUEST, "Flashy_PersonalEssentials.esp") as Quest
	GlobalVariable toiletOn = Game.GetFormFromFile(AN76_TOILET_ON, "Flashy_PersonalEssentials.esp") as GlobalVariable
	If bathroom && !bathroom.IsRunning()
		If toiletOn
			toiletOn.SetValue(1.0)
		EndIf
		bathroom.Start()
		started += " Bathroom Needs,"
	EndIf
	Quest camping = Game.GetFormFromFile(AN76_CAMPING_QUEST, "Flashy_PersonalEssentials.esp") as Quest
	If camping && !camping.IsRunning()
		camping.Start()
		started += " Camping,"
	EndIf
	_bootstrapped = True
	If started != ""
		Debug.Notification("AN76 Toilets started AN76's modules for you. Turn any off in AN76's MCM.")
		Debug.Trace("AN76 Toilets: started" + started + " once for this save", 0)
	Else
		Debug.Trace("AN76 Toilets: AN76's modules were already running - nothing started", 0)
	EndIf
EndFunction

Function Tick()
	If !_bootstrapped
		Bootstrap()
	EndIf
	If !BathroomOn()
		If _lastState != 0
			Debug.Trace("AN76 Toilets: AN76's Bathroom Needs are off (or AN76 is not installed) - nothing placed", 0)
			_lastState = 0
		EndIf
		RemoveAll()
		Return
	EndIf
	If _lastState != 1
		Debug.Trace("AN76 Toilets: AN76's Bathroom Needs are on - world toilets become usable", 0)
		_lastState = 1
	EndIf
	Actor player = Game.GetPlayer()
	Prune(player)
	If player.IsInCombat() || _spawned.Length >= MaxSpawns
		Return
	EndIf
	Bool male = player.GetActorBase().GetSex() == 0
	ObjectReference[] found = player.FindAllReferencesOfType(TargetList as Form, Radius)
	Int before = _spawned.Length
	Int i = 0
	While i < found.Length && _spawned.Length < MaxSpawns
		ObjectReference target = found[i]
		If target && !target.IsDisabled() && _for.Find(target) < 0 && Upright(target)
			Int index = Targets.Find(target.GetBaseObject())
			If index >= 0
				Form spawn = Spawns[index]
				If male || Urinals.Find(spawn) < 0
					Place(target, spawn)
				EndIf
			EndIf
		EndIf
		i += 1
	EndWhile
	If _spawned.Length > before
		Debug.Trace("AN76 Toilets: " + (_spawned.Length - before) + " placed (" + found.Length + " toilets and urinals in range, " + _spawned.Length + " live)", 0)
	EndIf
EndFunction

Bool Function Upright(ObjectReference akTarget)
	Return Math.Abs(akTarget.GetAngleX()) <= MaxTilt && Math.Abs(akTarget.GetAngleY()) <= MaxTilt
EndFunction

Function Place(ObjectReference akTarget, Form akSpawn)
	ObjectReference spawned = akTarget.PlaceAtMe(akSpawn, 1, False, True, True)
	If spawned
		spawned.SetScale(akTarget.GetScale() * ScaleUp)
		spawned.MoveTo(akTarget, 0.0, 0.0, 0.0, True)
		spawned.Enable(False)
		_for.Add(akTarget, 1)
		_spawned.Add(spawned, 1)
	EndIf
EndFunction

; Far away (another worldspace reads as far) or its toilet gone: deleted. Not by Is3DLoaded: a spawn
; just enabled, or a toilet baked into precombined meshes, can read unloaded while it is right there,
; and would be deleted and placed again every tick. Newest first so removal keeps indices valid.
Function Prune(Actor akPlayer)
	Int i = _spawned.Length - 1
	While i >= 0
		ObjectReference spawned = _spawned[i]
		ObjectReference target = _for[i]
		Bool keep = spawned != None && target != None && !target.IsDisabled()
		If keep && spawned.GetDistance(akPlayer) > Radius * 2.0
			keep = False
		EndIf
		If !keep
			If spawned
				spawned.Disable(False)
				spawned.Delete()
			EndIf
			_spawned.Remove(i, 1)
			_for.Remove(i, 1)
		EndIf
		i -= 1
	EndWhile
EndFunction

Function RemoveAll()
	Int i = _spawned.Length - 1
	While i >= 0
		If _spawned[i]
			_spawned[i].Disable(False)
			_spawned[i].Delete()
		EndIf
		i -= 1
	EndWhile
	_spawned.Clear()
	_for.Clear()
EndFunction
