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
var boss_portrait: TextureRect
var boss_bar: ProgressBar
var curse_mode := false
var turn_count := 0
var enemy_wave := 0
var inventory_popup: AcceptDialog
var inventory_list: ItemList
var inventory_details: Label
var inventory_selected := -1
var raid_stage := 1
var damage_numbers: Array[Label] = []
var shop_popup: AcceptDialog
var shop_label: Label
var battle_result_shown := false
var battle_result_dialog: AcceptDialog
var boss_phase := 1
var phase_label: Label
const LAN_PORT := 27545
var lan_status: Label
var lan_address: LineEdit
var lan_connected := false
var lan_host := false
var lan_joined := false
var lan_raid := false
var sync_revision := 0

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
	boss_portrait = TextureRect.new()
	boss_portrait.texture = preload("res://assets/backgrounds/fallen_king.svg")
	boss_portrait.custom_minimum_size = Vector2(0, 120)
	boss_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	boss_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	ui.add_child(boss_portrait)
	boss_bar = ProgressBar.new()
	boss_bar.max_value = 240
	boss_bar.value = 240
	boss_bar.show_percentage = false
	boss_bar.custom_minimum_size.y = 16
	ui.add_child(boss_bar)
	phase_label = Label.new()
	phase_label.add_theme_font_size_override("font_size", 18)
	phase_label.add_theme_color_override("font_color", Color("#e9a6a0"))
	ui.add_child(phase_label)
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
	var inventory_button := Button.new()
	inventory_button.text = "СУМКА И СНАРЯЖЕНИЕ"
	inventory_button.custom_minimum_size.y = 52
	inventory_button.pressed.connect(_open_inventory)
	ui.add_child(inventory_button)
	var equip_button := Button.new()
	equip_button.text = "СНАРЯДИТЬ ЛУЧШИЙ ПРЕДМЕТ"
	equip_button.custom_minimum_size.y = 52
	equip_button.pressed.connect(_equip_best)
	ui.add_child(equip_button)
	var shop_button := Button.new()
	shop_button.text = "ЛАВКА АЛХИМИКА"
	shop_button.custom_minimum_size.y = 52
	shop_button.pressed.connect(_open_shop)
	ui.add_child(shop_button)
	var lan_header := Label.new()
	lan_header.text = "СОВМЕСТНЫЙ РЕЙД • ОДНА WI-FI СЕТЬ"
	lan_header.add_theme_font_size_override("font_size", 18)
	lan_header.add_theme_color_override("font_color", Color("#f1d49c"))
	ui.add_child(lan_header)
	var lan_row := HBoxContainer.new()
	ui.add_child(lan_row)
	var host_button := Button.new()
	host_button.text = "СОЗДАТЬ"
	host_button.custom_minimum_size = Vector2(0, 50)
	host_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	host_button.pressed.connect(_host_lan)
	lan_row.add_child(host_button)
	lan_address = LineEdit.new()
	lan_address.placeholder_text = "IP хозяина"
	lan_address.text = "192.168.1."
	lan_address.custom_minimum_size = Vector2(150, 50)
	lan_address.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lan_row.add_child(lan_address)
	var join_button := Button.new()
	join_button.text = "ВОЙТИ"
	join_button.custom_minimum_size = Vector2(0, 50)
	join_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	join_button.pressed.connect(_join_lan)
	lan_row.add_child(join_button)
	lan_status = Label.new()
	lan_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lan_status.add_theme_font_size_override("font_size", 15)
	lan_status.text = "Оба телефона должны быть в одной Wi-Fi сети."
	ui.add_child(lan_status)
	var leave_button := Button.new()
	leave_button.text = "ОТКЛЮЧИТЬ СЕТЬ"
	leave_button.custom_minimum_size.y = 45
	leave_button.pressed.connect(_leave_lan)
	ui.add_child(leave_button)
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
	note.text = "Одиночный рейд, локальная арена и экспериментальный Wi-Fi кооператив.\n3D и онлайн-серверы ещё не готовы."
	note.add_theme_font_size_override("font_size", 15)
	ui.add_child(note)
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_lan_connected)
	multiplayer.connection_failed.connect(_on_lan_failed)
	multiplayer.server_disconnected.connect(_on_lan_disconnected)
	_create_inventory_popup()
	_create_shop_popup()
	_create_result_popup()
	_reset()

