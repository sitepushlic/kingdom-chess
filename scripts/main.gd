extends Control

const Progression = preload("res://scripts/progression.gd")
const Battlefield3D = preload("res://scripts/battlefield_3d.gd")
const HeroRoster = preload("res://scripts/hero_roster.gd")

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
var hp_bars: Array = []
var hp_bar_friendly_style: StyleBoxFlat
var hp_bar_enemy_style: StyleBoxFlat
var hazard_overlays: Array = []
var equipment_auras: Array = []
var visual_clock := 0.0
var selected := -1
var turn := 1
var ap := 2
var acted: Array = []
var winner := ""
var heal_used := false
var status: Label
var mode := "arena"
var selected_hero := "hero_01"
var hero_roster_dialog: AcceptDialog
var hero_roster_list: ItemList
var hero_roster_details: Label
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
var equipped_slots: Dictionary = {"Оружие":-1, "Тело":-1, "Реликвия":-1}
var raid_wins := 0
var dry_loot_streak := 0
var combat_hits := 0
var frost_guard_used := false
var phoenix_used := false
var poison_marks: Dictionary = {}
var hero_poison: Dictionary = {} # square -> remaining enemy turns
var raid_region := ""
var raid_encounter := ""
var raid_mission: Dictionary = {}
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
var shared_raid_stats: Dictionary = {}
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
var menu_toggle: Button
var battle_board: MarginContainer
var battle_layout: VBoxContainer
var battlefield_3d: Node3D
var battlefield_viewport: SubViewport
var battlefield_container: SubViewportContainer
const GRAPHICS_SETTINGS_PATH := "user://graphics.cfg"
var graphics_quality := 1
var graphics_button: Button
var castle: Dictionary = {"forge":0,"barracks":0,"treasury":0,"academy":0,"infirmary":0}
var castle_dialog: AcceptDialog
var castle_list: ItemList
var castle_details: Label
var owned_boards: Array = [0]
var selected_board := 0
var board_gallery_dialog: AcceptDialog
var board_gallery_list: ItemList
var board_gallery_details: Label

func _ready() -> void:
	hp_bar_friendly_style = StyleBoxFlat.new()
	hp_bar_friendly_style.bg_color = Color("#82d5ad")
	hp_bar_friendly_style.set_corner_radius_all(3)
	hp_bar_enemy_style = StyleBoxFlat.new()
	hp_bar_enemy_style.bg_color = Color("#d8838d")
	hp_bar_enemy_style.set_corner_radius_all(3)
	_load_profile()
	_load_graphics_quality()
	_apply_global_theme()
	var bg := TextureRect.new()
	bg.texture = preload("res://assets/backgrounds/ruined_kingdom.svg")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	var layout := VBoxContainer.new()
	battle_layout = layout
	layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layout.add_theme_constant_override("separation", 5)
	add_child(layout)
	var top_bar := HBoxContainer.new()
	top_bar.custom_minimum_size.y = 76
	top_bar.add_theme_constant_override("separation", 10)
	layout.add_child(top_bar)
	var top_brand := Label.new()
	top_brand.text = "♛  ВОЙНА КОРОЛЕВСТВ"
	top_brand.add_theme_font_size_override("font_size", 26)
	top_brand.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_brand.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	top_bar.add_child(top_brand)
	menu_toggle = _make_action_button("☰ МЕНЮ", _show_main_menu, top_bar)
	menu_toggle.custom_minimum_size = Vector2(145, 65)
	var board_frame := MarginContainer.new()
	battle_board = board_frame
	board_frame.custom_minimum_size.y = 710
	board_frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	board_frame.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	board_frame.add_theme_constant_override("margin_left", 6)
	board_frame.add_theme_constant_override("margin_top", 4)
	board_frame.add_theme_constant_override("margin_bottom", 4)
	layout.add_child(board_frame)
	var square := AspectRatioContainer.new()
	square.ratio = 1.0
	square.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	square.size_flags_vertical = Control.SIZE_EXPAND_FILL
	board_frame.add_child(square)
	var board_stack := Control.new()
	board_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	board_stack.size_flags_vertical = Control.SIZE_EXPAND_FILL
	square.add_child(board_stack)
	battlefield_container = SubViewportContainer.new()
	battlefield_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	battlefield_container.stretch = true
	battlefield_container.mouse_filter = Control.MOUSE_FILTER_STOP
	board_stack.add_child(battlefield_container)
	battlefield_viewport = SubViewport.new()
	battlefield_viewport.size = Vector2i(900, 900)
	battlefield_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	battlefield_viewport.gui_disable_input = true
	battlefield_container.add_child(battlefield_viewport)
	battlefield_3d = Battlefield3D.new()
	battlefield_viewport.add_child(battlefield_3d)
	battlefield_3d.set_visual_quality(graphics_quality)
	battlefield_3d.set_board_visual_style(selected_board)
	battlefield_3d.set_castle_visual_levels(castle)
	battlefield_container.gui_input.connect(_on_3d_board_input)
	var grid := GridContainer.new()
	grid.columns = 8
	grid.add_theme_constant_override("h_separation", 1)
	grid.add_theme_constant_override("v_separation", 1)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	board_stack.add_child(grid)
	grid.visible = false
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
		var aura := Panel.new()
		aura.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		aura.offset_left = 4
		aura.offset_top = 4
		aura.offset_right = -4
		aura.offset_bottom = -4
		aura.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var aura_style := StyleBoxFlat.new()
		aura_style.bg_color = Color(0, 0, 0, 0)
		aura_style.border_color = Color("#eac27b")
		aura_style.set_border_width_all(2)
		aura_style.set_corner_radius_all(13)
		aura.add_theme_stylebox_override("panel", aura_style)
		aura.visible = false
		b.add_child(aura)
		equipment_auras.append(aura)
		var hp := Label.new()
		hp.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
		hp.offset_top = -27
		hp.offset_bottom = -9
		hp.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hp.add_theme_font_size_override("font_size", 15)
		hp.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(hp)
		hp_labels.append(hp)
		var life := ProgressBar.new()
		life.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
		life.offset_left = 7
		life.offset_right = -7
		life.offset_top = -9
		life.offset_bottom = -3
		life.show_percentage = false
		life.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var life_bg := StyleBoxFlat.new()
		life_bg.bg_color = Color("#251d25")
		life_bg.set_corner_radius_all(3)
		life.add_theme_stylebox_override("background", life_bg)
		life.add_theme_stylebox_override("fill", hp_bar_friendly_style)
		b.add_child(life)
		hp_bars.append(life)
		var warning := ColorRect.new()
		warning.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		warning.color = Color(1.0, 0.12, 0.14, 0.24)
		warning.mouse_filter = Control.MOUSE_FILTER_IGNORE
		warning.visible = false
		b.add_child(warning)
		hazard_overlays.append(warning)
	var sidebar := PanelContainer.new()
	sidebar.custom_minimum_size = Vector2(0, 0)
	sidebar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sidebar.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(sidebar)
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color("#0b101b")
	panel_style.border_color = Color("#705a42")
	panel_style.set_border_width_all(1)
	panel_style.set_corner_radius_all(16)
	panel_style.set_content_margin_all(10)
	sidebar.add_theme_stylebox_override("panel", panel_style)
	var sidebar_column := VBoxContainer.new()
	sidebar_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sidebar_column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sidebar_column.add_theme_constant_override("separation", 6)
	sidebar.add_child(sidebar_column)
	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sidebar_column.add_child(scroll)
	var fixed_actions := VBoxContainer.new()
	fixed_actions.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fixed_actions.add_theme_constant_override("separation", 6)
	sidebar_column.add_child(fixed_actions)
	var ui := VBoxContainer.new()
	ui.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ui.add_theme_constant_override("separation", 8)
	scroll.add_child(ui)
	var heading := Label.new()
	heading.text = "♛  KINGDOM CHESS"
	heading.visible = false
	heading.add_theme_font_size_override("font_size", 19)
	heading.add_theme_color_override("font_color", Color("#f1d49c"))
	ui.add_child(heading)
	var subtitle := Label.new()
	subtitle.text = "ВОЙНА КОРОЛЕВСТВ • ТАКТИЧЕСКАЯ RPG"
	subtitle.visible = false
	subtitle.add_theme_font_size_override("font_size", 13)
	subtitle.add_theme_color_override("font_color", Color("#b8a4ba"))
	ui.add_child(subtitle)
	status = Label.new()
	status.add_theme_font_size_override("font_size", 20)
	ui.add_child(status)
	boss_portrait = TextureRect.new()
	boss_portrait.texture = preload("res://assets/backgrounds/fallen_king.svg")
	boss_portrait.custom_minimum_size = Vector2(0, 62)
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
	phase_label.add_theme_font_size_override("font_size", 15)
	phase_label.add_theme_color_override("font_color", Color("#e9a6a0"))
	ui.add_child(phase_label)
	var mode_row := HBoxContainer.new()
	ui.add_child(mode_row)
	mode_row.visible = false
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
	inventory_label.add_theme_font_size_override("font_size", 16)
	inventory_label.add_theme_color_override("font_color", Color("#e5c58c"))
	ui.add_child(inventory_label)
	equipment_label = Label.new()
	equipment_label.add_theme_font_size_override("font_size", 15)
	equipment_label.add_theme_color_override("font_color", Color("#c6e3e5"))
	equipment_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ui.add_child(equipment_label)
	var action_bar := GridContainer.new()
	action_bar.columns = 2
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
	action_bar.reparent(fixed_actions)
	end.reparent(fixed_actions)
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
	network_dialog.min_size = Vector2i(640, 450)
	add_child(network_dialog)
	var network_box := VBoxContainer.new()
	network_box.add_theme_constant_override("separation", 14)
	network_dialog.add_child(network_box)
	var network_caption := Label.new()
	network_caption.text = "Подключите оба телефона к одной Wi-Fi сети."
	network_caption.add_theme_font_size_override("font_size", 20)
	network_box.add_child(network_caption)
	var lan_row := VBoxContainer.new()
	lan_row.add_theme_constant_override("separation", 12)
	network_box.add_child(lan_row)
	_make_action_button("СОЗДАТЬ КОМНАТУ", _host_lan, lan_row)
	lan_address = LineEdit.new()
	lan_address.placeholder_text = "IP первого телефона"
	lan_address.custom_minimum_size = Vector2(560, 56)
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
	_create_hero_roster_popup()
	_create_shop_popup()
	_create_result_popup()
	_create_tutorial()
	_reset()
	var restored := _restore_battle()
	initializing = false
	if not restored:
		_save_battle()
	if not FileAccess.file_exists(tutorial_seen_path):
		call_deferred("_show_tutorial")

