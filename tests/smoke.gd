extends SceneTree

const Progression = preload("res://scripts/progression.gd")
const MainScene = preload("res://scenes/main.tscn")

func _initialize() -> void:
	_run()

func _assert_ok(condition: bool, description: String) -> void:
	if not condition:
		push_error("TEST FAILED: " + description)
		quit(1)

func _run() -> void:
	var game = MainScene.instantiate()
	root.add_child(game)
	await process_frame
	_assert_ok(ProjectSettings.get_setting("display/window/size/viewport_width") == 720, "Portrait viewport width")
	_assert_ok(ProjectSettings.get_setting("display/window/size/viewport_height") == 1280, "Portrait viewport height")
	_assert_ok(game.battle_layout is VBoxContainer, "Portrait layout stacks battlefield and HUD")
	_assert_ok(game.menu_toggle != null, "Menu is accessible from top button")
	var end_turn_buttons := game.find_children("*", "Button", true, false).filter(func(button): return button.text == "➤ ЗАВЕРШИТЬ ХОД")
	_assert_ok(end_turn_buttons.size() == 1, "End Turn button exists")
	if end_turn_buttons.size() == 1:
		_assert_ok(end_turn_buttons[0].get_parent() is VBoxContainer, "End Turn remains in fixed portrait action footer")
	_assert_ok(game.buttons.size() == 64, "Board creates 64 interactive buttons")
	_assert_ok(game.unit_images.size() == 64, "Board creates 64 illustrated units")
	_assert_ok(game.hazard_overlays.size() == 64, "Animated danger warning on every square")
	_assert_ok(game.equipment_auras.size() == 64, "Equipment auras rendered on chess units")
	_assert_ok(game.inventory_popup != null, "Inventory dialog exists")
	_assert_ok(game.shop_popup != null, "Alchemist shop exists")
	_assert_ok(game.main_menu != null and game.main_menu.visible, "Cinematic start menu visible at launch")
	_assert_ok(game.tutorial_popup != null, "First-run combat tutorial exists")
	_assert_ok(game.get_node_or_null("NetworkLobby") != null, "Co-op lobby is a dedicated dialog")
	_assert_ok(game.lan_address != null, "LAN address field exists")
	_assert_ok(game.lan_status != null, "LAN status field exists")
	_assert_ok(game.battle_result_dialog != null, "Battle result dialog exists")
	_assert_ok(game.boss_portrait != null, "Boss portrait exists")
	game.pieces.resize(64)
	game.health.resize(64)
	for i in range(64):
		game.pieces[i] = ""
		game.health[i] = 0
	game.pieces[52] = "P"
	game.health[52] = 65
	game.pieces[60] = "K"
	game.health[60] = 180
	game.pieces[4] = "k"
	game.health[4] = 240
	_assert_ok(game._legal(52, 44), "Pawn advances one square")
	_assert_ok(game._legal(52, 36), "Pawn advances two squares initially")
	_assert_ok(not game._legal(52, 35), "Pawn cannot capture empty square")
	_assert_ok(not game._legal(60, 52), "King cannot move onto ally")
	var state: Dictionary = game._snapshot()
	_assert_ok(state["pieces"].size() == 64, "Co-op state has 64 pieces")
	_assert_ok(state["health"].size() == 64, "Co-op state has 64 health values")
	_assert_ok(state.has("selected") and state.has("curse_mode"), "Co-op sync includes targeting state")
	_assert_ok(state.has("shield_active"), "Co-op sync includes shield protection")
	_assert_ok(state.has("raid_stats") and state["raid_stats"].has("attack"), "Co-op state includes RPG combat bonuses")
	game.mode = "arena"
	game._save_battle()
	_assert_ok(FileAccess.file_exists(game.battle_save_path), "Battle autosave exists")
	game.pieces[52] = ""
	_assert_ok(game._restore_battle(), "Autosaved battle restores")
	_assert_ok(game.pieces[52] == "P", "Restored piece matches saved state")
	game._reset()
	game.mode = "raid"
	game._reset()
	game.selected = 56
	game._shield_selected()
	_assert_ok(game.shield_active, "Rook activates protective shield")
	_assert_ok(game.ap == 1, "Shield costs one action")
	_assert_ok(game.selected == -1, "Shield clears selection")
	_assert_ok(game._team("k") == -1, "Dark faction")
	_assert_ok(game._team("K") == 1, "Light faction")
	for i in range(100):
		var item: Dictionary = Progression.roll_item(15)
		_assert_ok(int(item["rarity"]) >= 0 and int(item["rarity"]) < 7, "Rarity bounds")
		_assert_ok(int(item["level"]) >= 1 and int(item["level"]) <= 50, "Level bounds")
		_assert_ok(int(item["attack"]) > 0, "Attack bonus")
		_assert_ok(Progression.ITEM_SLOTS.has(item["slot"]), "Loot has RPG equipment slot")
		_assert_ok(item.has("armor") and item.has("hp") and item.has("crit") and item.has("lifesteal"), "Loot has RPG stats")
	_assert_ok(Progression.experience_needed(2) > Progression.experience_needed(1), "Increasing XP")
	game.equipment = [
		{"name":"Test sword","slot":"Оружие","level":1,"attack":12,"crit":0},
		{"name":"Test armor","slot":"Тело","level":1,"attack":2,"armor":8,"hp":30},
		{"name":"Test relic","slot":"Реликвия","level":1,"attack":1,"lifesteal":10}
	]
	game.equipped_slots = {"Оружие":0,"Тело":1,"Реликвия":2}
	game.shared_raid_stats = {"level": 9, "attack": 44, "armor": 12, "hp": 75, "crit": 8, "lifesteal": 4}
	game.lan_connected = true
	game.lan_host = false
	_assert_ok(game._attack_bonus() == 44 and game._armor_bonus() == 12, "Co-op client uses host equipment stats")
	_assert_ok(game._effective_level() == 9 and game._max_hp("K") == 255, "Co-op client displays host level and HP bonus")
	game.lan_connected = false
	game.shared_raid_stats.clear()
	_assert_ok(game._attack_bonus() == 15, "Equipped slots aggregate attack")
	_assert_ok(game._armor_bonus() == 8, "Equipped armor mitigates incoming damage")
	_assert_ok(game._max_hp("K") == 210, "Equipped armor raises hero maximum HP")
	game.pieces[60] = "K"
	game.health[60] = 180
	var damage_dealt: int = game._deal_damage(60, 30, false)
	_assert_ok(damage_dealt == 22 and game.health[60] == 158, "Armor reduces actual chess-piece damage")
	game._reset()
	game.health[60] = 180
	game.selected = 60
	game._heal_selected()
	_assert_ok(game.health[60] == 200, "Healing works above base HP when armor raises maximum HP")
	game.selected = 60
	game.heal_used = false
	game.acted.clear()
	game.ap = 2
	game.health[60] = 205
	game._heal_selected()
	_assert_ok(game.health[60] == 210, "Healing clamps to equipment-enhanced maximum HP")
	game.health[60] = 5
	_assert_ok(game._deal_damage(60, 100, false) > 0 and game.health[60] == 0, "Damage cannot produce negative HP")
	game.equipment = []
	game.equipped_slots = {"Оружие":-1,"Тело":-1,"Реликвия":-1}
	_assert_ok(Progression.experience_needed(2) > Progression.experience_needed(1), "Increasing XP")
	var old_gold: int = game.gold
	var old_potions: int = game.potions
	game.gold = 0
	game._buy_potions(1, 50)
	_assert_ok(game.potions == old_potions, "Cannot buy without gold")
	game.gold = 100
	game._buy_potions(1, 50)
	_assert_ok(game.gold == 50 and game.potions == old_potions + 1, "Shop purchase costs gold and grants potion")
	game.gold = old_gold
	game.potions = old_potions
	game._save_profile()
	print("KINGDOM CHESS: GAMEPLAY LOGIC SMOKE TESTS PASSED")
	game.queue_free()
	quit(0)