func _create_inventory_popup() -> void:
	inventory_popup = AcceptDialog.new()
	inventory_popup.title = "ХРАНИЛИЩЕ РЕЛИКВИЙ"
	inventory_popup.dialog_text = ""
	inventory_popup.min_size = Vector2i(700, 480)
	add_child(inventory_popup)
	var contents := VBoxContainer.new()
	contents.add_theme_constant_override("separation", 12)
	inventory_popup.add_child(contents)
	inventory_details = Label.new()
	inventory_details.text = "Выбери предмет."
	inventory_details.add_theme_font_size_override("font_size", 19)
	contents.add_child(inventory_details)
	inventory_list = ItemList.new()
	inventory_list.custom_minimum_size = Vector2(650, 285)
	inventory_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	inventory_list.item_selected.connect(_inventory_select)
	contents.add_child(inventory_list)
	var actions := HBoxContainer.new()
	contents.add_child(actions)
	var equip := Button.new()
	equip.text = "ЭКИПИРОВАТЬ"
	equip.custom_minimum_size = Vector2(250, 55)
	equip.pressed.connect(_inventory_equip)
	actions.add_child(equip)
	var sell := Button.new()
	sell.text = "ПРОДАТЬ ЗА ЗОЛОТО"
	sell.custom_minimum_size = Vector2(250, 55)
	sell.pressed.connect(_inventory_sell)
	actions.add_child(sell)

func _open_inventory() -> void:
	inventory_selected = -1
	_refresh_inventory()
	inventory_popup.popup_centered()

func _refresh_inventory() -> void:
	inventory_list.clear()
	for i in range(equipment.size()):
		var item: Dictionary = equipment[i]
		var rarity: int = clampi(int(item.get("rarity", 0)), 0, 6)
		var name: String = str(item.get("name", "Артефакт"))
		var mark := " [ЭКИПИРОВАНО]" if i == equipped else ""
		inventory_list.add_item("%s • %s • +%d атаки%s" % [name, Progression.RARITIES[rarity], int(item.get("attack", 0)), mark])
		inventory_list.set_item_custom_fg_color(i, _rarity_color(rarity))
	if equipment.is_empty():
		inventory_details.text = "Сумка пуста. Реликвии выпадают с боссов."
	else:
		inventory_details.text = "Предметов: %d • Золото: %d" % [equipment.size(), gold]

func _rarity_color(rarity: int) -> Color:
	var colors := ["#b6b6b6", "#75d69b", "#6daaff", "#c189f4", "#e9bd69", "#ff858e", "#fff1b4"]
	return Color(colors[clampi(rarity, 0, colors.size()-1)])

func _inventory_select(index: int) -> void:
	inventory_selected = index
	if index < 0 or index >= equipment.size(): return
	var item: Dictionary = equipment[index]
	var rarity: int = clampi(int(item.get("rarity", 0)), 0, 6)
	inventory_details.text = "%s • %s • Ур. %d • +%d к атаке" % [item.get("name", "Артефакт"), Progression.RARITIES[rarity], int(item.get("level", 1)), int(item.get("attack", 0))]

func _inventory_equip() -> void:
	if inventory_selected < 0 or inventory_selected >= equipment.size(): return
	equipped = inventory_selected
	_save_profile()
	_refresh_inventory()
	_draw()

func _inventory_sell() -> void:
	if inventory_selected < 0 or inventory_selected >= equipment.size(): return
	var item: Dictionary = equipment[inventory_selected]
	var price: int = 10 + int(item.get("level", 1)) * 5 + int(item.get("rarity", 0)) * 25
	gold += price
	equipment.remove_at(inventory_selected)
	if equipped == inventory_selected: equipped = -1
	elif equipped > inventory_selected: equipped -= 1
	inventory_selected = -1
	_save_profile()
	_refresh_inventory()
	_draw()

func _create_shop_popup() -> void:
	shop_popup = AcceptDialog.new()
	shop_popup.title = "ЛАВКА АЛХИМИКА"
	shop_popup.min_size = Vector2i(530, 300)
	add_child(shop_popup)
	var panel := VBoxContainer.new()
	panel.add_theme_constant_override("separation", 16)
	shop_popup.add_child(panel)
	shop_label = Label.new()
	shop_label.add_theme_font_size_override("font_size", 22)
	panel.add_child(shop_label)
	var buy := Button.new()
	buy.text = "КУПИТЬ ЗЕЛЬЕ • 50 ЗОЛОТА"
	buy.custom_minimum_size.y = 62
	buy.pressed.connect(_buy_potion)
	panel.add_child(buy)
	var supply := Button.new()
	supply.text = "НАБОР ПРИПАСОВ • 130 ЗОЛОТА (3 ЗЕЛЬЯ)"
	supply.custom_minimum_size.y = 62
	supply.pressed.connect(_buy_supply)
	panel.add_child(supply)