func _process(delta: float) -> void:
	visual_clock += delta
	for i in range(unit_images.size()):
		var emblem: TextureRect = unit_images[i]
		if i < pieces.size() and pieces[i] != "":
			var breath := sin(visual_clock * 2.2 + float(i) * 0.55)
			emblem.pivot_offset = emblem.size * 0.5
			emblem.scale = Vector2.ONE * (1.0 + breath * 0.025)
			emblem.modulate.a = 0.94 + breath * 0.06
		if i < equipment_auras.size():
			var aura: Panel = equipment_auras[i]
			if aura.visible:
				aura.modulate.a = 0.55 + 0.35 * (0.5 + 0.5 * sin(visual_clock * 2.5 + float(i)))
		if i < hazard_overlays.size():
			var warning: ColorRect = hazard_overlays[i]
			if warning.visible:
				warning.modulate.a = 0.45 + 0.5 * (0.5 + 0.5 * sin(visual_clock * 6.0))

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
	tutorial_popup.min_size = Vector2i(640, 620)
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
	var atmosphere := ColorRect.new()
	atmosphere.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	atmosphere.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var atmosphere_shader := Shader.new()
	atmosphere_shader.code = """
shader_type canvas_item;
void fragment() {
	vec2 uv = UV;
	float distance_to_center = length((uv - vec2(0.5, 0.46)) * vec2(1.0, 0.8));
	vec3 color = mix(vec3(0.012, 0.022, 0.043), vec3(0.14, 0.085, 0.073), (1.0 - smoothstep(0.12, 0.78, distance_to_center)));
	float mist = sin(uv.y * 12.0 + TIME * 0.17 + sin(uv.x * 8.0)) * 0.5 + 0.5;
	color += vec3(0.055, 0.027, 0.015) * mist * (1.0 - smoothstep(0.2, 0.85, uv.y));
	vec2 ember_grid = floor(vec2(uv.x * 16.0, uv.y * 28.0 + TIME * 0.3));
	vec2 ember_local = fract(vec2(uv.x * 16.0, uv.y * 28.0 + TIME * 0.3));
	float random_value = fract(sin(dot(ember_grid, vec2(127.1, 311.7))) * 43758.5453);
	float ember = (1.0 - smoothstep(0.015, 0.075, length(ember_local - vec2(random_value, 0.5)))) * step(0.93, random_value);
	color += vec3(0.8, 0.34, 0.1) * ember * 0.52;
	COLOR = vec4(color, 1.0);
}
"""
	var atmosphere_material := ShaderMaterial.new()
	atmosphere_material.shader = atmosphere_shader
	atmosphere.material = atmosphere_material
	main_menu.add_child(atmosphere)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	main_menu.add_child(center)
	var column := VBoxContainer.new()
	column.custom_minimum_size.x = 520
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
	game_title.add_theme_font_size_override("font_size", 32)
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
	menu_art.custom_minimum_size = Vector2(520, 185)
	menu_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	menu_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	column.add_child(menu_art)
	_make_action_button("⚔  НАЧАТЬ РЕЙД", _menu_start_raid, column)
	_make_action_button("♜  АРЕНА ДЛЯ ДВОИХ", _menu_start_arena, column)
	_make_action_button("◈  КООПЕРАТИВ ПО WI-FI", _menu_start_coop, column)
	_make_action_button("🎒  СНАРЯЖЕНИЕ", _open_inventory, column)
	_make_action_button("🏰  МОЁ КОРОЛЕВСТВО", _open_castle, column)
	_make_action_button("♟  МОЯ КОЛЛЕКЦИЯ ДОСОК", _open_board_gallery, column)
	graphics_button = _make_action_button("", _cycle_graphics_quality, column)
	_update_graphics_label()
	_make_action_button("❔  КАК ИГРАТЬ", _show_tutorial, column)
	_make_action_button("ПРОДОЛЖИТЬ БИТВУ", _menu_continue, column)
	main_menu.visible = true

func _open_castle() -> void:
	if castle_dialog == null:
		castle_dialog = AcceptDialog.new()
		castle_dialog.title = "МОЁ КОРОЛЕВСТВО — РАЗВИТИЕ ЗАМКА"
		castle_dialog.min_size = Vector2i(580, 560)
		add_child(castle_dialog)
		var layout := VBoxContainer.new()
		castle_dialog.add_child(layout)
		var intro := Label.new()
		intro.text = "Побеждай в рейдах, добывай золото и строй королевство. Улучшения работают только в PvE, не в шахматной арене."
		intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		layout.add_child(intro)
		castle_list = ItemList.new()
		castle_list.custom_minimum_size = Vector2(530, 290)
		layout.add_child(castle_list)
		castle_details = Label.new()
		castle_details.custom_minimum_size.y = 95
		castle_details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		layout.add_child(castle_details)
		castle_list.item_selected.connect(_on_castle_selected)
		var upgrade := Button.new()
		upgrade.text = "УЛУЧШИТЬ ЗДАНИЕ"
		upgrade.custom_minimum_size.y = 56
		upgrade.pressed.connect(_upgrade_castle_building)
		layout.add_child(upgrade)
	_refresh_castle()
	castle_dialog.popup_centered()

func _refresh_castle() -> void:
	if castle_list == null:
		return
	var current: int = 0
	var indices: PackedInt32Array = castle_list.get_selected_items()
	if not indices.is_empty():
		current = indices[0]
	castle_list.clear()
	for building in Progression.CASTLE_BUILDINGS:
		var level: int = int(castle.get(str(building["id"]), 0))
		castle_list.add_item("%s  •  уровень %d/100" % [str(building["name"]), level])
	castle_list.select(clampi(current, 0, Progression.CASTLE_BUILDINGS.size() - 1))
	_on_castle_selected(clampi(current, 0, Progression.CASTLE_BUILDINGS.size() - 1))

func _on_castle_selected(index: int) -> void:
	if castle_details == null or index < 0 or index >= Progression.CASTLE_BUILDINGS.size():
		return
	var building: Dictionary = Progression.CASTLE_BUILDINGS[index]
	var building_id: String = str(building["id"])
	var level: int = int(castle.get(building_id, 0))
	if level >= 100:
		castle_details.text = "%s\nУровень максимальный. Бонус: %d" % [building["description"], Progression.castle_bonus(castle, building_id)]
		return
	var cost: int = Progression.castle_upgrade_cost(building, level)
	var required_wins: int = Progression.castle_upgrade_requirement(building, level)
	castle_details.text = "%s\nБонус сейчас: %d\nСледующий уровень: %d золота; победы %d/%d; в казне %d" % [building["description"], Progression.castle_bonus(castle, building_id), cost, raid_wins, required_wins, gold]

func _upgrade_castle_building() -> void:
	if castle_list == null:
		return
	var indices: PackedInt32Array = castle_list.get_selected_items()
	if indices.is_empty():
		return
	var index: int = indices[0]
	if index < 0 or index >= Progression.CASTLE_BUILDINGS.size():
		return
	var building: Dictionary = Progression.CASTLE_BUILDINGS[index]
	var building_id: String = str(building["id"])
	var level: int = int(castle.get(building_id, 0))
	if not Progression.castle_upgrade_allowed(building, level, raid_wins, gold):
		_on_castle_selected(index)
		return
	gold -= Progression.castle_upgrade_cost(building, level)
	castle[building_id] = level + 1
	if battlefield_3d != null:
		battlefield_3d.set_castle_visual_levels(castle)
	_save_profile()
	_refresh_castle()
	_draw()

func _open_board_gallery() -> void:
	if board_gallery_dialog == null:
		board_gallery_dialog = AcceptDialog.new()
		board_gallery_dialog.title = "КОЛЛЕКЦИЯ ШАХМАТНЫХ ДОСОК"
		board_gallery_dialog.min_size = Vector2i(560, 520)
		add_child(board_gallery_dialog)
		var layout := VBoxContainer.new()
		board_gallery_dialog.add_child(layout)
		var intro := Label.new()
		intro.text = "Доски — только внешний вид. Побеждай в рейдах, собирай золото и открывай новые."
		intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		layout.add_child(intro)
		board_gallery_list = ItemList.new()
		board_gallery_list.custom_minimum_size = Vector2(520, 250)
		layout.add_child(board_gallery_list)
		board_gallery_details = Label.new()
		board_gallery_details.custom_minimum_size.y = 65
		board_gallery_details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		layout.add_child(board_gallery_details)
		board_gallery_list.item_selected.connect(_on_board_gallery_selected)
		var choose := Button.new()
		choose.text = "КУПИТЬ ИЛИ УСТАНОВИТЬ"
		choose.custom_minimum_size.y = 55
		choose.pressed.connect(_choose_board)
		layout.add_child(choose)
	_refresh_board_gallery()
	board_gallery_dialog.popup_centered()

func _refresh_board_gallery() -> void:
	if board_gallery_list == null:
		return
	board_gallery_list.clear()
	for index in range(Battlefield3D.BOARD_STYLES.size()):
		var palette: Dictionary = Battlefield3D.BOARD_STYLES[index]
		var marker := "✓" if index == selected_board else ("◆" if owned_boards.has(index) else "🔒")
		board_gallery_list.add_item("%s %s" % [marker, str(palette["name"])])
	board_gallery_list.select(selected_board)
	_on_board_gallery_selected(selected_board)

