Scriptname AN76Toilets:NpcToilets extends Quest
{NPCs go too. Whoever sits down on a toilet in their own routine -- a settler on one of our seats, the
Institute's toilets, Far Harbor's outhouses, one of AN76's built toilets -- undresses (children never),
pees, sometimes strains and poops, sighs, wipes and dresses again, with the sounds of their own sex.
No AN76 need behind it: a show for whoever is near. One NPC at a time; each one rests for a while after.
(Owner 2026-09-30: every sit, an MCM chance, fully undressed through our own clothes snapshot.)}

Sound Property FartShort Auto Const Mandatory
Sound Property FartShortF Auto Const Mandatory
Sound Property FartLong Auto Const Mandatory
Sound Property FartLongF Auto Const Mandatory
Sound Property FartWet Auto Const Mandatory
Sound Property FartWetF Auto Const Mandatory
Sound Property PeeSeat Auto Const Mandatory
Sound Property PeeSeatF Auto Const Mandatory
Sound Property Plop Auto Const Mandatory
Sound Property Paper Auto Const Mandatory
Topic[] Property StrainMaleLines Auto Const Mandatory
Topic[] Property StrainFemaleLines Auto Const Mandatory
Topic[] Property ReliefMaleLines Auto Const Mandatory
Topic[] Property ReliefFemaleLines Auto Const Mandatory
{Spoken lines in every vanilla human and ghoul voice type, with the strain and relief faces.}
Form[] Property Toilets Auto Const Mandatory
{Toilets an NPC can sit on from our own plugin and Fallout4.esm; the DLC and AN76 ones are added at run time.}
GlobalVariable Property NpcToiletsOn Auto Const Mandatory
GlobalVariable Property NpcToiletChance Auto Const Mandatory
GlobalVariable Property SoundsSetting Auto Const Mandatory
GlobalVariable Property LeftoversOn Auto Const Mandatory
{MCM (2026-10-02): a pile by a toilet that does not flush, and now and then a magazine left behind.}
Form[] Property Magazines Auto Const Mandatory
{Fallout4.esm's burnt magazines (MISC), the reading someone leaves by the toilet.}
Int Property MagazinePercent = 35 Auto Const
Int Property MaxProps = 6 Auto Const

Float Property ScanSeconds = 4.0 Auto Const
Float Property ScanRadius = 2500.0 Auto Const
{About 35 m: further than that nobody hears it anyway.}
Float Property RestHours = 8.0 Auto Const
{Game hours before the same NPC puts on the show again.}

Int Property SCAN_TIMER = 1 AutoReadOnly
Int Property NPC_QUEST = 0x000881 AutoReadOnly     ; this quest (tools/formids.json NpcQuest)
; Fallout4.esm
Int Property KW_HUMAN = 0x02CB72 AutoReadOnly      ; Keyword ActorTypeHuman
Int Property KW_GHOUL = 0x0EAFB7 AutoReadOnly      ; Keyword ActorTypeGhoul
; DLCCoast.esm: the barn outhouse seats (the only other sittable toilets in the game and its DLC)
Int Property DLC03_OUTHOUSE = 0x009899 AutoReadOnly     ; FURN BarnOuthouseChair01
Int Property DLC03_OUTHOUSE_WS = 0x0545A0 AutoReadOnly  ; FURN Dlc03BarnOuthouseChair01
; Flashy_PersonalEssentials.esp: AN76's buildable toilets (its own script ignores NPCs)
Int Property AN76_OUTHOUSE = 0x005D23 AutoReadOnly
Int Property AN76_POSTWAR = 0x005D22 AutoReadOnly
Int Property AN76_HOBO = 0x00A2A2 AutoReadOnly
Int Property AN76_INSTITUTE = 0x03FD70 AutoReadOnly
Int Property AN76_POOP = 0x03FD6D AutoReadOnly     ; Activator Flashy_Acti_PoopBrown (deleted on unload)

Form[] _toilets
Actor[] _rested
Float[] _restedAt
ObjectReference[] _props   ; the magazines we left: gone once their area unloads

Event OnQuestInit()
	Begin()
EndEvent

Event Actor.OnPlayerLoadGame(Actor akSender)
	If !OnOwnRecord()
		Return
	EndIf
	Begin()
EndEvent

; Only ever run on our own quest (see AN76Toilets:Sounds.OnOwnRecord).
Bool Function OnOwnRecord()
	If Game.GetFormFromFile(NPC_QUEST, "AN76_Toilets.esp") == Self as Form
		Return True
	EndIf
	Debug.Trace("AN76 Toilets: a stray NPC toilets instance on " + Self + " - stopped", 0)
	UnregisterForAllEvents()
	Return False
EndFunction

; On every load: the toilet list again (DLC and AN76 may have come or gone), and the scan.
Function Begin()
	RegisterForRemoteEvent(Game.GetPlayer(), "OnPlayerLoadGame")
	_toilets = new Form[0]
	Int i = 0
	While i < Toilets.Length
		_toilets.Add(Toilets[i])
		i += 1
	EndWhile
	AddToilet(DLC03_OUTHOUSE, "DLCCoast.esm")
	AddToilet(DLC03_OUTHOUSE_WS, "DLCCoast.esm")
	AddToilet(AN76_OUTHOUSE, "Flashy_PersonalEssentials.esp")
	AddToilet(AN76_POSTWAR, "Flashy_PersonalEssentials.esp")
	AddToilet(AN76_HOBO, "Flashy_PersonalEssentials.esp")
	AddToilet(AN76_INSTITUTE, "Flashy_PersonalEssentials.esp")
	If !_rested
		_rested = new Actor[0]
		_restedAt = new Float[0]
	EndIf
	Debug.Trace("AN76 Toilets: NPC toilets - " + _toilets.Length + " kinds of toilet an NPC can sit on", 0)
	StartTimer(ScanSeconds, SCAN_TIMER)
EndFunction

Function AddToilet(Int aiFormID, String asPlugin)
	If Game.IsPluginInstalled(asPlugin)
		Form f = Game.GetFormFromFile(aiFormID, asPlugin)
		If f
			_toilets.Add(f)
		EndIf
	EndIf
EndFunction

Event OnTimer(Int aiTimerID)
	If !OnOwnRecord() || aiTimerID != SCAN_TIMER
		Return
	EndIf
	TidyProps()
	If NpcToiletsOn.GetValueInt() == 1
		Actor player = Game.GetPlayer()
		Actor sitter = Sitter(player.FindAllReferencesWithKeyword(Game.GetFormFromFile(KW_HUMAN, "Fallout4.esm"), ScanRadius), player)
		If !sitter
			sitter = Sitter(player.FindAllReferencesWithKeyword(Game.GetFormFromFile(KW_GHOUL, "Fallout4.esm"), ScanRadius), player)
		EndIf
		If sitter
			Rest(sitter)
			If Utility.RandomFloat(0.0, 100.0) < NpcToiletChance.GetValue()
				Show(sitter)
			Else
				Debug.Trace("AN76 Toilets: " + sitter + " sat on a toilet - not this time (MCM chance)", 0)
			EndIf
		EndIf
	EndIf
	StartTimer(ScanSeconds, SCAN_TIMER)
EndEvent

; The first one sitting on a toilet who is free for it and has not had a turn lately.
Actor Function Sitter(ObjectReference[] akRefs, Actor akPlayer)
	Float now = Utility.GetCurrentGameTime()
	Int i = 0
	While i < akRefs.Length
		Actor a = akRefs[i] as Actor
		If a && a != akPlayer && a.GetSitState() == 3 && a.Is3DLoaded() && !a.IsDead() && !a.IsInCombat() && !a.IsInScene() && !a.IsInDialogueWithPlayer() && !a.IsInPowerArmor()
			ObjectReference seat = a.GetFurnitureReference()
			If seat && _toilets.Find(seat.GetBaseObject()) >= 0 && Rested(a, now)
				Return a
			EndIf
		EndIf
		i += 1
	EndWhile
	Return None
EndFunction

Bool Function Rested(Actor akActor, Float afNow)
	Int i = _rested.Find(akActor)
	Return i < 0 || (afNow - _restedAt[i]) * 24.0 >= RestHours
EndFunction

; Remembers when this NPC had a turn; forgets whoever has rested long enough, so the list stays short.
Function Rest(Actor akActor)
	Float now = Utility.GetCurrentGameTime()
	Int i = _rested.Length - 1
	While i >= 0
		If !_rested[i] || _rested[i] == akActor || (now - _restedAt[i]) * 24.0 >= RestHours
			_rested.Remove(i, 1)
			_restedAt.Remove(i, 1)
		EndIf
		i -= 1
	EndWhile
	_rested.Add(akActor)
	_restedAt.Add(now)
EndFunction

; ---- the show ------------------------------------------------------------------------------

Function Show(Actor akActor)
	ObjectReference seat = akActor.GetFurnitureReference()
	Bool male = akActor.GetLeveledActorBase().GetSex() != 1
	Bool sounds = SoundsSetting.GetValueInt() == 1
	Bool poop = Utility.RandomInt(0, 1) == 0
	Debug.Trace("AN76 Toilets: " + akActor + " goes on a toilet (" + seat + "), poop " + poop, 0)

	; Undressed for it -- a child never. Our own snapshot, the one that dresses the player again.
	Form[] worn = new Form[0]
	If !akActor.IsChild()
		worn = WornNow(akActor)
		Int u = 0
		While u < worn.Length
			akActor.UnequipItem(worn[u], False, True)
			u += 1
		EndWhile
	EndIf

	Int stream = 0
	If Beat(akActor, seat, 1.5) && sounds
		stream = Pick(akActor, male, PeeSeat, PeeSeatF).Play(akActor)
	EndIf
	If Beat(akActor, seat, 4.5)
		If stream
			Sound.StopInstance(stream)
			stream = 0
		EndIf
		If poop
			If sounds
				Speak(akActor, male, StrainMaleLines, StrainFemaleLines)
			EndIf
			If Beat(akActor, seat, 2.5) && sounds
				If Utility.RandomInt(0, 1) == 0
					Pick(akActor, male, FartShort, FartShortF).Play(akActor)
				Else
					Pick(akActor, male, FartLong, FartLongF).Play(akActor)
				EndIf
			EndIf
			If Beat(akActor, seat, 2.5) && sounds
				Pick(akActor, male, FartWet, FartWetF).Play(akActor)
			EndIf
			If Beat(akActor, seat, 2.0) && sounds
				Plop.Play(akActor)
			EndIf
			If Beat(akActor, seat, 2.0) && sounds && Utility.RandomInt(0, 1) == 0
				Plop.Play(akActor)
			EndIf
		ElseIf sounds && Utility.RandomInt(0, 2) == 0
			Pick(akActor, male, FartShort, FartShortF).Play(akActor)
		EndIf
	EndIf
	If Beat(akActor, seat, 1.5)
		If sounds
			Speak(akActor, male, ReliefMaleLines, ReliefFemaleLines)
		EndIf
		If poop && Beat(akActor, seat, 2.0) && sounds
			Paper.Play(akActor)
		EndIf
		Beat(akActor, seat, 2.0)
	EndIf
	If stream
		Sound.StopInstance(stream)
	EndIf

	; Dressed again: whatever came off and is still theirs and still off.
	Int putBack = 0
	Int i = 0
	While i < worn.Length
		Form item = worn[i]
		If item && !akActor.IsEquipped(item) && akActor.GetItemCount(item) > 0
			akActor.EquipItem(item, False, True)
			putBack += 1
		EndIf
		i += 1
	EndWhile
	Debug.Trace("AN76 Toilets: " + akActor + " done, dressed again (" + putBack + " of " + worn.Length + " items)", 0)
	If LeftoversOn.GetValueInt() == 1 && seat
		LeaveBehind(seat, poop)
	EndIf
EndFunction

; ---- what they leave behind (2026-10-02) ------------------------------------------------------

; A toilet that does not flush (a broken one, AN76's hobo toilet) keeps the evidence: AN76's own pile on
; the floor in front of it -- it missed. Now and then a burnt magazine by the toilet, someone's reading.
Function LeaveBehind(ObjectReference akSeat, Bool abPoop)
	Float a = akSeat.GetAngleZ()
	If abPoop && !Flushes(akSeat)
		Form pile = Game.GetFormFromFile(AN76_POOP, "Flashy_PersonalEssentials.esp")
		; One pile per toilet: the next visitor does not stack another on it.
		If pile && !Game.FindClosestReferenceOfTypeFromRef(pile, akSeat, 80.0)
			; The sitter faces the seat's -Y: the floor just in front of the toilet.
			ObjectReference p = akSeat.PlaceAtMe(pile, 1, False, False, True)
			If p
				p.MoveTo(akSeat, -24.0 * Math.Sin(a), -24.0 * Math.Cos(a), 0.0, False)
			EndIf
			Debug.Trace("AN76 Toilets: left a pile in front of " + akSeat, 0)
		EndIf
	EndIf
	If Magazines.Length > 0 && Utility.RandomInt(1, 100) <= MagazinePercent
		If _props == None
			_props = new ObjectReference[0]
		EndIf
		If _props.Length >= MaxProps
			Drop(0)
		EndIf
		ObjectReference m = akSeat.PlaceAtMe(Magazines[Utility.RandomInt(0, Magazines.Length - 1)], 1, False, False, True)
		If m
			; Beside the toilet on the floor (the seat's +X), at any angle.
			m.MoveTo(akSeat, 30.0 * Math.Cos(a), -30.0 * Math.Sin(a), 2.0, False)
			m.SetAngle(0.0, 0.0, Utility.RandomFloat(0.0, 359.0))
			_props.Add(m)
			Debug.Trace("AN76 Toilets: left a magazine by " + akSeat, 0)
		EndIf
	EndIf
EndFunction

Bool Function Flushes(ObjectReference akSeat)
	AN76Toilets:Seat ours = akSeat as AN76Toilets:Seat
	If ours
		Return ours.Flushable
	EndIf
	; AN76's hobo toilet is a bucket; every other toilet an NPC sits on has water or a pit.
	Return akSeat.GetBaseObject() != Game.GetFormFromFile(AN76_HOBO, "Flashy_PersonalEssentials.esp")
EndFunction

; The magazines we left: deleted once their cell has unloaded, or forgotten when the player picked one up.
; By the cell, not Is3DLoaded: a havok item just placed can read unloaded for a moment (review 2026-10-02).
Function TidyProps()
	If _props == None
		Return
	EndIf
	Int i = _props.Length - 1
	While i >= 0
		ObjectReference m = _props[i]
		Cell c = None
		If m
			c = m.GetParentCell()
		EndIf
		If !m || m.GetContainer() || !c || !c.IsAttached()
			Drop(i)
		EndIf
		i -= 1
	EndWhile
EndFunction

Function Drop(Int aiIndex)
	ObjectReference m = _props[aiIndex]
	If m && !m.GetContainer()
		m.Disable(False)
		m.Delete()
	EndIf
	_props.Remove(aiIndex, 1)
EndFunction

; Waits, then says whether the NPC is still sitting there for the next beat (up and gone: the show ends).
Bool Function Beat(Actor akActor, ObjectReference akSeat, Float afSeconds)
	Utility.Wait(afSeconds)
	Return akActor.Is3DLoaded() && !akActor.IsDead() && !akActor.IsInCombat() && akActor.GetSitState() == 3 && akActor.GetFurnitureReference() == akSeat
EndFunction

Sound Function Pick(Actor akActor, Bool abMale, Sound akMale, Sound akFemale)
	If abMale
		Return akMale
	EndIf
	Return akFemale
EndFunction

Function Speak(Actor akActor, Bool abMale, Topic[] akMale, Topic[] akFemale)
	Topic[] lines = akFemale
	If abMale
		lines = akMale
	EndIf
	akActor.Say(lines[Utility.RandomInt(0, lines.Length - 1)], None, False, None)
EndFunction

; What the NPC wears that they own (F4SE GetWornItem): the same snapshot as the player's clothes net.
Form[] Function WornNow(Actor akActor)
	Form[] worn = new Form[0]
	Int slot = 0
	; Armour only: a slot can report the armour ADDON (the model piece, e.g. NakedHands), which is no
	; inventory item -- GetItemCount on it logs an error every tick (log 2026-09-30).
	While slot < 32
		Actor:WornItem w = akActor.GetWornItem(slot, False)
		If w && (w.item as Armor) && worn.Find(w.item) < 0 && akActor.GetItemCount(w.item) > 0
			worn.Add(w.item)
		EndIf
		slot += 1
	EndWhile
	Return worn
EndFunction
