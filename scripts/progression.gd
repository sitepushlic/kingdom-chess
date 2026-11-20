extends RefCounted
class_name KingdomProgression

const SAVE_PATH = "user://kingdom_progress.json"
const RARITIES = ["Обычный", "Необычный", "Редкий", "Эпический", "Легендарный", "Мифический", "Реликтовый"]
const RARITY_WEIGHTS = [42, 28, 16, 8, 4, 1.5, 0.5]
const ITEM_NAMES = ["Клинок пепла", "Печать сумерек", "Корона стража", "Руна затмения", "Доспех ворона", "Кристалл бездны"]

static func load_profile() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return default_profile()
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return default_profile()
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return default_profile()
	var profile: Dictionary = default_profile()
	for key in profile.keys():
		if parsed.has(key):
			profile[key] = parsed[key]
	profile["level"] = clampi(int(profile["level"]), 1, 50)
	profile["xp"] = maxi(0, int(profile["xp"]))
	profile["gold"] = maxi(0, int(profile["gold"]))
	profile["potions"] = clampi(int(profile["potions"]), 0, 99)
	if typeof(profile["items"]) != TYPE_ARRAY:
		profile["items"] = []
	return profile

static func default_profile() -> Dictionary:
	return {"level":1, "xp":0, "gold":0, "potions":2, "items":[], "equipped":-1, "wins":0}

static func save_profile(profile: Dictionary) -> bool:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(profile))
	file.flush()
	return true

static func roll_item(level: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var total := 0.0
	for weight in RARITY_WEIGHTS:
		total += weight
	var roll := rng.randf_range(0.0, total)
	var rarity := 0
	for i in range(RARITY_WEIGHTS.size()):
		roll -= RARITY_WEIGHTS[i]
		if roll <= 0.0:
			rarity = i
			break
	var item_level := clampi(level + rng.randi_range(-1, 1), 1, 50)
	var bonus := 2 + item_level + rarity * 3 + rng.randi_range(0, 3)
	return {
		"name": ITEM_NAMES[rng.randi_range(0, ITEM_NAMES.size() - 1)],
		"rarity": rarity,
		"level": item_level,
		"attack": bonus
	}

static func experience_needed(level: int) -> int:
	return 100 + (level - 1) * 45