func _on_board_gallery_selected(index: int) -> void:
	if board_gallery_details == null or index < 0 or index >= Battlefield3D.BOARD_STYLES.size():
		return
	board_gallery_details.text = Progression.board_unlock_reason(index, owned_boards, raid_wins, gold)
	board_gallery_details.text += "\nДоска не влияет на характеристики героев и правила боя."

func _choose_board() -> void:
	if board_gallery_list == null:
		return
	var selected_items: PackedInt32Array = board_gallery_list.get_selected_items()
	if selected_items.is_empty():
		return
	var index: int = selected_items[0]
	if index < 0 or index >= Battlefield3D.BOARD_STYLES.size():
		return
	if not owned_boards.has(index):
		if raid_wins < Progression.BOARD_WIN_REQUIREMENTS[index] or gold < Progression.BOARD_COSTS[index]:
			_on_board_gallery_selected(index)
			return
		gold -= Progression.BOARD_COSTS[index]
		owned_boards.append(index)
		owned_boards.sort()
	selected_board = index
	if battlefield_3d != null:
		battlefield_3d.set_board_visual_style(selected_board)
	_save_profile()
	_refresh_board_gallery()
	board_gallery_list.select(index)
	_on_board_gallery_selected(index)
	_draw()

func _load_graphics_quality() -> void:
	var config := ConfigFile.new()
	if config.load(GRAPHICS_SETTINGS_PATH) == OK:
		var saved: Variant = config.get_value("graphics", "quality", 1)
		if typeof(saved) == TYPE_INT:
			graphics_quality = clampi(saved, 0, 2)

func _update_graphics_label() -> void:
	if graphics_button != null:
		graphics_button.text = "⚙  ГРАФИКА: " + ["НИЗКАЯ", "СРЕДНЯЯ", "ВЫСОКАЯ"][graphics_quality]

func _cycle_graphics_quality() -> void:
	graphics_quality = (graphics_quality + 1) % 3
	if battlefield_3d != null:
		battlefield_3d.set_visual_quality(graphics_quality)
	var config := ConfigFile.new()
	config.set_value("graphics", "quality", graphics_quality)
	config.save(GRAPHICS_SETTINGS_PATH)
	_update_graphics_label()

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
	inventory_popup.min_size = Vector2i(650, 580)
	add_child(inventory_popup)
	var contents := VBoxContainer.new()
	contents.add_theme_constant_override("separation", 12)
	inventory_popup.add_child(contents)
	inventory_details = Label.new()
	inventory_details.text = "Выбери предмет."
	inventory_details.add_theme_font_size_override("font_size", 19)
	contents.add_child(inventory_details)
	inventory_list = ItemList.new()
	inventory_list.custom_minimum_size = Vector2(590, 285)
	inventory_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	inventory_list.item_selected.connect(_inventory_select)
	contents.add_child(inventory_list)
	var actions := HBoxContainer.new()
	contents.add_child(actions)
	var equip := Button.new()
	equip.text = "ЭКИПИРОВАТЬ"
	equip.custom_minimum_size = Vector2(220, 55)
	equip.pressed.connect(_inventory_equip)
	actions.add_child(equip)
	var sell := Button.new()
	sell.text = "ПРОДАТЬ ЗА ЗОЛОТО"
	sell.custom_minimum_size = Vector2(220, 55)
	sell.pressed.connect(_inventory_sell)
	actions.add_child(sell)
	var upgrade := Button.new()
	upgrade.text = "УСИЛИТЬ"
	upgrade.custom_minimum_size = Vector2(140, 55)
	upgrade.pressed.connect(_inventory_upgrade)
	actions.add_child(upgrade)

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
		var slot: String = str(item.get("slot", "Оружие"))
		var mark := " [НАДЕТО]" if int(equipped_slots.get(slot, -1)) == i else ""
		inventory_list.add_item("%s • %s • %s • +%d атаки%s" % [name, slot, Progression.RARITIES[rarity], int(item.get("attack", 0)), mark])
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
	inventory_details.text = "%s • %s • Ур. %d • Усиление +%d/12\nАтака +%d  Защита +%d  HP +%d\nКрит %d%%  Вампиризм %d%%\nПробитие %d  Блок %d%%  Кровотечение %d%%\nСила %d • Цена усиления %d" % [item.get("name", "Артефакт"), Progression.RARITIES[rarity], int(item.get("level", 1)), int(item.get("upgrade", 0)), int(item.get("attack", 0)), int(item.get("armor", 0)), int(item.get("hp", 0)), int(item.get("crit", 0)), int(item.get("lifesteal", 0)), int(item.get("penetration", 0)), int(item.get("block", 0)), int(item.get("bleed", 0)), Progression.item_score(item), Progression.upgrade_cost(item)]
	if not Progression.can_equip(item, raid_wins, player_level):
		inventory_details.text += "\n🔒 Недоступно: требуется больше побед и уровней для этой редкости/усиления."
	var trait_id: int = int(item.get("trait_id", -1))
	if trait_id >= 0 and trait_id < Progression.TRAITS.size():
		inventory_details.text += "\nОСОБОЕ СВОЙСТВО: " + Progression.TRAITS[trait_id] + "\n" + Progression.TRAIT_DESCRIPTIONS[trait_id]

func _inventory_equip() -> void:
	if inventory_selected < 0 or inventory_selected >= equipment.size(): return
	var item: Dictionary = equipment[inventory_selected]
	if lan_connected and not lan_host:
		inventory_details.text = "В сетевом рейде экипировку меняет создатель комнаты."
		return
	if not Progression.can_equip(item, raid_wins, player_level):
		inventory_details.text = "Предмет пока заблокирован. Повышай уровень и побеждай боссов для открытия редкости и усилений."
		return
	var slot: String = str(item.get("slot", "Оружие"))
	if not Progression.ITEM_SLOTS.has(slot): slot = "Оружие"
	equipped_slots[slot] = inventory_selected
	equipped = inventory_selected if slot == "Оружие" else int(equipped_slots.get("Оружие", -1))
	_save_profile()
	_refresh_inventory()
	_draw()

func _inventory_upgrade() -> void:
	if lan_connected and not lan_host:
		inventory_details.text = "В кооперативе улучшения доступны только создателю комнаты."
		return
	if inventory_selected < 0 or inventory_selected >= equipment.size(): return
	var item: Dictionary = equipment[inventory_selected]
	if int(item.get("upgrade", 0)) >= Progression.upgrade_cap(raid_wins, player_level):
		inventory_details.text = "Лимит усиления текущей главы: +%d. Побеждай боссов и повышай уровень." % Progression.upgrade_cap(raid_wins, player_level)
		return
	var cost: int = Progression.upgrade_cost(item)
	if gold < cost:
		inventory_details.text = "Для улучшения нужно %d золота. Сейчас: %d." % [cost, gold]
		return
	gold -= cost
	equipment[inventory_selected] = Progression.upgrade_item(item)
	_save_profile()
	_refresh_inventory()
	_inventory_select(inventory_selected)
	_draw()

func _inventory_sell() -> void:
	if lan_connected and not lan_host:
		inventory_details.text = "Во время сетевого рейда снаряжение меняет хозяин комнаты."
		return
	if inventory_selected < 0 or inventory_selected >= equipment.size(): return
	var item: Dictionary = equipment[inventory_selected]
	var price: int = Progression.sell_price(item)
	gold += price
	equipment.remove_at(inventory_selected)
	for slot in Progression.ITEM_SLOTS:
		var index: int = int(equipped_slots.get(slot, -1))
		if index == inventory_selected: equipped_slots[slot] = -1
		elif index > inventory_selected: equipped_slots[slot] = index - 1
	equipped = int(equipped_slots.get("Оружие", -1))
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
	shared_raid_stats.clear()
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

static func sanitize_hero_poison(raw: Variant, board: Array) -> Dictionary:
	var clean: Dictionary = {}
	if typeof(raw) != TYPE_DICTIONARY or board.size() != 64: return clean
	for key in raw.keys():
		var cell: int = -1
		if typeof(key) == TYPE_INT:
			cell = key
		elif typeof(key) == TYPE_STRING and str(key).is_valid_int():
			cell = int(key)
		if cell < 0 or cell >= 64: continue
		if typeof(raw[key]) != TYPE_INT and typeof(raw[key]) != TYPE_FLOAT: continue
		var ticks: int = int(raw[key])
		if ticks < 1 or ticks > 2 or float(raw[key]) != float(ticks): continue
		if typeof(board[cell]) != TYPE_STRING: continue
		if not str(board[cell]) in ["K", "Q", "R", "B", "N", "P"]: continue
		clean[cell] = ticks
	return clean

static func valid_battle_arrays(board: Variant, hp_values: Variant) -> bool:
	if typeof(board) != TYPE_ARRAY or typeof(hp_values) != TYPE_ARRAY: return false
	if board.size() != 64 or hp_values.size() != 64: return false
	for index in range(64):
		if typeof(board[index]) != TYPE_STRING: return false
		if board[index] != "" and not GLYPHS.has(board[index]): return false
		if typeof(hp_values[index]) != TYPE_INT and typeof(hp_values[index]) != TYPE_FLOAT: return false
		var value: float = float(hp_values[index])
		if not is_finite(value) or value < 0.0 or value > 1000000.0: return false
		if board[index] == "" and value != 0.0: return false
	return true