func _open_shop() -> void:
	_update_shop()
	shop_popup.popup_centered()

func _update_shop() -> void:
	shop_label.text = "Золото: %d    Зелья: %d/99" % [gold, potions]

func _buy_potion() -> void:
	_buy_potions(1, 50)

func _buy_supply() -> void:
	_buy_potions(3, 130)

func _buy_potions(count: int, cost: int) -> void:
	if gold < cost:
		shop_label.text = "Недостаточно золота! Нужно %d." % cost
		return
	if potions + count > 99:
		shop_label.text = "Сумка с зельями переполнена."
		return
	gold -= cost
	potions += count
	_save_profile()
	_update_shop()
	_draw()

func _create_result_popup() -> void:
	battle_result_dialog = AcceptDialog.new()
	battle_result_dialog.title = "ИТОГ БИТВЫ"
	battle_result_dialog.min_size = Vector2i(620, 250)
	add_child(battle_result_dialog)

func _show_result() -> void:
	if winner == "" or battle_result_shown: return
	battle_result_shown = true
	battle_result_dialog.dialog_text = "%s\n\n%s\n\nУровень: %d  •  Золото: %d  •  Трофеи: %d" % [winner, battle_log, player_level, gold, equipment.size()]
	battle_result_dialog.popup_centered()

func _host_lan() -> void:
	_leave_lan()
	var peer := ENetMultiplayerPeer.new()
	var result: Error = peer.create_server(LAN_PORT, 1)
	if result != OK:
		lan_status.text = "Не удалось создать сервер: " + str(result)
		return
	multiplayer.multiplayer_peer = peer
	lan_connected = true
	lan_host = true
	lan_raid = true
	mode = "raid"
	_reset()
	var ips: Array[String] = IP.get_local_addresses()
	var addresses: Array[String] = []
	for ip in ips:
		if ip.contains(".") and not ip.begins_with("127.") and not ip.begins_with("169.254."):
			addresses.append(ip)
	lan_status.text = "Сервер готов, порт %d. IP: %s" % [LAN_PORT, ", ".join(addresses)]

func _join_lan() -> void:
	_leave_lan()
	var address := lan_address.text.strip_edges()
	if not address.is_valid_ip_address():
		lan_status.text = "Введи IP телефона-хозяина, например 192.168.1.10"
		return
	var peer := ENetMultiplayerPeer.new()
	var result: Error = peer.create_client(address, LAN_PORT)
	if result != OK:
		lan_status.text = "Ошибка подключения: " + str(result)
		return
	multiplayer.multiplayer_peer = peer
	lan_connected = true
	lan_host = false
	lan_raid = true
	lan_status.text = "Подключаемся к " + address + "…"

func _leave_lan() -> void:
	if multiplayer.multiplayer_peer != null:
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null
	lan_connected = false
	lan_host = false
	lan_joined = false
	lan_raid = false
	if lan_status != null:
		lan_status.text = "Сеть отключена."

func _on_peer_connected(id: int) -> void:
	if not lan_host: return
	lan_status.text = "Напарник подключён. Совместный рейд начался!"
	_send_snapshot.rpc_id(id, _snapshot())

func _on_peer_disconnected(_id: int) -> void:
	if lan_host:
		lan_status.text = "Напарник отключился. Можно продолжать одному."

func _on_lan_connected() -> void:
	lan_joined = true
	lan_status.text = "Подключено. Ожидаем состояние рейда…"

func _on_lan_failed() -> void:
	_leave_lan()
	lan_status.text = "Не удалось подключиться. Проверь Wi-Fi и IP."

func _on_lan_disconnected() -> void:
	_leave_lan()
	lan_status.text = "Соединение с хозяином потеряно."

