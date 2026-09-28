; IMPORT-ONLY: the reconstructed base sources have no Weapon.psc, so a script naming the type
; (Actor.GetEquippedWeapon's return) does not compile. NEVER under papyrus/: compiled as a source
; it would emit a Weapon.pex shadowing the game's own.
ScriptName Weapon Extends Form Native hidden