static func valid_raid_snapshot(data: Variant) -> bool:
	if typeof(data) != TYPE_DICTIONARY: return false
	if not valid_battle_arrays(data.get("pieces"), data.get("health")): return false
	for key in ["ap", "turn", "boss_hp", "boss_phase", "raid_round", "raid_stage", "boss_target", "enemy_wave"]:
		if typeof(data.get(key)) != TYPE_INT: return false
	if int(data["ap"]) < 0 or int(data["ap"]) > 2: return false
	if int(data["turn"]) != 1 and int(data["turn"]) != -1: return false
	if int(data["boss_hp"]) < 0 or int(data["boss_hp"]) > 1000000: return false
	if int(data["boss_phase"]) < 1 or int(data["boss_phase"]) > 2: return false
	if int(data["raid_round"]) < 0 or int(data["raid_round"]) > 100000: return false
	if int(data["raid_stage"]) < 1 or int(data["raid_stage"]) > 6: return false
	if int(data["boss_target"]) < -1 or int(data["boss_target"]) > 63: return false
	if int(data["enemy_wave"]) < 0 or int(data["enemy_wave"]) > 100000: return false
	if typeof(data.get("winner")) != TYPE_STRING or typeof(data.get("battle_log")) != TYPE_STRING: return false
	if typeof(data.get("acted")) != TYPE_ARRAY: return false
	for square in data["acted"]:
		if typeof(square) != TYPE_INT or square < 0 or square >= 64: return false
	return true

func _snapshot() -> Dictionary:
	return {
		"pieces": pieces.duplicate(), "health": health.duplicate(),
		"hero_poison": hero_poison.duplicate(),
		"ap": ap, "turn": turn, "winner": winner,
		"boss_hp": boss_hp, "boss_phase": boss_phase,
		"raid_round": raid_round, "raid_stage": raid_stage, "raid_encounter": raid_encounter, "raid_mission": raid_mission.duplicate(true),
		"boss_target": boss_target, "battle_log": battle_log,
		"acted": acted.duplicate(), "enemy_wave": enemy_wave,
		"selected": selected, "curse_mode": curse_mode, "heal_used": heal_used,
		"shield_active": shield_active,
		"raid_stats": {
			"level": player_level, "attack": _attack_bonus(),
			"armor": _armor_bonus(), "hp": _item_stat("hp"),
			"penetration": _item_stat("penetration"), "block": _item_stat("block"), "bleed": _item_stat("bleed"),
			"crit": _item_stat("crit"), "lifesteal": _item_stat("lifesteal")
		}
	}

func _broadcast_snapshot() -> void:
	if not lan_host or multiplayer.multiplayer_peer == null: return
	sync_revision += 1
	_send_snapshot.rpc(_snapshot())

@rpc("authority", "call_remote", "reliable")
func _send_snapshot(data: Dictionary) -> void:
	if lan_host or not lan_connected: return
	if not valid_raid_snapshot(data): return
	pieces = data["pieces"].duplicate()
	health = data["health"].duplicate()
	hero_poison = sanitize_hero_poison(data.get("hero_poison", {}), pieces)
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
	raid_region = Progression.region_for_run(maxi(0, (raid_stage - 1) * 3))
	raid_encounter = str(data.get("raid_encounter", ""))
	raid_mission = data.get("raid_mission", Progression.mission_for_run(raid_wins)).duplicate(true)
	selected = int(data.get("selected", -1))
	curse_mode = bool(data.get("curse_mode", false))
	heal_used = bool(data.get("heal_used", false))
	shield_active = bool(data.get("shield_active", false))
	var incoming_stats: Variant = data.get("raid_stats", {})
	if typeof(incoming_stats) == TYPE_DICTIONARY:
		shared_raid_stats.clear()
		for stat in ["level", "attack", "armor", "hp", "crit", "lifesteal", "penetration", "block", "bleed"]:
			shared_raid_stats[stat] = clampi(int(incoming_stats.get(stat, 0)), 0, 10000)
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
	if not valid_battle_arrays(parsed.get("pieces"), parsed.get("health")): return false
	# JSON.parse_string() returns floating-point numbers for saved JSON integers.
	# Normalize only exact, bounded integral values from disk; keep network
	# snapshot validation strict so fractional/forged network fields stay rejected.
	for key in ["ap", "turn", "boss_hp", "boss_phase", "raid_round", "raid_stage", "boss_target", "enemy_wave"]:
		var value: Variant = parsed.get(key)
		if typeof(value) == TYPE_FLOAT:
			if not is_finite(value) or absf(value) > 1000000.0 or value != float(int(value)): return false
			parsed[key] = int(value)
	if typeof(parsed.get("acted")) != TYPE_ARRAY: return false
	for index in range(parsed["acted"].size()):
		var action: Variant = parsed["acted"][index]
		if typeof(action) == TYPE_FLOAT:
			if not is_finite(action) or action != float(int(action)): return false
			parsed["acted"][index] = int(action)
	# Reuse the same strict action/turn schema as network snapshots.
	if not valid_raid_snapshot(parsed): return false
	var new_mode: String = str(parsed.get("mode", "arena"))
	if new_mode != "arena" and new_mode != "raid": return false
	for item in parsed["pieces"]:
		if typeof(item) != TYPE_STRING or (item != "" and not GLYPHS.has(item)): return false
	for value in parsed["health"]:
		if typeof(value) != TYPE_FLOAT and typeof(value) != TYPE_INT: return false
	pieces = parsed["pieces"].duplicate()
	health = parsed["health"].duplicate()
	hero_poison = sanitize_hero_poison(parsed.get("hero_poison", {}), pieces)
	mode = new_mode
	ap = clampi(int(parsed.get("ap", 2)), 0, 2)
	turn = 1 if int(parsed.get("turn", 1)) == 1 else -1
	winner = str(parsed.get("winner", ""))
	boss_hp = maxi(0, int(parsed.get("boss_hp", 240)))
	boss_phase = clampi(int(parsed.get("boss_phase", 1)), 1, 2)
	raid_round = maxi(0, int(parsed.get("raid_round", 0)))
	raid_stage = clampi(int(parsed.get("raid_stage", 1)), 1, 6)
	raid_region = Progression.region_for_run(maxi(0, (raid_stage - 1) * 3))
	raid_mission = Progression.mission_for_run(raid_wins)
	raid_encounter = str(parsed.get("raid_encounter", raid_mission.get("type", "Штурм")))
	raid_mission = parsed.get("raid_mission", raid_mission).duplicate(true)
	boss_target = clampi(int(parsed.get("boss_target", -1)), -1, 63)
	battle_log = str(parsed.get("battle_log", "Битва продолжается."))
	acted = parsed["acted"].duplicate()
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
	selected_hero = str(profile.get("selected_hero", "hero_01"))
	castle = Progression.sanitize_castle(profile.get("castle", {}))
	owned_boards = Progression.sanitize_board_collection(profile.get("owned_boards", [0]))
	selected_board = int(profile.get("selected_board", 0))
	experience = int(profile["xp"])
	gold = int(profile["gold"])
	potions = int(profile["potions"])
	equipment = profile["items"]
	equipped = int(profile["equipped"])
	equipped_slots = profile.get("slots", {"Оружие":-1, "Тело":-1, "Реликвия":-1}).duplicate()
	if equipped >= 0 and int(equipped_slots.get("Оружие", -1)) < 0:
		equipped_slots["Оружие"] = equipped
	raid_wins = int(profile["wins"])
	dry_loot_streak = int(profile.get("dry_streak", 0))
	if equipped < 0 or equipped >= equipment.size():
		equipped = -1
	for slot in Progression.ITEM_SLOTS:
		var index: int = int(equipped_slots.get(slot, -1))
		if index < 0 or index >= equipment.size() or not Progression.can_equip(equipment[index], raid_wins, player_level): equipped_slots[slot] = -1

func _create_hero_roster_popup() -> void:
	hero_roster_dialog = AcceptDialog.new()
	hero_roster_dialog.title = "ГЕРОИ КОРОЛЕВСТВА — 30 ПЕРСОНАЖЕЙ"
	hero_roster_dialog.min_size = Vector2i(640, 850)
	add_child(hero_roster_dialog)
	var layout := VBoxContainer.new()
	hero_roster_dialog.add_child(layout)
	var intro := Label.new()
	intro.text = "Редкие герои открываются за победы и уровни. Выбери одного лидера."
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(intro)
	hero_roster_list = ItemList.new()
	hero_roster_list.custom_minimum_size = Vector2(610, 510)
	hero_roster_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(hero_roster_list)
	hero_roster_details = Label.new()
	hero_roster_details.custom_minimum_size.y = 150
	hero_roster_details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(hero_roster_details)
	hero_roster_list.item_selected.connect(_on_hero_roster_selected)
	var choose := Button.new()
	choose.text = "НАЗНАЧИТЬ ЛИДЕРОМ"
	choose.custom_minimum_size.y = 58
	choose.pressed.connect(_choose_hero)
	layout.add_child(choose)

func _open_hero_roster() -> void:
	hero_roster_list.clear()
	for hero in HeroRoster.HEROES:
		var open: bool = HeroRoster.unlocked(hero, raid_wins, player_level)
		var label: String = "%s %s • %s [%s]" % ["✓" if open else "🔒", hero["name"], hero["title"], HeroRoster.TIER_NAMES[int(hero["rarity"])]]
		hero_roster_list.add_item(label)
	hero_roster_list.select(0)
	for index in range(HeroRoster.HEROES.size()):
		if str(HeroRoster.HEROES[index]["id"]) == selected_hero:
			hero_roster_list.select(index)
			break
	_on_hero_roster_selected(hero_roster_list.get_selected_items()[0])
	hero_roster_dialog.popup_centered()

func _on_hero_roster_selected(index: int) -> void:
	if index < 0 or index >= HeroRoster.HEROES.size(): return
	var hero: Dictionary = HeroRoster.HEROES[index]
	var open: bool = HeroRoster.unlocked(hero, raid_wins, player_level)
	var progress: Dictionary = HeroRoster.quest_progress(hero, raid_wins, player_level)
	var unlock_text: String = "ДОСТУПЕН — можно выбрать" if open else "ЗАДАНИЕ: %s\nПобеды: %d/%d | Уровень: %d/%d" % [hero["quest"], progress["wins"], progress["required_wins"], progress["level"], progress["required_level"]]
	hero_roster_details.text = "%s • %s\n%s\nРоль: %s | Атака +%d | Защита +%d | HP +%d | Крит +%d%%\n%s" % [hero["name"], HeroRoster.TIER_NAMES[int(hero["rarity"])], hero["story"], hero["role"], hero["attack"], hero["armor"], hero["hp"], hero["crit"], unlock_text]

