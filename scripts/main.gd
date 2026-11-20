extends Control

const Progression = preload("res://scripts/progression.gd")

const UNIT_TEXTURES = {
	"K": preload("res://assets/units/k.svg"),
	"Q": preload("res://assets/units/q.svg"),
	"R": preload("res://assets/units/r.svg"),
	"B": preload("res://assets/units/b.svg"),
	"N": preload("res://assets/units/n.svg"),
	"P": preload("res://assets/units/p.svg")
}
const GLYPHS = {"K":"♔","Q":"♕","R":"♖","B":"♗","N":"♘","P":"♙","k":"♚","q":"♛","r":"♜","b":"♝","n":"♞","p":"♟"}
const HP = {"K":180,"Q":100,"R":150,"B":85,"N":115,"P":65}
const DAMAGE = {"K":20,"Q":35,"R":24,"B":22,"N":30,"P":15}
var pieces: Array = []
var health: Array = []
var buttons: Array = []
var unit_images: Array = []
var hp_labels: Array = []
var selected := -1
var turn := 1
var ap := 2
var acted: Array = []
var winner := ""
var heal_used := false
var status: Label
var mode := "arena"
var player_level := 1
var experience := 0
var gold := 0
var potions := 2
var boss_hp := 240
var enemy_turn := false
var info: Label
var inventory_label: Label
var mode_button: Button
var skill_button: Button
var battle_log := "Битва начинается."
var equipment: Array = []
var equipped := -1
var raid_wins := 0
var boss_target := -1
var raid_round := 0
var equipment_label: Label
var curse_mode := false
var turn_count := 0
var enemy_wave := 0

