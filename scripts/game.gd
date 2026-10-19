extends Node
## Autoload: the whole game's state machine and score keeper.
##
## Holds the config/database references, tracks the current round, and computes
## the score. Scenes read from here and call start_level / on_pick / finish;
## they never own the score themselves, so any screen can show it consistently.

const Config := preload("res://data/config.gd")
const Items := preload("res://data/items.gd")
const Levels := preload("res://data/levels.gd")
const PaintedRooms := preload("res://data/painted_rooms.gd")

signal score_changed(value: int)
signal found_changed(found: int, total: int)

# --- current round ----------------------------------------------------------
var level: Dictionary = {}         ## the THLevels entry being played
var round_items: Array = []        ## [{id, toxic, room}] actually placed
var found_toxic: Array = []        ## ids the player correctly flagged
var picked_wrong: Array = []       ## ids the player wrongly flagged
var score := 0
var streak := 0
var time_left := 0.0
var playing := false


func config() -> Object:
    return Config


## Build a round: spread this level's toxic + safe items across its rooms.
## Toxic items are guaranteed to appear; safe decoys fill the rest. Room
## assignment is randomised so replaying the same level feels different.
func start_level(level_id: String) -> void:
    level = Levels.by_id(level_id)
    round_items.clear()
    found_toxic.clear()
    picked_wrong.clear()
    score = 0
    streak = 0
    time_left = float(level.get("time", 120))
    playing = true

    # painted levels: items are fixed hotspots in the room art
    # Only hotspots named in the level's toxic / safe lists are used.
    if PaintedRooms.has_level(level_id):
        var allowed: Array = level.get("toxic", []) + level.get("safe", [])
        var uid := 0
        for room in PaintedRooms.get_level(level_id)["rooms"]:
            for h in room["hotspots"]:
                if not h["id"] in allowed:
                    continue
                round_items.append({
                    "uid": uid, "id": h["id"], "room": room["name"], "rect": h["rect"],
                    "toxic": bool(Items.get_item(h["id"]).get("toxic", false)),
                })
                uid += 1
        score_changed.emit(score)
        found_changed.emit(found_toxic.size(), total_toxic())
        return

    var rooms: Array = level.get("rooms", ["ห้อง"])
    var pool: Array = []
    for id in level.get("toxic", []):
        pool.append({"id": id, "toxic": true})
    for id in level.get("safe", []):
        pool.append({"id": id, "toxic": true if false else false})
    pool.shuffle()

    # hand each item a room, keeping rooms roughly balanced
    var r := 0
    for entry in pool:
        entry["room"] = rooms[r % rooms.size()]
        round_items.append(entry)
        r += 1

    score_changed.emit(score)
    found_changed.emit(found_toxic.size(), total_toxic())


func total_toxic() -> int:
    var n := 0
    for e in round_items:
        if e["toxic"]:
            n += 1
    return n


func items_in_room(room: String) -> Array:
    return round_items.filter(func(e): return e["room"] == room)


## Returns the reveal outcome so the room can play the right animation:
##   { correct: bool, data: {...}, delta: int }
func on_pick(entry: Dictionary) -> Dictionary:
    var data: Dictionary = Items.get_item(entry["id"])
    var delta := 0
    if entry["toxic"]:
        entry["found"] = true
        streak += 1
        delta = int(data.get("points", 100)) + (streak - 1) * Config.STREAK_BONUS
        found_toxic.append(entry["id"])
        Sfx.play(&"correct", 1.0 + 0.03 * (streak - 1))
    else:
        streak = 0
        delta = int(data.get("penalty", -50))
        picked_wrong.append(entry["id"])
        Sfx.play(&"wrong")
    score = max(0, score + delta)
    score_changed.emit(score)
    found_changed.emit(found_toxic.size(), total_toxic())
    return {"correct": entry["toxic"], "data": data, "delta": delta}


func _process(delta: float) -> void:
    if not playing:
        return
    time_left -= delta
    if time_left <= 0.0:
        time_left = 0.0
        playing = false


func finish() -> Dictionary:
    playing = false
    var time_bonus := int(time_left) * Config.TIME_BONUS_PER_SEC
    var final_score := score + time_bonus
    var total := total_toxic()
    var rank := _rank(found_toxic.size(), total)
    return {
        "score": final_score,
        "base": score,
        "time_bonus": time_bonus,
        "found": found_toxic.duplicate(),
        "total": total,
        "wrong": picked_wrong.duplicate(),
        "rank": rank,
    }


## Best score this round could give: every toxic item on one unbroken streak
## plus the time bonus for the whole clock (a ceiling - no one hits it).
func max_score() -> int:
    var n := 0
    var pts := 0
    for e in round_items:
        if e["toxic"]:
            pts += int(Items.get_item(e["id"]).get("points", 100))
            n += 1
    pts += int(Config.STREAK_BONUS * n * (n - 1) / 2.0)
    pts += int(level.get("time", 120)) * Config.TIME_BONUS_PER_SEC
    return maxi(pts, 1)


## 0-5 stars from the score, using Config.STAR_STEPS.
func star_rating(final_score: int) -> int:
    if final_score <= 0:
        return 0
    var ratio := float(final_score) / float(max_score())
    var stars := 0
    for step in Config.STAR_STEPS:
        if ratio >= step:
            stars += 1
    return mini(stars, 5)


func _rank(found: int, total: int) -> String:
    if total == 0:
        return "นักสืบฝึกหัด"
    var ratio := float(found) / float(total)
    if ratio >= 1.0:
        return "ยอดนักสืบสารพิษ"
    elif ratio >= 0.6:
        return "นักสืบมือดี"
    return "นักสืบฝึกหัด"
