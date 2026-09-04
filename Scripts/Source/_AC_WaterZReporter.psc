Scriptname _AC_WaterZReporter extends ObjectReference
;/
    Reports the Z height of the water surface into a global.

    Clean-room reconstruction from ArtOfTheCatch.esp's VMAD - see
    _AC_GivePowerQuestScript.psc for the full note. Attached to ACTI 02001303
    (_AC_WaterReporter), so it extends ObjectReference.

    How it is used: _AC_BeginFishing casts _AC_TestWaterSpell at the water in front of the
    player. That spell's effect places one of these activators at the impact point, which
    for a water-collision hit is the water surface. Reading its Z gives the surface height,
    which is where the bobber has to sit.

    Property as recovered:
        _AC_WaterZVal  GLOB 020012FE
/;

GlobalVariable Property _AC_WaterZVal Auto

; OnInit fires when the reference is created by the spell; OnLoad covers a reference that
; was already placed and is being streamed in. Both are cheap and idempotent.
Event OnInit()
    Report()
EndEvent

Event OnLoad()
    Report()
EndEvent

Function Report()
    If _AC_WaterZVal
        _AC_WaterZVal.SetValue(Self.GetPositionZ())
    EndIf
EndFunction
