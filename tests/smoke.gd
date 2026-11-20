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
	_assert_ok(game.buttons.size() == 64, "Board creates 64 interactive buttons")
	_assert_ok(game.unit_images.size() == 64, "Board creates 64 illustrated units")
	_assert_ok(game.inventory_popup != null, "Inventory dialog exists")
	_assert_ok(game.shop_popup != null, "Alchemist shop exists")
	_assert_ok(game.main_menu != null and game.main_menu.visible, "Cinematic start menu visible at launch")
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
