extends RefCounted
class_name KingdomProgression

const SAVE_PATH = "user://kingdom_progress.json"
# Cosmetic-only boards. Unlock thresholds are campaign victories, not
# PvP rating; no item, unit or combat modifier reads these fields.
const BOARD_COSTS = [0, 300, 900, 1800]
# The first functional castle loop. Upgrades are earned by raids and
# paid in gold. They grant modest PvE-only benefits, never arena stats.
const CASTLE_BUILDINGS = [
	{"id":"forge","name":"Кузница","description":"Усиливает атаки в рейдах","base_cost":160,"wins":0},
	{"id":"barracks","name":"Казармы","description":"Добавляет здоровье союзникам в рейдах","base_cost":220,"wins":1},
	{"id":"treasury","name":"Казначейство","description":"Увеличивает золото за рейды","base_cost":280,"wins":2},
	{"id":"academy","name":"Академия","description":"Увеличивает опыт за рейды","base_cost":350,"wins":3},
	{"id":"infirmary","name":"Лазарет","description":"Усиливает лечение зельями в рейдах","base_cost":300,"wins":4}
]

static func default_castle() -> Dictionary:
	return {"forge":0,"barracks":0,"treasury":0,"academy":0,"infirmary":0}

static func sanitize_castle(raw: Variant) -> Dictionary:
	var result: Dictionary = default_castle()
	if typeof(raw) != TYPE_DICTIONARY:
		return result
	for key in result.keys():
		var value: Variant = raw.get(key, 0)
		var validated: int = safe_save_int(value, 0, 0, 100)
		# Reject, rather than silently clamp, a forged building level.
		if typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT:
			if float(value) < 0.0 or float(value) > 100.0:
				validated = 0
		result[key] = validated
	return result

static func castle_upgrade_cost(building: Dictionary, current_level: int) -> int:
	# Costs grow steadily; 100 levels provide a substantial long-term goal.
	return int(building["base_cost"]) * (current_level + 1) * (current_level + 1)

static func castle_upgrade_requirement(building: Dictionary, current_level: int) -> int:
	return int(building["wins"]) + current_level * 2

static func castle_upgrade_allowed(building: Dictionary, current_level: int, wins: int, balance: int) -> bool:
	return current_level >= 0 and current_level < 100 and wins >= castle_upgrade_requirement(building, current_level) and balance >= castle_upgrade_cost(building, current_level)

static func castle_bonus(castle: Dictionary, building_id: String) -> int:
	var level: int = clampi(int(castle.get(building_id, 0)), 0, 100)
	match building_id:
		"forge": return mini(30, level * 2)
		"barracks": return mini(100, level * 5)
		"treasury": return mini(50, level * 3)
		"academy": return mini(50, level * 3)
		"infirmary": return mini(30, level * 3)
	return 0

const BOARD_WIN_REQUIREMENTS = [0, 2, 6, 12]

static func sanitize_board_collection(raw: Variant) -> Array:
	var owned: Array = [0]
	if typeof(raw) != TYPE_ARRAY:
		return owned
	for entry in raw:
		if typeof(entry) != TYPE_INT and typeof(entry) != TYPE_FLOAT:
			continue
		var number: float = float(entry)
		if not is_finite(number) or number != float(int(number)):
			continue
		var index: int = int(number)
		if index > 0 and index < BOARD_COSTS.size() and not owned.has(index):
			owned.append(index)
	owned.sort()
	return owned

static func board_unlock_reason(index: int, owned: Array, wins: int, gold: int) -> String:
	if index < 0 or index >= BOARD_COSTS.size():
		return "Неизвестная доска"
	if owned.has(index):
		return "В коллекции"
	if wins < BOARD_WIN_REQUIREMENTS[index]:
		return "Нужно побед в рейдах: %d/%d" % [wins, BOARD_WIN_REQUIREMENTS[index]]
	if gold < BOARD_COSTS[index]:
		return "Не хватает золота: %d/%d" % [gold, BOARD_COSTS[index]]
	return "Доступно за %d золота" % BOARD_COSTS[index]

