extends RefCounted
## Painted (2D) rooms for levels that have finished room art.
##
## Each level lists its rooms LEFT -> RIGHT; the arrows walk along that line
## (no wrap-around) and the game opens on `start`. Every hotspot is a clickable
## area over an object painted in the room image:
##   id    key in data/items.gd (toxic or safe comes from there)
##   rect  [x0, y0, x1, y1] in PERCENT of the room image (0-100)
## To move or add a hotspot, edit the numbers here - no scene editing needed.
## A level that is not listed here falls back to the 3D placeholder room.
## Which hotspots are LIVE in a round is decided by the level's "toxic" /
## "safe" lists in data/levels.gd - a hotspot whose id is not listed there is
## ignored, so the art can hold more objects than one round uses.
class_name THPaintedRooms

const Items := preload("res://data/items.gd")

const ART_DIR := "res://assets/ui/"
const BACKGROUND := "game_play_bg.png"

## Room art lives in assets/ui/game_play_scene/<scene>.jpeg and each room has
## its own item sheet in assets/ui/items_sheet/. The item pictures used by the
## popup, the FOUND panel and the summary are cut from that sheet into
## assets/ui/items_icons/<scene>/<id>.png (looked up first; then
## assets/ui/item_<id>.png, then a crop of the room art).
## Where each hotspot sits: assets/items_position/<scene>.jpg and
## docs/items_position_report.md.
## "overlay" (optional) is a transparent layer drawn over the room art.
const LEVELS := {
    "condo": {
        "start": "ห้องนั่งเล่น",
        "rooms": [
            {
                "name": "ห้องนอน", "art": "game_play_scene/condo_bedroom.jpeg",
                "hotspots": [
                    {"id": "rat_poison",          "rect": [12.5, 73.1, 19.2, 88.3]},
                    {"id": "air_freshener",       "rect": [71.1, 12.9, 76.4, 27.9]},
                    {"id": "mosquito_spray",      "rect": [87.8, 52.8, 91.9, 69.7]},
                    {"id": "glass_cleaner",       "rect": [24.4, 31.2, 29.8, 45.0]},
                    {"id": "sleeping_pills",      "rect": [35.3, 40.5, 39.4, 52.1]},
                    {"id": "correction_fluid",    "rect": [21.0, 53.2, 24.8, 64.1]},
                    {"id": "water_bottle",        "rect": [35.3, 72.0, 39.1, 85.7]},
                    {"id": "hand_gel",            "rect": [73.1, 65.6, 77.8, 80.1]},
                    {"id": "lotion",              "rect": [50.1, 83.3, 56.7, 94.9]},
                ],
            },
            {
                "name": "ห้องนั่งเล่น", "art": "game_play_scene/condo_living.jpeg",
                "hotspots": [
                    {"id": "termite_killer",      "rect": [13.3, 68.5, 19.6, 86.6]},
                    {"id": "water_bottle",        "rect": [32.3, 60.8, 36.5, 75.3]},
                    {"id": "glass_cleaner",       "rect": [18.5, 32.4, 22.8, 45.8]},
                    {"id": "dish_soap",           "rect": [22.6, 38.7, 26.2, 50.9]},
                    {"id": "soy_sauce",           "rect": [30.3, 38.1, 33.5, 50.5]},
                    {"id": "alcohol_gel",         "rect": [65.4, 68.0, 69.2, 79.8]},
                    {"id": "floor_cleaner",       "rect": [79.3, 69.6, 87.4, 87.3]},
                    {"id": "vinegar",             "rect": [11.3, 21.3, 14.5, 34.0]},
                    {"id": "laundry_detergent",   "rect": [87.7, 47.0, 94.5, 60.5]},
                ],
            },
            {
                "name": "ห้องน้ำ", "art": "game_play_scene/condo_bathroom.jpeg",
                "hotspots": [
                    {"id": "bug_spray",           "rect": [ 4.6, 75.7,  8.9, 91.3]},
                    {"id": "room_deodorizer",     "rect": [19.1, 14.5, 23.9, 30.3]},
                    {"id": "mouthwash",           "rect": [63.5, 40.3, 67.6, 52.3]},
                    {"id": "alcohol_gel",         "rect": [69.3, 30.5, 72.9, 41.5]},
                    {"id": "body_scrub",          "rect": [24.2, 57.5, 28.3, 65.5]},
                    {"id": "glass_cleaner",       "rect": [22.7, 29.2, 26.9, 42.6]},
                    {"id": "shower_cream",        "rect": [35.5, 37.2, 39.3, 47.8]},
                    {"id": "laundry_detergent",   "rect": [86.3, 52.5, 92.5, 67.8]},
                ],
            },
        ],
    },
    "house": {
        "start": "ห้องนั่งเล่น",
        "rooms": [
            {
                "name": "ห้องครัว", "art": "game_play_scene/home_kitchen.jpeg",
                "hotspots": [
                    {"id": "termite_killer",      "rect": [39.0,  2.4, 43.6, 16.1]},
                    {"id": "soy_sauce",           "rect": [24.3, 38.6, 28.0, 50.4]},
                    {"id": "vinegar",             "rect": [21.2, 36.0, 24.5, 47.0]},
                    {"id": "baking_soda",         "rect": [65.2,  3.2, 71.4, 15.5]},
                    {"id": "floor_cleaner",       "rect": [78.2, 63.2, 84.4, 78.9]},
                    {"id": "glass_cleaner",       "rect": [74.8, 23.7, 79.1, 36.0]},
                    {"id": "water_bottle",        "rect": [60.6, 67.1, 64.3, 80.4]},
                ],
            },
            {
                "name": "ห้องนั่งเล่น", "art": "game_play_scene/home_living.jpeg",
                "hotspots": [
                    {"id": "bug_spray",           "rect": [ 9.0, 48.4, 13.7, 66.8]},
                    {"id": "floor_cleaner",       "rect": [19.7, 76.3, 26.4, 94.4]},
                    {"id": "glass_cleaner",       "rect": [73.7, 37.5, 78.4, 53.0]},
                    {"id": "alcohol_gel",         "rect": [40.0, 28.2, 46.1, 42.2]},
                    {"id": "cough_syrup",         "rect": [17.7, 49.6, 22.8, 60.8]},
                    {"id": "correction_fluid",    "rect": [89.9, 54.4, 93.1, 63.1]},
                    {"id": "water_bottle",        "rect": [55.2, 51.5, 59.2, 65.1]},
                    {"id": "air_freshener",       "rect": [52.7,  1.8, 57.9, 16.5]},
                ],
            },
            {
                "name": "ห้องนอน", "art": "game_play_scene/home_bedroom.jpeg",
                "hotspots": [
                    {"id": "rat_poison",          "rect": [11.5, 69.2, 17.6, 85.5]},
                    {"id": "baby_powder",         "rect": [23.8, 49.7, 27.2, 60.0]},
                    {"id": "sleeping_pills",      "rect": [39.2, 40.0, 42.6, 49.9]},
                    {"id": "water_bottle",        "rect": [31.8, 38.5, 35.3, 51.9]},
                    {"id": "fever_medicine",      "rect": [12.9, 26.0, 17.6, 38.5]},
                    {"id": "air_freshener",       "rect": [82.1, 20.0, 87.1, 35.9]},
                    {"id": "mosquito_spray",      "rect": [90.1, 53.0, 93.7, 67.5]},
                    {"id": "hand_gel",            "rect": [72.5, 67.5, 77.2, 82.8]},
                ],
            },
            {
                "name": "ห้องน้ำ", "art": "game_play_scene/home_bathroom.jpeg",
                "hotspots": [
                    {"id": "toilet_cleaner",      "rect": [23.8, 71.0, 31.4, 88.3]},
                    {"id": "shower_cream",        "rect": [35.7, 37.0, 39.5, 48.0]},
                    {"id": "herbal_shampoo",      "rect": [47.9, 16.9, 51.8, 28.0]},
                    {"id": "face_wash",           "rect": [65.8, 41.4, 69.5, 50.9]},
                    {"id": "alcohol_gel",         "rect": [68.9, 30.3, 73.0, 41.8]},
                    {"id": "mouthwash",           "rect": [75.4, 47.2, 80.0, 58.4]},
                    {"id": "glass_cleaner",       "rect": [86.1, 22.0, 90.4, 35.1]},
                    {"id": "hand_gel",            "rect": [62.5, 42.1, 66.4, 52.8]},
                    {"id": "water_bottle",        "rect": [71.6, 73.4, 77.7, 87.8]},
                    {"id": "fabric_softener",     "rect": [84.0, 51.2, 92.8, 68.3]},
                ],
            },
        ],
    },
    "school": {
        "start": "ห้องวิทยาศาสตร์",
        "rooms": [
            {
                "name": "ห้องศิลปะ", "art": "game_play_scene/school_art.jpeg",
                "hotspots": [
                    {"id": "thinner",             "rect": [ 1.7, 13.3,  7.2, 25.8]},
                    {"id": "gloss_varnish",       "rect": [60.5, 69.1, 63.6, 79.7]},
                    {"id": "latex_glue",          "rect": [53.5, 71.4, 58.7, 83.6]},
                    {"id": "oil_paint",           "rect": [50.0, 82.6, 54.4, 86.7]},
                    {"id": "turpentine",          "rect": [94.1, 43.1, 98.0, 54.5]},
                    {"id": "spray_paint",         "rect": [31.3, 69.8, 34.5, 81.2]},
                    {"id": "dish_soap",           "rect": [83.0, 35.3, 86.4, 45.3]},
                ],
            },
            {
                "name": "ห้องวิทยาศาสตร์", "art": "game_play_scene/school_science.jpeg",
                "hotspots": [
                    {"id": "sulfuric_acid",       "rect": [81.7, 56.8, 85.1, 67.4]},
                    {"id": "soy_sauce",           "rect": [32.3, 22.9, 35.5, 34.4]},
                    {"id": "syrup",               "rect": [51.9, 36.4, 55.3, 48.6]},
                    {"id": "food_coloring",       "rect": [68.4, 52.2, 77.0, 62.7]},
                    {"id": "dish_soap",           "rect": [62.6, 15.5, 65.6, 23.8]},
                    {"id": "vinegar",             "rect": [ 1.3, 45.5,  7.5, 54.8]},
                ],
            },
            {
                "name": "ห้องพยาบาล", "art": "game_play_scene/school_firstaid.jpeg",
                "hotspots": [
                    {"id": "mercury",             "rect": [18.5, 37.2, 22.2, 48.1]},
                    {"id": "mouthwash",           "rect": [24.2, 37.5, 28.0, 47.7]},
                    {"id": "rubbing_alcohol",     "rect": [44.6, 22.9, 47.8, 32.9]},
                    {"id": "saline",              "rect": [29.0, 61.2, 32.9, 73.4]},
                    {"id": "cough_syrup",         "rect": [88.3, 52.0, 92.1, 64.5]},
                    {"id": "red_antiseptic",      "rect": [80.4, 30.5, 84.1, 41.1]},
                    {"id": "liniment",            "rect": [81.1, 71.2, 85.2, 83.2]},
                ],
            },
            {
                "name": "ห้องอาหาร", "art": "game_play_scene/school_canteen.jpeg",
                "hotspots": [
                    {"id": "bug_spray",           "rect": [45.4,  2.6, 47.9, 12.5]},
                    {"id": "dish_soap",           "rect": [28.7, 26.7, 32.2, 36.8]},
                    {"id": "soy_sauce",           "rect": [34.8, 46.2, 37.5, 55.6]},
                    {"id": "vinegar",             "rect": [43.2, 75.4, 46.0, 85.8]},
                    {"id": "baking_soda",         "rect": [84.0, 38.4, 88.3, 47.9]},
                    {"id": "floor_cleaner",       "rect": [90.7, 54.5, 98.5, 71.5]},
                ],
            },
        ],
    },
    "factory": {
        "start": "ห้องสินค้า",
        "rooms": [
            {
                "name": "ห้องวิจัย", "art": "game_play_scene/factory_rd.jpeg",
                "hotspots": [
                    {"id": "arsenic",             "rect": [66.9,  8.9, 71.7, 23.2]},
                    {"id": "food_coloring",       "rect": [30.9, 38.0, 34.6, 45.7]},
                    {"id": "ethanol_wash",        "rect": [36.2, 52.1, 40.7, 66.4]},
                    {"id": "hand_soap",           "rect": [79.6, 71.9, 84.5, 89.8]},
                    {"id": "alum",                "rect": [60.7, 68.8, 67.3, 85.5]},
                    {"id": "distilled_solution",  "rect": [53.7, 31.5, 61.8, 44.3]},
                    {"id": "distilled_water",     "rect": [15.4, 78.6, 24.6, 96.6]},
                ],
            },
            {
                "name": "ห้องสินค้า", "art": "game_play_scene/factory_assembly.jpeg",
                "hotspots": [
                    {"id": "industrial_glue",     "rect": [13.2, 76.8, 21.3, 94.3]},
                    {"id": "grease",              "rect": [38.3, 11.0, 42.0, 16.9]},
                    {"id": "machine_oil",         "rect": [62.1, 20.7, 65.8, 34.7]},
                    {"id": "correction_fluid",    "rect": [39.5, 45.1, 42.9, 54.7]},
                    {"id": "water_bottle",        "rect": [56.1, 47.9, 59.3, 60.9]},
                    {"id": "hand_soap",           "rect": [85.7, 80.0, 90.6, 92.8]},
                    {"id": "anti_moisture_spray", "rect": [59.5, 82.6, 68.7, 93.5]},
                ],
            },
            {
                "name": "ห้องซ่อมบำรุง", "art": "game_play_scene/factory_ma.jpeg",
                "hotspots": [
                    {"id": "rust_remover",        "rect": [12.8, 67.2, 21.4, 86.8]},
                    {"id": "grease",              "rect": [26.0, 79.1, 32.8, 91.3]},
                    {"id": "gasket_glue",         "rect": [29.8, 43.3, 36.2, 47.4]},
                    {"id": "leak_sealant",        "rect": [41.4, 45.9, 45.5, 59.1]},
                    {"id": "water_bottle",        "rect": [54.4, 44.6, 57.8, 58.8]},
                    {"id": "lubricant",           "rect": [46.5, 44.2, 53.1, 60.0]},
                    {"id": "pipe_cement",         "rect": [62.1, 61.5, 68.1, 73.8]},
                    {"id": "system_cleaner",      "rect": [73.8, 80.0, 82.0, 95.0]},
                ],
            },
            {
                "name": "ห้องเก็บพัสดุ", "art": "game_play_scene/factory_store.jpeg",
                "hotspots": [
                    {"id": "sodium_cyanide",      "rect": [12.5, 61.5, 29.4, 93.1]},
                    {"id": "phosphoric_acid",     "rect": [38.1, 51.3, 48.8, 74.0]},
                    {"id": "engine_oil",          "rect": [56.5, 52.5, 65.4, 71.8]},
                    {"id": "saline",              "rect": [60.9, 28.4, 68.3, 44.7]},
                    {"id": "floor_cleaner",       "rect": [68.0, 74.4, 78.2, 96.5]},
                    {"id": "rubbing_alcohol",     "rect": [40.0, 30.0, 48.8, 52.1]},
                ],
            },
        ],
    },
    "farm": {
        "start": "โรงเรือนเก็บวัสดุและสารเคมี",
        "rooms": [
            {
                "name": "โรงเรือนกระจก", "art": "game_play_scene/farm_greenhouse.jpeg",
                "hotspots": [
                    {"id": "weed_killer",         "rect": [17.7, 69.7, 25.0, 84.3]},
                    {"id": "chemical_fertilizer", "rect": [24.3, 52.8, 30.9, 66.2]},
                    {"id": "root_stimulant",      "rect": [36.0, 36.2, 39.7, 47.4]},
                    {"id": "water_bottle",        "rect": [54.9, 58.2, 58.4, 71.8]},
                    {"id": "bio_compost_liquid",  "rect": [61.7, 72.7, 68.7, 88.5]},
                    {"id": "soil_conditioner",    "rect": [65.5, 51.6, 73.6, 67.3]},
                    {"id": "bio_pesticide",       "rect": [64.2, 13.1, 67.8, 22.9]},
                    {"id": "plant_hormone",       "rect": [79.4, 28.2, 83.9, 41.2]},
                ],
            },
            {
                "name": "โรงเรือนเก็บวัสดุและสารเคมี", "art": "game_play_scene/farm_supply_shed.jpeg",
                "hotspots": [
                    {"id": "bug_spray",           "rect": [12.3, 67.0, 25.6, 96.8]},
                    {"id": "chemical_fertilizer", "rect": [14.1, 42.1, 24.0, 58.9]},
                    {"id": "engine_oil",          "rect": [32.0, 30.4, 39.7, 47.2]},
                    {"id": "root_stimulant",      "rect": [53.2, 15.0, 57.9, 28.8]},
                    {"id": "plant_hormone",       "rect": [67.9, 15.7, 76.7, 35.1]},
                    {"id": "water_bottle",        "rect": [55.7, 52.0, 59.4, 68.1]},
                    {"id": "bio_compost_liquid",  "rect": [58.0, 33.9, 66.1, 51.1]},
                    {"id": "dish_soap",           "rect": [75.4, 63.6, 87.0, 88.3]},
                ],
            },
            {
                "name": "โรงซ่อมบำรุงเครื่องจักรฟาร์ม", "art": "game_play_scene/farm_workshop.jpeg",
                "hotspots": [
                    {"id": "nozzle_cleaner",      "rect": [20.7, 40.5, 25.3, 55.9]},
                    {"id": "battery_acid",        "rect": [49.1, 24.3, 53.4, 35.9]},
                    {"id": "lubricant",           "rect": [52.4, 26.1, 59.0, 39.6]},
                    {"id": "water_bottle",        "rect": [37.2, 38.2, 40.6, 50.0]},
                    {"id": "grease",              "rect": [40.9,  8.2, 46.0, 18.5]},
                    {"id": "coolant",             "rect": [55.7, 67.9, 63.3, 82.7]},
                    {"id": "anti_rust",           "rect": [33.7, 42.8, 37.0, 52.9]},
                    {"id": "waterproofing",       "rect": [43.5, 77.8, 49.3, 87.9]},
                    {"id": "gasket_glue",         "rect": [39.1, 18.4, 45.5, 25.6]},
                ],
            },
            {
                "name": "โรงเรือนเลี้ยงสัตว์", "art": "game_play_scene/farm_barn.jpeg",
                "hotspots": [
                    {"id": "rat_poison",          "rect": [40.0,  8.5, 45.4, 22.3]},
                    {"id": "coop_disinfectant",   "rect": [34.7, 60.2, 43.5, 79.2]},
                    {"id": "fungicide",           "rect": [40.7, 35.3, 46.0, 52.0]},
                    {"id": "feed_additive",       "rect": [57.2, 31.3, 68.3, 52.1]},
                    {"id": "wound_spray",         "rect": [70.1, 39.3, 76.0, 56.7]},
                    {"id": "animal_vitamin",      "rect": [19.4, 67.4, 25.1, 80.8]},
                    {"id": "water_bottle",        "rect": [52.2, 50.8, 56.2, 65.5]},
                    {"id": "barn_floor_cleaner",  "rect": [64.2, 71.9, 73.0, 89.2]},
                ],
            },
        ],
    },
}


static func has_level(level_id: String) -> bool:
    return LEVELS.has(level_id)


static func get_level(level_id: String) -> Dictionary:
    return LEVELS.get(level_id, {})


static func room_names(level_id: String) -> Array:
    return get_level(level_id).get("rooms", []).map(func(r): return r["name"])


static func ids_in_level(level_id: String, toxic: bool) -> Array:
    var out: Array = []
    for r in get_level(level_id).get("rooms", []):
        for h in r["hotspots"]:
            if bool(Items.get_item(h["id"]).get("toxic", false)) == toxic:
                out.append(h["id"])
    return out
