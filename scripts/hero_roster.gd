extends RefCounted
## Authored 30-character collection; high tiers are earned through gameplay milestones.
const HEROES = [
	{
		"id": "hero_01",
		"name": "Аэлин",
		"title": "Страж рассвета",
		"piece": "K",
		"rarity": 0,
		"role": "Бастион",
		"story": "Хранительница первого маяка, отказавшаяся от короны.",
		"quest": "Доступен с начала",
		"wins": 0,
		"level": 1,
		"attack": 2,
		"armor": 1,
		"hp": 8,
		"crit": 0
	},
	{
		"id": "hero_02",
		"name": "Бран",
		"title": "Пепельный мечник",
		"piece": "N",
		"rarity": 0,
		"role": "Натиск",
		"story": "Бывший оруженосец, переживший падение крепости.",
		"quest": "Доступен с начала",
		"wins": 0,
		"level": 1,
		"attack": 3,
		"armor": 2,
		"hp": 11,
		"crit": 1
	},
	{
		"id": "hero_03",
		"name": "Мира",
		"title": "Лесная следопытка",
		"piece": "B",
		"rarity": 0,
		"role": "Точность",
		"story": "Видит тропы, скрытые от королевских карт.",
		"quest": "Доступен с начала",
		"wins": 0,
		"level": 1,
		"attack": 4,
		"armor": 3,
		"hp": 14,
		"crit": 2
	},
	{
		"id": "hero_04",
		"name": "Торен",
		"title": "Кузнец клятв",
		"piece": "R",
		"rarity": 0,
		"role": "Бастион",
		"story": "Выковал щит из ворот сожжённого города.",
		"quest": "Доступен с начала",
		"wins": 0,
		"level": 1,
		"attack": 2,
		"armor": 4,
		"hp": 17,
		"crit": 0
	},
	{
		"id": "hero_05",
		"name": "Лисса",
		"title": "Искра улиц",
		"piece": "P",
		"rarity": 0,
		"role": "Натиск",
		"story": "Разведчица, спасшая сотню жителей из осады.",
		"quest": "Доступен с начала",
		"wins": 0,
		"level": 1,
		"attack": 3,
		"armor": 1,
		"hp": 20,
		"crit": 1
	},
	{
		"id": "hero_06",
		"name": "Орвин",
		"title": "Хранитель рун",
		"piece": "Q",
		"rarity": 0,
		"role": "Магия",
		"story": "Учёный, расшифровавший язык древних шахмат.",
		"quest": "Доступен с начала",
		"wins": 0,
		"level": 1,
		"attack": 4,
		"armor": 2,
		"hp": 8,
		"crit": 2
	},
	{
		"id": "hero_07",
		"name": "Вейра",
		"title": "Ледяная дуэлянтка",
		"piece": "N",
		"rarity": 1,
		"role": "Натиск",
		"story": "Поклялась победить зимнего генерала его же клинком.",
		"quest": "Победить 2 боссов кампании",
		"wins": 2,
		"level": 1,
		"attack": 6,
		"armor": 6,
		"hp": 27,
		"crit": 1
	},
	{
		"id": "hero_08",
		"name": "Кадор",
		"title": "Часовой перевала",
		"piece": "R",
		"rarity": 1,
		"role": "Бастион",
		"story": "Последний страж замёрзшего моста.",
		"quest": "Победить 3 боссов кампании",
		"wins": 3,
		"level": 1,
		"attack": 7,
		"armor": 7,
		"hp": 30,
		"crit": 2
	},
	{
		"id": "hero_09",
		"name": "Селена",
		"title": "Певица приливов",
		"piece": "B",
		"rarity": 1,
		"role": "Магия",
		"story": "Слышит голоса затонувшего собора.",
		"quest": "Победить 4 боссов кампании",
		"wins": 4,
		"level": 1,
		"attack": 8,
		"armor": 4,
		"hp": 33,
		"crit": 3
	},
	{
		"id": "hero_10",
		"name": "Рагнар",
		"title": "Волчий капитан",
		"piece": "K",
		"rarity": 1,
		"role": "Бастион",
		"story": "Объединил изгнанников против ледяной армии.",
		"quest": "Победить 5 боссов кампании",
		"wins": 5,
		"level": 1,
		"attack": 6,
		"armor": 5,
		"hp": 36,
		"crit": 1
	},
	{
		"id": "hero_11",
		"name": "Эшра",
		"title": "Ядовитая тень",
		"piece": "N",
		"rarity": 2,
		"role": "Точность",
		"story": "Победила алхимиков их собственным ядом.",
		"quest": "Победить 6 боссов кампании",
		"wins": 6,
		"level": 1,
		"attack": 11,
		"armor": 9,
		"hp": 40,
		"crit": 3
	},
	{
		"id": "hero_12",
		"name": "Дарион",
		"title": "Рыцарь глубин",
		"piece": "R",
		"rarity": 2,
		"role": "Бастион",
		"story": "Вернулся из собора, где исчез его отряд.",
		"quest": "Победить 7 боссов кампании",
		"wins": 7,
		"level": 1,
		"attack": 12,
		"armor": 10,
		"hp": 43,
		"crit": 4
	},
	{
		"id": "hero_13",
		"name": "Немора",
		"title": "Оракул бездны",
		"piece": "Q",
		"rarity": 2,
		"role": "Магия",
		"story": "Пожертвовала памятью ради пророчества.",
		"quest": "Победить 8 боссов кампании",
		"wins": 8,
		"level": 1,
		"attack": 10,
		"armor": 7,
		"hp": 46,
		"crit": 2
	},
	{
		"id": "hero_14",
		"name": "Фарис",
		"title": "Охотник за масками",
		"piece": "B",
		"rarity": 2,
		"role": "Точность",
		"story": "Знает имена всех предателей совета.",
		"quest": "Победить 9 боссов кампании",
		"wins": 9,
		"level": 1,
		"attack": 11,
		"armor": 8,
		"hp": 49,
		"crit": 3
	},
	{
		"id": "hero_15",
		"name": "Кайра",
		"title": "Обсидиановый клинок",
		"piece": "N",
		"rarity": 3,
		"role": "Натиск",
		"story": "Её меч расколол чёрный монолит.",
		"quest": "Победить 10 боссов кампании",
		"wins": 10,
		"level": 1,
		"attack": 16,
		"armor": 12,
		"hp": 68,
		"crit": 5
	},
	{
		"id": "hero_16",
		"name": "Гримвольд",
		"title": "Железный маршал",
		"piece": "R",
		"rarity": 3,
		"role": "Бастион",
		"story": "Восстал против собственного легиона.",
		"quest": "Победить 11 боссов кампании",
		"wins": 11,
		"level": 1,
		"attack": 14,
		"armor": 13,
		"hp": 56,
		"crit": 3
	},
	{
		"id": "hero_17",
		"name": "Илиана",
		"title": "Пламенная жрица",
		"piece": "Q",
		"rarity": 3,
		"role": "Магия",
		"story": "Хранит последний огонь кузниц.",
		"quest": "Победить 12 боссов кампании",
		"wins": 12,
		"level": 1,
		"attack": 15,
		"armor": 10,
		"hp": 59,
		"crit": 4
	},
	{
		"id": "hero_18",
		"name": "Ворон",
		"title": "Безымянный палач",
		"piece": "B",
		"rarity": 3,
		"role": "Точность",
		"story": "Снял маску лишь перед побеждённым королём.",
		"quest": "Победить 13 боссов кампании",
		"wins": 13,
		"level": 1,
		"attack": 16,
		"armor": 11,
		"hp": 62,
		"crit": 5
	},
	{
		"id": "hero_19",
		"name": "Астра",
		"title": "Небесная вестница",
		"piece": "B",
		"rarity": 4,
		"role": "Магия",
		"story": "Пронесла послание сквозь разорванное небо.",
		"quest": "Победить 14 боссов кампании",
		"wins": 14,
		"level": 1,
		"attack": 18,
		"armor": 15,
		"hp": 81,
		"crit": 4
	},
	{
		"id": "hero_20",
		"name": "Зефир",
		"title": "Всадник грозы",
		"piece": "N",
		"rarity": 4,
		"role": "Натиск",
		"story": "Укротил молнию, поразившую его крепость.",
		"quest": "Победить 15 боссов кампании",
		"wins": 15,
		"level": 1,
		"attack": 19,
		"armor": 16,
		"hp": 84,
		"crit": 5
	},
	{
		"id": "hero_21",
		"name": "Солар",
		"title": "Страж звёзд",
		"piece": "K",
		"rarity": 4,
		"role": "Бастион",
		"story": "Собрал доспех из упавших звёзд.",
		"quest": "Победить 16 боссов кампании",
		"wins": 16,
		"level": 1,
		"attack": 20,
		"armor": 13,
		"hp": 72,
		"crit": 6
	},
	{
		"id": "hero_22",
		"name": "Эйдис",
		"title": "Повелительница ветров",
		"piece": "Q",
		"rarity": 4,
		"role": "Магия",
		"story": "Остановила бурю ценой собственного имени.",
		"quest": "Победить 17 боссов кампании",
		"wins": 17,
		"level": 1,
		"attack": 18,
		"armor": 14,
		"hp": 75,
		"crit": 4
	},
	{
		"id": "hero_23",
		"name": "Морвен",
		"title": "Королева затмения",
		"piece": "Q",
		"rarity": 5,
		"role": "Магия",
		"story": "Бывшая наследница трона, отказавшаяся служить тьме.",
		"quest": "Победить 18 боссов и достичь уровня 20",
		"wins": 18,
		"level": 20,
		"attack": 23,
		"armor": 18,
		"hp": 94,
		"crit": 6
	},
	{
		"id": "hero_24",
		"name": "Азраэль",
		"title": "Падший архонт",
		"piece": "K",
		"rarity": 5,
		"role": "Бастион",
		"story": "Перешёл на сторону живых после тысячи лет стражи.",
		"quest": "Победить 19 боссов и достичь уровня 20",
		"wins": 19,
		"level": 20,
		"attack": 24,
		"armor": 19,
		"hp": 97,
		"crit": 7
	},
	{
		"id": "hero_25",
		"name": "Фенрикс",
		"title": "Возрождённый феникс",
		"piece": "N",
		"rarity": 5,
		"role": "Натиск",
		"story": "Восстал из пепла последней битвы.",
		"quest": "Победить 20 боссов и достичь уровня 20",
		"wins": 20,
		"level": 20,
		"attack": 22,
		"armor": 16,
		"hp": 100,
		"crit": 5
	},
	{
		"id": "hero_26",
		"name": "Ноктис",
		"title": "Клинок пустоты",
		"piece": "B",
		"rarity": 5,
		"role": "Точность",
		"story": "Отсекает не тела, а клятвы.",
		"quest": "Победить 21 боссов и достичь уровня 20",
		"wins": 21,
		"level": 20,
		"attack": 23,
		"armor": 17,
		"hp": 88,
		"crit": 6
	},
	{
		"id": "hero_27",
		"name": "Элизиум",
		"title": "Судья времён",
		"piece": "Q",
		"rarity": 6,
		"role": "Магия",
		"story": "Остановил часы в ночь гибели королевства.",
		"quest": "Победить 22 боссов и достичь уровня 35",
		"wins": 22,
		"level": 35,
		"attack": 28,
		"armor": 21,
		"hp": 107,
		"crit": 8
	},
	{
		"id": "hero_28",
		"name": "Валькирия",
		"title": "Крылатая корона",
		"piece": "N",
		"rarity": 6,
		"role": "Натиск",
		"story": "Вернулась с края мира с крыльями бури.",
		"quest": "Победить 23 боссов и достичь уровня 35",
		"wins": 23,
		"level": 35,
		"attack": 26,
		"armor": 22,
		"hp": 110,
		"crit": 6
	},
	{
		"id": "hero_29",
		"name": "Обелиск",
		"title": "Живой бастион",
		"piece": "R",
		"rarity": 6,
		"role": "Бастион",
		"story": "Древняя крепость обрела волю и имя.",
		"quest": "Победить 24 боссов и достичь уровня 35",
		"wins": 24,
		"level": 35,
		"attack": 27,
		"armor": 19,
		"hp": 113,
		"crit": 7
	},
	{
		"id": "hero_30",
		"name": "Серафина",
		"title": "Последний рассвет",
		"piece": "K",
		"rarity": 6,
		"role": "Магия",
		"story": "Собрала семь печатей и пробудила солнце.",
		"quest": "Победить 25 боссов и достичь уровня 35",
		"wins": 25,
		"level": 35,
		"attack": 28,
		"armor": 20,
		"hp": 116,
		"crit": 8
	}
]
const TIER_NAMES = ["Обычный","Необычный","Редкий","Эпический","Легендарный","Мифический","Реликтовый"]
static func get_hero(id: String) -> Dictionary:
	for hero in HEROES:
		if str(hero["id"]) == id: return hero.duplicate(true)
	return HEROES[0].duplicate(true)