const HeroRoster = preload("res://scripts/hero_roster.gd")
const RARITIES = ["Обычный", "Необычный", "Редкий", "Эпический", "Легендарный", "Мифический", "Реликтовый"]
const RARITY_WEIGHTS = [42, 28, 16, 8, 4, 1.5, 0.5]
const SLOT_NAMES = {
	"Оружие": ["Клинок пепла", "Меч рассвета", "Копьё бурь", "Коса бездны", "Клинок короля", "Сабля призрака"],
	"Тело": ["Доспех ворона", "Латы стража", "Броня бастиона", "Мантия тумана", "Панцирь дракона", "Доспех титана"],
	"Реликвия": ["Печать сумерек", "Руна затмения", "Кристалл бездны", "Амулет крови", "Око феникса", "Сердце бури"]
}
const PREFIXES = ["Закалённый", "Зачарованный", "Проклятый", "Королевский", "Древний", "Возвышенный", "Вечный"]
const AFFIXES = ["Пробуждение", "Ярость", "Стойкость", "Жатва", "Сокрушение", "Оберег"]
const REGIONS = ["Пепельная крепость", "Ледяной бастион", "Затонувший собор", "Обсидиановая цитадель", "Небесный разлом", "Трон вечной ночи"]
const ENCOUNTERS = ["Штурм", "Осада", "Охота", "Засада", "Разлом"]
const CAMPAIGN = [
	{"title":"Пепельный дозор", "type":"Штурм", "goal":"Прорви передовую и уничтожь Падшего короля.", "enemy":"p", "modifier":"none"},
	{"title":"Стены без знамён", "type":"Осада", "goal":"Пройди через тяжёлую оборону ладей.", "enemy":"r", "modifier":"fortified"},
	{"title":"Пепельный маршал", "type":"Засада", "goal":"Победи командира и открой путь к северу.", "enemy":"b", "modifier":"ambush"},
	{"title":"Белая метель", "type":"Охота", "goal":"Переживи натиск быстрых всадников.", "enemy":"n", "modifier":"frost"},
	{"title":"Ледяные ворота", "type":"Осада", "goal":"Разбей гарнизон ледяного бастиона.", "enemy":"r", "modifier":"fortified"},
	{"title":"Страж вечной зимы", "type":"Разлом", "goal":"Избегай опасной центральной линии.", "enemy":"q", "modifier":"frost"},
	{"title":"Затонувший причал", "type":"Засада", "goal":"Не дай врагам окружить своего короля.", "enemy":"b", "modifier":"ambush"},
	{"title":"Храм глубин", "type":"Штурм", "goal":"Очисти путь через храмовых стражей.", "enemy":"p", "modifier":"poison"},
	{"title":"Сердце собора", "type":"Разлом", "goal":"Сломи проклятие затонувшего собора.", "enemy":"q", "modifier":"poison"},
	{"title":"Обсидиановая тропа", "type":"Охота", "goal":"Останови стремительных охотников.", "enemy":"n", "modifier":"fury"},
	{"title":"Кузницы тьмы", "type":"Осада", "goal":"Разрушь укрепления обсидиановой цитадели.", "enemy":"r", "modifier":"fortified"},
	{"title":"Генерал чёрного камня", "type":"Засада", "goal":"Победи элитный отряд генерала.", "enemy":"b", "modifier":"fury"},
	{"title":"Мост над бездной", "type":"Разлом", "goal":"Пробейся через опасный небесный мост.", "enemy":"q", "modifier":"rift"},
	{"title":"Стражи небес", "type":"Охота", "goal":"Сдержи штурм небесной кавалерии.", "enemy":"n", "modifier":"fury"},
	{"title":"Разорванное небо", "type":"Разлом", "goal":"Преодолей нестабильную магию разлома.", "enemy":"q", "modifier":"rift"},
	{"title":"Врата вечной ночи", "type":"Осада", "goal":"Победи стражей последнего бастиона.", "enemy":"r", "modifier":"fortified"},
	{"title":"Совет теней", "type":"Засада", "goal":"Разбей элитных советников короля.", "enemy":"b", "modifier":"poison"},
	{"title":"Последняя корона", "type":"Разлом", "goal":"Одержи решающую победу над Падшим королём.", "enemy":"q", "modifier":"rift"}
]
const SET_NAMES = ["Пепельный легион", "Ледяная стража", "Бездонная бездна", "Золотой рассвет", "Проклятый трон", "Звёздный орден"]
const BOSS_RARITY_WEIGHTS = [8, 20, 27, 23, 14, 6, 2]
const ITEM_SLOTS = ["Оружие", "Тело", "Реликвия"]
const TRAITS = ["Огненный удар", "Ледяной щит", "Грозовой разряд", "Возрождение", "Ядовитое лезвие", "Казнь"]
const TRAIT_DESCRIPTIONS = [
	"Каждая третья атака наносит дополнительный огненный урон.",
	"Первый полученный удар за раунд ослабляется.",
	"При критическом ударе молния поражает дополнительную цель.",
	"Один раз за битву спасает героя от смертельного удара.",
	"Атаки накладывают яд, который срабатывает в конце раунда.",
	"Урон повышается по врагам с низким запасом здоровья."
]