func _choose_hero() -> void:
	var indices := hero_roster_list.get_selected_items()
	if indices.is_empty(): return
	var hero: Dictionary = HeroRoster.HEROES[indices[0]]
	if not HeroRoster.unlocked(hero, raid_wins, player_level):
		hero_roster_details.text += "\nСначала выполни задание для открытия героя."
		return
	if winner == "" and mode == "raid" and raid_round > 0:
		hero_roster_details.text += "\nСменить лидера можно после завершения текущего рейда."
		return
	selected_hero = str(hero["id"])
	_save_profile()
	hero_roster_dialog.hide()
	_draw()

func _save_profile() -> void:
	Progression.save_profile({
		"level": player_level, "xp": experience, "gold": gold,
		"potions": potions, "items": equipment,
		"equipped": equipped, "slots": equipped_slots, "wins": raid_wins, "dry_streak": dry_loot_streak, "selected_hero": selected_hero,
		"owned_boards": owned_boards, "selected_board": selected_board, "castle": castle
	})

func _item_stat(stat: String) -> int:
	# Equal-stat local PvP: earned gear, hero rarity and level never decide a chess duel.
	if mode == "arena": return 0
	if lan_connected and not lan_host and shared_raid_stats.has(stat):
		return int(shared_raid_stats[stat])
	var total := 0
	for slot in Progression.ITEM_SLOTS:
		var index: int = int(equipped_slots.get(slot, -1))
		if index >= 0 and index < equipment.size() and Progression.can_equip(equipment[index], raid_wins, player_level):
			total += maxi(0, int(equipment[index].get(stat, 0)))
	var eligible_slots: Dictionary = equipped_slots.duplicate()
	for slot in Progression.ITEM_SLOTS:
		var item_index: int = int(eligible_slots.get(slot, -1))
		if item_index < 0 or item_index >= equipment.size() or not Progression.can_equip(equipment[item_index], raid_wins, player_level):
			eligible_slots[slot] = -1
	var set_stats: Dictionary = Progression.set_bonus(equipment, eligible_slots)
	total += int(set_stats.get(stat, 0))
	return total

func _has_trait(trait_id: int) -> bool:
	if mode == "arena": return false
	for slot in Progression.ITEM_SLOTS:
		var index: int = int(equipped_slots.get(slot, -1))
		if index >= 0 and index < equipment.size() and Progression.can_equip(equipment[index], raid_wins, player_level) and int(equipment[index].get("trait_id", -1)) == trait_id:
			return true
	return false

func _effective_level() -> int:
	if lan_connected and not lan_host and shared_raid_stats.has("level"):
		return maxi(1, int(shared_raid_stats["level"]))
	return player_level

func _attack_bonus() -> int:
	return _item_stat("attack") + (int(HeroRoster.get_hero(selected_hero)["attack"]) + Progression.castle_bonus(castle, "forge") if mode == "raid" else 0)

func _armor_bonus() -> int:
	return _item_stat("armor") + (int(HeroRoster.get_hero(selected_hero)["armor"]) if mode == "raid" else 0)

func _max_hp(piece: String, friendly: bool = true) -> int:
	return HP[piece.to_upper()] + (_item_stat("hp") + int(HeroRoster.get_hero(selected_hero)["hp"]) + Progression.castle_bonus(castle, "barracks") if friendly and mode == "raid" else 0)

func _deal_damage(target: int, raw_damage: int, attacker_is_hero: bool) -> int:
	var amount := maxi(1, raw_damage)
	if mode == "raid":
		if attacker_is_hero:
			combat_hits += 1
			if _has_trait(0) and combat_hits % 3 == 0:
				amount += maxi(8, int(ceil(float(amount) * 0.35)))
				battle_log += "\nОГНЕННЫЙ УДАР!"
			var execution_max: int = (240 + (raid_stage - 1) * 100 + int(raid_wins / 6.0) * 35) if target == 4 else _max_hp(pieces[target], false)
			if _has_trait(5) and health[target] < execution_max * 0.35:
				amount = int(ceil(float(amount) * 1.35))
				battle_log += "\nКАЗНЬ!"
			if _has_trait(4):
				poison_marks[target] = mini(5, int(poison_marks.get(target, 0)) + 1)
			var enemy_armor: int = (18 + raid_stage * 5) if target == 4 else (5 + raid_stage * 2)
			amount = Progression.damage_after_armor(amount, enemy_armor, _item_stat("penetration"))
			var crit_chance: int = _item_stat("crit") + int(HeroRoster.get_hero(selected_hero)["crit"])
			if randi_range(1, 100) <= crit_chance:
				amount = int(ceil(amount * 1.5))
				battle_log += "\nКРИТИЧЕСКИЙ УДАР!"
				if _has_trait(2):
					for other in range(64):
						if other != target and _team(pieces[other]) == -1:
							var arc_damage := maxi(1, int(ceil(float(amount) * 0.28)))
							health[other] = maxi(0, health[other] - arc_damage)
							_damage_popup(other, arc_damage)
							if other == 4: boss_hp = health[other]
							battle_log += "\nГРОЗОВОЙ РАЗРЯД: %d урона" % arc_damage
							break
		else:
			if _has_trait(1) and not frost_guard_used:
				amount = maxi(1, int(ceil(float(amount) * 0.55)))
				frost_guard_used = true
				battle_log += "\nЛЕДЯНОЙ ЩИТ!"
			amount = Progression.damage_after_armor(amount, _armor_bonus())
			if randi_range(1, 100) <= mini(60, _item_stat("block")):
				amount = maxi(1, int(ceil(amount * 0.5)))
				battle_log += "\nБЛОК! Урон снижен вдвое."
			if _has_trait(3) and not phoenix_used and amount >= health[target] and _team(pieces[target]) == 1:
				phoenix_used = true
				health[target] = maxi(1, int(ceil(float(_max_hp(pieces[target], true)) * 0.25)))
				_damage_popup(target, health[target], true)
				battle_log += "\nВОЗРОЖДЕНИЕ!"
				return 0
	health[target] = maxi(0, health[target] - amount)
	_damage_popup(target, amount)
	if attacker_is_hero and mode == "raid":
		if health[target] > 0 and randi_range(1, 100) <= _item_stat("bleed"):
			var bleed_damage: int = maxi(1, int(ceil(amount * 0.22)))
			health[target] = maxi(0, health[target] - bleed_damage)
			_damage_popup(target, bleed_damage)
			battle_log += "\nКРОВОТЕЧЕНИЕ: +%d урона" % bleed_damage
		var lifesteal: int = _item_stat("lifesteal")
		if lifesteal > 0 and selected >= 0 and selected < 64 and pieces[selected] != "":
			var restored: int = mini(int(ceil(amount * lifesteal / 100.0)), maxi(0, _max_hp(pieces[selected], _team(pieces[selected]) == 1) - health[selected]))
			if restored > 0:
				health[selected] += restored
				_damage_popup(selected, restored, true)
	return amount

func _equip_best() -> void:
	if equipment.is_empty():
		battle_log = "Предметы выпадают после победы в рейде."
		_draw()
		return
	var changed: Array[String] = []
	for slot in Progression.ITEM_SLOTS:
		var best := -1
		var best_score := -1
		for i in range(equipment.size()):
			var item: Dictionary = equipment[i]
			if str(item.get("slot", "")) != slot: continue
			if not Progression.can_equip(item, raid_wins, player_level): continue
			var score: int = Progression.item_score(item)
			if score > best_score:
				best_score = score
				best = i
		if best >= 0:
			equipped_slots[slot] = best
			changed.append(slot + ": " + str(equipment[best].get("name", "Артефакт")))
	equipped = int(equipped_slots.get("Оружие", -1))
	battle_log = "Автоподбор комплекта:\n" + "\n".join(changed) if not changed.is_empty() else "Пока нет экипировки доступного уровня."
	_save_profile()
	_draw()

func _reward(amount: int) -> void:
	var xp_gain: int = amount
	var gold_gain: int = int(amount / 2.0)
	if mode == "raid":
		xp_gain += int(float(amount) * float(Progression.castle_bonus(castle, "academy")) / 100.0)
		gold_gain += int(float(amount) * 0.5 * float(Progression.castle_bonus(castle, "treasury")) / 100.0)
	experience += xp_gain
	gold += gold_gain
	while player_level < 50 and experience >= Progression.experience_needed(player_level):
		experience -= Progression.experience_needed(player_level)
		player_level += 1
		potions += 1
		battle_log = "Новый уровень! Получено зелье."
	_save_profile()

func _minion_loot() -> void:
	if mode != "raid": return
	if equipment.size() >= 100:
		battle_log += "\nСумка заполнена (100/100)."
		return
	if dry_loot_streak < 15 and randi_range(1, 100) > mini(75, 18 + dry_loot_streak * 5):
		dry_loot_streak += 1
		_save_profile()
		return
	var item: Dictionary = Progression.roll_item_for_progress(player_level, raid_wins, false, mini(2, int(dry_loot_streak / 5)))
	dry_loot_streak = 0
	equipment.append(item)
	battle_log += "\nТРОФЕЙ: %s [%s]" % [item["name"], Progression.RARITIES[int(item["rarity"])]]
	_save_profile()

