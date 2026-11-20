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
var main_menu: PanelContainer
var menu_title: Label
var sidebar_tabs: TabContainer
var ui_combat: VBoxContainer
var ui_camp: VBoxContainer
var ui_network: VBoxContainer
var battle_save_path := "user://battle_autosave.json"
var initializing := true
var tutorial_popup: AcceptDialog
var tutorial_seen_path := "user://tutorial_seen.flag"
var last_saved_turn := -1
var last_saved_round := -1
var shield_active := false

func _ready() -> void:
	_load_profile()
	_apply_global_theme()
	var bg := TextureRect.new()
	bg.texture = preload("res://assets/backgrounds/ruined_kingdom.svg")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	var layout := HBoxContainer.new()
	layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layout.add_theme_constant_override("separation", 12)
	add_child(layout)
	var board_frame := MarginContainer.new()
	board_frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	board_frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
	board_frame.add_theme_constant_override("margin_left", 18)
	board_frame.add_theme_constant_override("margin_top", 18)
	board_frame.add_theme_constant_override("margin_bottom", 18)
	layout.add_child(board_frame)
	var square := AspectRatioContainer.new()
	square.ratio = 1.0
	square.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	square.size_flags_vertical = Control.SIZE_EXPAND_FILL
	board_frame.add_child(square)
	var grid := GridContainer.new()
	grid.columns = 8
	grid.add_theme_constant_override("h_separation", 1)
	grid.add_theme_constant_override("v_separation", 1)
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
		emblem.offset_left = 0
		emblem.offset_top = -3
		emblem.offset_right = 0
		emblem.offset_bottom = -15
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
	sidebar.custom_minimum_size = Vector2(405, 0)
	sidebar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.add_child(sidebar)
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color("#0b101b")
	panel_style.border_color = Color("#705a42")
	panel_style.set_border_width_all(1)
	panel_style.set_corner_radius_all(18)
	panel_style.set_content_margin_all(14)
	sidebar.add_theme_stylebox_override("panel", panel_style)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sidebar.add_child(scroll)
	var ui := VBoxContainer.new()
	ui.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ui.add_theme_constant_override("separation", 8)
	scroll.add_child(ui)
	var heading := Label.new()
	heading.text = "♛  KINGDOM CHESS"
	heading.add_theme_font_size_override("font_size", 26)
	heading.add_theme_color_override("font_color", Color("#f1d49c"))
	ui.add_child(heading)
	var subtitle := Label.new()
	subtitle.text = "ВОЙНА КОРОЛЕВСТВ • ТАКТИЧЕСКАЯ RPG"
	subtitle.add_theme_font_size_override("font_size", 16)
	subtitle.add_theme_color_override("font_color", Color("#b8a4ba"))
	ui.add_child(subtitle)
	status = Label.new()
	status.add_theme_font_size_override("font_size", 21)
	ui.add_child(status)
	boss_portrait = TextureRect.new()
	boss_portrait.texture = preload("res://assets/backgrounds/fallen_king.svg")
	boss_portrait.custom_minimum_size = Vector2(0, 85)
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
	mode_button.text = "⚔ АРЕНА"
	mode_button.custom_minimum_size.y = 43
	mode_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mode_button.pressed.connect(_switch_mode)
	mode_row.add_child(mode_button)
	var raid_button := Button.new()
	raid_button.text = "♛ РЕЙД"
	raid_button.custom_minimum_size.y = 43
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
	var action_bar := HBoxContainer.new()
	action_bar.add_theme_constant_override("separation", 8)
	ui.add_child(action_bar)
	var heal := _make_action_button("✦ ЛЕЧЕНИЕ", _heal_selected, action_bar)
	heal.tooltip_text = "Восстановить 20 HP выбранному герою"
	var curse := _make_action_button("☄ ПРОКЛЯТИЕ", _curse_selected, action_bar)
	curse.tooltip_text = "Выбери ферзя или слона, затем цель"
	var shield := _make_action_button("⛨ ЩИТ", _shield_selected, action_bar)
	shield.tooltip_text = "Ладья защищает союзников от следующего удара босса"
	var potion := _make_action_button("♥ ЗЕЛЬЕ", _use_potion, action_bar)
	potion.tooltip_text = "Восстановить 40 HP"
	var end := _make_action_button("➤ ЗАВЕРШИТЬ ХОД", _end_turn, ui)
	end.custom_minimum_size.y = 56
	info = Label.new()
	info.add_theme_font_size_override("font_size", 17)
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.add_theme_color_override("font_color", Color("#d8d6df"))
	ui.add_child(info)
	var quick := HBoxContainer.new()
	quick.add_theme_constant_override("separation", 7)
	ui.add_child(quick)
	_make_action_button("🎒 СНАРЯЖЕНИЕ", _open_inventory, quick)
	_make_action_button("⚗ ЛАВКА", _open_shop, quick)
	_make_action_button("☰ МЕНЮ", _show_main_menu, quick)
		var tutorial := _make_action_button("❔ ПРАВИЛА И СПОСОБНОСТИ", _show_tutorial, ui)
	tutorial.custom_minimum_size.y = 38
	var network := Button.new()
	network.text = "◈  КООПЕРАТИВ ПО WI-FI"
	network.custom_minimum_size.y = 45
	network.pressed.connect(_show_network)
	ui.add_child(network)
	var network_dialog := AcceptDialog.new()
	network_dialog.name = "NetworkLobby"
	network_dialog.title = "КОМНАТА СОВМЕСТНОГО РЕЙДА"
	network_dialog.min_size = Vector2i(750, 360)
	add_child(network_dialog)
	var network_box := VBoxContainer.new()
	network_box.add_theme_constant_override("separation", 14)
	network_dialog.add_child(network_box)
	var network_caption := Label.new()
	network_caption.text = "Подключите оба телефона к одной Wi-Fi сети."
	network_caption.add_theme_font_size_override("font_size", 20)
	network_box.add_child(network_caption)
	var lan_row := HBoxContainer.new()
	lan_row.add_theme_constant_override("separation", 12)
	network_box.add_child(lan_row)
	_make_action_button("СОЗДАТЬ КОМНАТУ", _host_lan, lan_row)
	lan_address = LineEdit.new()
	lan_address.placeholder_text = "IP первого телефона"
	lan_address.custom_minimum_size = Vector2(220, 56)
	lan_address.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lan_row.add_child(lan_address)
	_make_action_button("ПОДКЛЮЧИТЬСЯ", _join_lan, lan_row)
	lan_status = Label.new()
	lan_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lan_status.add_theme_font_size_override("font_size", 20)
	lan_status.text = "Создайте комнату на первом телефоне."
	network_box.add_child(lan_status)
	_make_action_button("ОТКЛЮЧИТЬСЯ", _leave_lan, network_box)
	_create_main_menu()
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_lan_connected)
	multiplayer.connection_failed.connect(_on_lan_failed)
	multiplayer.server_disconnected.connect(_on_lan_disconnected)
	_create_inventory_popup()
	_create_shop_popup()
	_create_result_popup()
	_create_tutorial()
	_reset()
	initializing = false
	if not _restore_battle():
		_save_battle()
	if not FileAccess.file_exists(tutorial_seen_path):
		call_deferred("_show_tutorial")

