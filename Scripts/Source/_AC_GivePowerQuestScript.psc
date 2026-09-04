Scriptname _AC_GivePowerQuestScript extends Quest
;/
    Grants the fishing power to the player.

    Clean-room reconstruction. This installation shipped no Papyrus at all - 0 .psc and
    0 .pex - while ArtOfTheCatch.esp attaches this script to QUST _AC_Main. The symptom
    was, in Papyrus.0.log:

        error: Unable to bind script _AC_GivePowerQuestScript to _AC_Main (14000D62)
               because their base types do not match

    The signature below was recovered from the plugin's own VMAD subrecord with
    RequiemLotDPatch/tools/vmaddump.py: the parent type comes from the record it is
    attached to (QUST -> Quest), and both property names and their concrete types come
    from the VMAD, resolved against Skyrim.esm. No original code was seen or copied.

    Property types as recovered:
        PlayerRef      form 00000014   the player reference
        _AC_FishPower  SPEL 02001300   the lesser power that starts the minigame
/;

Actor Property PlayerRef Auto
Spell Property _AC_FishPower Auto

Event OnInit()
    GivePower()
EndEvent

; The quest is start-game-enabled, so OnInit covers a new game. A save made before the
; scripts existed will not re-run OnInit, so re-grant on load as well; AddSpell is a no-op
; when the actor already has it, and HasSpell keeps the log quiet either way.
Function GivePower()
    Actor thePlayer = PlayerRef
    If !thePlayer
        thePlayer = Game.GetPlayer()
    EndIf
    If !thePlayer || !_AC_FishPower
        Return
    EndIf
    If !thePlayer.HasSpell(_AC_FishPower)
        thePlayer.AddSpell(_AC_FishPower, false)
    EndIf
EndFunction
