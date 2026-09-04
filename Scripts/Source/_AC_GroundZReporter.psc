Scriptname _AC_GroundZReporter extends ObjectReference
;/
    Reports the Z height of the ground into a global.

    Clean-room reconstruction from ArtOfTheCatch.esp's VMAD - see
    _AC_GivePowerQuestScript.psc for the full note. Attached to ACTI 02001301
    (_AC_GroundReporter), so it extends ObjectReference.

    The companion to _AC_WaterZReporter: _AC_BeginFishing casts _AC_TestGroundSpell at the
    same spot it tested for water. Comparing the two heights is how the minigame decides
    whether there is actually water to fish in rather than a puddle-thin sliver or dry
    land - if the water surface is not meaningfully above the ground, there is nowhere for
    a fish to be.

    Property as recovered:
        _AC_GroundZVal  GLOB 020012FD
/;

GlobalVariable Property _AC_GroundZVal Auto

Event OnInit()
    Report()
EndEvent

Event OnLoad()
    Report()
EndEvent

Function Report()
    If _AC_GroundZVal
        _AC_GroundZVal.SetValue(Self.GetPositionZ())
    EndIf
EndFunction