func _apply_global_theme() -> void:
	var theme := Theme.new()
	var base := StyleBoxFlat.new()
	base.bg_color = Color("#243346")
	base.border_color = Color("#7d674f")
	base.set_border_width_all(1)
	base.set_corner_radius_all(10)
	base.set_content_margin_all(9)
	theme.set_stylebox("normal", "Button", base)
	var over := base.duplicate()
	over.bg_color = Color("#354f65")
	theme.set_stylebox("hover", "Button", over)
	theme.set_stylebox("pressed", "Button", over)
	theme.set_color("font_color", "Button", Color("#f2e6d2"))
	theme.set_color("font_hover_color", "Button", Color.WHITE)
	theme.set_color("font_color", "Label", Color("#f2e6d2"))
	self.theme = theme

func _make_action_button(label: String, callback: Callable, parent: Control) -> Button:
	var button := Button.new()
	button.text = label
	button.custom_minimum_size.y = 50
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_font_size_override("font_size", 17)
	button.pressed.connect(callback)
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("#233040")
	normal.border_color = Color("#665d5b")
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(11)
	normal.set_content_margin_all(8)
	var hover := normal.duplicate()
	hover.bg_color = Color("#354c61")
	var pressed := normal.duplicate()
	pressed.bg_color = Color("#6a4a3e")
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_color_override("font_color", Color("#f2e7d4"))
	parent.add_child(button)
	return button