func _ready() -> void:
	_load_profile()
	var bg := TextureRect.new()
	bg.texture = preload("res://assets/backgrounds/ruined_kingdom.svg")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	var layout := HBoxContainer.new()
	layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layout.add_theme_constant_override("separation", 22)
	add_child(layout)
	var board_frame := MarginContainer.new()
	board_frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	board_frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
	board_frame.add_theme_constant_override("margin_left", 16)
	board_frame.add_theme_constant_override("margin_top", 12)
	board_frame.add_theme_constant_override("margin_bottom", 12)
	layout.add_child(board_frame)
	var square := AspectRatioContainer.new()
	square.ratio = 1.0
	square.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	square.size_flags_vertical = Control.SIZE_EXPAND_FILL
	board_frame.add_child(square)
	var grid := GridContainer.new()
	grid.columns = 8
	grid.add_theme_constant_override("h_separation", 2)
	grid.add_theme_constant_override("v_separation", 2)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	square.add_child(grid)
	for i in range(64):
		var b := Button.new()
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.size_flags_vertical = Control.SIZE_EXPAND_FILL
		b.add_theme_font_size_override("font_size", 18)
		b.pressed.connect(_tap.bind(i))
		grid.add_child(b)
		buttons.append(b)
		var emblem := TextureRect.new()
		emblem.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		emblem.offset_left = 4
		emblem.offset_top = 2
		emblem.offset_right = -4
		emblem.offset_bottom = -17
		emblem.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		emblem.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		emblem.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(emblem)
		unit_images.append(emblem)
		var hp := Label.new()
		hp.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
		hp.offset_top = -20
		hp.offset_bottom = -1
		hp.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hp.add_theme_font_size_override("font_size", 15)
		hp.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(hp)
		hp_labels.append(hp)
	var sidebar := PanelContainer.new()
	sidebar.custom_minimum_size = Vector2(460, 0)
	sidebar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.add_child(sidebar)
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color("#191724")
	panel_style.border_color = Color("#a88750")
	panel_style.set_border_width_all(2)
	panel_style.set_content_margin_all(22)
	sidebar.add_theme_stylebox_override("panel", panel_style)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sidebar.add_child(scroll)
	var ui := VBoxContainer.new()
	ui.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ui.add_theme_constant_override("separation", 12)
	scroll.add_child(ui)
	var heading := Label.new()
	heading.text = "⚔  ВОЙНА КОРОЛЕВСТВ"
	heading.add_theme_font_size_override("font_size", 28)
	heading.add_theme_color_override("font_color", Color("#f1d49c"))
	ui.add_child(heading)
	var subtitle := Label.new()
	subtitle.text = "ХРОНИКИ ПАДШЕГО ТРОНА"
	subtitle.add_theme_font_size_override("font_size", 16)
	subtitle.add_theme_color_override("font_color", Color("#b8a4ba"))
	ui.add_child(subtitle)
	status = Label.new()
	status.add_theme_font_size_override("font_size", 25)
	ui.add_child(status)
	var mode_row := HBoxContainer.new()
	ui.add_child(mode_row)
	mode_button = Button.new()
	mode_button.text = "РЕЖИМ: АРЕНА"
	mode_button.custom_minimum_size.y = 54
	mode_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mode_button.pressed.connect(_switch_mode)
	mode_row.add_child(mode_button)
	var raid_button := Button.new()
	raid_button.text = "РЕЙД"
	raid_button.custom_minimum_size.y = 54
	raid_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	raid_button.pressed.connect(_start_raid)
	mode_row.add_child(raid_button)
	inventory_label = Label.new()
	inventory_label.add_theme_font_size_override("font_size", 18)
	inventory_label.add_theme_color_override("font_color", Color("#e5c58c"))
	ui.add_child(inventory_label)
	equipment_label = Label.new()
	equipment_label.add_theme_font_size_override("font_size", 17)
	equipment_label.add_theme_color_override("font_color", Color("#c6e3e5"))
	equipment_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ui.add_child(equipment_label)
	var equip_button := Button.new()
	equip_button.text = "СНАРЯДИТЬ ЛУЧШИЙ ПРЕДМЕТ"
	equip_button.custom_minimum_size.y = 52
	equip_button.pressed.connect(_equip_best)
	ui.add_child(equip_button)
	var guide := Label.new()
	guide.text = "Выбери героя и клетку назначения.\n2 действия на ход • Тактический бой"
	guide.add_theme_font_size_override("font_size", 18)
	ui.add_child(guide)
	skill_button = Button.new()
	skill_button.text = "✦ БЛАГОСЛОВЕНИЕ (+20 HP)"
	skill_button.custom_minimum_size.y = 58
	skill_button.pressed.connect(_heal_selected)
	ui.add_child(skill_button)
	var fire := Button.new()
	fire.text = "🔥 ПРОКЛЯТИЕ — ВЫБРАТЬ ЦЕЛЬ"
	fire.custom_minimum_size.y = 58
	fire.pressed.connect(_curse_selected)
	ui.add_child(fire)
	var potion := Button.new()
	potion.text = "ЗЕЛЬЕ: ЛЕЧЕНИЕ (+40 HP)"
	potion.custom_minimum_size.y = 58
	potion.pressed.connect(_use_potion)
	ui.add_child(potion)
	info = Label.new()
	info.add_theme_font_size_override("font_size", 17)
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ui.add_child(info)
	var end := Button.new()
	end.text = "ЗАВЕРШИТЬ ХОД"
	end.custom_minimum_size.y = 65
	end.pressed.connect(_end_turn)
	ui.add_child(end)
	var restart := Button.new()
	restart.text = "НОВАЯ БИТВА"
	restart.custom_minimum_size.y = 60
	restart.pressed.connect(_reset)
	ui.add_child(restart)
	var note := Label.new()
	note.text = "Одиночный рейд и локальная арена.\nСеть, 3D и кооператив ещё не готовы."
	note.add_theme_font_size_override("font_size", 15)
	ui.add_child(note)
	_reset()

func _switch_mode() -> void:
	mode = "arena"
	_reset()

func _start_raid() -> void:
	mode = "raid"
	_reset()

func _load_profile() -> void:
	var profile: Dictionary = Progression.load_profile()
	player_level = int(profile["level"])
	experience = int(profile["xp"])
	gold = int(profile["gold"])
	potions = int(profile["potions"])
	equipment = profile["items"]
	equipped = int(profile["equipped"])
	raid_wins = int(profile["wins"])
	if equipped < 0 or equipped >= equipment.size():
		equipped = -1

func _save_profile() -> void:
	Progression.save_profile({
		"level": player_level, "xp": experience, "gold": gold,
		"potions": potions, "items": equipment,
		"equipped": equipped, "wins": raid_wins
	})

