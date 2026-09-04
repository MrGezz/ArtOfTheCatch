# Art of the Catch — Papyrus scripts

## Why this folder exists

This installation shipped **no Papyrus at all** — 0 `.psc` and 0 `.pex` anywhere, and no
BSA — while `ArtOfTheCatch.esp` attaches five `_AC_*` scripts. Nothing was lost from git:
`git log --all --diff-filter=D` shows no script was ever tracked. The symptom in
`Papyrus.0.log` was:

    error: Unable to bind script _AC_GivePowerQuestScript to _AC_Main (14000D62)
           because their base types do not match

Without these, fishing cannot run at all.

## Clean room

No original code was seen or copied. Every signature was recovered from the plugin's own
`VMAD` subrecords with `RequiemLotDPatch/tools/vmaddump.py`, which reads:

- the **parent type**, from the record each script is attached to
  (`MGEF` → `ActiveMagicEffect`, `QUST` → `Quest`, `ACTI`/`REFR` → `ObjectReference`)
- every **property name**
- each property's **concrete type**, by resolving the form it points at against
  `Skyrim.esm` and `Update.esm` (886,250 forms indexed)

Those are facts about the plugin, not about anyone's source.

| script | extends | properties |
|---|---|---|
| `_AC_BeginFishing` | `ActiveMagicEffect` | 48 |
| `_AC_GivePowerQuestScript` | `Quest` | 2 |
| `_AC_GroundZReporter` | `ObjectReference` | 1 |
| `_AC_ReelTriggerScript` | `ObjectReference` | 1 |
| `_AC_WaterZReporter` | `ObjectReference` | 1 |

Three further scripts the plugin references are **not** ours to write: `critterFish` and
`FXfakeCritterScript` are vanilla Skyrim (attached to `Skyrim.esm` records), and
`_Camp_PerkNodeControllerBehavior` belongs to Campfire.

## What is inferred, and what is not

The **property set is recovered**; the **minigame sequence in `_AC_BeginFishing` is a
reconstruction.** The properties name every beat of it — a pole to check for, water and
ground probes reporting into globals, a bobber with four collision references, a cast
sound, a pull-the-line prompt and trigger, per-fish messages paired with per-fish
ingredients, two failure messages — but the timings and exact ordering are inferred. The
`TUNING` properties at the top of that script are starting points, not measured values.

Pinned by the plugin and not to be drifted:

- no pole → `_AC_ErrorNeedPole`
- no fish in reach → `_AC_ErrorNoFishNearby`
- reeled too late → `_AC_ErrorDidntCatchAnything`
- `CritterPondFishNN` pairs with `CritterPondFishNNIngredient` and `_AC_CaughtFishNN`
- salmon pay out `FoodSalmon` and `_AC_CaughtFishSalmon`

## Build

    RequiemLotDPatch/tools/compile-papyrus.cmd Scripts/Source Scripts

Both `.psc` and `.pex` ship. Verified: 5/5 compile with 0 errors and 0 warnings, and on a
clean boot `Papyrus.0.log` contains **no `_AC_` line at all** — every script binds.

Not verified: the minigame in play. That needs someone to load a save, equip the pole and
fish.