func _snapshot() -> Dictionary:
	return {
		"pieces": pieces.duplicate(), "health": health.duplicate(),
		"ap": ap, "turn": turn, "winner": winner,
		"boss_hp": boss_hp, "boss_phase": boss_phase,
		"raid_round": raid_round, "raid_stage": raid_stage,
		"boss_target": boss_target, "battle_log": battle_log,
		"acted": acted.duplicate(), "enemy_wave": enemy_wave,
		"selected": selected, "curse_mode": curse_mode, "heal_used": heal_used
	}

func _broadcast_snapshot() -> void:
	if not lan_host or multiplayer.multiplayer_peer == null: return
	sync_revision += 1
	_send_snapshot.rpc(_snapshot())

@rpc("authority", "call_remote", "reliable")
func _send_snapshot(data: Dictionary) -> void:
	if lan_host or not lan_connected: return
	if typeof(data.get("pieces")) != TYPE_ARRAY or data["pieces"].size() != 64: return
	if typeof(data.get("health")) != TYPE_ARRAY or data["health"].size() != 64: return
	pieces = data["pieces"].duplicate()
	health = data["health"].duplicate()
	ap = int(data["ap"])
	turn = int(data["turn"])
	winner = str(data["winner"])
	boss_hp = int(data["boss_hp"])
	boss_phase = int(data["boss_phase"])
	raid_round = int(data["raid_round"])
	raid_stage = int(data["raid_stage"])
	boss_target = int(data["boss_target"])
	battle_log = str(data["battle_log"])
	acted = data["acted"].duplicate()
	enemy_wave = int(data["enemy_wave"])
	mode = "raid"
	selected = int(data.get("selected", -1))
	curse_mode = bool(data.get("curse_mode", false))
	heal_used = bool(data.get("heal_used", false))
	_draw()

@rpc("any_peer", "call_remote", "reliable")
func _request_action(action: String, square: int = -1) -> void:
	if not lan_host or not lan_raid: return
	if multiplayer.get_remote_sender_id() <= 1: return
	if action == "tap" and square >= 0 and square < 64:
		_tap(square)
	elif action == "end":
		_end_turn()
	elif action == "heal":
		_heal_selected()
	elif action == "potion":
		_use_potion()
	elif action == "curse":
		_curse_selected()
	_broadcast_snapshot()

func _switch_mode() -> void:
	if lan_connected:
		lan_status.text = "Отключи сеть перед сменой режима."
		return
	mode = "arena"
	_reset()

func _start_raid() -> void:
	if lan_connected and not lan_host: return
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
	if lan_connected and not lan_host:
		_request_action.rpc_id(1, "potion")
		return
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
	if lan_connected and not lan_host:
		_request_action.rpc_id(1, "curse")
		return
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
	_flash_square(target, Color("#e99fff"))
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
	if winner == "": battle_log = "Проклятие наносит 30 урона."
	_draw()

func _spend_action(index: int) -> void:
	acted.append(index)
	selected = -1
	ap -= 1
	if ap <= 0 and winner == "":
		_end_turn()

func _reset() -> void:
	if lan_connected and not lan_host: return
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
	battle_result_shown = false
	raid_stage = mini(3, 1 + int(raid_wins / 3))
	boss_hp = 240 + (raid_stage - 1) * 100
	boss_phase = 1
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
	_broadcast_snapshot()

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
		var f := -1 if _team(pieces[a]) == 1 else 1
		if dc == 0 and pieces[b] == "":
			if dr == f: return true
			return dr == 2*f and r0 == (6 if _team(pieces[a]) == 1 else 1) and pieces[a+8*f] == ""
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

func _flash_square(index: int, tint: Color) -> void:
	if index < 0 or index >= buttons.size(): return
	var cell: Button = buttons[index]
	cell.modulate = tint
	var tween := create_tween()
	tween.tween_property(cell, "modulate", Color.WHITE, 0.35).set_trans(Tween.TRANS_SINE)

func _tap(i: int) -> void:
	if lan_connected and not lan_host:
		_request_action.rpc_id(1, "tap", i)
		return
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
			_flash_square(i, Color("#ff897b"))
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
			_flash_square(i, Color("#f6e5b0"))
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
	if lan_connected and not lan_host:
		_request_action.rpc_id(1, "heal")
		return
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
	if lan_connected and not lan_host:
		_request_action.rpc_id(1, "end")
		return
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

