Scriptname _AC_BeginFishing extends ActiveMagicEffect
;/
    The fishing minigame: cast a line at a nearby fish, wait for the bite, reel in.

    Clean-room reconstruction. This installation shipped no Papyrus at all - 0 .psc and
    0 .pex anywhere in the workspace, and no BSA - while ArtOfTheCatch.esp attaches this
    script to MGEF 02000D8D (_AC_MiniGameEffect). No original code was seen or copied;
    nothing of it survives in the repository's git history either.

    What IS recovered, exactly, from the plugin's own VMAD subrecord using
    RequiemLotDPatch/tools/vmaddump.py: the parent type (MGEF -> ActiveMagicEffect), all
    48 property names, and each property's concrete type, resolved by looking up the form
    it points at in Skyrim.exe's masters. Those are facts about the plugin.

    What is INFERRED: the sequence below. The property set names every beat of it - a pole
    to check for, water and ground probes reporting into globals, a bobber and four
    collision references, a cast sound, a "pull the line" message and trigger, per-fish
    caught messages paired with per-fish ingredients, and two failure messages - but the
    timings and the exact order are a reconstruction, not a port. Treat the numbers in
    TUNING below as starting points.

    Behaviour that IS pinned by the plugin, and should not drift:
      * no pole in inventory        -> _AC_ErrorNeedPole
      * no fish within reach        -> _AC_ErrorNoFishNearby
      * reeled too late or not at all -> _AC_ErrorDidntCatchAnything
      * each CritterPondFishNN pairs with CritterPondFishNNIngredient and _AC_CaughtFishNN
      * salmon pay out FoodSalmon and _AC_CaughtFishSalmon
/;

; ---- TUNING -------------------------------------------------------------------------
Float Property SearchRadius = 512.0 Auto        ; how far to look for a fish
Float Property MinWaterDepth = 24.0 Auto        ; water surface must clear the bed by this
Float Property BiteDelayMin = 2.0 Auto          ; seconds before the fish bites
Float Property BiteDelayMax = 6.0 Auto
Float Property ReelWindow = 2.5 Auto            ; seconds the player has to pull the line
Float Property PollInterval = 0.1 Auto

; ---- properties, all recovered from the plugin's VMAD --------------------------------
Actor Property PlayerRef Auto

; Base objects (ACTI), so these are Form - not ObjectReference. The plugin stores base
; forms here, and declaring a reference type would fail to bind.
Form Property CritterPondFish01 Auto
Form Property CritterPondFish02 Auto
Form Property CritterPondFish03 Auto
Form Property CritterPondFish04 Auto
Form Property CritterPondFish05 Auto
Form Property CritterSalmon01 Auto
Form Property CritterSalmon02 Auto
Form Property FCAmbWaterfallSalmon01 Auto
Form Property FCAmbWaterfallSalmon02 Auto
Form Property _AC_Bobber Auto

Ingredient Property CritterPondFish01Ingredient Auto
Ingredient Property CritterPondFish02Ingredient Auto
Ingredient Property CritterPondFish03Ingredient Auto
Ingredient Property CritterPondFish04Ingredient Auto
Ingredient Property CritterPondFish05Ingredient Auto
Potion Property FoodSalmon Auto

Idle Property IdlePickup_Ground Auto
Idle Property IdleWipeBrow Auto

ObjectReference Property _AC_Anchor Auto
ObjectReference Property _AC_BobberCol1 Auto
ObjectReference Property _AC_BobberCol2 Auto
ObjectReference Property _AC_BobberCol3 Auto
ObjectReference Property _AC_BobberCol4 Auto
ObjectReference Property _AC_PullLineTriggerRef Auto
ObjectReference Property _AC_WaterTarget Auto
ObjectReference Property _AC_WaterTester Auto

Spell Property _AC_CastLineFishPoleEffect Auto
Spell Property _AC_TestGroundSpell Auto
Spell Property _AC_TestWaterSpell Auto

Sound Property _AC_CastLineSM Auto
Sound Property _AC_CatchFish Auto

Message Property _AC_CaughtFish01 Auto
Message Property _AC_CaughtFish02 Auto
Message Property _AC_CaughtFish03 Auto
Message Property _AC_CaughtFish04 Auto
Message Property _AC_CaughtFish05 Auto
Message Property _AC_CaughtFishSalmon Auto
Message Property _AC_ErrorDidntCatchAnything Auto
Message Property _AC_ErrorNeedPole Auto
Message Property _AC_ErrorNoFishNearby Auto
Message Property _AC_PullLineMsg Auto

FormList Property _AC_FishWaterfallTypes Auto
FormList Property critterFishTypes Auto

Weapon Property _AC_FishingPole Auto
MiscObject Property _AC_FishingPoleMiscItem Auto

GlobalVariable Property _AC_GroundZVal Auto
GlobalVariable Property _AC_PlayerActivatedTrigger Auto
GlobalVariable Property _AC_WaterZVal Auto

