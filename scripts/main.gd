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
var status: Label

func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Color("#171321")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var ui := VBoxContainer.new()
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.add_theme_constant_override("separation", 14)
	add_child(ui)
	var heading := Label.new()
	heading.text = "⚔ ВОЙНА КОРОЛЕВСТВ"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override("font_size", 36)
	ui.add_child(heading)
	status = Label.new()
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ui.add_child(status)
	var square := AspectRatioContainer.new()
	square.ratio = 1.0
	square.size_flags_vertical = Control.SIZE_EXPAND_FILL
	ui.add_child(square)
	var grid := GridContainer.new()
	grid.columns = 8
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	square.add_child(grid)
	for i in range(64):
		var b := Button.new()
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.size_flags_vertical = Control.SIZE_EXPAND_FILL
		b.add_theme_font_size_override("font_size", 28)
		b.pressed.connect(_tap.bind(i))
		grid.add_child(b)
		buttons.append(b)
	var help := Label.new()
	help.text = "Выбери фигуру и клетку. 2 действия за ход.\nАтаки уменьшают здоровье."
	help.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ui.add_child(help)
	var end := Button.new()
	end.text = "ЗАВЕРШИТЬ ХОД"
	end.pressed.connect(_end_turn)
	ui.add_child(end)
	var restart := Button.new()
	restart.text = "НОВАЯ БИТВА"
	restart.pressed.connect(_reset)
	ui.add_child(restart)
	var note := Label.new()
	note.text = "Прототип: два игрока на одном экране. Онлайн позже."
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note.add_theme_font_size_override("font_size", 16)
	ui.add_child(note)
	_reset()

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
	winner = ""
	acted.clear()
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
	if winner != "": return
	if selected == -1:
		if _team(pieces[i]) == turn and not acted.has(i): selected = i
	elif selected == i:
		selected = -1
	elif _legal(selected,i):
		var attacker: String = pieces[selected]
		if pieces[i] != "":
			health[i] -= DAMAGE[attacker.to_upper()]
			if health[i] > 0:
				acted.append(selected)
			else:
				if pieces[i].to_upper() == "K":
					winner = "ПОБЕДА СВЕТЛЫХ!" if turn == 1 else "ПОБЕДА ТЁМНЫХ!"
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

func _end_turn() -> void:
	if winner != "": return
	turn = -turn
	ap = 2
	acted.clear()
	selected = -1
	_draw()

func _draw() -> void:
	status.text = winner if winner != "" else ("СВЕТЛЫЕ" if turn == 1 else "ТЁМНЫЕ") + " • ОД: " + str(ap)
	for i in range(64):
		var b: Button = buttons[i]
		var p: String = pieces[i]
		b.text = GLYPHS.get(p,"") + ("\n"+str(health[i]) if p != "" else "")
		var style := StyleBoxFlat.new()
		var row: int = i / 8
		style.bg_color = Color("#51425c") if (row+i%8)%2 == 0 else Color("#b5a7a7")
		if selected == i: style.bg_color = Color("#d4a53c")
		elif selected >= 0 and _legal(selected,i): style.bg_color = Color("#60845c")
		b.add_theme_stylebox_override("normal",style)
		b.add_theme_stylebox_override("hover",style)
		b.add_theme_stylebox_override("pressed",style)
		b.add_theme_color_override("font_color",Color("#fff3dd") if _team(p) == 1 else Color("#201824"))
