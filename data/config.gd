extends RefCounted
## Tunable settings, kept in one place so staff can retune the exhibition build
## by editing this file - no scene digging required. Everything here is read at
## runtime by Game; nothing is baked into a scene.
class_name THConfig

## How rooms are drawn:
##   "room3d"     - full 3D room built from primitives / Blender .glb (default)
##   "backdrop2d" - the AI room painting as a flat backdrop with clickable
##                  hotspots layered on top (lighter, ships without models)
## The two share the same item logic, so switching is a one-word change.
const RENDER_MODE := "backdrop2d"

## How items are drawn:
##   "sprite" - the AI item painting as an upright billboard (labels stay crisp,
##              children can read the real warning symbols) - default when the
##              images exist
##   "model"  - the tinted Blender .glb model
## Falls back automatically: sprite -> model -> primitive, whichever is present.
const ITEM_MODE := "sprite"

## Exhibition kiosks open every level from the start; a classroom build can set
## this false to make children clear the easy levels first.
const EXHIBITION_UNLOCK_ALL := true

## Kiosk idle timeout: with no mouse / touch / keyboard input for this many
## seconds on any screen other than the attach (title) screen, the game drops
## back to attach. BGM / SFX on-off choices are kept. 0 disables it.
const IDLE_TIMEOUT_SEC := 60.0

## Turn edutainment extras on/off without touching code that uses them.
const HINTS_ENABLED := true
const MASCOT_ENABLED := true

## Scoring knobs.
const TIME_BONUS_PER_SEC := 5      ## points added per second left at the end
const STREAK_BONUS := 25           ## extra per correct-in-a-row step
const WRONG_SHAKE := true

## Summary-screen star rating. The score is compared with the best score the
## round allows (every toxic item found on a perfect streak, plus the time bonus
## for the full clock). Each entry is the share of that best score needed for one
## more star - 5 entries = 5 stars max.
const STAR_STEPS := [0.10, 0.25, 0.40, 0.55, 0.70]

## Camera feel in the 3D room.
const CAM_ORBIT_SPEED := 0.006
const CAM_MIN_PITCH := -0.15
const CAM_MAX_PITCH := 0.55