func _attack_bonus() -> int:
	if equipped < 0 or equipped >= equipment.size(): return 0
	return int(equipment[equipped].get("attack", 0))

func _equip_best() -> void:
	if equipment.is_empty():
		battle_log = "Предметы выпадают после победы в рейде."
		_draw()
		return
	var best := 0
	for i in range(1, equipment.size()):
		if int(equipment[i].get("attack", 0)) > int(equipment[best].get("attack", 0)):
			best = i
	equipped = best
	battle_log = "Экипировано: " + str(equipment[best].get("name", "Артефакт"))
	_save_profile()
	_draw()

func _reward(amount: int) -> void:
	experience += amount
	gold += int(amount / 2.0)
	while player_level < 50 and experience >= Progression.experience_needed(player_level):
		experience -= Progression.experience_needed(player_level)
		player_level += 1
		potions += 1
		battle_log = "Новый уровень! Получено зелье."
	_save_profile()

func _raid_victory() -> void:
	if winner != "": return
	winner = "ПОБЕДА! БОСС ПОВЕРЖЕН!"
	raid_wins += 1
	_reward(100)
	var item: Dictionary = Progression.roll_item(player_level)
	equipment.append(item)
	battle_log = "Добыча: %s (%s), +%d к атаке" % [item["name"], Progression.RARITIES[int(item["rarity"])], int(item["attack"])]
	_save_profile()

func _use_potion() -> void:
	if winner != "" or potions <= 0 or selected < 0 or ap < 1 or acted.has(selected): return
	if _team(pieces[selected]) != turn: return
	var p: String = pieces[selected].to_upper()
	if health[selected] >= HP[p]: return
	health[selected] = mini(HP[p], health[selected] + 40)
	potions -= 1
	_save_profile()
	_spend_action(selected)
	battle_log = "Зелье восстанавливает 40 здоровья."
	_draw()

func _curse_selected() -> void:
	if winner != "" or selected < 0 or ap < 1 or acted.has(selected): return
	if pieces[selected].to_upper() != "Q" and pieces[selected].to_upper() != "B":
		battle_log = "Проклятие доступно только ферзю и слону."
		_draw()
		return
	curse_mode = not curse_mode
	battle_log = "Выбери подсвеченного врага." if curse_mode else "Проклятие отменено."
	_draw()

func _apply_curse(target: int) -> void:
	if selected < 0 or not _legal(selected,target) or pieces[target] == "":
		return
	if _team(pieces[target]) != -turn: return
	var source: int = selected
	health[target] -= 30
	if mode == "raid" and target == 4:
		boss_hp = maxi(0, health[target])
	if health[target] <= 0:
		var victim: String = pieces[target]
		pieces[target] = ""
		health[target] = 0
		if victim.to_upper() == "K":
			if mode == "raid": _raid_victory()
			else: winner = "ПОБЕДА!"
		elif mode == "raid":
			_reward(20)
	curse_mode = false
	_spend_action(source)
	battle_log = "Проклятие наносит 30 урона."
	_draw()

func _spend_action(index: int) -> void:
	acted.append(index)
	selected = -1
	ap -= 1
	if ap <= 0 and winner == "":
		_end_turn()

func _reset() -> void:
	pieces.clear()
	health.clear()
	for r in range(8):
		for c in range(8):
			var p := ""
			if r == 0: p = "rnbqkbnr"[c]
			elif r == 1: p = "p"
			elif r == 6: p = "P"
			elif r == 7: p = "RNBQKBNR"[c]
			pieces.append(p)
			health.append(HP[p.to_upper()] if p != "" else 0)
	turn = 1
	ap = 2
	selected = -1
	curse_mode = false
	turn_count = 0
	enemy_wave = 0
	boss_hp = 240
	raid_round = 0
	boss_target = -1
	battle_log = "Рейд: уничтожь тёмного короля!" if mode == "raid" else "Арена: два игрока на одном устройстве."
	if mode == "raid":
		for i in range(8,16):
			pieces[i] = ""
			health[i] = 0
		for i in range(0,8):
			if i != 4:
				pieces[i] = ""
				health[i] = 0
		health[4] = boss_hp
		pieces[11] = "n"
		health[11] = HP["N"]
		pieces[12] = "p"
		health[12] = HP["P"]
		boss_target = _choose_boss_target()
	winner = ""
	acted.clear()
	heal_used = false
	_draw()

