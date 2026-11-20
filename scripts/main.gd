extends Control

const GLYPHS = {"K":"♔","Q":"♕","R":"♖","B":"♗","N":"♘","P":"♙","k":"♚","q":"♛","r":"♜","b":"♝","n":"♞","p":"♟"}
const HP = {"K":180,"Q":100,"R":150,"B":85,"N":115,"P":65}
const DAMAGE = {"K":20,"Q":35,"R":24,"B":22,"N":30,"P":15}
var pieces: Array = []
var health: Array = []
var buttons: Array = []
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

func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Color("#110f19")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
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
		b.add_theme_font_size_override("font_size", 25)
		b.pressed.connect(_tap.bind(i))
		grid.add_child(b)
		buttons.append(b)
	var sidebar := PanelContainer.new()
	sidebar.custom_minimum_size = Vector2(420, 0)
	sidebar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.add_child(sidebar)
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color("#211a2b")
	panel_style.border_color = Color("#866947")
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
	heading.text = "⚔ ВОЙНА КОРОЛЕВСТВ"
	heading.add_theme_font_size_override("font_size", 28)
	heading.add_theme_color_override("font_color", Color("#f1d49c"))
	ui.add_child(heading)
	var subtitle := Label.new()
	subtitle.text = "ТАКТИЧЕСКАЯ АРЕНА • ПРОТОТИП"
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
	var guide := Label.new()
	guide.text = "Выбери фигуру, затем клетку.\nДва действия за ход.\nКаждая фигура атакует по шахматным правилам."
	guide.add_theme_font_size_override("font_size", 18)
	ui.add_child(guide)
	skill_button = Button.new()
	skill_button.text = "✦ БЛАГОСЛОВЕНИЕ (+20 HP)"
	skill_button.custom_minimum_size.y = 58
	skill_button.pressed.connect(_heal_selected)
	ui.add_child(skill_button)
	var fire := Button.new()
	fire.text = "🔥 ПРОКЛЯТИЕ (30 УРОНА)"
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

func _reward(amount: int) -> void:
	experience += amount
	gold += amount / 2
	if experience >= player_level * 100:
		experience -= player_level * 100
		player_level += 1
		potions += 1
		battle_log = "Новый уровень! Получено зелье."

func _use_potion() -> void:
	if winner != "" or potions <= 0 or selected < 0 or ap < 1 or acted.has(selected): return
	if _team(pieces[selected]) != turn: return
	var p: String = pieces[selected].to_upper()
	if health[selected] >= HP[p]: return
	health[selected] = mini(HP[p], health[selected] + 40)
	potions -= 1
	_spend_action(selected)
	battle_log = "Зелье восстанавливает 40 здоровья."
	_draw()

func _curse_selected() -> void:
	if winner != "" or selected < 0 or ap < 1 or acted.has(selected): return
	if pieces[selected].to_upper() != "Q" and pieces[selected].to_upper() != "B": return
	var target := -1
	for i in range(64):
		if _team(pieces[i]) == -turn and _legal(selected,i):
			target = i
			break
	if target < 0: return
	health[target] -= 30
	if health[target] <= 0:
		var victim: String = pieces[target]
		pieces[target] = ""
		health[target] = 0
		if victim.to_upper() == "K": winner = "ПОБЕДА!"
		_reward(20)
	_spend_action(selected)
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
	boss_hp = 240
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
	if selected == -1:
		if _team(pieces[i]) == turn and not acted.has(i): selected = i
	elif selected == i:
		selected = -1
	elif _legal(selected,i):
		var attacker: String = pieces[selected]
		if pieces[i] != "":
			var damage: int = DAMAGE[attacker.to_upper()]
			if mode == "raid": damage += (player_level - 1) * 2
			health[i] -= damage
			if mode == "raid" and i == 4:
				boss_hp = maxi(0,health[i])
			if health[i] > 0:
				acted.append(selected)
			else:
				if pieces[i].to_upper() == "K":
					winner = "ПОБЕДА! БОСС ПОВЕРЖЕН!" if mode == "raid" else ("ПОБЕДА СВЕТЛЫХ!" if turn == 1 else "ПОБЕДА ТЁМНЫХ!")
					if mode == "raid": _reward(100)
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

func _boss_action() -> void:
	if winner != "": return
	enemy_turn = true
	var targets: Array = []
	for i in range(64):
		if _team(pieces[i]) == 1:
			targets.append(i)
	if targets.is_empty():
		winner = "ПОРАЖЕНИЕ"
	else:
		var target: int = targets[randi_range(0,targets.size()-1)]
		health[target] -= 25
		battle_log = "Падший король наносит 25 урона!"
		if health[target] <= 0:
			if pieces[target] == "K": winner = "ПОРАЖЕНИЕ"
			pieces[target] = ""
			health[target] = 0
	turn = 1
	ap = 2
	acted.clear()
	selected = -1
	heal_used = false
	enemy_turn = false
	_draw()

func _draw() -> void:
	status.text = winner if winner != "" else ("ГЕРОИ" if mode == "raid" else ("СВЕТЛЫЕ" if turn == 1 else "ТЁМНЫЕ")) + " • ОД: " + str(ap)
	mode_button.text = "РЕЖИМ: АРЕНА" if mode == "arena" else "РЕЖИМ: РЕЙД"
	inventory_label.text = "Ур. %d  •  Опыт: %d/%d  •  Золото: %d  •  Зелья: %d" % [player_level,experience,player_level*100,gold,potions]
	info.text = ("БОСС: %d/240 HP\n" % boss_hp if mode == "raid" else "") + battle_log
	for i in range(64):
		var b: Button = buttons[i]
		var p: String = pieces[i]
		b.text = GLYPHS.get(p,"") + ("\n"+str(health[i]) if p != "" else "")
		var style := StyleBoxFlat.new()
		var row: int = i / 8
		style.bg_color = Color("#49354b") if (row+i%8)%2 == 0 else Color("#9d8b78")
		if selected == i: style.bg_color = Color("#d4a53c")
		elif selected >= 0 and _legal(selected,i): style.bg_color = Color("#60845c")
		b.add_theme_stylebox_override("normal",style)
		b.add_theme_stylebox_override("hover",style)
		b.add_theme_stylebox_override("pressed",style)
		b.add_theme_color_override("font_color",Color("#fff3dd") if _team(p) == 1 else Color("#201824"))
