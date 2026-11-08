extends RefCounted
## The five locations. Each pulls its items from the shared THItems pool, so a
## teacher tunes difficulty here (time, how many toxic/safe items, which rooms)
## without touching gameplay code.
##
## Per level:
##   name, subtitle, stars (1-5), time  (seconds)
##   rooms   list of room labels shown in the room switcher
##   toxic   item ids that ARE toxic and count toward the checklist
##   safe    item ids that are decoys - safe look-alikes
##   accent  theme colour for the level card and room tint
class_name THLevels

const LIST := [
	{
		"id": "condo", "name": "คอนโด", "subtitle": "ห้องเดี่ยวกลางเมือง",
		"stars": 1, "time": 120, "accent": Color("4FA6E0"),
		# painted rooms: hotspot positions + room order live in
		# data/painted_rooms.gd. Only hotspots whose id is listed below are
		# clickable, so these lists decide the round (and the "?" count).
		"rooms": ["ห้องนอน", "ห้องนั่งเล่น", "ห้องน้ำ"],
		"toxic": ["bleach", "glass_cleaner", "dish_soap", "teflon_pan"],
		"safe": ["water_bottle", "soy_sauce", "alcohol_gel", "vinegar",
			"sleeping_pills", "correction_fluid", "hand_gel", "lotion", "mouthwash",
			"body_scrub", "shower_cream"],
	},
	{
		"id": "house", "name": "บ้าน", "subtitle": "บ้านเดี่ยวพร้อมสวน",
		"stars": 2, "time": 180, "accent": Color("6BC24A"),
		# painted rooms (data/painted_rooms.gd): only ids listed here are live
		"rooms": ["ห้องครัว", "ห้องรับแขก", "ห้องนอน", "ห้องน้ำ"],
		"toxic": ["toilet_cleaner", "mothballs", "air_freshener", "termite_killer", "house_paint"],
		"safe": ["soy_sauce", "vinegar", "baking_soda", "water_bottle", "alcohol_gel",
			"cough_syrup", "correction_fluid", "baby_powder", "sleeping_pills",
			"fever_medicine", "hand_gel", "shower_cream", "herbal_shampoo", "face_wash",
			"mouthwash", "fabric_softener"],
	},
	{
		"id": "school", "name": "โรงเรียน", "subtitle": "ห้องเรียนและห้องแล็บ",
		"stars": 3, "time": 180, "accent": Color("F0A83D"),
		# painted rooms (data/painted_rooms.gd): only ids listed here are live
		"rooms": ["ห้องศิลปะ", "ห้องวิทยาศาสตร์", "ห้องพยาบาล", "โรงอาหาร"],
		"toxic": ["sulfuric_acid", "mercury", "thinner", "spray_paint", "floor_cleaner"],
		"safe": ["gloss_varnish", "latex_glue", "oil_paint", "turpentine", "syrup",
			"food_coloring", "vinegar", "mouthwash", "rubbing_alcohol", "saline",
			"cough_syrup", "red_antiseptic", "liniment", "soy_sauce", "baking_soda"],
	},
	{
		"id": "factory", "name": "โรงงาน", "subtitle": "สายผลิตและโกดังเคมี",
		"stars": 4, "time": 240, "accent": Color("E06A5B"),
		# painted rooms (data/painted_rooms.gd): only ids listed here are live
		"rooms": ["ห้องวิจัยและประกันคุณภาพ", "ห้องฝ่ายผลิต", "ห้องซ่อมบำรุงและสาธารณูปโภค", "ห้องเก็บของและสารเคมี"],
		"toxic": ["industrial_glue", "arsenic", "sodium_cyanide", "phosphoric_acid", "rust_remover"],
		"safe": ["food_coloring", "ethanol_wash", "hand_soap", "alum",
			"distilled_solution", "distilled_water", "grease", "machine_oil",
			"correction_fluid", "water_bottle", "anti_moisture_spray", "gasket_glue",
			"leak_sealant", "lubricant", "pipe_cement", "system_cleaner", "engine_oil",
			"rubbing_alcohol", "saline"],
	},
	{
		"id": "farm", "name": "ฟาร์ม", "subtitle": "แปลงผักและโรงเก็บ",
		"stars": 5, "time": 240, "accent": Color("9E7B3C"),
		# painted rooms (data/painted_rooms.gd): only ids listed here are live
		"rooms": ["โรงเพาะชำ", "โรงเรือนเก็บวัสดุและสารเคมี", "โรงซ่อมบำรุงเครื่องจักรฟาร์ม", "โรงเรือนเลี้ยงสัตว์"],
		"toxic": ["bug_spray", "weed_killer", "rat_poison", "nozzle_cleaner", "battery_acid"],
		"safe": ["chemical_fertilizer", "root_stimulant", "water_bottle",
			"bio_compost_liquid", "soil_conditioner", "bio_pesticide", "plant_hormone",
			"engine_oil", "lubricant", "grease", "coolant", "anti_rust",
			"waterproofing", "gasket_glue", "coop_disinfectant", "fungicide",
			"feed_additive", "wound_spray", "animal_vitamin", "barn_floor_cleaner"],
	},
]

## Room background art keyed by level id (used by the 2.5D backdrop mode and as
## a wall texture reference in 3D mode).
const ROOM_ART := {
	"condo": "res://assets/ui/ai_room_condo.png",
	"house": "res://assets/ui/ai_room_house.png",
	"school": "res://assets/ui/ai_room_school.png",
	"factory": "res://assets/ui/ai_room_factory.png",
	"farm": "res://assets/ui/ai_room_farm.png",
}


static func by_id(id: String) -> Dictionary:
	for lv in LIST:
		if lv["id"] == id:
			return lv
	return {}