func _raid_victory() -> void:
	if winner != "": return
	winner = "ФИНАЛ КАМПАНИИ! КОРОЛЕВСТВО ОСВОБОЖДЕНО!" if raid_wins == 17 else "ПОБЕДА! БОСС ПОВЕРЖЕН!"
	raid_wins += 1
	_reward(100)
	var item: Dictionary = Progression.first_clear_reward(raid_wins)
	if not item.is_empty():
		item = Progression.limit_reward_to_progress(item, raid_wins, player_level)
	if item.is_empty():
		item = Progression.roll_item_for_progress(player_level, raid_wins, true, mini(2, int(raid_wins / 10)))
	if equipment.size() >= 100:
		gold += 100
		battle_log = "Сумка полна! Вместо реликвии получено 100 золота."
		_save_profile()
		return
	equipment.append(item)
	battle_log = "НАГРАДА ГЛАВЫ: %s!" % item["name"] if raid_wins % 3 == 0 and raid_wins <= 18 else "Добыча: %s (%s), +%d к атаке" % [item["name"], Progression.RARITIES[int(item["rarity"])], int(item["attack"])]
	if raid_wins == 18:
		battle_log += "\nСЮЖЕТ ЗАВЕРШЁН: все шесть регионов освобождены. Открыты бесконечные экспедиции с новыми сочетаниями противников."
	var newly_unlocked: Array[String] = []
	for hero in HeroRoster.HEROES:
		if HeroRoster.unlocked(hero, raid_wins, player_level) and not HeroRoster.unlocked(hero, raid_wins - 1, player_level):
			newly_unlocked.append(str(hero["name"]))
	if not newly_unlocked.is_empty():
		battle_log += "\nНОВЫЕ ГЕРОИ: %s! Открой список героев, чтобы выбрать лидера." % ", ".join(newly_unlocked)
	_save_profile()

func _use_potion() -> void:
	if lan_connected and not lan_host:
		_request_action.rpc_id(1, "potion")
		return
	if winner != "" or potions <= 0 or selected < 0 or ap < 1 or acted.has(selected): return
	if _team(pieces[selected]) != turn: return
	var p: String = pieces[selected].to_upper()
	if health[selected] >= _max_hp(p, _team(pieces[selected]) == 1): return
	var heal_amount: int = 40 + (Progression.castle_bonus(castle, "infirmary") if mode == "raid" else 0)
	var healed: int = mini(heal_amount, _max_hp(p, _team(pieces[selected]) == 1) - health[selected])
	health[selected] += healed
	_damage_popup(selected, healed, true)
	potions -= 1
	_save_profile()
	_spend_action(selected)
	battle_log = "Зелье восстанавливает до %d здоровья." % heal_amount
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
	if battlefield_3d != null: battlefield_3d.attack(source, target, true)
	_deal_damage(target, 30 + (_attack_bonus() if mode == "raid" else 0), turn == 1)
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
			_minion_loot()
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
	if battlefield_3d != null:
		battlefield_3d.clear_last_move_visual()
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
			health.append(_max_hp(p, _team(p) == 1) if p != "" else 0)
	turn = 1
	ap = 2
	selected = -1
	curse_mode = false
	turn_count = 0
	enemy_wave = 0
	battle_result_shown = false
	raid_stage = mini(6, 1 + int(raid_wins / 3))
	raid_region = Progression.region_for_run(raid_wins)
	raid_mission = Progression.mission_for_run(raid_wins)
	raid_encounter = str(raid_mission.get("type", "Штурм"))
	boss_hp = 240 + (raid_stage - 1) * 100 + int(raid_wins / 6.0) * 35
	boss_phase = 1
	combat_hits = 0
	frost_guard_used = false
	phoenix_used = false
	poison_marks.clear()
	hero_poison.clear()
	raid_round = 0
	boss_target = -1
	battle_log = ("%s • %s. %s\nКаждый ход: 2 действия. Нажми фигуру, затем подсвеченную клетку." % [raid_region, str(raid_mission.get("title", raid_encounter)), str(raid_mission.get("goal", "Победи босса."))]) if mode == "raid" else "Арена: два игрока на одном устройстве."
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
		match raid_encounter:
			"Осада":
				pieces[10] = "r"
				health[10] = HP["R"] + raid_stage * 15
			"Охота":
				pieces[10] = "n"
				health[10] = HP["N"] + raid_stage * 12
				pieces[13] = "n"
				health[13] = HP["N"] + raid_stage * 12
			"Засада":
				pieces[9] = "b"
				health[9] = HP["B"] + raid_stage * 10
				pieces[14] = "p"
				health[14] = HP["P"] + raid_stage * 10
			"Разлом":
				pieces[10] = "q"
				health[10] = HP["Q"] + raid_stage * 18
			_:
				pass
		var modifier: String = str(raid_mission.get("modifier", "none"))
		match modifier:
			"fortified":
				for i in range(64):
					if _team(pieces[i]) == -1 and i != 4: health[i] += 35 + raid_stage * 9
			"fury":
				for i in range(64):
					if _team(pieces[i]) == -1 and i != 4: health[i] += 10 + raid_stage * 5
			"ambush":
				for i in [17, 22]:
					if pieces[i] == "":
						pieces[i] = "p"
						health[i] = HP["P"] + raid_stage * 8
			"rift":
				for i in [18, 21]:
					if pieces[i] == "":
						pieces[i] = "n"
						health[i] = HP["N"] + raid_stage * 6
			_:
				pass
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

# A threatened king cannot walk into a square attacked by an enemy chess piece.
# This uses geometric threats, independent of HP: even a surviving defender
# controls its capture squares. Raid boss movement is handled separately.
func _king_destination_safe(source: int, destination: int) -> bool:
	if source < 0 or source >= 64 or destination < 0 or destination >= 64: return false
	var moving_team: int = _team(pieces[source])
	if moving_team == 0: return false
	var simulated: Array = pieces.duplicate()
	simulated[destination] = simulated[source]
	simulated[source] = ""
	return not _king_threatened(simulated, moving_team)

func _king_threatened(board: Array, team: int) -> bool:
	var king_square: int = board.find("K" if team == 1 else "k")
	if king_square < 0: return true
	for enemy in range(64):
		if _team(str(board[enemy])) == -team and _chess_attacks_square(board, enemy, king_square):
			return true
	return false

# Nonlethal attacks do not relocate their attacker. Simulate only actual
# movement or lethal captures when testing whether a pinned unit may move.
func _move_preserves_king(source: int, destination: int) -> bool:
	if mode == "raid": return true
	if pieces[destination] != "":
		# The attacker only relocates when damage kills the target. For a
		# nonlethal RPG strike the current board remains in place.
		var attacker_team: int = _team(pieces[source])
		var current_safe: bool = not _king_threatened(pieces, attacker_team)
		var capture_safe: bool = _king_destination_safe(source, destination)
		var damage: int = DAMAGE.get(pieces[source].to_upper(), 0)
		var lethal: bool = health.size() == 64 and int(health[destination]) <= damage
		return capture_safe if lethal else current_safe
	return _king_destination_safe(source, destination)

# Pure attack geometry: pawns threaten diagonals even when a square is empty.
func _chess_attacks_square(board: Array, source: int, target: int) -> bool:
	if source < 0 or source >= 64 or target < 0 or target >= 64 or source == target: return false
	var piece: String = str(board[source])
	if piece == "": return false
	var dr: int = int(target / 8) - int(source / 8)
	var dc: int = target % 8 - source % 8
	var kind: String = piece.to_upper()
	if kind == "P":
		return dr == (-1 if piece == "P" else 1) and absi(dc) == 1
	if kind == "N": return (absi(dr) == 2 and absi(dc) == 1) or (absi(dr) == 1 and absi(dc) == 2)
	if kind == "K": return maxi(absi(dr), absi(dc)) == 1
	if kind == "R" and dr != 0 and dc != 0: return false
	if kind == "B" and absi(dr) != absi(dc): return false
	if kind == "Q" and not (dr == 0 or dc == 0 or absi(dr) == absi(dc)): return false
	var step_r: int = signi(dr)
	var step_c: int = signi(dc)
	var r: int = int(source / 8) + step_r
	var c: int = source % 8 + step_c
	while r != int(target / 8) or c != target % 8:
		if board[r * 8 + c] != "": return false
		r += step_r
		c += step_c
	return true

func _legal(a: int, b: int) -> bool:
	if pieces.size() != 64 or health.size() != 64: return false
	if a < 0 or a >= 64 or b < 0 or b >= 64: return false
	if a == b or pieces[a] == "": return false
	if _team(pieces[a]) == _team(pieces[b]): return false
	var p: String = pieces[a].to_upper()
	var r0: int = a / 8
	var c0: int = a % 8
	var r1: int = b / 8
	var c1: int = b % 8
	var dr: int = r1 - r0
	var dc: int = c1 - c0
	if p == "N": return ((abs(dr) == 2 and abs(dc) == 1) or (abs(dr) == 1 and abs(dc) == 2)) and _move_preserves_king(a, b)
	if p == "K":
		if maxi(absi(dr), absi(dc)) != 1: return false
		return _move_preserves_king(a, b)
	if p == "P":
		var f := -1 if _team(pieces[a]) == 1 else 1
		if dc == 0 and pieces[b] == "":
			if dr == f: return _move_preserves_king(a, b)
			return dr == 2*f and r0 == (6 if _team(pieces[a]) == 1 else 1) and pieces[a+8*f] == "" and _move_preserves_king(a, b)
		return abs(dc) == 1 and dr == f and pieces[b] != "" and _move_preserves_king(a, b)
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
	return _move_preserves_king(a, b)

func _attack_trail(source: int, target: int) -> void:
	if source < 0 or source >= buttons.size() or target < 0 or target >= buttons.size(): return
	var trail := Line2D.new()
	trail.width = 9.0
	trail.default_color = Color("#f8d38e") if _team(pieces[source]) == 1 else Color("#e16a86")
	trail.antialiased = true
	trail.z_index = 95
	trail.add_point(buttons[source].get_global_rect().get_center() - global_position)
	trail.add_point(buttons[target].get_global_rect().get_center() - global_position)
	add_child(trail)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(trail, "width", 1.0, 0.28).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(trail, "modulate:a", 0.0, 0.28)
	tween.chain().tween_callback(trail.queue_free)