func _create_tutorial() -> void:
	tutorial_popup = AcceptDialog.new()
	tutorial_popup.title = "КАК ИГРАТЬ"
	tutorial_popup.min_size = Vector2i(690, 460)
	tutorial_popup.dialog_text = "ЦЕЛЬ: победить Падшего короля.\n\n1. Нажми на своего героя на доске.\n2. Зелёные клетки — доступные ходы.\n3. Нажми на зелёную клетку для перемещения.\n4. Красная клетка — будущий удар босса: уйди с неё.\n5. У тебя 2 действия за ход.\n\nСПОСОБНОСТИ\n✦ Лечение — восстановить здоровье героя.\n☄ Проклятие — удар ферзя или слона.\n⛨ Щит — защита ладьи от атаки босса.\n♥ Зелье — лечение из запасов.\n\nСнаряжение и добыча сохраняются после рейда."
	add_child(tutorial_popup)
	tutorial_popup.confirmed.connect(_tutorial_complete)
	tutorial_popup.canceled.connect(_tutorial_complete)

func _show_tutorial() -> void:
	if tutorial_popup != null:
		tutorial_popup.popup_centered()

func _tutorial_complete() -> void:
	var file := FileAccess.open(tutorial_seen_path, FileAccess.WRITE)
	if file != null:
		file.store_string("1")
		file.close()

func _create_main_menu() -> void:
	main_menu = PanelContainer.new()
	main_menu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	main_menu.mouse_filter = Control.MOUSE_FILTER_STOP
	var backdrop := StyleBoxFlat.new()
	backdrop.bg_color = Color(0.025, 0.038, 0.07, 0.87)
	main_menu.add_theme_stylebox_override("panel", backdrop)
	add_child(main_menu)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	main_menu.add_child(center)
	var column := VBoxContainer.new()
	column.custom_minimum_size.x = 440
	column.add_theme_constant_override("separation", 8)
	center.add_child(column)
	menu_title = Label.new()
	menu_title.text = "♛"
	menu_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	menu_title.add_theme_font_size_override("font_size", 56)
	menu_title.add_theme_color_override("font_color", Color("#d9b97e"))
	column.add_child(menu_title)
	var game_title := Label.new()
	game_title.text = "ВОЙНА КОРОЛЕВСТВ"
	game_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	game_title.add_theme_font_size_override("font_size", 34)
	game_title.add_theme_color_override("font_color", Color("#f6e6c7"))
	column.add_child(game_title)
	var game_subtitle := Label.new()
	game_subtitle.text = "ХРОНИКИ ПАДШЕГО ТРОНА"
	game_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	game_subtitle.add_theme_font_size_override("font_size", 18)
	game_subtitle.add_theme_color_override("font_color", Color("#adbbc6"))
	column.add_child(game_subtitle)
	var menu_art := TextureRect.new()
	menu_art.texture = preload("res://assets/backgrounds/fallen_king.svg")
	menu_art.custom_minimum_size = Vector2(440, 110)
	menu_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	menu_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	column.add_child(menu_art)
	_make_action_button("⚔  НАЧАТЬ РЕЙД", _menu_start_raid, column)
	_make_action_button("♜  АРЕНА ДЛЯ ДВОИХ", _menu_start_arena, column)
	_make_action_button("◈  КООПЕРАТИВ ПО WI-FI", _menu_start_coop, column)
	_make_action_button("🎒  СНАРЯЖЕНИЕ", _open_inventory, column)
	_make_action_button("❔  КАК ИГРАТЬ", _show_tutorial, column)
	_make_action_button("ПРОДОЛЖИТЬ БИТВУ", _menu_continue, column)
	main_menu.visible = true

func _show_main_menu() -> void:
	if not lan_connected:
		_save_battle()
	main_menu.visible = true

func _menu_continue() -> void:
	if not _restore_battle():
		battle_log = "Сохранённой битвы нет. Выбери рейд или арену."
		_draw()
	main_menu.visible = false

func _menu_start_raid() -> void:
	_start_raid()
	main_menu.visible = false

func _menu_start_arena() -> void:
	if lan_connected: _leave_lan()
	mode = "arena"
	_reset()
	main_menu.visible = false