func _team(p: String) -> int:
	if p == "": return 0
	return 1 if p == p.to_upper() else -1

func _legal(a: int, b: int) -> bool:
	if a == b or pieces[a] == "": return false
	if _team(pieces[a]) == _team(pieces[b]): return false
	var p: String = pieces[a].to_upper()
	var r0: int = a / 8
	var c0: int = a % 8
	var r1: int = b / 8
	var c1: int = b % 8
	var dr: int = r1 - r0
	var dc: int = c1 - c0
	if p == "N": return (abs(dr) == 2 and abs(dc) == 1) or (abs(dr) == 1 and abs(dc) == 2)
	if p == "K": return max(abs(dr),abs(dc)) == 1
	if p == "P":
		var f := -1 if turn == 1 else 1
		if dc == 0 and pieces[b] == "":
			if dr == f: return true
			return dr == 2*f and r0 == (6 if turn == 1 else 1) and pieces[a+8*f] == ""
		return abs(dc) == 1 and dr == f and pieces[b] != ""
	if p == "R" and dr != 0 and dc != 0: return false
	if p == "B" and abs(dr) != abs(dc): return false
	if p == "Q" and not (dr == 0 or dc == 0 or abs(dr) == abs(dc)): return false
	var sr := signi(dr)
	var sc := signi(dc)
	var r := r0+sr
	var c := c0+sc
	while r != r1 or c != c1:
		if pieces[r*8+c] != "": return false
		r += sr
		c += sc
	return true

func _tap(i: int) -> void:
	if winner != "" or enemy_turn or (mode == "raid" and turn == -1): return
	if curse_mode:
		if selected >= 0 and pieces[i] != "" and _team(pieces[i]) == -turn and _legal(selected,i):
			_apply_curse(i)
		elif i == selected:
			curse_mode = false
			_draw()
		return
	if selected == -1:
		if _team(pieces[i]) == turn and not acted.has(i): selected = i
	elif selected == i:
		selected = -1
	elif _legal(selected,i):
		var attacker: String = pieces[selected]
		if pieces[i] != "":
			var damage: int = DAMAGE[attacker.to_upper()]
			if mode == "raid": damage += (player_level - 1) * 2 + _attack_bonus()
			health[i] -= damage
			if mode == "raid" and i == 4:
				boss_hp = maxi(0,health[i])
			if health[i] > 0:
				acted.append(selected)
			else:
				if pieces[i].to_upper() == "K":
					if mode == "raid": _raid_victory()
					else: winner = "ПОБЕДА СВЕТЛЫХ!" if turn == 1 else "ПОБЕДА ТЁМНЫХ!"
				_move(selected,i)
		else:
			_move(selected,i)
		selected = -1
		ap -= 1
		if ap <= 0 and winner == "": _end_turn()
	elif _team(pieces[i]) == turn and not acted.has(i):
		selected = i
	_draw()

func _move(a: int,b: int) -> void:
	pieces[b] = pieces[a]
	health[b] = health[a]
	pieces[a] = ""
	health[a] = 0
	acted.append(b)

func _heal_selected() -> void:
	if winner != "" or heal_used or ap < 1 or selected < 0: return
	if _team(pieces[selected]) != turn or acted.has(selected): return
	var p: String = pieces[selected].to_upper()
	if health[selected] >= HP[p]: return
	health[selected] = mini(HP[p], health[selected] + 20)
	acted.append(selected)
	heal_used = true
	selected = -1
	ap -= 1
	if ap <= 0:
		_end_turn()
	else:
		_draw()

func _end_turn() -> void:
	if winner != "": return
	if mode == "raid" and turn == 1:
		_boss_action()
		return
	turn = -turn
	ap = 2
	heal_used = false
	acted.clear()
	selected = -1
	_draw()

func _choose_boss_target() -> int:
	var target := -1
	var score := 99999
	for i in range(64):
		if _team(pieces[i]) != 1: continue
		var distance: int = absi(int(i / 8) - 0) + absi(i % 8 - 4)
		var value: int = distance * 10 + int(health[i] / 10)
		if value < score:
			score = value
			target = i
	return target