func _animate_hit(index: int, healing: bool = false) -> void:
	if index < 0 or index >= unit_images.size(): return
	var sprite: TextureRect = unit_images[index]
	if sprite.texture == null: return
	var original_position: Vector2 = sprite.position
	var original_color: Color = Color("#a4ffda") if healing else Color("#ff656e")
	sprite.modulate = original_color
	var tween := create_tween()
	tween.tween_property(sprite, "position:x", original_position.x - 7.0, 0.055)
	tween.tween_property(sprite, "position:x", original_position.x + 6.0, 0.075)
	tween.tween_property(sprite, "position:x", original_position.x, 0.10)
	tween.parallel().tween_property(sprite, "modulate", Color.WHITE, 0.25)

func _impact_effect(index: int, healing: bool = false) -> void:
	if index < 0 or index >= buttons.size(): return
	var cell: Button = buttons[index]
	var ring := Panel.new()
	ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ring.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ring.pivot_offset = cell.size * 0.5
	ring.scale = Vector2(0.25, 0.25)
	ring.modulate.a = 0.95
	ring.z_index = 22
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0)
	style.border_color = Color("#8affce") if healing else Color("#ffc06b")
	style.set_border_width_all(5)
	style.set_corner_radius_all(22)
	ring.add_theme_stylebox_override("panel", style)
	cell.add_child(ring)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(ring, "scale", Vector2(1.4, 1.4), 0.38).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(ring, "modulate:a", 0.0, 0.38)
	tween.chain().tween_callback(ring.queue_free)

func _damage_popup(index: int, amount: int, healing: bool = false) -> void:
	if battlefield_3d != null:
		battlefield_3d.hit(index, healing)
		battlefield_3d.show_combat_number(index, amount, healing)

	if index < 0 or index >= buttons.size(): return
	# The 2D grid is a hidden input fallback when the 3D SubViewport is active.
	# Avoid allocating invisible sprites, tweens and labels for every combat hit.
	if not buttons[index].get_parent().visible:
		return
	_impact_effect(index, healing)
	_animate_hit(index, healing)
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

func _on_3d_board_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var scale_factor := Vector2(battlefield_viewport.size) / battlefield_container.size
		var square_index: int = battlefield_3d.pick_square(event.position * scale_factor)
		if square_index >= 0:
			_tap(square_index)

func _tap(i: int) -> void:
	# Network peers and touch handlers must never index outside the chessboard.
	if i < 0 or i >= 64: return
	if lan_connected and not lan_host:
		_request_action.rpc_id(1, "tap", i)
		return
	if winner != "" or enemy_turn or ap <= 0 or (mode == "raid" and turn == -1): return
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
			if mode == "raid" and turn == 1: damage += (player_level - 1) * 2 + _attack_bonus()
			_attack_trail(selected, i)
			if battlefield_3d != null: battlefield_3d.attack(selected, i)
			_deal_damage(i, damage, turn == 1)
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
					_minion_loot()
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
	if battlefield_3d != null: battlefield_3d.animate_move(a, b)
	_animate_move(a, b)
	# Status follows the moving unit, not the vacated board square.
	var poison_turns: int = int(hero_poison.get(a, 0))
	var enemy_poison_stacks: int = int(poison_marks.get(a, 0))
	hero_poison.erase(a)
	hero_poison.erase(b)
	poison_marks.erase(a)
	poison_marks.erase(b)
	if poison_turns > 0: hero_poison[b] = poison_turns
	if enemy_poison_stacks > 0: poison_marks[b] = enemy_poison_stacks
	pieces[b] = pieces[a]
	health[b] = health[a]
	# Pawn promotion retains the chess class system: reaching the back rank
	# upgrades the unit to a queen and preserves its current HP.
	if pieces[b] == "P" and int(b / 8) == 0: pieces[b] = "Q"
	elif pieces[b] == "p" and int(b / 8) == 7: pieces[b] = "q"
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
	if health[selected] >= _max_hp(p, _team(pieces[selected]) == 1): return
	var restored: int = mini(20, _max_hp(p, _team(pieces[selected]) == 1) - health[selected])
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

# Checks whether the active side has any legal chess movement or RPG strike.
# In a damage-based battle, a legal attack is not necessarily an immediate
# check escape; full HP-aware mate evaluation remains a separate rule.
func _has_legal_action(team: int) -> bool:
	for source in range(64):
		if _team(pieces[source]) != team: continue
		for destination in range(64):
			if _legal(source, destination): return true
	return false

func _end_turn() -> void:
	if lan_connected and not lan_host:
		_request_action.rpc_id(1, "end")
		return
	if winner != "": return
	# In arena a player cannot pass the turn while their king is in check.
	# RPG attacks may require multiple actions to defeat a threatening unit.
	# Restore one action so the defender can continue resolving the threat.
	if mode == "arena" and _king_threatened(pieces, turn):
		if not _has_legal_action(turn):
			winner = "ПОБЕДА ТЁМНЫХ!" if turn == 1 else "ПОБЕДА СВЕТЛЫХ!"
			battle_log = "МАТ: нет допустимых действий для защиты короля."
			_draw()
			return
		ap = maxi(1, ap)
		acted.clear()
		selected = -1
		battle_log = "ШАХ! Защитите короля перед завершением хода."
		_draw()
		return
	if mode == "raid" and turn == 1:
		_boss_action()
		return
	turn = -turn
	if mode == "arena" and not _has_legal_action(turn):
		if _king_threatened(pieces, turn):
			winner = "ПОБЕДА ТЁМНЫХ!" if turn == 1 else "ПОБЕДА СВЕТЛЫХ!"
			battle_log = "МАТ: королю некуда уйти и нет допустимых защитных действий."
		else:
			winner = "НИЧЬЯ"
			battle_log = "ПАТ: нет допустимых ходов, король не под шахом."
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
			_deal_damage(attack_target, DAMAGE[pieces[source].to_upper()], false)
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

func _boss_aoe_hit(index: int, damage: int) -> void:
	if index < 0 or index >= 64 or _team(pieces[index]) != 1: return
	_deal_damage(index, damage, false)
	if health[index] <= 0:
		if pieces[index] == "K": winner = "ПОРАЖЕНИЕ"
		pieces[index] = ""
		health[index] = 0

func _tick_hero_poison() -> void:
	var remaining: Dictionary = {}
	for key in hero_poison.keys():
		var cell: int = int(key)
		if cell < 0 or cell >= 64 or _team(pieces[cell]) != 1: continue
		_boss_aoe_hit(cell, 3 + raid_stage * 2)
		if winner != "": break
		if _team(pieces[cell]) == 1 and int(hero_poison[key]) > 1:
			remaining[cell] = int(hero_poison[key]) - 1
	hero_poison = remaining

func _apply_mission_modifier() -> void:
	if mode != "raid" or winner != "": return
	var modifier: String = str(raid_mission.get("modifier", "none"))
	match modifier:
		"frost":
			if raid_round % 3 == 0:
				var chilled := 0
				for cell in range(64):
					if _team(pieces[cell]) == 1 and int(cell / 8) <= 4:
						_boss_aoe_hit(cell, 8 + raid_stage * 3)
						chilled += 1
				if chilled > 0: battle_log += "\nМОРОЗ: ледяная волна поразила %d героев." % chilled
		"poison":
			if raid_round % 3 == 0:
				var poisoned := 0
				for cell in range(64):
					if _team(pieces[cell]) == 1 and cell % 8 in [1, 6]:
						_boss_aoe_hit(cell, 6 + raid_stage * 2)
						if _team(pieces[cell]) == 1: hero_poison[cell] = 2
						poisoned += 1
				if poisoned > 0: battle_log += "\nЯДОВИТЫЙ ТУМАН: %d героев под ударом." % poisoned
		"fury":
			if raid_round % 3 == 0:
				for cell in range(64):
					if _team(pieces[cell]) == -1 and cell != 4:
						health[cell] += 10 + raid_stage * 3
				battle_log += "\nЯРОСТЬ: прислужники восстанавливают здоровье."
		"fortified":
			if raid_round % 4 == 0:
				for cell in range(64):
					if _team(pieces[cell]) == -1 and cell != 4:
						health[cell] += 8 + raid_stage * 2
				battle_log += "\nУКРЕПЛЕНИЯ: гарнизон укрепляет оборону."
		"ambush":
			if raid_round % 4 == 0:
				for cell in [16, 23]:
					if pieces[cell] == "":
						pieces[cell] = "p"
						health[cell] = HP["P"] + raid_stage * 5
						battle_log += "\nЗАСАДА: прибыло подкрепление!"
						break
		"rift":
			if raid_round % 3 == 0:
				var burned := 0
				for cell in range(64):
					if _team(pieces[cell]) == 1 and cell % 8 in [3, 4]:
						_boss_aoe_hit(cell, 9 + raid_stage * 3)
						burned += 1
				if burned > 0: battle_log += "\nРАЗЛОМ: %d героев получили урон." % burned