static func load_profile() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return default_profile()
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return default_profile()
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return default_profile()
	return sanitize_profile(parsed)

static func safe_save_int(value: Variant, fallback: int, minimum: int, maximum: int) -> int:
	# Never coerce malformed JSON strings, booleans, fractions or huge numbers.
	if typeof(value) != TYPE_INT and typeof(value) != TYPE_FLOAT:
		return fallback
	var number := float(value)
	if not is_finite(number) or absf(number) > 1000000000.0 or number != float(int(number)):
		return fallback
	return clampi(int(number), minimum, maximum)

static func sanitize_profile(parsed: Dictionary) -> Dictionary:
	var profile: Dictionary = default_profile()
	for key in profile.keys():
		if parsed.has(key):
			profile[key] = parsed[key]
	profile["level"] = safe_save_int(profile["level"], 1, 1, 50)
	profile["xp"] = safe_save_int(profile["xp"], 0, 0, 1000000000)
	profile["gold"] = safe_save_int(profile["gold"], 0, 0, 1000000000)
	profile["potions"] = safe_save_int(profile["potions"], 2, 0, 99)
	profile["wins"] = safe_save_int(profile["wins"], 0, 0, 1000000000)
	profile["dry_streak"] = safe_save_int(profile["dry_streak"], 0, 0, 100)
	profile["selected_hero"] = HeroRoster.valid_selection(str(profile.get("selected_hero", "hero_01")), int(profile["wins"]), int(profile["level"]))
	profile["castle"] = sanitize_castle(profile.get("castle", {}))
	profile["owned_boards"] = sanitize_board_collection(profile.get("owned_boards", [0]))
	profile["selected_board"] = safe_save_int(profile.get("selected_board", 0), 0, 0, BOARD_COSTS.size() - 1)
	if not profile["owned_boards"].has(profile["selected_board"]):
		profile["selected_board"] = 0
	if typeof(profile["items"]) != TYPE_ARRAY:
		profile["items"] = []
	if typeof(profile.get("slots")) != TYPE_DICTIONARY:
		profile["slots"] = {"Оружие":-1,"Тело":-1,"Реликвия":-1}
	# Compact invalid inventory entries without changing which valid items are equipped.
	# Saved slot indices refer to the old array and must be remapped after compaction.
	var cleaned_items: Array = []
	var index_map: Dictionary = {}
	for old_index in range(profile["items"].size()):
		var entry: Variant = profile["items"][old_index]
		if typeof(entry) == TYPE_DICTIONARY and is_valid_equipment_item(entry):
			index_map[old_index] = cleaned_items.size()
			cleaned_items.append(entry)
	var remapped_slots: Dictionary = {}
	for slot in ITEM_SLOTS:
		var raw_index: Variant = profile["slots"].get(slot, -1)
		remapped_slots[slot] = -1
		if typeof(raw_index) != TYPE_INT and typeof(raw_index) != TYPE_FLOAT:
			continue
		if not is_finite(float(raw_index)) or absf(float(raw_index)) > 1000000.0:
			continue
		if float(raw_index) != float(int(raw_index)):
			continue
		if index_map.has(int(raw_index)):
			remapped_slots[slot] = index_map[int(raw_index)]
	profile["items"] = cleaned_items
	profile["slots"] = sanitize_equipment_slots(cleaned_items, remapped_slots, int(profile["level"]), int(profile["wins"]))
	profile["equipped"] = int(profile["slots"]["Оружие"])
	return profile