func _minion_actions() -> void:
	var minions: Array[int] = []
	for i in range(64):
		if _team(pieces[i]) == -1 and i != 4:
			minions.append(i)
	for source in minions:
		if pieces[source] == "" or winner != "": continue
		var attack_target := -1
		for target in range(64):
			if _team(pieces[target]) == 1 and _legal(source, target):
				if attack_target < 0 or health[target] < health[attack_target]:
					attack_target = target
		if attack_target >= 0:
			health[attack_target] -= DAMAGE[pieces[source].to_upper()]
			_flash_square(attack_target, Color("#ff8a77"))
			if health[attack_target] <= 0:
				if pieces[attack_target] == "K":
					winner = "ПОРАЖЕНИЕ"
				pieces[attack_target] = ""
				health[attack_target] = 0
			battle_log += "\nСтраж наносит удар!"
			continue
		var best := -1
		var best_distance := 9999
		for destination in range(64):
			if pieces[destination] != "" or not _legal(source,destination): continue
			for hero in range(64):
				if _team(pieces[hero]) != 1: continue
				var distance: int = absi(int(destination / 8) - int(hero / 8)) + absi(destination % 8 - hero % 8)
				if distance < best_distance:
					best_distance = distance
					best = destination
		if best >= 0:
			_move(source, best)

func _boss_action() -> void:
	if winner != "": return
	enemy_turn = true
	raid_round += 1
	turn_count += 1
	var boss_max_hp: int = 240 + (raid_stage - 1) * 100
	if boss_phase == 1 and boss_hp <= int(boss_max_hp / 2.0):
		boss_phase = 2
		battle_log = "ПАДШИЙ КОРОЛЬ В ЯРОСТИ! Его удары усиливаются."
	_minion_actions()
	if winner != "":
		enemy_turn = false
		_draw()
		return
	if boss_target >= 0 and _team(pieces[boss_target]) == 1:
		var damage := (25 if raid_round % 3 != 0 else 45) + (raid_stage - 1) * 10 + (15 if boss_phase == 2 else 0)
		health[boss_target] -= damage
		_flash_square(boss_target, Color("#ff5e72"))
		battle_log = "Падший король наносит %d урона по отмеченной клетке!" % damage
		if health[boss_target] <= 0:
			if pieces[boss_target] == "K": winner = "ПОРАЖЕНИЕ"
			pieces[boss_target] = ""
			health[boss_target] = 0
	else:
		battle_log = "Герои уклонились от удара Падшего короля!"
	if raid_round % (3 if boss_phase == 2 else 4) == 0 and boss_hp > 0:
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
	boss_portrait.visible = mode == "raid"
	boss_bar.visible = mode == "raid"
	boss_bar.max_value = 240 + (raid_stage - 1) * 100
	boss_bar.value = boss_hp
	phase_label.visible = mode == "raid"
	phase_label.text = "ФАЗА II • ЯРОСТЬ ПАДШЕГО" if boss_phase == 2 else "ФАЗА I • ПРОБУЖДЕНИЕ"
	inventory_label.text = "Ур. %d  •  Опыт: %d/%d  •  Золото: %d  •  Зелья: %d" % [player_level,experience,Progression.experience_needed(player_level),gold,potions]
	var equipped_name := "нет"
	if equipped >= 0 and equipped < equipment.size():
		equipped_name = str(equipment[equipped].get("name", "Артефакт")) + " (+" + str(_attack_bonus()) + ")"
	equipment_label.text = "Снаряжение: %s\nТрофеи: %d  •  Побед в рейдах: %d" % [equipped_name,equipment.size(),raid_wins]
	info.text = ("ГЛАВА %d • БОСС: %d/%d HP • Раунд %d\n" % [raid_stage, boss_hp, 240 + (raid_stage - 1) * 100, raid_round] if mode == "raid" else "") + battle_log
	for i in range(64):
		var b: Button = buttons[i]
		var p: String = pieces[i]
		b.text = ""
		var image_node: TextureRect = unit_images[i]
		image_node.texture = UNIT_TEXTURES.get(p.to_upper()) if p != "" else null
		image_node.modulate = Color("#f8e3c0") if _team(p) == 1 else Color("#e2a3e9")
		var hp_node: Label = hp_labels[i]
		hp_node.text = str(health[i]) if p != "" else ""
		hp_node.add_theme_color_override("font_color", Color("#f9e8b4") if _team(p) == 1 else Color("#eed0ff"))
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
	if winner != "" and not battle_result_shown:
		call_deferred("_show_result")
	if lan_host and lan_connected:
		call_deferred("_broadcast_snapshot")