; ---- state ---------------------------------------------------------------------------
Bool bFishing = false

Event OnEffectStart(Actor akTarget, Actor akCaster)
    ; The power can be spammed. One cast at a time, or the bobber references get moved
    ; out from under a run that is still waiting.
    If bFishing
        Return
    EndIf

    Actor thePlayer = akCaster
    If !thePlayer
        thePlayer = Game.GetPlayer()
    EndIf
    If !thePlayer
        Return
    EndIf

    If !HasPole(thePlayer)
        ShowMessage(_AC_ErrorNeedPole)
        Return
    EndIf

    ObjectReference fishRef = FindFish(thePlayer)
    If !fishRef
        ShowMessage(_AC_ErrorNoFishNearby)
        Return
    EndIf

    bFishing = true
    RunCast(thePlayer, fishRef)
    bFishing = false
EndEvent

Event OnEffectFinish(Actor akTarget, Actor akCaster)
    ; If the effect is cut short - the player fast travels, the cell unloads - make sure
    ; nothing is left enabled in the world.
    Cleanup(Game.GetPlayer())
    bFishing = false
EndEvent

; --------------------------------------------------------------------------------------

Bool Function HasPole(Actor thePlayer)
    If _AC_FishingPole && thePlayer.GetItemCount(_AC_FishingPole) > 0
        Return true
    EndIf
    If _AC_FishingPoleMiscItem && thePlayer.GetItemCount(_AC_FishingPoleMiscItem) > 0
        Return true
    EndIf
    Return false
EndFunction

; Nearest fish critter. The vanilla critterFishTypes list holds the pond fish; the mod's
; own _AC_FishWaterfallTypes holds the leaping waterfall salmon. Check both and take
; whichever is closer, so standing at a waterfall does not report "no fish nearby".
ObjectReference Function FindFish(Actor thePlayer)
    ObjectReference pond = None
    ObjectReference falls = None

    If critterFishTypes
        pond = Game.FindClosestReferenceOfAnyTypeInListFromRef(critterFishTypes, thePlayer, SearchRadius)
    EndIf
    If _AC_FishWaterfallTypes
        falls = Game.FindClosestReferenceOfAnyTypeInListFromRef(_AC_FishWaterfallTypes, thePlayer, SearchRadius)
    EndIf

    If pond && falls
        If thePlayer.GetDistance(pond) <= thePlayer.GetDistance(falls)
            Return pond
        EndIf
        Return falls
    EndIf
    If pond
        Return pond
    EndIf
    Return falls
EndFunction

; Probe the spot with the two test spells and read back what the reporter activators
; wrote. Returns true when there is enough water above the bed to fish in.
Bool Function ProbeWater(Actor thePlayer, ObjectReference fishRef)
    If !_AC_WaterZVal || !_AC_GroundZVal
        ; Without the globals there is nothing to compare; do not block the cast on a
        ; probe that cannot report.
        Return true
    EndIf

    If _AC_WaterTester
        _AC_WaterTester.MoveTo(fishRef)
    EndIf
    If _AC_WaterTarget
        _AC_WaterTarget.MoveTo(fishRef)
    EndIf

    If _AC_TestWaterSpell && _AC_WaterTester
        _AC_TestWaterSpell.Cast(_AC_WaterTester, _AC_WaterTester)
    EndIf
    If _AC_TestGroundSpell && _AC_WaterTester
        _AC_TestGroundSpell.Cast(_AC_WaterTester, _AC_WaterTester)
    EndIf

    ; Give the placed reporters a moment to fire OnInit and write their heights.
    Utility.Wait(0.5)

    Float waterZ = _AC_WaterZVal.GetValue()
    Float groundZ = _AC_GroundZVal.GetValue()
    Return (waterZ - groundZ) >= MinWaterDepth
EndFunction

Function RunCast(Actor thePlayer, ObjectReference fishRef)
    If !ProbeWater(thePlayer, fishRef)
        ShowMessage(_AC_ErrorNoFishNearby)
        Cleanup(thePlayer)
        Return
    EndIf

    If _AC_FishingPole
        thePlayer.EquipItem(_AC_FishingPole, false, true)
    EndIf
    If _AC_CastLineFishPoleEffect
        _AC_CastLineFishPoleEffect.Cast(thePlayer, thePlayer)
    EndIf
    If _AC_CastLineSM
        _AC_CastLineSM.Play(thePlayer)
    EndIf

    PlaceBobber(fishRef)

    ; The fish takes its time.
    Utility.Wait(BiteDelayMin + Utility.RandomFloat(0.0, BiteDelayMax - BiteDelayMin))

    ; Clear any stale activation before arming, then prompt.
    If _AC_PlayerActivatedTrigger
        _AC_PlayerActivatedTrigger.SetValue(0.0)
    EndIf
    ArmTrigger(thePlayer)
    ShowMessage(_AC_PullLineMsg)

    If WaitForReel()
        GiveCatch(thePlayer, fishRef)
    Else
        ShowMessage(_AC_ErrorDidntCatchAnything)
        If IdleWipeBrow
            thePlayer.PlayIdle(IdleWipeBrow)
        EndIf
    EndIf

    Cleanup(thePlayer)