func _menu_start_coop() -> void:
	main_menu.visible = false
	_show_network()

func _show_network() -> void:
	get_node("NetworkLobby").popup_centered()

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
	var ips := IP.get_local_addresses()
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
		"selected": selected, "curse_mode": curse_mode, "heal_used": heal_used,
		"shield_active": shield_active
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
	shield_active = bool(data.get("shield_active", false))
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
	elif action == "shield":
		_shield_selected()
	_broadcast_snapshot()

func _save_battle() -> void:
	if initializing or lan_connected or pieces.size() != 64: return
	var payload := _snapshot()
	payload["mode"] = mode
	payload["saved_at"] = Time.get_unix_time_from_system()
	var file := FileAccess.open(battle_save_path, FileAccess.WRITE)
	if file == null: return
	file.store_string(JSON.stringify(payload))
	file.close()

func _restore_battle() -> bool:
	if lan_connected or not FileAccess.file_exists(battle_save_path): return false
	var file := FileAccess.open(battle_save_path, FileAccess.READ)
	if file == null: return false
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY: return false
	if typeof(parsed.get("pieces")) != TYPE_ARRAY or parsed["pieces"].size() != 64: return false
	if typeof(parsed.get("health")) != TYPE_ARRAY or parsed["health"].size() != 64: return false
	var new_mode: String = str(parsed.get("mode", "arena"))
	if new_mode != "arena" and new_mode != "raid": return false
	for item in parsed["pieces"]:
		if typeof(item) != TYPE_STRING or (item != "" and not GLYPHS.has(item)): return false
	for value in parsed["health"]:
		if typeof(value) != TYPE_FLOAT and typeof(value) != TYPE_INT: return false
	pieces = parsed["pieces"].duplicate()
	health = parsed["health"].duplicate()
	mode = new_mode
	ap = clampi(int(parsed.get("ap", 2)), 0, 2)
	turn = 1 if int(parsed.get("turn", 1)) == 1 else -1
	winner = str(parsed.get("winner", ""))
	boss_hp = maxi(0, int(parsed.get("boss_hp", 240)))
	boss_phase = clampi(int(parsed.get("boss_phase", 1)), 1, 2)
	raid_round = maxi(0, int(parsed.get("raid_round", 0)))
	raid_stage = clampi(int(parsed.get("raid_stage", 1)), 1, 3)
	boss_target = clampi(int(parsed.get("boss_target", -1)), -1, 63)
	battle_log = str(parsed.get("battle_log", "Битва продолжается."))
	acted = parsed.get("acted", []).duplicate()
	enemy_wave = maxi(0, int(parsed.get("enemy_wave", 0)))
	selected = -1
	curse_mode = false
	heal_used = bool(parsed.get("heal_used", false))
	shield_active = bool(parsed.get("shield_active", false))
	battle_result_shown = false
	_draw()
	return true

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_CLOSE_REQUEST:
		_save_battle()

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

func _shield_selected() -> void:
	if lan_connected and not lan_host:
		_request_action.rpc_id(1, "shield")
		return
	if winner != "" or mode != "raid" or selected < 0 or ap < 1: return
	if pieces[selected] != "R" or acted.has(selected):
		battle_log = "Щит может установить только светлая ладья."
		_draw()
		return
	shield_active = true
	battle_log = "Щит ладьи: следующий удар босса будет ослаблен на 50%."
	_spend_action(selected)
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
	_damage_popup(target, 30)
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
	shield_active = false
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

func _damage_popup(index: int, amount: int, healing: bool = false) -> void:
	if index < 0 or index >= buttons.size(): return
	var number := Label.new()
	number.text = ("+" if healing else "−") + str(amount)
	number.add_theme_font_size_override("font_size", 30)
	number.add_theme_color_override("font_color", Color("#92f3c5") if healing else Color("#ffb36e"))
	number.add_theme_color_override("font_shadow_color", Color("#090e16"))
	number.add_theme_constant_override("shadow_offset_x", 2)
	number.add_theme_constant_override("shadow_offset_y", 3)
	number.mouse_filter = Control.MOUSE_FILTER_IGNORE
	number.position = Vector2(13, 0)
	number.z_index = 30
	buttons[index].add_child(number)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(number, "position:y", -46.0, 0.65).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(number, "modulate:a", 0.0, 0.65)
	tween.chain().tween_callback(number.queue_free)

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
			_damage_popup(i, damage)
			_flash_square(i, Color("#ff897b"))
			if mode == "raid" and i == 4:
				boss_hp = maxi(0,health[i])
			if health[i] > 0:
				acted.append(selected)
			else:
				if pieces[i].to_upper() == "K":
					if mode == "raid": _raid_victory()
					else: winner = "ПОБЕДА СВЕТЛЫХ!" if turn == 1 else "ПОБЕДА ТЁМНЫХ!"
				elif mode == "raid":
					_reward(20)
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
	_animate_move(a, b)
	pieces[b] = pieces[a]
	health[b] = health[a]
	pieces[a] = ""
	health[a] = 0
	acted.append(b)