static func sanitize_equipment_slots(items: Array, slots: Dictionary, level: int, wins: int = 100000) -> Dictionary:
	# Save files can contain stale indices after selling gear, wrong-slot gear or level-locked gear.
	var valid := {}
	for slot in ITEM_SLOTS:
		var raw_index: Variant = slots.get(slot, -1)
		valid[slot] = -1
		# Do not coerce strings, booleans or fractional JSON numbers into valid inventory indices.
		if typeof(raw_index) != TYPE_INT and typeof(raw_index) != TYPE_FLOAT:
			continue
		if not is_finite(float(raw_index)) or float(raw_index) != float(int(raw_index)):
			continue
		var index := int(raw_index)
		if index < 0 or index >= items.size():
			continue
		if typeof(items[index]) != TYPE_DICTIONARY:
			continue
		var item: Dictionary = items[index]
		if not is_valid_equipment_item(item) or str(item["slot"]) != slot or not can_equip(item, wins, level):
			continue
		valid[slot] = index
	return valid

static func is_valid_equipment_item(item: Dictionary) -> bool:
	# Treat loaded inventory as untrusted JSON: invalid equipment must not grant combat bonuses.
	if not ITEM_SLOTS.has(item.get("slot", null)):
		return false
	for field in ["level", "rarity", "power", "upgrade", "set_id", "trait_id", "attack", "armor", "hp", "crit", "lifesteal", "penetration", "block", "bleed"]:
		var value: Variant = item.get(field)
		if typeof(value) != TYPE_INT and typeof(value) != TYPE_FLOAT:
			return false
		# JSON can carry fractional, infinite or enormous values: never truncate these into bonuses.
		if not is_finite(float(value)) or absf(float(value)) > 1000000.0 or float(value) != float(int(value)):
			return false
	if int(item["level"]) < 1 or int(item["level"]) > 50:
		return false
	if int(item["rarity"]) < 0 or int(item["rarity"]) >= RARITIES.size():
		return false
	if int(item["upgrade"]) < 0 or int(item["upgrade"]) > 12:
		return false
	if int(item["set_id"]) < -1 or int(item["set_id"]) >= SET_NAMES.size():
		return false
	if int(item["trait_id"]) < -1 or int(item["trait_id"]) >= TRAITS.size():
		return false
	# Never trust a locally edited save to inject million-point combat gear.
	# The procedural generator stays far below these generous hard ceilings.
	for stat in ["power", "attack", "armor", "hp"]:
		if int(item[stat]) < 0 or int(item[stat]) > 10000:
			return false
	for stat in ["crit", "lifesteal", "penetration", "block", "bleed"]:
		if int(item[stat]) < 0:
			return false
	for percent in ["crit", "lifesteal", "penetration", "block", "bleed"]:
		if int(item[percent]) > 100:
			return false
	return true

static func default_profile() -> Dictionary:
	return {"level":1, "xp":0, "gold":0, "potions":2, "items":[], "equipped":-1, "slots":{"Оружие":-1,"Тело":-1,"Реликвия":-1}, "wins":0, "dry_streak":0, "selected_hero":"hero_01", "owned_boards":[0], "selected_board":0, "castle":default_castle()}

static func save_profile(profile: Dictionary) -> bool:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(profile))
	file.flush()
	return true

# The campaign sets a hard power ceiling. Rarity and upgrades are earned, not rolled on day one.
static func rarity_cap(wins: int, level: int) -> int:
	var chapter_cap: int = clampi(int(wins / 3.0), 0, 6)
	var level_cap: int = clampi(int((level - 1) / 5.0), 0, 6)
	return mini(chapter_cap, level_cap)

static func upgrade_cap(wins: int, level: int) -> int:
	return mini(12, mini(2 + int(wins / 3.0) * 2, 2 + int((level - 1) / 5.0) * 2))

static func can_equip(item: Dictionary, wins: int, level: int) -> bool:
	return is_valid_equipment_item(item) and int(item["level"]) <= level and int(item["rarity"]) <= rarity_cap(wins, level) and int(item["upgrade"]) <= upgrade_cap(wins, level)

static func limit_reward_to_progress(item: Dictionary, wins: int, level: int) -> Dictionary:
	var result: Dictionary = item.duplicate(true)
	var cap: int = rarity_cap(wins, level)
	result["rarity"] = mini(int(result.get("rarity", 0)), cap)
	if int(result["rarity"]) < 3: result["set_id"] = -1
	if int(result["rarity"]) < 4: result["trait_id"] = -1
	result["upgrade"] = mini(int(result.get("upgrade", 0)), upgrade_cap(wins, level))
	return result

