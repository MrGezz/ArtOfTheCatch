Scriptname _AC_ReelTriggerScript extends ObjectReference
;/
    The "pull the line" prompt. Records that the player reeled in.

    Clean-room reconstruction from ArtOfTheCatch.esp's VMAD - see
    _AC_GivePowerQuestScript.psc for the full note. Attached to REFR 02000D89
    (_AC_PullLineTriggerRef), so it extends ObjectReference.

    _AC_BeginFishing moves this reference onto the player and enables it while a fish is
    biting, so activating is what "pulling the line" means. All this script does is raise
    the flag; the minigame polls it and decides whether the timing was good. Keeping the
    decision out of here matters, because the trigger can also be activated when no cast
    is running, and then the flag is simply stale and gets cleared before the next cast.

    Property as recovered:
        _AC_PlayerActivatedTrigger  GLOB 020012FF
/;

GlobalVariable Property _AC_PlayerActivatedTrigger Auto

Event OnActivate(ObjectReference akActionRef)
    If akActionRef == Game.GetPlayer() && _AC_PlayerActivatedTrigger
        _AC_PlayerActivatedTrigger.SetValue(1.0)
    EndIf
EndEvent
