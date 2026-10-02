Scriptname AN76Toilets:Spawner extends Quest
{Makes the world's toilets and urinals usable while Advanced Needs 76's Bathroom Needs are on, and
(2026-10-02) its dead kitchen stoves and espresso machines: AN76's food prep and its Silt Bean coffee.

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
FormList Property AN76ToiletList Auto Const Mandatory
{Empty in the plugin; filled at run time with AN76's four toilets (AN76 is not a master).}
GlobalVariable Property WorldToiletsOn Auto Const Mandatory
{MCM: world toilets and urinals usable.}
Form[] Property Kitchens Auto Const Mandatory
{The spawns that are kitchens (2026-10-02): a stove that preps food, an espresso machine that brews coffee.}
GlobalVariable Property WorldKitchensOn Auto Const Mandatory
{MCM: world stoves and coffee machines usable.}

Float Property Radius = 1500.0 Auto Const
Float Property TickSeconds = 3.0 Auto Const
Float Property ScaleUp = 1.02 Auto Const
Float Property MaxTilt = 10.0 Auto Const
{Degrees. A toilet lying on its side is scenery.}
Int Property MaxSpawns = 48 Auto Const
Int Property MaxKitchens = 24 Auto Const
{Of MaxSpawns: a kitchen-dense place (a diner, a hub) never takes the toilets' share (review 2026-10-02).}

Int Property TICK_TIMER = 1 AutoReadOnly
Int Property AN76_BATHROOM_QUEST = 0x03B902 AutoReadOnly
Int Property AN76_ESSENTIALS_QUEST = 0x001EE2 AutoReadOnly   ; Flashy_EssentialsMain (the mod itself)
Int Property AN76_NEEDS_QUEST = 0x001EDD AutoReadOnly        ; Flashy_NeedsMain (the needs system)
Int Property AN76_CAMPING_QUEST = 0x007B72 AutoReadOnly      ; Flashy_CampingSystem
Int Property AN76_TOILET_ON = 0x03B8FB AutoReadOnly          ; GlobalVariable Flashy_NeedsHygieneToilet
Int Property MQ102_ID = 0x01CC2A AutoReadOnly                 ; Fallout4.esm MQ102, AN76's own "left the vault" test

ObjectReference[] _for
ObjectReference[] _spawned
Int _lastState = -1   ; retired 2026-10-02 (kept: a save holds it)
Int _lastMask = -1    ; -1 unknown; 1 toilets on, 2 kitchens on
Bool _bootstrapped = False
ObjectReference[] _locked
Int Property AN76_OUTHOUSE = 0x005D23 AutoReadOnly
Int Property AN76_POSTWAR_TOILET = 0x005D22 AutoReadOnly
Int Property AN76_HOBO_TOILET = 0x00A2A2 AutoReadOnly
Int Property AN76_INSTITUTE_TOILET = 0x03FD70 AutoReadOnly

Event OnQuestInit()
	Begin()
EndEvent

Event Actor.OnPlayerLoadGame(Actor akSender)
	If !OnOwnRecord()
		Return
	EndIf
	_lastMask = -1   ; say the state again on every load
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

; Only ever run on our own quest. A save made while a build had renumbered the plugin can hold an
; instance of this script on some other record (2026-09-29: on an MCM global); such an instance says so
; once and stops for good instead of running with its properties empty.
Bool Function OnOwnRecord()
	If Game.GetFormFromFile(0x000819, "AN76_Toilets.esp") == Self as Form
		Return True
	EndIf
	Debug.Trace("AN76 Toilets: a stray spawner instance on " + Self + " - stopped", 0)
	UnregisterForAllEvents()
	Return False
EndFunction

Event OnTimer(Int aiTimerID)
	If !OnOwnRecord()
		Return
	EndIf
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
	LockAN76Toilets(Game.GetPlayer())
	; Two switches: the toilets need AN76's Bathroom Needs running, the kitchens only AN76 itself (its
	; prepped food and its coffee). Either one changing takes everything down; the next ticks place again.
	Bool toiletsOn = BathroomOn() && WorldToiletsOn.GetValueInt() == 1
	Bool kitchensOn = Game.IsPluginInstalled("Flashy_PersonalEssentials.esp") && WorldKitchensOn.GetValueInt() == 1
	Int mask = 0
	If toiletsOn
		mask += 1
	EndIf
	If kitchensOn
		mask += 2
	EndIf
	If mask != _lastMask
		Debug.Trace("AN76 Toilets: world toilets " + toiletsOn + " (AN76's Bathroom Needs and the MCM), world kitchens " + kitchensOn, 0)
		_lastMask = mask
		RemoveAll()
	EndIf
	If mask == 0
		Return
	EndIf
	Actor player = Game.GetPlayer()
	Prune(player)
	If player.IsInCombat() || _spawned.Length >= MaxSpawns
		Return
	EndIf
	Bool male = player.GetActorBase().GetSex() == 0
	ObjectReference[] found = player.FindAllReferencesOfType(TargetList as Form, Radius)
	Int before = _spawned.Length
	; Two passes: the toilets and urinals first, then the kitchens, at most MaxKitchens of them.
	Int kitchenCount = CountKitchens()
	Int pass = 0
	While pass < 2
		Int i = 0
		While i < found.Length && _spawned.Length < MaxSpawns
			ObjectReference target = found[i]
			; Not a toilet shrunk to nothing: a mod hides a leftover that way (a tester, 2026-10-01: the Underground
			; Hideout's "TOILET" floated mid-floor, the poop landed there, the real toilet stood by the wall).
			If target && !target.IsDisabled() && _for.Find(target) < 0 && Upright(target) && target.GetScale() >= 0.5
				Int index = Targets.Find(target.GetBaseObject())
				If index >= 0
					Form spawn = Spawns[index]
					Bool kitchen = Kitchens.Find(spawn) >= 0
					If pass == 0 && !kitchen && toiletsOn && (male || Urinals.Find(spawn) < 0)
						Place(target, spawn)
					ElseIf pass == 1 && kitchen && kitchensOn && kitchenCount < MaxKitchens
						Place(target, spawn)
						kitchenCount += 1
					EndIf
				EndIf
			EndIf
			i += 1
		EndWhile
		pass += 1
	EndWhile
	If _spawned.Length > before
		Debug.Trace("AN76 Toilets: " + (_spawned.Length - before) + " placed (" + found.Length + " toilets, urinals, stoves and coffee machines in range, " + _spawned.Length + " live)", 0)
	EndIf
EndFunction

; AN76's own toilets are placed as loose physics objects, so sitting down can shove one away (the
; owner's camp toilet, 2026-09-29). Keyframed: collisions no longer move it, activation still works.
Function LockAN76Toilets(Actor akPlayer)
	If AN76ToiletList.GetSize() == 0
		Int[] ids = new Int[4]
		ids[0] = AN76_OUTHOUSE
		ids[1] = AN76_POSTWAR_TOILET
		ids[2] = AN76_HOBO_TOILET
		ids[3] = AN76_INSTITUTE_TOILET
		Int k = 0
		While k < ids.Length
			Form toilet = Game.GetFormFromFile(ids[k], "Flashy_PersonalEssentials.esp")
			If toilet
				AN76ToiletList.AddForm(toilet)
			EndIf
			k += 1
		EndWhile
		If AN76ToiletList.GetSize() == 0
			Return
		EndIf
	EndIf
	If _locked == None
		_locked = new ObjectReference[0]
	EndIf
	ObjectReference[] found = akPlayer.FindAllReferencesOfType(AN76ToiletList as Form, Radius)
	Int i = 0
	While i < found.Length
		ObjectReference toilet = found[i]
		If toilet && _locked.Find(toilet) < 0
			toilet.SetMotionType(toilet.Motion_Keyframed, True)
			If _locked.Length >= 32
				_locked.Remove(0, 1)
			EndIf
			_locked.Add(toilet, 1)
			Debug.Trace("AN76 Toilets: locked AN76's " + toilet.GetBaseObject() + " in place", 0)
		EndIf
		i += 1
	EndWhile
EndFunction

Int Function CountKitchens()
	Int n = 0
	Int i = 0
	While i < _spawned.Length
		If _spawned[i] && Kitchens.Find(_spawned[i].GetBaseObject()) >= 0
			n += 1
		EndIf
		i += 1
	EndWhile
	Return n
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
		; And never trust a distance across an interior's walls: a different cell where either is inside.
		If keep
			Cell here = akPlayer.GetParentCell()
			Cell there = spawned.GetParentCell()
			If there != here && (!here || !there || here.IsInterior() || there.IsInterior())
				keep = False
			EndIf
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