static func roll_item_for_progress(level: int, wins: int, boss: bool = false, luck: int = 0) -> Dictionary:
	# Reward must be usable immediately: random item level can roll +1 above
	# the player, while rarity is independently gated by wins AND level.
	var player_level: int = clampi(level, 1, 50)
	var item: Dictionary = roll_item(player_level, boss, luck)
	var cap: int = rarity_cap(wins, player_level)
	if int(item["rarity"]) <= cap and int(item["level"]) <= player_level:
		return item
	for attempt in range(40):
		item = roll_item(player_level, boss, 0)
		if int(item["rarity"]) <= cap and int(item["level"]) <= player_level:
			return item
	# Preserve actual generated combat stats; only the legal rarity/level
	# gates are lowered. Recalculate neither attack nor armor upward.
	item = limit_reward_to_progress(item, wins, player_level)
	item["level"] = mini(int(item["level"]), player_level)
	return item

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
	var set_id := rng.randi_range(0, SET_NAMES.size() - 1) if rarity >= 3 else -1
	var trait_id := rng.randi_range(0, TRAITS.size() - 1) if rarity >= 4 else -1
	var name: String = SLOT_NAMES[slot][rng.randi_range(0, SLOT_NAMES[slot].size() - 1)]
	if rarity >= 2:
		name = PREFIXES[rarity] + " " + name
	if rarity >= 4:
		name += " • " + AFFIXES[affix]
	if set_id >= 0:
		name = SET_NAMES[set_id] + ": " + name
	if trait_id >= 0:
		name += " • " + TRAITS[trait_id]
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
		"power": power, "affix": AFFIXES[affix], "set_id": set_id, "upgrade": 0, "trait_id": trait_id,
		"attack": attack, "armor": armor, "hp": hp,
		"crit": crit, "lifesteal": lifesteal,
		"penetration": penetration, "block": block, "bleed": bleed
	}

static func first_clear_reward(wins: int) -> Dictionary:
	# Hand-authored milestone rewards replace repeating random drops at chapter endings.
	var chapter := int(wins / 3.0)
	if wins <= 0 or wins % 3 != 0 or chapter > REGIONS.size():
		return {}
	var slot: String = ITEM_SLOTS[(chapter - 1) % ITEM_SLOTS.size()]
	var trait_id := (chapter - 1) % TRAITS.size()
	var set_id := chapter - 1
	var rarity := mini(6, 3 + int(chapter / 2.0))
	var power := 15 + chapter * 12
	return {
		"name": "Наследие " + REGIONS[chapter - 1],
		"slot": slot, "rarity": rarity, "level": maxi(1, chapter * 3 - 2),
		"power": power, "affix": "Наследие", "set_id": set_id, "upgrade": 0, "trait_id": trait_id,
		"attack": power if slot == "Оружие" else int(power * 0.25),
		"armor": power if slot == "Тело" else int(power * 0.12),
		"hp": power * 3 if slot == "Тело" else power,
		"crit": 3 + chapter if slot == "Оружие" else 0,
		"lifesteal": 2 + chapter if slot == "Реликвия" else 0,
		"penetration": chapter * 3 if slot == "Оружие" else 0,
		"block": chapter * 3 if slot == "Тело" else 0,
		"bleed": 0
	}

static func region_for_run(wins: int) -> String:
	return REGIONS[clampi(int(wins / 3.0), 0, REGIONS.size() - 1)]

static func boss_hazard_cells(stage: int, next_round: int, encounter: String) -> Array[int]:
	var cells: Array[int] = []
	if next_round <= 0: return cells
	for i in range(64):
		var threatened := false
		match stage:
			2: threatened = next_round % 3 == 0 and int(i / 8) <= 3
			5: threatened = next_round % 3 == 0 and i % 8 in [2, 5]
			6: threatened = next_round % 3 == 0
		if encounter == "Разлом" and next_round % 4 == 0 and i % 8 == 4:
			threatened = true
		if threatened: cells.append(i)
	return cells

static func hazard_cells(modifier: String, next_round: int) -> Array[int]:
	var cells: Array[int] = []
	if next_round <= 0: return cells
	match modifier:
		"frost":
			if next_round % 3 == 0:
				for i in range(64):
					if int(i / 8) <= 4: cells.append(i)
		"poison":
			if next_round % 3 == 0:
				for i in range(64):
					if i % 8 in [1, 6]: cells.append(i)
		"rift":
			if next_round % 3 == 0:
				for i in range(64):
					if i % 8 in [3, 4]: cells.append(i)
	return cells