func _animate_move(source: int, destination: int) -> void:
	if source < 0 or source >= unit_images.size(): return
	if destination < 0 or destination >= unit_images.size(): return
	if pieces[source] == "": return
	var sprite := TextureRect.new()
	sprite.texture = UNIT_TEXTURES.get(pieces[source].to_upper())
	sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sprite.modulate = Color("#fff1c7") if _team(pieces[source]) == 1 else Color("#ff9ea8")
	sprite.z_index = 100
	var from_rect: Rect2 = buttons[source].get_global_rect()
	var to_rect: Rect2 = buttons[destination].get_global_rect()
	sprite.size = from_rect.size
	sprite.global_position = from_rect.position
	add_child(sprite)
	sprite.global_position = from_rect.position
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(sprite, "global_position", to_rect.position, 0.24).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(sprite, "modulate:a", 0.0, 0.24)
	tween.chain().tween_callback(sprite.queue_free)

func _heal_selected() -> void:
	if lan_connected and not lan_host:
		_request_action.rpc_id(1, "heal")
		return
	if winner != "" or heal_used or ap < 1 or selected < 0: return
	if _team(pieces[selected]) != turn or acted.has(selected): return
	var p: String = pieces[selected].to_upper()
	if health[selected] >= HP[p]: return
	var restored: int = mini(20, HP[p] - health[selected])
	health[selected] += restored
	_damage_popup(selected, restored, true)
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
			_damage_popup(attack_target, DAMAGE[pieces[source].to_upper()])
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
		if shield_active:
			damage = maxi(1, int(ceil(damage * 0.5)))
		health[boss_target] -= damage
		_damage_popup(boss_target, damage)
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
	shield_active = false
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
	if not lan_connected and pieces.size() == 64:
		_save_battle()
	status.text = winner if winner != "" else ("ГЕРОИ" if mode == "raid" else ("СВЕТЛЫЕ" if turn == 1 else "ТЁМНЫЕ")) + " • ОД: " + str(ap)
	mode_button.text = "⚔ АРЕНА" if mode == "arena" else "⚔ РЕЙД"
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
	info.text = ("⛨ ЩИТ АКТИВЕН\n" if shield_active else "") + ("ГЛАВА %d • БОСС: %d/%d HP • Раунд %d\n" % [raid_stage, boss_hp, 240 + (raid_stage - 1) * 100, raid_round] if mode == "raid" else "") + battle_log
	for i in range(64):
		var b: Button = buttons[i]
		var p: String = pieces[i]
		b.text = ""
		var image_node: TextureRect = unit_images[i]
		image_node.texture = UNIT_TEXTURES.get(p.to_upper()) if p != "" else null
		image_node.modulate = Color("#fff2dc") if _team(p) == 1 else Color("#db9ba5")
		var hp_node: Label = hp_labels[i]
		hp_node.text = str(health[i]) if p != "" else ""
		hp_node.add_theme_color_override("font_color", Color("#ffe9ad") if _team(p) == 1 else Color("#ffbdc5"))
		var style := StyleBoxFlat.new()
		var row: int = i / 8
		style.bg_color = Color("#192a34") if (row+i%8)%2 == 0 else Color("#47505a")
		style.border_color = Color("#46545d") if (row+i%8)%2 == 0 else Color("#7a7770")
		style.set_border_width_all(1)
		style.set_corner_radius_all(2)
		style.shadow_color = Color(0.01, 0.02, 0.04, 0.55)
		style.shadow_size = 3
		style.anti_aliasing = true
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
