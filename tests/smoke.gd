extends SceneTree

const Progression = preload("res://scripts/progression.gd")
const MainScene = preload("res://scenes/main.tscn")

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run_tests")

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)

func _run_tests() -> void:
	var game = MainScene.instantiate()
	root.add_child(game)
	await process_frame
	_check(game.pieces.size() == 64, "Board must contain 64 squares")
	_check(game.health.size() == 64, "Health must contain 64 entries")
	_check(game.buttons.size() == 64, "UI must have 64 board buttons")
	_check(game._legal(52, 44), "White pawn must move one square forward")
	_check(game._legal(52, 36), "White pawn must move two squares from starting rank")
	_check(not game._legal(52, 35), "Pawn cannot move diagonally to an empty square")
	_check(not game._legal(60, 52), "King cannot move onto allied pawn")
	game._tap(52)
	game._tap(36)
	_check(game.pieces[36] == "P", "Pawn must reach destination")
	_check(game.pieces[52] == "", "Pawn must leave origin")
	_check(game.ap == 1, "Movement costs one action")
	game._start_raid()
	_check(game.mode == "raid", "Raid mode should start")
	_check(game.boss_hp == 240, "Boss must start at 240 HP")
	_check(game.pieces[4] == "k", "Boss should be on E8")
	_check(game.pieces[11] == "n", "Raid minion should spawn")
	_check(game._choose_boss_target() >= 0, "Boss must select a target")
	game._boss_action()
	_check(game.raid_round == 1, "Boss action increments round")
	_check(game.turn == 1 and game.ap == 2, "Boss returns control to heroes")
	for i in range(100):
		var item: Dictionary = Progression.roll_item(15)
		_check(int(item["rarity"]) >= 0 and int(item["rarity"]) < 7, "Rarity within seven tiers")
		_check(int(item["level"]) >= 1 and int(item["level"]) <= 50, "Item level within limits")
		_check(int(item["attack"]) > 0, "Item attack bonus positive")
	_check(Progression.experience_needed(2) > Progression.experience_needed(1), "XP requirement increases")
	game.queue_free()
	if failures.is_empty():
		print("KINGDOM CHESS: ALL GAMEPLAY SMOKE TESTS PASSED")
		quit(0)
	else:
		print("KINGDOM CHESS: %d FAILED TESTS" % failures.size())
		quit(1)