EndFunction

Function PlaceBobber(ObjectReference fishRef)
    Float x = fishRef.GetPositionX()
    Float y = fishRef.GetPositionY()
    Float z = fishRef.GetPositionZ()
    If _AC_WaterZVal && _AC_WaterZVal.GetValue() != 0.0
        z = _AC_WaterZVal.GetValue()
    EndIf

    If _AC_Anchor
        _AC_Anchor.MoveTo(fishRef)
        _AC_Anchor.SetPosition(x, y, z)
        _AC_Anchor.Enable()
    EndIf

    ; The four collision references form the bobber's float cage; keep them with it.
    MoveCollision(_AC_BobberCol1, x, y, z)
    MoveCollision(_AC_BobberCol2, x, y, z)
    MoveCollision(_AC_BobberCol3, x, y, z)
    MoveCollision(_AC_BobberCol4, x, y, z)
EndFunction

Function MoveCollision(ObjectReference col, Float x, Float y, Float z)
    If col
        col.SetPosition(x, y, z)
        col.Enable()
    EndIf
EndFunction

; Put the reel prompt on the player so activating is what pulls the line.
Function ArmTrigger(Actor thePlayer)
    If _AC_PullLineTriggerRef
        _AC_PullLineTriggerRef.MoveTo(thePlayer)
        _AC_PullLineTriggerRef.Enable()
    EndIf
EndFunction

; Poll the trigger global for the length of the reel window.
Bool Function WaitForReel()
    If !_AC_PlayerActivatedTrigger
        Return false
    EndIf
    Float waited = 0.0
    While waited < ReelWindow
        If _AC_PlayerActivatedTrigger.GetValue() > 0.0
            Return true
        EndIf
        Utility.Wait(PollInterval)
        waited += PollInterval
    EndWhile
    Return false
EndFunction

Function GiveCatch(Actor thePlayer, ObjectReference fishRef)
    If _AC_CatchFish
        _AC_CatchFish.Play(thePlayer)
    EndIf
    If IdlePickup_Ground
        thePlayer.PlayIdle(IdlePickup_Ground)
    EndIf

    Form caught = fishRef.GetBaseObject()

    ; Pair the critter with its ingredient and its message. The plugin defines these as
    ; five matched sets plus salmon, so keep them matched.
    If caught == CritterPondFish01
        Award(thePlayer, CritterPondFish01Ingredient, _AC_CaughtFish01)
    ElseIf caught == CritterPondFish02
        Award(thePlayer, CritterPondFish02Ingredient, _AC_CaughtFish02)
    ElseIf caught == CritterPondFish03
        Award(thePlayer, CritterPondFish03Ingredient, _AC_CaughtFish03)
    ElseIf caught == CritterPondFish04
        Award(thePlayer, CritterPondFish04Ingredient, _AC_CaughtFish04)
    ElseIf caught == CritterPondFish05
        Award(thePlayer, CritterPondFish05Ingredient, _AC_CaughtFish05)
    ElseIf caught == CritterSalmon01 || caught == CritterSalmon02 \
        || caught == FCAmbWaterfallSalmon01 || caught == FCAmbWaterfallSalmon02
        Award(thePlayer, FoodSalmon, _AC_CaughtFishSalmon)
    Else
        ; A critter from the list that is not one of the six named sets. Still a catch -
        ; fall back to the first pond fish rather than silently giving nothing.
        Award(thePlayer, CritterPondFish01Ingredient, _AC_CaughtFish01)
    EndIf

    ; The fish has been taken out of the water.
    fishRef.Disable()
EndFunction

Function Award(Actor thePlayer, Form item, Message msg)
    If item
        thePlayer.AddItem(item, 1, true)
    EndIf
    ShowMessage(msg)
EndFunction

Function Cleanup(Actor thePlayer)
    DisableRef(_AC_Anchor)
    DisableRef(_AC_BobberCol1)
    DisableRef(_AC_BobberCol2)
    DisableRef(_AC_BobberCol3)
    DisableRef(_AC_BobberCol4)
    DisableRef(_AC_PullLineTriggerRef)
    If _AC_PlayerActivatedTrigger
        _AC_PlayerActivatedTrigger.SetValue(0.0)
    EndIf
EndFunction

Function DisableRef(ObjectReference ref)
    If ref && !ref.IsDisabled()
        ref.Disable()
    EndIf
EndFunction

Function ShowMessage(Message msg)
    If msg
        msg.Show()
    EndIf
EndFunction
