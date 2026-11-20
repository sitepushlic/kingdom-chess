extends RefCounted
class_name KingdomProgression

const SAVE_PATH = "user://kingdom_progress.json"
const RARITIES = ["Обычный", "Необычный", "Редкий", "Эпический", "Легендарный", "Мифический", "Реликтовый"]
const RARITY_WEIGHTS = [42, 28, 16, 8, 4, 1.5, 0.5]
const SLOT_NAMES = {
	"Оружие": ["Клинок пепла", "Меч рассвета", "Копьё бурь", "Коса бездны", "Клинок короля", "Сабля призрака"],
	"Тело": ["Доспех ворона", "Латы стража", "Броня бастиона", "Мантия тумана", "Панцирь дракона", "Доспех титана"],
	"Реликвия": ["Печать сумерек", "Руна затмения", "Кристалл бездны", "Амулет крови", "Око феникса", "Сердце бури"]
}
const PREFIXES = ["Закалённый", "Зачарованный", "Проклятый", "Королевский", "Древний", "Возвышенный", "Вечный"]
const AFFIXES = ["Пробуждение", "Ярость", "Стойкость", "Жатва", "Сокрушение", "Оберег"]
const BOSS_RARITY_WEIGHTS = [8, 20, 27, 23, 14, 6, 2]
const ITEM_SLOTS = ["Оружие", "Тело", "Реликвия"]

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
	profile["dry_streak"] = clampi(int(profile.get("dry_streak", 0)), 0, 100)
	if typeof(profile["items"]) != TYPE_ARRAY:
		profile["items"] = []
	if typeof(profile.get("slots")) != TYPE_DICTIONARY:
		profile["slots"] = {"Оружие":-1,"Тело":-1,"Реликвия":-1}
	for slot in ITEM_SLOTS:
		profile["slots"][slot] = clampi(int(profile["slots"].get(slot, -1)), -1, profile["items"].size()-1)
	return profile

static func default_profile() -> Dictionary:
	return {"level":1, "xp":0, "gold":0, "potions":2, "items":[], "equipped":-1, "slots":{"Оружие":-1,"Тело":-1,"Реликвия":-1}, "wins":0, "dry_streak":0}

static func save_profile(profile: Dictionary) -> bool:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(profile))
	file.flush()
	return true

static func roll_item(level: int, boss: bool = false, luck: int = 0) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var weights: Array = BOSS_RARITY_WEIGHTS if boss else RARITY_WEIGHTS
	var total := 0.0
	for weight in weights:
		total += float(weight)
	var roll := rng.randf_range(0.0, total)
	var rarity := weights.size() - 1
	for i in range(weights.size()):
		roll -= float(weights[i])
		if roll <= 0.0:
			rarity = i
			break
	rarity = clampi(rarity + clampi(luck, 0, 3), 0, 6)
	var item_level := clampi(level + rng.randi_range(-1, 1), 1, 50)
	var slot: String = ITEM_SLOTS[rng.randi_range(0, ITEM_SLOTS.size() - 1)]
	var power := 4 + item_level * 2 + rarity * (4 + int(item_level / 8.0)) + rng.randi_range(0, 5)
	var affix := rng.randi_range(0, AFFIXES.size() - 1)
	var name: String = SLOT_NAMES[slot][rng.randi_range(0, SLOT_NAMES[slot].size() - 1)]
	if rarity >= 2:
		name = PREFIXES[rarity] + " " + name
	if rarity >= 4:
		name += " • " + AFFIXES[affix]
	var attack := power if slot == "Оружие" else int(power * (0.18 if slot == "Тело" else 0.35))
	var armor := int(power * (0.72 if slot == "Тело" else 0.08))
	var hp := power * (3 if slot == "Тело" else (1 if slot == "Реликвия" else 0))
	var crit := mini(35, (2 + rarity * 3 + int(power / 12.0)) if slot == "Оружие" else (rarity if slot == "Реликвия" else 0))
	var lifesteal := mini(24, (2 + rarity * 2) if slot == "Реликвия" else 0)
	var penetration := mini(45, (rarity * 3 + int(power / 9.0)) if slot == "Оружие" else 0)
	var block := mini(35, (2 + rarity * 3) if slot == "Тело" else 0)
	var bleed := mini(30, (rarity * 2 + int(power / 15.0)) if slot == "Оружие" and affix == 3 else 0)
	return {
		"name": name, "slot": slot, "rarity": rarity, "level": item_level,
		"power": power, "affix": AFFIXES[affix],
		"attack": attack, "armor": armor, "hp": hp,
		"crit": crit, "lifesteal": lifesteal,
		"penetration": penetration, "block": block, "bleed": bleed
	}

static func damage_after_armor(raw: int, armor: int, penetration: int = 0) -> int:
	var effective_armor := maxi(0, armor - maxi(0, penetration))
	return maxi(1, int(ceil(float(maxi(1, raw)) * 100.0 / (100.0 + float(effective_armor) * 2.0))))

static func item_score(item: Dictionary) -> int:
	return int(item.get("attack", 0)) * 3 + int(item.get("armor", 0)) * 2 + int(item.get("hp", 0)) / 5 + int(item.get("crit", 0)) * 3 + int(item.get("lifesteal", 0)) * 4 + int(item.get("penetration", 0)) * 2 + int(item.get("block", 0)) * 3 + int(item.get("bleed", 0)) * 3

static func sell_price(item: Dictionary) -> int:
	return 10 + int(item.get("level", 1)) * 6 + int(item.get("rarity", 0)) * 35 + int(item.get("power", 0)) * 2

static func experience_needed(level: int) -> int:
	return 100 + (level - 1) * 45