static func unlocked(hero: Dictionary, wins: int, level: int) -> bool:
	return wins >= int(hero["wins"]) and level >= int(hero["level"])

static func available_count(wins: int, level: int) -> int:
	var count := 0
	for hero in HEROES:
		if unlocked(hero, wins, level): count += 1
	return count

static func valid_selection(id: String, wins: int, level: int) -> String:
	var hero := get_hero(id)
	return str(hero["id"]) if str(hero["id"]) == id and unlocked(hero, wins, level) else "hero_01"

static func quest_progress(hero: Dictionary, wins: int, level: int) -> Dictionary:
	# Both campaign victories and player level are mandatory; no premium shortcut.
	var required_wins: int = maxi(0, int(hero.get("wins", 0)))
	var required_level: int = maxi(1, int(hero.get("level", 1)))
	var current_wins: int = clampi(wins, 0, required_wins)
	var current_level: int = clampi(level, 0, required_level)
	return {
		"wins": current_wins,
		"required_wins": required_wins,
		"level": current_level,
		"required_level": required_level,
		"unlocked": wins >= required_wins and level >= required_level
	}

static func next_unlock(wins: int, level: int) -> Dictionary:
	# Choose the closest locked hero by normalized remaining progress.
	var best: Dictionary = {}
	var best_distance: float = INF
	for hero in HEROES:
		if unlocked(hero, wins, level):
			continue
		var progress: Dictionary = quest_progress(hero, wins, level)
		var win_gap: float = float(progress["required_wins"] - progress["wins"]) / float(maxi(1, int(progress["required_wins"])))
		var level_gap: float = float(progress["required_level"] - progress["level"]) / float(maxi(1, int(progress["required_level"])))
		var distance: float = win_gap + level_gap
		if distance < best_distance:
			best_distance = distance
			best = hero.duplicate(true)
	return best