static func mission_for_run(wins: int) -> Dictionary:
	if wins < CAMPAIGN.size():
		return CAMPAIGN[clampi(wins, 0, CAMPAIGN.size() - 1)].duplicate(true)
	# Post-campaign expeditions are generated from independent modifiers, not a fixed five-stage loop.
	var expedition := maxi(0, wins - CAMPAIGN.size())
	var seed := (expedition * 1103515245 + 12345) & 0x7fffffff
	var encounter: String = str(ENCOUNTERS[seed % ENCOUNTERS.size()])
	var modifier_names := ["fury", "frost", "poison", "fortified", "rift", "ambush"]
	var modifier: String = modifier_names[int(seed / 7) % modifier_names.size()]
	return {"title":"Экспедиция №%d" % (expedition + 1), "type":encounter,
		"goal":"Выживи в экспедиции и получи материалы для улучшения снаряжения.",
		"enemy":"q" if modifier == "rift" else "n", "modifier":modifier}

static func encounter_for_run(wins: int) -> String:
	return str(mission_for_run(wins).get("type", "Штурм"))

static func upgrade_cost(item: Dictionary) -> int:
	var tier := clampi(int(item.get("upgrade", 0)), 0, 12)
	return (tier + 1) * (tier + 1) * 45 + int(item.get("level", 1)) * 12 + int(item.get("rarity", 0)) * 55

static func upgrade_item(item: Dictionary) -> Dictionary:
	var result := item.duplicate(true)
	var tier := clampi(int(result.get("upgrade", 0)), 0, 12)
	if tier >= 12:
		return result
	result["upgrade"] = tier + 1
	var scale := 1.0 + (0.10 if tier < 4 else (0.07 if tier < 8 else 0.04))
	for stat in ["attack", "armor", "hp"]:
		var base: int = int(result.get(stat, 0))
		if base > 0:
			result[stat] = maxi(base + 1, int(ceil(base * scale)))
	if (tier + 1) % 3 == 0:
		for stat in ["crit", "block", "lifesteal", "penetration", "bleed"]:
			if int(result.get(stat, 0)) > 0:
				result[stat] = mini(50, int(result[stat]) + 1)
	return result

static func set_bonus(items: Array, slots: Dictionary) -> Dictionary:
	var counts: Dictionary = {}
	for slot in ITEM_SLOTS:
		var index: int = int(slots.get(slot, -1))
		if index < 0 or index >= items.size():
			continue
		if typeof(items[index]) != TYPE_DICTIONARY:
			continue
		var item: Dictionary = items[index]
		if not is_valid_equipment_item(item) or str(item["slot"]) != slot:
			continue
		var set_id: int = int(item["set_id"])
		if set_id >= 0:
			counts[set_id] = int(counts.get(set_id, 0)) + 1
	var bonus := {"attack": 0, "armor": 0, "hp": 0, "crit": 0, "lifesteal": 0}
	for set_id in counts:
		if counts[set_id] >= 2:
			bonus["attack"] += 12 + int(set_id) * 3
			bonus["hp"] += 35
		if counts[set_id] >= 3:
			bonus["armor"] += 18
			bonus["crit"] += 5
			bonus["lifesteal"] += 3
	return bonus

static func damage_after_armor(raw: int, armor: int, penetration: int = 0) -> int:
	var effective_armor := maxi(0, armor - maxi(0, penetration))
	return maxi(1, int(ceil(float(maxi(1, raw)) * 100.0 / (100.0 + float(effective_armor) * 2.0))))

static func item_score(item: Dictionary) -> int:
	return int(item.get("attack", 0)) * 3 + int(item.get("armor", 0)) * 2 + int(item.get("hp", 0)) / 5 + int(item.get("crit", 0)) * 3 + int(item.get("lifesteal", 0)) * 4 + int(item.get("penetration", 0)) * 2 + int(item.get("block", 0)) * 3 + int(item.get("bleed", 0)) * 3

static func sell_price(item: Dictionary) -> int:
	return 10 + int(item.get("level", 1)) * 6 + int(item.get("rarity", 0)) * 35 + int(item.get("power", 0)) * 2

static func experience_needed(level: int) -> int:
	return 100 + (level - 1) * 45