func _boss_action() -> void:
	if winner != "": return
	enemy_turn = true
	raid_round += 1
	_tick_hero_poison()
	if winner != "":
		enemy_turn = false
		_draw()
		return
	frost_guard_used = false
	turn_count += 1
	for target in poison_marks.keys():
		var square: int = int(target)
		if square < 0 or square >= 64 or _team(pieces[square]) != -1:
			continue
		var poison_damage: int = int(poison_marks[target]) * (4 + raid_stage * 2)
		health[square] = maxi(0, health[square] - poison_damage)
		_damage_popup(square, poison_damage)
		battle_log += "\nЯД: %d урона" % poison_damage
		if square == 4:
			boss_hp = health[square]
			if boss_hp <= 0:
				_raid_victory()
				_draw()
				return
		elif health[square] <= 0:
			pieces[square] = ""
			health[square] = 0
	poison_marks.clear()
	var boss_max_hp: int = 240 + (raid_stage - 1) * 100 + int(raid_wins / 6.0) * 35
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
		damage = _deal_damage(boss_target, damage, false)
		_flash_square(boss_target, Color("#ff5e72"))
		battle_log = "Падший король наносит %d урона по отмеченной клетке!" % damage
		if health[boss_target] <= 0:
			if pieces[boss_target] == "K": winner = "ПОРАЖЕНИЕ"
			pieces[boss_target] = ""
			health[boss_target] = 0
	else:
		battle_log = "Герои уклонились от удара Падшего короля!"
	if raid_stage == 2 and raid_round % 3 == 0:
		for hero_index in range(64):
			if _team(pieces[hero_index]) == 1 and int(hero_index / 8) <= 3:
				_boss_aoe_hit(hero_index, 10 + raid_stage * 3)
				battle_log += "\nЛЕДЯНАЯ БУРЯ: %d клетка" % hero_index
	elif raid_stage == 3 and raid_round % 3 == 0:
		var weakest := -1
		for hero_index in range(64):
			if _team(pieces[hero_index]) == 1 and (weakest < 0 or health[hero_index] < health[weakest]):
				weakest = hero_index
		if weakest >= 0:
			_boss_aoe_hit(weakest, 18 + raid_stage * 4)
			battle_log += "\nПРИЗРАЧНЫЙ УДАР!"
	elif raid_stage == 4 and raid_round % 4 == 0:
		boss_hp = mini(boss_max_hp, boss_hp + 30 + raid_stage * 8)
		health[4] = boss_hp
		battle_log += "\nОБСИДИАНОВОЕ СЕРДЦЕ: босс восстанавливает здоровье!"
	elif raid_stage == 5 and raid_round % 3 == 0:
		for hero_index in range(64):
			if _team(pieces[hero_index]) == 1 and hero_index % 8 in [2, 5]:
				_boss_aoe_hit(hero_index, 12 + raid_stage * 3)
				battle_log += "\nНЕБЕСНАЯ МОЛНИЯ!"
	elif raid_stage == 6 and raid_round % 3 == 0:
		for hero_index in range(64):
			if _team(pieces[hero_index]) == 1 and health[hero_index] > 0:
				_boss_aoe_hit(hero_index, 8 + raid_stage * 2)
		battle_log += "\nТЬМА ПОГЛОЩАЕТ АРЕНУ!"
	if raid_encounter == "Разлом" and raid_round % 4 == 0:
		for hero_index in range(64):
			if _team(pieces[hero_index]) == 1 and hero_index % 8 == 4:
				_boss_aoe_hit(hero_index, 12 + raid_stage * 5)
				battle_log += "\nРазлом обжигает центральную линию!"
	_apply_mission_modifier()
	if winner != "":
		enemy_turn = false
		_draw()
		return
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
	if status == null or mode_button == null or boss_portrait == null or boss_bar == null or phase_label == null or inventory_label == null or equipment_label == null or info == null:
		return
	status.text = winner if winner != "" else ("ГЕРОИ" if mode == "raid" else ("СВЕТЛЫЕ" if turn == 1 else "ТЁМНЫЕ")) + " • ОД: " + str(ap) + (" • ШАХ!" if mode == "arena" and _king_threatened(pieces, turn) else "")
	mode_button.text = "⚔ АРЕНА" if mode == "arena" else "⚔ РЕЙД"
	boss_portrait.visible = mode == "raid"
	boss_bar.visible = mode == "raid"
	boss_bar.max_value = 240 + (raid_stage - 1) * 100 + int(raid_wins / 6.0) * 35
	boss_bar.value = boss_hp
	phase_label.visible = mode == "raid"
	phase_label.text = "ФАЗА II • ЯРОСТЬ ПАДШЕГО" if boss_phase == 2 else "ФАЗА I • ПРОБУЖДЕНИЕ"
	inventory_label.text = "Ур. %d  •  Опыт: %d/%d  •  Золото: %d  •  Зелья: %d" % [player_level,experience,Progression.experience_needed(player_level),gold,potions]
	equipment_label.text = "⚔ +%d  ⛨ +%d  ♥ +%d  ✦ %d%%  ☽ %d%%\nТрофеи: %d  •  Побед: %d" % [_attack_bonus(),_armor_bonus(),_item_stat("hp"),_item_stat("crit"),_item_stat("lifesteal"),equipment.size(),raid_wins]
	var next_hero: Dictionary = HeroRoster.next_unlock(raid_wins, player_level) if mode == "raid" else {}
	var next_quest: String = ""
	if not next_hero.is_empty():
		var quest: Dictionary = HeroRoster.quest_progress(next_hero, raid_wins, player_level)
		next_quest = "СЛЕДУЮЩИЙ ГЕРОЙ: %s • победы %d/%d, ур. %d/%d\n" % [next_hero["name"], quest["wins"], quest["required_wins"], quest["level"], quest["required_level"]]
	info.text = ("♛ ЛИДЕР: %s • %s\n" % [HeroRoster.get_hero(selected_hero)["name"], HeroRoster.TIER_NAMES[int(HeroRoster.get_hero(selected_hero)["rarity"])]] if mode == "raid" else "") + next_quest + ("⛨ ЩИТ АКТИВЕН\n" if shield_active else "") + ("ГЛАВА %d • %s\nМИССИЯ: %s\nЦЕЛЬ: %s\nБОСС: %d/%d HP • Раунд %d\n" % [raid_stage, raid_region, str(raid_mission.get("title", raid_encounter)), str(raid_mission.get("goal", "Победи босса.")), boss_hp, 240 + (raid_stage - 1) * 100 + int(raid_wins / 6.0) * 35, raid_round] if mode == "raid" else "") + battle_log
	if selected >= 0 and selected < 64 and pieces[selected] != "":
		var hero: String = pieces[selected]
		var hero_attack: int = DAMAGE[hero.to_upper()] + ((_attack_bonus() + (_effective_level() - 1) * 2) if mode == "raid" and _team(hero) == 1 else 0)
		var hero_hp: int = _max_hp(hero, _team(hero) == 1)
		info.text = "ВЫБРАН: %s • HP %d/%d • УРОН %d\n" % [GLYPHS[hero], health[selected], hero_hp, hero_attack] + info.text
	for i in range(64):
		var b: Button = buttons[i]
		var p: String = pieces[i]
		hazard_overlays[i].visible = mode == "raid" and boss_target == i and winner == ""
		b.text = ""
		var image_node: TextureRect = unit_images[i]
		image_node.texture = UNIT_TEXTURES.get(p.to_upper()) if p != "" else null
		image_node.modulate = Color("#fff2dc") if _team(p) == 1 else Color("#db9ba5")
		var aura: Panel = equipment_auras[i]
		aura.visible = mode == "raid" and _team(p) == 1 and _attack_bonus() > 0
		var hp_node: Label = hp_labels[i]
		hp_node.text = str(health[i]) if p != "" else ""
		var life: ProgressBar = hp_bars[i]
		life.visible = p != ""
		if p != "":
			life.max_value = maxi(1, (240 + (raid_stage - 1) * 100 + int(raid_wins / 6.0) * 35) if mode == "raid" and i == 4 else _max_hp(p, _team(p) == 1))
			life.value = maxi(0, health[i])
			life.add_theme_stylebox_override("fill", hp_bar_friendly_style if _team(p) == 1 else hp_bar_enemy_style)
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
	if battlefield_3d != null and pieces.size() == 64:
		var legal_targets: Array = []
		if selected >= 0 and selected < 64:
			for square_index in range(64):
				if _legal(selected, square_index):
					legal_targets.append(square_index)
		var max_health: Array = []
		for index in range(64):
			var piece: String = pieces[index]
			max_health.append((240 + (raid_stage - 1) * 100 + int(raid_wins / 6.0) * 35) if mode == "raid" and index == 4 else (_max_hp(piece, _team(piece) == 1) if piece != "" else 1))
		battlefield_3d.set_region(clampi(raid_stage - 1, 0, 5) if mode == "raid" else 0)
		battlefield_3d.set_mission_visual_variant(posmod(raid_wins, 3) if mode == "raid" else 0)
		battlefield_3d.set_boss_phase(boss_phase if mode == "raid" else 1)
		battlefield_3d.set_hero_gear(equipment, equipped_slots)
		battlefield_3d.set_selected_hero_visual(HeroRoster.get_hero(selected_hero))
		var forecast: Array[int] = []
		var boss_forecast: Array[int] = []
		if mode == "raid" and winner == "":
			forecast = Progression.hazard_cells(str(raid_mission.get("modifier", "none")), raid_round + 1)
			boss_forecast = Progression.boss_hazard_cells(raid_stage, raid_round + 1, raid_encounter)
		if mode == "raid" and winner == "" and raid_stage == 3 and (raid_round + 1) % 3 == 0:
			var weakest := -1
			for hero_index in range(64):
				if _team(pieces[hero_index]) == 1 and (weakest < 0 or health[hero_index] < health[weakest]):
					weakest = hero_index
			if weakest >= 0 and not boss_forecast.has(weakest): boss_forecast.append(weakest)
		for square in boss_forecast:
			if not forecast.has(square): forecast.append(square)
		var warning_type: String = str(raid_mission.get("modifier", "none"))
		if forecast.size() > 0 and boss_forecast.size() > 0: warning_type = "boss"
		battlefield_3d.set_hazards(forecast, warning_type)
		battlefield_3d.set_poison_indicators(hero_poison if mode == "raid" and winner == "" else {}, poison_marks if mode == "raid" and winner == "" else {})
		var checked_square: int = pieces.find("K" if turn == 1 else "k") if mode == "arena" and winner == "" and _king_threatened(pieces, turn) else -1
		battlefield_3d.set_checked_king(checked_square)
		battlefield_3d.sync_board(pieces, selected, legal_targets, boss_target if mode == "raid" and winner == "" else -1, health, max_health)
	if winner != "" and not battle_result_shown:
		call_deferred("_show_result")
	if lan_host and lan_connected:
		call_deferred("_broadcast_snapshot")
