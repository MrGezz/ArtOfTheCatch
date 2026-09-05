# ArtOfTheCatch
Art of the Catch is a complete fishing experience for Skyrim.

## Vanilla overrides removed (2026-09-05)

`ArtOfTheCatch.esp` carried thirteen overrides of Skyrim.esm activators and flora it never
changed: `CritterPondFish01`-`05`, `CritterSalmon01`/`02`, `FCAmbWaterfallSalmon01`/`02`
(ACTI) and `FXAmbWaterSalmon01A`/`01B`/`02A`/`02B` (FLOR). Each had a VMAD identical to
vanilla and differed only by *lacking* `FULL` and `RNAM` - the localized strings an
unlocalized plugin drops when the Creation Kit re-saves a record. In the build they also
overwrote Creation Club Fishing's versions of the same records (its `ccBGSSSE001_FoodSalmon`
ingredient and script properties), so hand-caught salmon reverted to vanilla items with no
name. Removed with `RequiemLotDPatch/tools/droprecords.py` (13 records, 43,784 -> 39,518
bytes, `ArtOfTheCatch.esp.bak-droprecords` kept). `_AC_FishWaterfallTypes` and
`_AC_MiniGameEffect` still reference the base forms, which now resolve to whichever plugin
loads last: CC Fishing here, Hearthfires/vanilla in a load order without it. The fishing
minigame itself uses the mod's own records and `FoodSalmon`.