func _boss_action() -> void:
	if winner != "": return
	enemy_turn = true
	raid_round += 1
	turn_count += 1
	if boss_target >= 0 and _team(pieces[boss_target]) == 1:
		var damage := 25 if raid_round % 3 != 0 else 45
		health[boss_target] -= damage
		battle_log = "Падший король наносит %d урона по отмеченной клетке!" % damage
		if health[boss_target] <= 0:
			if pieces[boss_target] == "K": winner = "ПОРАЖЕНИЕ"
			pieces[boss_target] = ""
			health[boss_target] = 0
	else:
		battle_log = "Герои уклонились от удара Падшего короля!"
	if raid_round % 4 == 0 and boss_hp > 0:
		var spawn := -1
		for cell in [8, 9, 10, 13, 14, 15]:
			if pieces[cell] == "":
				spawn = cell
				break
		if spawn >= 0:
			pieces[spawn] = "p"
			health[spawn] = HP["P"]
			enemy_wave += 1
			battle_log += "\nВосстал скелет-страж!"
	boss_target = _choose_boss_target()
	if boss_target >= 0 and winner == "":
		battle_log += "\nСледующая цель: %s%d" % ["ABCDEFGH".substr(boss_target % 8, 1), 8 - int(boss_target / 8)]
	turn = 1
	ap = 2
	acted.clear()
	selected = -1
	curse_mode = false
	heal_used = false
	enemy_turn = false
	_draw()

func _draw() -> void:
	status.text = winner if winner != "" else ("ГЕРОИ" if mode == "raid" else ("СВЕТЛЫЕ" if turn == 1 else "ТЁМНЫЕ")) + " • ОД: " + str(ap)
	mode_button.text = "РЕЖИМ: АРЕНА" if mode == "arena" else "РЕЖИМ: РЕЙД"
	inventory_label.text = "Ур. %d  •  Опыт: %d/%d  •  Золото: %d  •  Зелья: %d" % [player_level,experience,Progression.experience_needed(player_level),gold,potions]
	var equipped_name := "нет"
	if equipped >= 0 and equipped < equipment.size():
		equipped_name = str(equipment[equipped].get("name", "Артефакт")) + " (+" + str(_attack_bonus()) + ")"
	equipment_label.text = "Снаряжение: %s\nТрофеи: %d  •  Побед в рейдах: %d" % [equipped_name,equipment.size(),raid_wins]
	info.text = ("БОСС: %d/240 HP • Раунд %d\n" % [boss_hp, raid_round] if mode == "raid" else "") + battle_log
	for i in range(64):
		var b: Button = buttons[i]
		var p: String = pieces[i]
		b.text = ""
		var image_node: TextureRect = unit_images[i]
		image_node.texture = UNIT_TEXTURES.get(p.to_upper()) if p != "" else null
		image_node.modulate = Color("#f8e3c0") if _team(p) == 1 else Color("#e2a3e9")
		var hp_node: Label = hp_labels[i]
		hp_node.text = str(health[i]) if p != "" else ""
		hp_node.add_theme_color_override("font_color", Color("#f9e8b4") if _team(p) == 1 else Color("#eed0ff")
		var style := StyleBoxFlat.new()
		var row: int = i / 8
		style.bg_color = Color("#292536") if (row+i%8)%2 == 0 else Color("#554758")
		style.border_color = Color("#8b7453") if (row+i%8)%2 == 0 else Color("#6f5a55")
		style.set_border_width_all(1)
		style.set_corner_radius_all(4)
		if mode == "raid" and boss_target == i and winner == "":
			style.bg_color = Color("#8c3440")
			style.border_color = Color("#ff8c7e")
			style.set_border_width_all(3)
		if selected == i: style.bg_color = Color("#d4a53c")
		elif selected >= 0 and _legal(selected,i):
			if curse_mode and pieces[i] != "": style.bg_color = Color("#8b426c")
			elif not curse_mode: style.bg_color = Color("#44675e")
		b.add_theme_stylebox_override("normal",style)
		b.add_theme_stylebox_override("hover",style)
		b.add_theme_stylebox_override("pressed",style)
		b.add_theme_stylebox_override("focus",StyleBoxEmpty.new())
		b.add_theme_color_override("font_color",Color("#fff3dd") if _team(p) == 1 else Color("#201824"))
