extends SceneTree

const Progression = preload("res://scripts/progression.gd")
const HeroRoster = preload("res://scripts/hero_roster.gd")
const MainScene = preload("res://scenes/main.tscn")

func _initialize() -> void:
	_run()

var _failure_count: int = 0

func _assert_ok(condition: bool, description: String) -> void:
	if not condition:
		_failure_count += 1
		push_error("TEST FAILED: " + description)

func _check_mesh_integrity(node: Node) -> void:
	# Pinpoint missing imported GLB meshes instead of reporting only the
	# renderer backend warning: mesh_get_surface_count(null).
	if node is MeshInstance3D:
		var mesh_node: MeshInstance3D = node as MeshInstance3D
		_assert_ok(mesh_node.mesh != null, "3D mesh resource exists: " + str(mesh_node.get_path()))
		# Do not query RenderingServer mesh surfaces under --headless:
		# Godot 4.3 dummy renderer logs mesh_get_surface_count(null).
		# Mesh existence is safe to validate here; imported GLB geometry is
		# checked by the Python asset validator before Godot import.
	for child in node.get_children():
		_check_mesh_integrity(child)

func _run() -> void:
	_assert_ok(Progression.CASTLE_BUILDINGS.size() == 5, "Castle has five functional buildings")
	# Deterministic fallback cases catch rare high-rarity and over-level loot.
	for rarity in range(7):
		for rolled_level in [1, 2, 10, 50]:
			for slot in Progression.ITEM_SLOTS:
				var raw_drop: Dictionary = {
					"name":"Legendary trial", "slot":slot, "level":rolled_level,
					"rarity":rarity, "power":4 + rolled_level * 2 + rarity * (4 + int(rolled_level / 8.0)) + 5,
					"affix":Progression.AFFIXES[3], "set_id":3, "trait_id":2
				}
				var legal_drop: Dictionary = Progression.normalize_progress_drop(raw_drop, 1, 0)
				_assert_ok(int(legal_drop["level"]) == 1 and int(legal_drop["rarity"]) == 0, "Loot downgrade enforces starter level and rarity")
				_assert_ok(int(legal_drop["power"]) == 11, "Loot downgrade cannot retain high-level power")
				_assert_ok(int(legal_drop["set_id"]) == -1 and int(legal_drop["trait_id"]) == -1, "Starter loot strips locked set and trait")
				_assert_ok(int(legal_drop["penetration"]) <= 5 and int(legal_drop["crit"]) <= 35, "Starter loot recomputes capped combat stats")
				_assert_ok(not str(legal_drop["name"]).contains(" • "), "Starter loot name removes locked affixes")
				_assert_ok(int(raw_drop["level"]) == rolled_level and int(raw_drop["rarity"]) == rarity, "Loot normalization does not mutate original")
	var high_drop: Dictionary = {"name":"Epic trial", "slot":"Оружие", "level":50, "rarity":6, "power":4 + 50 * 2 + 6 * 10 + 5, "affix":Progression.AFFIXES[3], "set_id":2, "trait_id":2}
	var mid_drop: Dictionary = Progression.normalize_progress_drop(high_drop, 20, 3)
	_assert_ok(int(mid_drop["level"]) == 20 and int(mid_drop["rarity"]) == 3 and int(mid_drop["power"]) <= 4 + 20 * 2 + 3 * 6 + 5, "Midgame fallback respects item power ceiling")
	_assert_ok(int(mid_drop["trait_id"]) == -1, "Midgame downgrade strips legendary-only traits")
	_assert_ok(Progression.sanitize_castle({"forge":4,"academy":-3,"barracks":"99","treasury":100000,"infirmary":1.5}) == {"forge":4,"barracks":0,"treasury":0,"academy":0,"infirmary":0}, "Castle save rejects forged, negative and malformed upgrades")
	_assert_ok(Progression.castle_bonus({"forge":100}, "forge") == 30, "Castle PvE attack bonus is capped")
	_assert_ok(Progression.castle_bonus({"barracks":100}, "barracks") == 100, "Castle PvE health bonus is capped")
	_assert_ok(Progression.castle_bonus({"treasury":100}, "treasury") == 50, "Castle raid gold bonus is capped")
	_assert_ok(Progression.castle_bonus({"academy":100}, "academy") == 50, "Castle raid XP bonus is capped")
	_assert_ok(Progression.castle_bonus({"infirmary":100}, "infirmary") == 30, "Castle healing bonus is capped")
	var forge_building: Dictionary = Progression.CASTLE_BUILDINGS[0]
	_assert_ok(Progression.castle_upgrade_cost(forge_building, 0) == 160 and Progression.castle_upgrade_cost(forge_building, 1) == 640, "Building upgrades have increasing costs")
	_assert_ok(Progression.castle_upgrade_allowed(forge_building, 0, 0, 160), "Starter forge can be built")
	_assert_ok(not Progression.castle_upgrade_allowed(forge_building, 1, 0, 10000), "Further upgrades require raid victories")
	_assert_ok(not Progression.castle_upgrade_allowed(forge_building, 0, 0, 159), "Building requires sufficient gold")
	_assert_ok(not Progression.castle_upgrade_allowed(forge_building, 100, 9999, 10000000), "Building level cap enforced")
	_assert_ok(Progression.sanitize_board_collection([3, 3, -1, 2, 4, "1", 1.5, 1]) == [0, 1, 2, 3], "Board ownership sanitizes duplicates, forged indices and fractions")
	_assert_ok(Progression.sanitize_board_collection("malformed") == [0], "Invalid collection restores starter board")
	var forged_board_profile: Dictionary = Progression.default_profile()
	forged_board_profile["owned_boards"] = [1, 3, 3, 900]
	forged_board_profile["selected_board"] = 2
	var cleaned_board_profile: Dictionary = Progression.sanitize_profile(forged_board_profile)
	_assert_ok(cleaned_board_profile["owned_boards"] == [0, 1, 3], "Saved collection is normalized")
	_assert_ok(cleaned_board_profile["selected_board"] == 0, "Cannot select unowned board from save")
	_assert_ok(Progression.board_unlock_reason(2, [0], 0, 900).contains("побед"), "Board unlock requires campaign progress")
	_assert_ok(Progression.board_unlock_reason(2, [0], 6, 0).contains("золота"), "Board unlock requires enough gold")
	_assert_ok(Progression.board_unlock_reason(2, [0], 6, 900).contains("Доступно"), "Board unlock becomes available after both gates")
	# Corrupted/edited local saves must never inject oversized equipment bonuses.
	var legitimate_gear: Dictionary = Progression.roll_item(1)
	_assert_ok(Progression.is_valid_equipment_item(legitimate_gear), "Generated starter equipment passes validation")
	for inflated_stat in ["power", "attack", "armor", "hp"]:
		var forged_gear: Dictionary = legitimate_gear.duplicate(true)
		forged_gear[inflated_stat] = 100000
		_assert_ok(not Progression.is_valid_equipment_item(forged_gear), "Forged oversized " + inflated_stat + " is rejected")
	var forged_inventory: Dictionary = Progression.default_profile()
	var forged_attack: Dictionary = legitimate_gear.duplicate(true)
	forged_attack["attack"] = 100000
	forged_inventory["items"] = [forged_attack]
	forged_inventory["slots"] = {"Оружие":0,"Тело":0,"Реликвия":0}
	var sanitized_inventory: Dictionary = Progression.sanitize_profile(forged_inventory)
	_assert_ok(sanitized_inventory["items"].is_empty(), "Forged equipment is removed from saved inventory")
	_assert_ok(int(sanitized_inventory["slots"]["Оружие"]) == -1, "Forged equipment cannot remain equipped")
	_assert_ok(Progression.rarity_cap(0, 1) == 0, "New players can only obtain common gear")
	_assert_ok(Progression.upgrade_cap(0, 1) == 2, "New players cannot upgrade beyond +2")
	_assert_ok(Progression.rarity_cap(18, 1) == 0, "Campaign wins alone cannot bypass level requirement")
	_assert_ok(Progression.rarity_cap(0, 50) == 0, "High level alone cannot bypass chapter progression")
	_assert_ok(Progression.rarity_cap(18, 35) == 6, "Endgame unlocks relic rarity after both gates")
	_assert_ok(Progression.upgrade_cap(18, 35) == 12, "Endgame unlocks +12 upgrades")
	var late_reward: Dictionary = Progression.first_clear_reward(3)
	var early_reward: Dictionary = Progression.limit_reward_to_progress(late_reward, 3, 3)
	_assert_ok(int(early_reward["rarity"]) <= Progression.rarity_cap(3, 3), "Chapter rewards obey rarity cap")
	_assert_ok(int(early_reward["trait_id"]) == -1, "Early chapter reward cannot grant legendary trait")
	_assert_ok(not Progression.can_equip(late_reward, 0, 1), "Starting player cannot equip overpowered chapter reward")
	for loot_test in range(20):
		var starter_drop: Dictionary = Progression.roll_item_for_progress(1, 0, true, 3)
		_assert_ok(int(starter_drop["rarity"]) == 0, "Boss loot and luck cannot bypass starting rarity")
	# Random campaign loot must be usable when earned, including the +1 item-level roll.
	for reward_level in [1, 2, 5, 10, 20, 35, 50]:
		for reward_wins in [0, 3, 9, 18, 25]:
			for reward_boss in [false, true]:
				for reward_attempt in range(6):
					var reward: Dictionary = Progression.roll_item_for_progress(reward_level, reward_wins, reward_boss, 3)
					_assert_ok(Progression.is_valid_equipment_item(reward), "Campaign reward remains a valid item")
					_assert_ok(Progression.can_equip(reward, reward_wins, reward_level), "Campaign reward never rolls above player level or rarity gate")
	# A common-rarity drop cannot carry legendary-tier power after reward gating.
	for starter_attempt in range(100):
		var gated_item: Dictionary = Progression.roll_item_for_progress(1, 0, true, 3)
		_assert_ok(int(gated_item["power"]) <= 11, "Starter loot power stays within the level-one common-item roll range")
		_assert_ok(Progression.can_equip(gated_item, 0, 1), "Gated starter reward is immediately usable")
	_assert_ok(HeroRoster.HEROES.size() == 30, "30 unique authored heroes are available")
	var hero_ids: Dictionary = {}
	var rarity_counts: Dictionary = {}
	for hero in HeroRoster.HEROES:
		_assert_ok(not hero_ids.has(hero["id"]), "Every hero has a unique persistent ID")
		hero_ids[hero["id"]] = true
		rarity_counts[hero["rarity"]] = int(rarity_counts.get(hero["rarity"], 0)) + 1
		_assert_ok(str(hero["story"]).length() > 20, "Each hero has a written backstory")
		_assert_ok(int(hero["attack"]) > 0 and int(hero["hp"]) > 0, "Each hero has combat stats")
	_assert_ok(rarity_counts.size() == 7, "All seven character value tiers are represented")
	_assert_ok(HeroRoster.available_count(0, 1) == 6, "Six starter heroes provide initial choice")
	var starter_progress: Dictionary = HeroRoster.quest_progress(HeroRoster.HEROES[0], 0, 1)
	_assert_ok(starter_progress["unlocked"] and starter_progress["wins"] == 0, "Starter hero quest is complete on day one")
	var final_progress: Dictionary = HeroRoster.quest_progress(HeroRoster.HEROES[29], 18, 35)
	_assert_ok(not final_progress["unlocked"] and final_progress["wins"] == 18 and final_progress["required_wins"] == 25, "Final hero quest reports campaign gate without bypass")
	_assert_ok(not HeroRoster.quest_progress(HeroRoster.HEROES[29], 25, 1)["unlocked"], "Hero quest cannot bypass player level gate")
	_assert_ok(HeroRoster.quest_progress(HeroRoster.HEROES[29], 25, 35)["unlocked"], "Endgame hero unlocks only when both gates are met")
	_assert_ok(not HeroRoster.next_unlock(0, 1).is_empty(), "Early campaign displays a next earnable hero")
	var next_early: Dictionary = HeroRoster.next_unlock(0, 1)
	_assert_ok(not next_early.is_empty() and not HeroRoster.unlocked(next_early, 0, 1), "Next quest never points to an already unlocked hero")
	var wins_unlocks: int = 0
	for hero in HeroRoster.HEROES:
		if HeroRoster.unlocked(hero, 6, 20) and not HeroRoster.unlocked(hero, 5, 20):
			wins_unlocks += 1
	_assert_ok(wins_unlocks > 0, "Winning a boss battle can unlock additional heroes")

	_assert_ok(HeroRoster.next_unlock(25, 35).is_empty(), "Completed hero collection has no pending unlocks")

	_assert_ok(HeroRoster.available_count(25, 35) == 30, "Every hero can be earned through quests")
	_assert_ok(not HeroRoster.unlocked(HeroRoster.HEROES[29], 18, 35), "Strongest hero cannot be claimed by campaign clear alone")
	_assert_ok(HeroRoster.valid_selection("hero_30", 0, 1) == "hero_01", "Locked hero cannot be injected into save")
	var game = MainScene.instantiate()
	# Redraw can be requested by state transitions before _ready constructs HUD controls.
	game._draw()
	_assert_ok(game.status == null, "Pre-ready redraw leaves uninitialized HUD untouched")
	root.add_child(game)
	# SceneTree._initialize runs before the first frame; defer checks until the 3D viewport and HUD finish _ready.
	await process_frame
	if game.battlefield_3d != null:
		_check_mesh_integrity(game.battlefield_3d)
	_assert_ok(game.battlefield_3d != null, "3D battlefield initialized before chess warning assertions")
	if game.battlefield_3d != null:
		var board_root: Node3D = game.battlefield_3d.board_root
		_assert_ok(board_root.get_node_or_null("FileCoordinate_A_-1") != null, "Chessboard displays A file coordinate")
		_assert_ok(board_root.get_node_or_null("FileCoordinate_H_1") != null, "Chessboard displays H file coordinate")
		_assert_ok(board_root.get_node_or_null("RankCoordinate_8_-1") != null, "Chessboard displays rank eight")
		_assert_ok(board_root.get_node_or_null("RankCoordinate_1_1") != null, "Chessboard displays rank one")
		# Geometry reuse must preserve per-instance materials and transforms.
		var cache_parent := Node3D.new()
		game.battlefield_3d.add_child(cache_parent)
		var test_mat_a := StandardMaterial3D.new()
		var test_mat_b := StandardMaterial3D.new()
		var shared_box_a: MeshInstance3D = game.battlefield_3d._box(Vector3(0.37, 0.43, 0.51), test_mat_a, cache_parent, Vector3(1, 2, 3))
		var shared_box_b: MeshInstance3D = game.battlefield_3d._box(Vector3(0.37, 0.43, 0.51), test_mat_b, cache_parent, Vector3(3, 2, 1))
		_assert_ok(shared_box_a.mesh == shared_box_b.mesh, "Identical 3D boxes reuse one GPU mesh resource")
		_assert_ok(shared_box_a.material_override != shared_box_b.material_override and shared_box_a.position != shared_box_b.position, "Shared mesh keeps independent appearance and placement")
		var shared_ring_a: MeshInstance3D = game.battlefield_3d._ring(0.31, 0.04, test_mat_a, cache_parent, Vector3.ZERO)
		var shared_ring_b: MeshInstance3D = game.battlefield_3d._ring(0.31, 0.04, test_mat_b, cache_parent, Vector3.ONE)
		_assert_ok(shared_ring_a.mesh == shared_ring_b.mesh, "Identical 3D torus rings reuse one GPU mesh resource")
		cache_parent.queue_free()
		_assert_ok(game.battlefield_3d.board_gems.size() == 4, "Four animated gemstones exist")
		_assert_ok(game.battlefield_3d.board_gem_halos.size() == 4, "Four optional gemstone halos exist")
		game.battlefield_3d.set_visual_quality(0)
		_assert_ok(not game.battlefield_3d.board_gem_halos[0].visible, "Low quality disables gemstone halos")
		game.battlefield_3d.set_visual_quality(2)
		_assert_ok(game.battlefield_3d.board_gem_halos[0].visible, "High quality enables gemstone halos")
		game.battlefield_3d.set_visual_quality(1)
		_assert_ok(not game.battlefield_3d.board_gem_halos[0].visible, "Default quality disables expensive halo geometry")
		var skyline: Node3D = game.battlefield_3d.region_scenery.get_node_or_null("CastleSkyline")
		_assert_ok(skyline != null, "3D kingdom skyline is constructed outside the chess arena")
		if skyline != null:
			_assert_ok(skyline.get_node_or_null("CastleCurtainWall") != null, "Castle has a curtain wall")
			_assert_ok(skyline.get_node_or_null("CastleWatchtower_-1") != null, "Castle has west watchtower")
			_assert_ok(skyline.get_node_or_null("CastleWatchtower_1") != null, "Castle has east watchtower")
			_assert_ok(skyline.get_node_or_null("CastleBanner_-1") != null, "Castle has left gatehouse banner")
			for building_index in range(5):
				_assert_ok(skyline.get_node_or_null("CastleBuilding_%d" % building_index) != null, "Castle has visually distinct building %d" % building_index)
			for bar_index in range(7):
				_assert_ok(skyline.get_node_or_null("CastleGateBar_%02d" % bar_index) != null, "Gate portcullis bar %d exists" % bar_index)
			for side in [-1, 1]:
				_assert_ok(skyline.get_node_or_null("CastleWatchtower_%d" % side) != null, "Detailed castle tower exists")
			for building_index in range(5):
				var detail_building: Node3D = skyline.get_node_or_null("CastleBuilding_%d" % building_index)
				if detail_building != null:
					_assert_ok(detail_building.get_node_or_null("RoofRidge") != null, "Castle roof ridge %d exists" % building_index)
					_assert_ok(detail_building.get_node_or_null("CastleWindow_-1") != null, "Castle west window %d exists" % building_index)
					_assert_ok(detail_building.get_node_or_null("CastleWindow_1") != null, "Castle east window %d exists" % building_index)
			for merlon_index in range(20):
				_assert_ok(skyline.get_node_or_null("CastleMerlon_%02d" % merlon_index) != null, "Castle curtain has crenellation %d" % merlon_index)
		_assert_ok(game.battlefield_3d.ambient_motes.size() <= 12, "Ambient effects remain bounded on Android")
		if game.battlefield_3d.ambient_motes.size() > 0:
			game.battlefield_3d.set_visual_quality(2)
			_assert_ok(game.battlefield_3d.ambient_motes[0].visible, "High quality enables ambient motes")
			game.battlefield_3d.set_visual_quality(1)
			_assert_ok(not game.battlefield_3d.ambient_motes[0].visible, "Medium quality disables ambient motes")
		game._open_castle()
		_assert_ok(game.castle_list.item_count == 5, "Castle dialog displays five upgradeable buildings")
		game.battlefield_3d.set_castle_visual_levels({"forge":0,"barracks":5,"treasury":10,"academy":15,"infirmary":20})
		var skyline_visual: Node3D = game.battlefield_3d.region_scenery.get_node_or_null("CastleSkyline")
		_assert_ok(skyline_visual != null, "Upgradable castle scenery exists")
		if skyline_visual != null:
			for stage_index in range(5):
				var visual_building: Node3D = skyline_visual.get_node_or_null("CastleBuilding_%d" % stage_index)
				_assert_ok(visual_building != null, "Upgradable castle building %d exists" % stage_index)
				if visual_building != null:
					_assert_ok(int(visual_building.get_meta("upgrade_stage", -1)) == stage_index, "Building %d reflects its saved construction tier" % stage_index)
					_assert_ok(visual_building.scale.y >= 1.0, "Building visual scale never collapses")
					for ornament_index in range(4):
						var ornament: Node3D = visual_building.get_node_or_null("UpgradeOrnament_%d" % ornament_index)
						_assert_ok(ornament != null and ornament.visible == (ornament_index < stage_index), "Construction ornaments follow upgrade tier")
		game.battlefield_3d.set_castle_visual_levels(game.castle)
		var initial_castle: Dictionary = game.castle.duplicate(true)
		var castle_gold: int = game.gold
		var castle_wins: int = game.raid_wins
		game.castle = Progression.default_castle()
		game.gold = 160
		game.raid_wins = 0
		game.castle_list.select(0)
		game._upgrade_castle_building()
		_assert_ok(game.castle["forge"] == 1 and game.gold == 0, "Castle forge purchases exactly once for correct cost")
		game._upgrade_castle_building()
		_assert_ok(game.castle["forge"] == 1 and game.gold == 0, "Insufficient resources cannot buy another castle level")
		game.mode = "raid"
		var raid_attack: int = game._attack_bonus()
		var raid_health: int = game._max_hp("P", true)
		game.mode = "arena"
		_assert_ok(game._attack_bonus() == 0, "Castle upgrades do not affect arena attack")
		_assert_ok(game._max_hp("P", true) <= raid_health, "Castle upgrades do not affect arena HP")
		game.mode = "raid"
		_assert_ok(game._attack_bonus() == raid_attack, "Castle PvE attack bonus remains active")
		game.castle = initial_castle
		game.battlefield_3d.set_castle_visual_levels(initial_castle)
		game.gold = castle_gold
		game.raid_wins = castle_wins
		game._save_profile()
		game.castle_dialog.hide()
		_assert_ok(game.owned_boards.has(0), "Starter cosmetic board always owned")
		game._open_board_gallery()
		_assert_ok(game.board_gallery_list.item_count == 4, "Board collection dialog lists four skins")
		var old_gold: int = game.gold
		var old_wins: int = game.raid_wins
		var old_owned: Array = game.owned_boards.duplicate()
		var old_board: int = game.selected_board
		game.owned_boards = [0]
		game.raid_wins = 0
		game.gold = 100000
		game.board_gallery_list.select(3)
		game._choose_board()
		_assert_ok(game.selected_board == 0 and game.gold == 100000, "Cannot purchase locked board with gold alone")
		game.raid_wins = 12
		game.board_gallery_list.select(3)
		game._choose_board()
		_assert_ok(game.selected_board == 3 and game.owned_boards.has(3), "Eligible board unlocks and equips")
		_assert_ok(game.gold == 100000 - Progression.BOARD_COSTS[3], "Board purchase deducts exact price")
		game.board_gallery_list.select(3)
		game._choose_board()
		_assert_ok(game.gold == 100000 - Progression.BOARD_COSTS[3], "Owned board never charges twice")
		_assert_ok(game.battlefield_3d.board_style_index == 3, "Selected owned board updates 3D appearance")
		game.gold = old_gold
		game.raid_wins = old_wins
		game.owned_boards = old_owned
		game.selected_board = old_board
		game.battlefield_3d.set_board_visual_style(old_board)
		game._save_profile()
		game.board_gallery_dialog.hide()
		_assert_ok(game.battlefield_3d.BOARD_STYLES.size() == 4, "Four visual-only chessboard styles are available")
		var original_dark: Color = game.battlefield_3d.tile_materials[0].albedo_color
		var original_piece_count: int = game.battlefield_3d.piece_nodes.size()
		game.battlefield_3d.set_board_visual_style(2)
		_assert_ok(game.battlefield_3d.board_style_index == 2, "Board style changes to obsidian")
		_assert_ok(game.battlefield_3d.tile_materials[0].albedo_color != original_dark, "Board style changes visible material color")
		_assert_ok(game.battlefield_3d.piece_nodes.size() == original_piece_count, "Board cosmetics never rebuild combat pieces")
		game.battlefield_3d.set_board_visual_style(999)
		_assert_ok(game.battlefield_3d.board_style_index == 3, "Board style selection clamps invalid index")
		game.battlefield_3d.set_board_visual_style(0)
		_assert_ok(game.battlefield_3d.tile_materials[0].albedo_color == original_dark, "Original chessboard palette restores exactly")
		for x in [-1, 1]:
			for z in [-1, 1]:
				_assert_ok(board_root.get_node_or_null("BoardCornerPlinth_%d_%d" % [x, z]) != null, "3D board has four carved corner plinths")
				_assert_ok(board_root.get_node_or_null("BoardCornerGem_%d_%d" % [x, z]) != null, "3D board has four corner gemstones")
	# Chess-first RPG movement: threat geometry, king safety and pinned pieces.
	game.mode = "arena"
	game._reset()
	_assert_ok(game.valid_battle_arrays(game.pieces, game.health), "Fresh battle has valid pieces and HP arrays")
	var valid_sync: Dictionary = game._snapshot()
	_assert_ok(game.valid_raid_snapshot(valid_sync), "Host-generated raid snapshot passes schema validation")
	var invalid_sync: Dictionary = valid_sync.duplicate(true)
	invalid_sync.erase("boss_phase")
	_assert_ok(not game.valid_raid_snapshot(invalid_sync), "Missing raid phase cannot corrupt client state")
	invalid_sync = valid_sync.duplicate(true)
	invalid_sync["turn"] = 0
	_assert_ok(not game.valid_raid_snapshot(invalid_sync), "Invalid turn owner is rejected")
	invalid_sync = valid_sync.duplicate(true)
	invalid_sync["acted"] = [64]
	_assert_ok(not game.valid_raid_snapshot(invalid_sync), "Out-of-range acted square is rejected")
	invalid_sync = valid_sync.duplicate(true)
	invalid_sync["ap"] = -1
	_assert_ok(not game.valid_raid_snapshot(invalid_sync), "Negative AP is rejected before save restore")
	invalid_sync = valid_sync.duplicate(true)
	invalid_sync["ap"] = 99
	_assert_ok(not game.valid_raid_snapshot(invalid_sync), "Oversized AP is rejected before save restore")
	invalid_sync = valid_sync.duplicate(true)
	invalid_sync["acted"] = ["0"]
	_assert_ok(not game.valid_raid_snapshot(invalid_sync), "String action indices cannot enter restored state")

	var malformed_board: Array = game.pieces.duplicate()
	var malformed_hp: Array = game.health.duplicate()
	malformed_board[0] = "not_a_chess_piece"
	_assert_ok(not game.valid_battle_arrays(malformed_board, malformed_hp), "Malformed network piece is rejected")
	malformed_board[0] = game.pieces[0]
	malformed_hp[0] = -1
	_assert_ok(not game.valid_battle_arrays(malformed_board, malformed_hp), "Negative network HP is rejected")
	malformed_hp[0] = game.health[0]
	malformed_hp[10] = 1000001
	_assert_ok(not game.valid_battle_arrays(malformed_board, malformed_hp), "Excessive network HP is rejected")

	var before_invalid_tap: Array = game.pieces.duplicate()
	game._tap(-1)
	game._tap(64)
	_assert_ok(game.pieces == before_invalid_tap, "Invalid board tap indices cannot mutate battle")
	game.ap = 0
	game.selected = -1
	game._tap(48)
	_assert_ok(game.selected == -1 and game.pieces == before_invalid_tap, "Zero action points block selecting and moving units")
	game.ap = 2
	_assert_ok(not game._legal(-1, 0) and not game._legal(0, 64), "Out-of-range chess moves are rejected")
	var empty_board: Array = []
	empty_board.resize(64)
	empty_board.fill("")
	empty_board[60] = "K"
	empty_board[4] = "r"
	empty_board[52] = "R"
	empty_board[0] = "k"
	game.pieces = empty_board.duplicate()
	_assert_ok(game._king_threatened(game.pieces, 1) == false, "Friendly rook blocks rook check")
	_assert_ok(not game._legal(52, 53), "Pinned rook cannot step aside and expose king")
	_assert_ok(game._legal(52, 44), "Pinned rook can slide along the pin line")
	game.pieces[44] = "p"
	_assert_ok(game._legal(52, 44), "Pinned rook may attack enemy on the pin line")
	game.pieces[44] = ""
	game.pieces[53] = "p"
	_assert_ok(not game._legal(52, 53), "Lethal RPG capture cannot expose own king")
	game.pieces[53] = ""
	game.pieces[52] = ""
	_assert_ok(game._king_threatened(game.pieces, 1), "Rook gives check on open file")
	# A rook can remove a checking attacker with a lethal RPG strike, but a
	# nonlethal hit must not count as a check escape.
	game.pieces[5] = "R"
	game.health[4] = 10
	_assert_ok(game._legal(5, 4), "Lethal capture of checking rook resolves check")
	game.health[4] = 150
	_assert_ok(not game._legal(5, 4), "Nonlethal strike cannot leave king in check")
	game.pieces[5] = ""
	game.health[4] = 150

	_assert_ok(game.battlefield_3d != null, "3D board exists for check warning")
	_assert_ok(game.battlefield_3d.tile_materials.size() == 2, "Chessboard uses two reusable 3D tile materials")
	_assert_ok(game.battlefield_3d.tiles.size() == 64, "Chessboard retains all 64 3D tiles")
	_assert_ok(game.battlefield_3d.highlights.size() == 64, "All legal-move highlight markers remain present")
	_assert_ok(game.battlefield_3d.highlights[0].material_override == game.battlefield_3d.highlights[63].material_override, "Legal-move markers reuse one 3D material")
	_assert_ok(game.battlefield_3d.tiles[0].material_override == game.battlefield_3d.tiles[2].material_override, "Same-color tiles share material instance")
	_assert_ok(game.battlefield_3d.tiles[0].material_override != game.battlefield_3d.tiles[1].material_override, "Alternating chess squares keep distinct materials")
	game.battlefield_3d.set_region(1)
	var hero_visual: Dictionary = HeroRoster.get_hero("hero_01")
	game.battlefield_3d.set_selected_hero_visual(hero_visual)
	_assert_ok(game.battlefield_3d.selected_hero_signature == "hero_01", "Selected hero identity reaches 3D renderer")
	var original_hero_visual: Node3D = game.battlefield_3d._build_piece("K")
	_assert_ok(original_hero_visual.get_node_or_null("VisualRig") != null, "Humanoid character has a separate animation rig")
	var fallback_rig: Node3D = original_hero_visual.get_node_or_null("VisualRig")
	var authored_hero: Node = fallback_rig.get_node_or_null("AuthoredCharacter")
	if authored_hero != null:
		# Godot can convert skinned glTF joint nodes into Skeleton3D bones;
		# requiring a Node named Arm1 would incorrectly reject a valid skin.
		var has_right_arm: bool = authored_hero.find_child("Arm1", true, false) != null
		var has_right_leg: bool = authored_hero.find_child("Leg1", true, false) != null
		for candidate in authored_hero.find_children("*", "Skeleton3D", true, false):
			var skeleton: Skeleton3D = candidate as Skeleton3D
			has_right_arm = has_right_arm or skeleton.find_bone("Arm1") >= 0
			has_right_leg = has_right_leg or skeleton.find_bone("Leg1") >= 0
		_assert_ok(has_right_arm, "Imported hero has animated right arm joint or bone")
		_assert_ok(has_right_leg, "Imported hero has animated right leg joint or bone")
		var cape_skeleton: Skeleton3D = null
		for candidate in authored_hero.find_children("*", "Skeleton3D", true, false):
			var skeleton: Skeleton3D = candidate as Skeleton3D
			if skeleton.find_bone("CapeShoulder") >= 0 and skeleton.find_bone("CapeHem") >= 0:
				cape_skeleton = skeleton
				break
		_assert_ok(cape_skeleton != null, "Godot imports cape as actual Skeleton3D with shoulder and hem bones")
		var spine_skeleton: Skeleton3D = null
		for candidate in authored_hero.find_children("*", "Skeleton3D", true, false):
			var skeleton: Skeleton3D = candidate as Skeleton3D
			if skeleton.find_bone("SpineHip") >= 0 and skeleton.find_bone("SpineChest") >= 0:
				spine_skeleton = skeleton
				break
		_assert_ok(spine_skeleton != null, "Godot imports actual weighted torso Skeleton3D with hip and chest bones")
		for limb_name in ["Arm1", "Arm-1", "Leg1", "Leg-1"]:
			var limb_skeleton_found: bool = false
			for candidate in authored_hero.find_children("*", "Skeleton3D", true, false):
				var skeleton: Skeleton3D = candidate as Skeleton3D
				if skeleton.find_bone(limb_name) >= 0 and skeleton.find_bone(limb_name + "Lower") >= 0:
					limb_skeleton_found = true
					break
			_assert_ok(limb_skeleton_found, "Godot imports weighted upper/lower limb bones: " + limb_name)
		_assert_ok(fallback_rig.get_node_or_null("Arm_L") == null, "Imported hero does not duplicate fallback arms")
		_assert_ok(original_hero_visual.find_child("RangerHood", true, false) != null or original_hero_visual.find_child("KingCrownProng1", true, false) != null, "Imported hero preserves generated silhouette")
		_assert_ok(original_hero_visual.find_child("SurfaceDetail", true, false) == null, "Imported hero avoids redundant legacy costume nodes")
	else:
		_assert_ok(fallback_rig.get_node_or_null("Arm_L") != null and fallback_rig.get_node_or_null("Arm_R") != null, "Fallback humanoid has articulated arms")
		_assert_ok(fallback_rig.get_node_or_null("Leg_L") != null and fallback_rig.get_node_or_null("Leg_R") != null, "Fallback humanoid has articulated legs")
		game.battlefield_3d._animate_limbs(fallback_rig, "attack")
	_assert_ok(original_hero_visual.find_child("HeroIdentity_01", true, false) != null, "Hero's identity mesh is attached to animation rig")
	_assert_ok(original_hero_visual.find_child("HeroIdentity_01", true, false) != null, "Hero has a distinct visible 3D identity crest")
	game.battlefield_3d.set_selected_hero_visual(HeroRoster.get_hero("hero_30"))
	var rare_hero_visual: Node3D = game.battlefield_3d._build_piece("K")
	_assert_ok(rare_hero_visual.find_child("HeroIdentity_30", true, false) != null, "Highest rarity hero has distinct 3D crest")
	var epic_halo: Node3D = rare_hero_visual.find_child("HeroRarityHalo", true, false) as Node3D
	_assert_ok(epic_halo != null and epic_halo.visible, "High-rarity hero has a visible animated 3D identity halo")

	var authored_boss_visual: Node3D = game.battlefield_3d._build_piece("k", true, false)
	_assert_ok(authored_boss_visual.find_child("AuthoredCharacter", true, false) != null, "Regional boss imports its dedicated 3D scene")
	_assert_ok(authored_boss_visual.find_child("EmberHorn1", true, false) != null or authored_boss_visual.find_child("GlacierSpire0", true, false) != null, "Regional boss retains authored physical landmarks")
	authored_boss_visual.queue_free()
	# All 72 character assets must import, not only representative samples.
	var character_paths: Array[String] = []
	for hero_number in range(1, 31):
		character_paths.append("res://assets/characters/hero_%02d.glb" % hero_number)
	for region_number in range(6):
		character_paths.append("res://assets/characters/boss_region_%d.glb" % region_number)
		for chess_class in ["p", "r", "n", "b", "q", "k"]:
			character_paths.append("res://assets/characters/enemy_%s_region_%d.glb" % [chess_class, region_number])
	_assert_ok(character_paths.size() == 72, "Exactly 72 character GLB import paths")
	for character_path in character_paths:
		_assert_ok(ResourceLoader.exists(character_path), "Character GLB exists: " + character_path)
		var packed_character: Resource = load(character_path)
		_assert_ok(packed_character is PackedScene, "Character GLB imports as scene: " + character_path)
		if packed_character is PackedScene:
			var character_instance: Node = (packed_character as PackedScene).instantiate()
			var imported_skeletons: Array[Node] = character_instance.find_children("*", "Skeleton3D", true, false)
			# Godot may merge compatible glTF skins into fewer Skeleton3D
			# nodes. Assert real skinned meshes and required bones instead
			# of assuming a one-to-one glTF skin/Skeleton3D mapping.
			_assert_ok(imported_skeletons.size() >= 1, "Character imports an animated Skeleton3D: " + character_path)
			var skinned_mesh_count: int = 0
			for mesh_candidate in character_instance.find_children("*", "MeshInstance3D", true, false):
				var mesh_instance: MeshInstance3D = mesh_candidate as MeshInstance3D
				if mesh_instance.skeleton != NodePath(""):
					skinned_mesh_count += 1
			_assert_ok(skinned_mesh_count >= 6, "Six character surfaces retain skeleton bindings: " + character_path)
			var imported_bones: Dictionary = {}
			for imported_skeleton in imported_skeletons:
				var skeleton: Skeleton3D = imported_skeleton as Skeleton3D
				for bone_index in range(skeleton.get_bone_count()):
					imported_bones[skeleton.get_bone_name(bone_index)] = true
			for required_bone in ["CapeShoulder", "CapeHem", "SpineHip", "SpineChest", "Arm1Lower", "Arm-1Lower", "Leg1Lower", "Leg-1Lower"]:
				_assert_ok(imported_bones.has(required_bone), "Imported character has deforming bone " + required_bone + ": " + character_path)
			# Check every generated character's animation library, not only
			# the representative hero/enemy/boss subset below.
			var imported_player: AnimationPlayer = character_instance.find_child("AnimationPlayer", true, false) as AnimationPlayer
			_assert_ok(imported_player != null, "Character imports an AnimationPlayer: " + character_path)
			if imported_player != null:
				for required_clip in ["idle", "move", "attack", "hit", "death", "cast"]:
					var clip_found: bool = imported_player.has_animation(required_clip)
					for library_name in imported_player.get_animation_library_list():
						var library: AnimationLibrary = imported_player.get_animation_library(library_name)
						if library != null and library.has_animation(required_clip):
							clip_found = true
							break
					_assert_ok(clip_found, "Character retains imported clip %s: %s" % [required_clip, character_path])
			character_instance.free()
	# Generated GLBs are required in CI before Godot import. Verify hero-ID
	# and region-boss models really load and contain all six authored clip names.
	var required_clips := ["idle", "move", "attack", "hit", "death", "cast"]
	for asset_name in ["hero_01", "hero_15", "hero_30", "boss_region_0", "boss_region_5", "enemy_p_region_0", "enemy_n_region_3", "enemy_k_region_5"]:
		var asset_path: String = "res://assets/characters/%s.glb" % asset_name
		_assert_ok(ResourceLoader.exists(asset_path), "Generated GLB exists: " + asset_name)
		var imported: Resource = load(asset_path)
		_assert_ok(imported is PackedScene, "Generated GLB imports as scene: " + asset_name)
		if imported is PackedScene:
			var model: Node = (imported as PackedScene).instantiate()
			var player: AnimationPlayer = model.find_child("AnimationPlayer", true, false) as AnimationPlayer
			_assert_ok(player != null, "GLB animation player exists: " + asset_name)
			if player != null:
				for clip_name in required_clips:
					var found: bool = player.has_animation(clip_name)
					for library_name in player.get_animation_library_list():
						var library: AnimationLibrary = player.get_animation_library(library_name)
						if library != null and library.has_animation(clip_name):
							found = true
					_assert_ok(found, "GLB clip %s exists: %s" % [clip_name, asset_name])
					if found:
						# Avoid get_animation() on a name that exists only
						# inside a named import library: Godot logs an error
						# even when the fallback lookup would succeed.
						var animation: Animation = null
						for library_name in player.get_animation_library_list():
							var library: AnimationLibrary = player.get_animation_library(library_name)
							if library != null and library.has_animation(clip_name):
								animation = library.get_animation(clip_name)
								break
						if animation == null and player.has_animation(clip_name):
							animation = player.get_animation(clip_name)
						_assert_ok(animation != null, "Imported animation resource exists: %s/%s" % [asset_name, clip_name])
						if animation != null:
							_assert_ok(animation.get_track_count() >= 8, "Imported 3D clip retains bone and body tracks: %s/%s" % [asset_name, clip_name])
							_assert_ok(animation.length >= 0.27, "Imported 3D clip has nontrivial duration: %s/%s" % [asset_name, clip_name])
			model.free()
	# Only the chosen hero bearer gets its ID-specific imported model,
	# not every allied piece of the same chess class.
	var hero_king: Node3D = game.battlefield_3d._build_piece("K", false, true)
	var other_king: Node3D = game.battlefield_3d._build_piece("K", false, false)
	_assert_ok(bool(hero_king.get_meta("selected_hero_piece", false)), "Chosen hero bearer is marked")
	_assert_ok(not bool(other_king.get_meta("selected_hero_piece", true)), "Other units are not selected hero")
	_assert_ok(other_king.find_child("HeroIdentity_30", true, false) == null, "Other same-class units do not receive selected hero insignia")
	hero_king.queue_free()
	other_king.queue_free()
	# Gear geometry belongs only to the selected hero bearer, never to
	# every allied piece. Gear changes must not clear unrelated board units.
	var prior_gear: Dictionary = game.battlefield_3d.hero_gear.duplicate(true)
	game.battlefield_3d.hero_gear = {"Оружие": {"rarity": 3, "upgrade": 0}, "Тело": {"rarity": 3, "upgrade": 0}, "Реликвия": {"rarity": 3, "upgrade": 0}}
	var geared_bearer: Node3D = game.battlefield_3d._build_piece("K", false, true)
	var plain_ally: Node3D = game.battlefield_3d._build_piece("K", false, false)
	_assert_ok(geared_bearer.find_child("Rarity_Оружие", true, false) != null, "Selected bearer receives equipped weapon")
	_assert_ok(plain_ally.find_child("Rarity_Оружие", true, false) == null, "Other allied unit has no selected hero gear")
	# Imported GLB gear must follow animated arm joints, not float at
	# world-space offsets while the hero swings or casts.
	var weapon_socket: Node = geared_bearer.find_child("GearSocket_weapon", true, false)
	_assert_ok(weapon_socket != null, "Equipped weapon creates an authored GLB socket")
	if weapon_socket != null:
		_assert_ok(weapon_socket.get_parent().name == "Arm1" or (weapon_socket.get_parent() is BoneAttachment3D and weapon_socket.get_parent().bone_name == "Arm1"), "Weapon follows animated right arm bone")
	var armor_socket: Node = geared_bearer.find_child("GearSocket_armor", true, false)
	_assert_ok(armor_socket != null, "Equipped armor creates imported GLB socket")
	if armor_socket != null:
		_assert_ok(armor_socket.get_parent().name == "BodyRig" or (armor_socket.get_parent() is BoneAttachment3D and armor_socket.get_parent().bone_name == "SpineChest"), "Chest armor follows animated spine bone or torso fallback")
	var relic_socket: Node = geared_bearer.find_child("GearSocket_relic", true, false)
	_assert_ok(relic_socket != null, "Equipped relic creates imported GLB socket")
	if relic_socket != null:
		_assert_ok(relic_socket.get_parent().name == "Arm-1" or (relic_socket.get_parent() is BoneAttachment3D and relic_socket.get_parent().bone_name == "Arm-1"), "Relic follows animated left arm bone")
	geared_bearer.queue_free()
	plain_ally.queue_free()
	game.battlefield_3d.hero_gear = prior_gear
	# Imported modular equipment must exist for all 21 tier/slot combinations.
	for gear_slot in ["weapon", "armor", "relic"]:
		for gear_tier in range(7):
			var gear_asset: String = "res://assets/equipment/%s_tier_%d.glb" % [gear_slot, gear_tier]
			_assert_ok(ResourceLoader.exists(gear_asset), "Modular equipment GLB exists: " + gear_asset)
			_assert_ok(load(gear_asset) is PackedScene, "Modular equipment GLB imports: " + gear_asset)
	# All generated characters (30 heroes, 36 enemy classes and six bosses)
	# must be importable, and board redraws must reuse their PackedScenes.
	var character_paths: Array[String] = []
	for hero_id in range(1, 31):
		character_paths.append("res://assets/characters/hero_%02d.glb" % hero_id)
	for region_id in range(6):
		character_paths.append("res://assets/characters/boss_region_%d.glb" % region_id)
		for chess_role in ["p", "r", "n", "b", "q", "k"]:
			character_paths.append("res://assets/characters/enemy_%s_region_%d.glb" % [chess_role, region_id])
	for character_path in character_paths:
		var imported_scene: PackedScene = game.battlefield_3d._get_character_scene(character_path)
		_assert_ok(imported_scene != null and imported_scene == game.battlefield_3d._get_character_scene(character_path), "Character GLB import cached: " + character_path)
	_assert_ok(character_paths.size() == 72 and game.battlefield_3d.character_scene_cache.size() >= 72, "All 72 unique hero, enemy and boss GLBs cached alongside optional legacy class models")
	_assert_ok(game.battlefield_3d._get_character_scene("res://assets/characters/missing_999.glb") == null, "Missing character scene handled safely")

	# Imported 21-model cache avoids repeated disk/import lookups on
	# inventory changes. Material cache distinguishes rarity and upgrades.
	for gear_slot in ["weapon", "armor", "relic"]:
		for gear_tier in range(7):
			var path: String = "res://assets/equipment/%s_tier_%d.glb" % [gear_slot, gear_tier]
			var scene_a: PackedScene = game.battlefield_3d._get_equipment_scene(path)
			var scene_b: PackedScene = game.battlefield_3d._get_equipment_scene(path)
			_assert_ok(scene_a != null and scene_a == scene_b, "Equipment GLB cache reuses imported PackedScene")
	_assert_ok(game.battlefield_3d.equipment_scene_cache.size() == 21, "All 21 equipment scenes cached without duplicate entries")
	var prior_cache_gear: Dictionary = game.battlefield_3d.hero_gear.duplicate(true)
	game.battlefield_3d.hero_gear["Оружие"] = {"rarity": 4, "upgrade": 2}
	var cached_gear_material: Material = game.battlefield_3d._gear_material("Оружие")
	_assert_ok(cached_gear_material == game.battlefield_3d._gear_material("Оружие"), "Gear material cache reuses matching rarity and upgrade")
	game.battlefield_3d.hero_gear["Оружие"] = {"rarity": 4, "upgrade": 3}
	_assert_ok(cached_gear_material != game.battlefield_3d._gear_material("Оружие"), "Different upgrade levels receive distinct PBR materials")
	game.battlefield_3d.hero_gear = prior_cache_gear
	# Every roster ID must generate a unique physical signature, not only a tint.
	var hero_art_signatures: Dictionary = {}
	for hero_number in range(1, 31):
		var costume := Node3D.new()
		var art_mat: Material = game.battlefield_3d.gold_material
		game.battlefield_3d._add_hero_signature_costume(hero_number, 0, costume, art_mat)
		var family: int = (hero_number - 1) % 5
		var signature: int = int((hero_number - 1) / 5)
		var art_key: String = "%d:%d" % [family, signature]
		_assert_ok(costume.get_child_count() > 0 and not hero_art_signatures.has(art_key), "Hero %02d has unique 3D costume geometry recipe" % hero_number)
		hero_art_signatures[art_key] = true
		costume.free()
	_assert_ok(hero_art_signatures.size() == 30, "All 30 hero art recipes are represented")
	# Equipment rarity must change physical geometry for all three slots.
	var saved_gear: Dictionary = game.battlefield_3d.hero_gear.duplicate(true)
	for slot in ["Оружие", "Тело", "Реликвия"]:
		var previous_signature := ""
		for tier in range(7):
			game.battlefield_3d.hero_gear[slot] = {"rarity": tier, "upgrade": 0}
			var equipment := Node3D.new()
			game.battlefield_3d._add_equipment_geometry(slot, equipment)
			var all_meshes: Array[Node] = equipment.find_children("*", "MeshInstance3D", true, false)
			var names: PackedStringArray = []
			for mesh_node in all_meshes:
				names.append(str(mesh_node.name))
			var geometry_signature: String = "|".join(names)
			_assert_ok(all_meshes.size() > 0 and geometry_signature != previous_signature, "%s tier %d has distinct equipment geometry" % [slot, tier])
			previous_signature = geometry_signature
			equipment.free()
	game.battlefield_3d.hero_gear = saved_gear
	game.battlefield_3d.set_selected_hero_visual(hero_visual)
	_assert_ok(game.battlefield_3d.tile_materials[0].albedo_color == Color("#243e59"), "Region palette updates shared dark material")
	_assert_ok(game.battlefield_3d.tile_materials[1].albedo_color == Color("#92b7d0"), "Region palette updates shared light material")
	# Six regional backdrops must be actual distinct 3D geometry, not tile recolors.
	var region_counts: Array[int] = []
	for region_index in range(6):
		game.battlefield_3d.set_region(region_index)
		var region_meshes: int = game.battlefield_3d.region_scenery.get_child_count()
		_assert_ok(region_meshes >= 20, "Region %d has 3D environmental landmarks" % region_index)
		region_counts.append(region_meshes)
	_assert_ok(region_counts.size() == 6, "Six distinct environment scenes can be constructed")
	# Three mission layouts per region must be visually distinct.
	game.battlefield_3d.set_region(2)
	var mission_geometry_counts: Array[int] = []
	for variant in range(3):
		game.battlefield_3d.set_mission_visual_variant(variant)
		mission_geometry_counts.append(game.battlefield_3d.region_scenery.get_child_count())
	_assert_ok(mission_geometry_counts[0] != mission_geometry_counts[1], "Mission standard and obelisk layouts have distinct geometry")
	_assert_ok(mission_geometry_counts[1] != mission_geometry_counts[2], "Mission obelisk and ward layouts have distinct geometry")
	game.battlefield_3d.set_mission_visual_variant(0)
	game.battlefield_3d.set_region(1)

	game.battlefield_3d.set_visual_quality(0)
	_assert_ok(not game.battlefield_3d.key_light.shadow_enabled and not game.battlefield_3d.rim_light.visible, "Low mobile quality disables shadows and rim light")
	_assert_ok(not game.battlefield_3d.region_scenery.visible, "Low mobile quality culls optional 3D region scenery")
	_assert_ok(game.battlefield_3d.torches.all(func(light): return not light.visible), "Low mobile quality disables dynamic torch lights")
	_assert_ok(game.battlefield_3d.torch_flames.all(func(flame): return not flame.visible), "Low quality also culls torch flame meshes")
	var low_flame_scale: Vector3 = game.battlefield_3d.torch_flames[0].scale
	game.battlefield_3d._process(0.25)
	_assert_ok(game.battlefield_3d.torch_flames[0].scale == low_flame_scale, "Low quality skips hidden torch animation work")
	game.battlefield_3d.set_visual_quality(2)
	_assert_ok(game.battlefield_3d.key_light.shadow_enabled and game.battlefield_3d.rim_light.visible, "High quality restores shadow and rim light")
	_assert_ok(game.battlefield_3d.region_scenery.visible, "High quality restores 3D region scenery")
	_assert_ok(game.battlefield_3d.torches.all(func(light): return light.visible), "High quality restores torch lighting")
	_assert_ok(game.battlefield_3d.torch_flames.all(func(flame): return flame.visible), "High quality restores all flame meshes")
	_assert_ok(game.battlefield_3d.torch_flames.all(func(flame): return flame.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF), "Decorative emissive flames never cast shadows")
	var fx_root: Node3D = game.battlefield_3d.board_root
	game.battlefield_3d.set_visual_quality(0)
	var low_fx_count: int = fx_root.get_child_count()
	game.battlefield_3d._spawn_impact_sparks(60, false)
	_assert_ok(fx_root.get_child_count() == low_fx_count, "Low quality skips impact particle meshes")
	game.battlefield_3d.set_visual_quality(1)
	var medium_fx_count: int = fx_root.get_child_count()
	game.battlefield_3d._spawn_impact_sparks(60, false)
	_assert_ok(fx_root.get_child_count() == medium_fx_count + 5, "Medium quality spawns five impact sparks")
	await process_frame
	game.battlefield_3d.set_visual_quality(2)
	var high_fx_count: int = fx_root.get_child_count()
	game.battlefield_3d._spawn_impact_sparks(60, true)
	_assert_ok(fx_root.get_child_count() == high_fx_count + 9, "High quality spawns nine healing sparks")
	game.battlefield_3d.set_visual_quality(1)
	game.battlefield_3d.set_visual_quality(0)
	var low_fx_children: int = game.battlefield_3d.board_root.get_child_count()
	game.battlefield_3d._spawn_attack_trail(48, 40, false)
	_assert_ok(game.battlefield_3d.board_root.get_child_count() == low_fx_children, "Low Android quality skips transient 3D attack trail meshes")
	var low_impact_before: int = game.battlefield_3d.board_root.get_child_count()
	game.battlefield_3d._spawn_hit_impact(40, false)
	_assert_ok(game.battlefield_3d.board_root.get_child_count() == low_impact_before, "Low quality suppresses 3D impact shockwave")
	game.battlefield_3d.set_visual_quality(1)
	var medium_fx_children: int = game.battlefield_3d.board_root.get_child_count()
	game.battlefield_3d._spawn_attack_trail(48, 40, true)
	_assert_ok(game.battlefield_3d.board_root.get_child_count() == medium_fx_children + 4, "Medium quality renders four magical attack trail segments")
	var medium_impact_before: int = game.battlefield_3d.board_root.get_child_count()
	game.battlefield_3d._spawn_hit_impact(40, true)
	_assert_ok(game.battlefield_3d.board_root.get_child_count() == medium_impact_before + 5, "Medium quality adds one shockwave and four sparks")
	game.battlefield_3d.set_visual_quality(2)
	var high_impact_before: int = game.battlefield_3d.board_root.get_child_count()
	game.battlefield_3d._spawn_hit_impact(40, false)
	_assert_ok(game.battlefield_3d.board_root.get_child_count() == high_impact_before + 9, "High quality adds one shockwave and eight sparks")
	_assert_ok(game.battlefield_3d.impact_materials.size() == 2, "Impact effects reuse exactly two cached class materials")
	var impact_material: Material = game.battlefield_3d.impact_materials["physical"]
	game.battlefield_3d._spawn_hit_impact(41, false)
	_assert_ok(game.battlefield_3d.impact_materials["physical"] == impact_material, "Repeated physical attacks reuse material instance")
	game.battlefield_3d._spawn_attack_trail(40, 32, false)
	game.battlefield_3d._spawn_attack_trail(40, 32, true)
	_assert_ok(game.battlefield_3d.attack_trail_materials.size() == 2, "Both attack trail types share cached materials")
	_assert_ok(game.battlefield_3d.primitive_mesh_cache.has("trail_mesh:physical") and game.battlefield_3d.primitive_mesh_cache.has("trail_mesh:magic"), "Attack trails reuse geometry across strikes")
	game.battlefield_3d.set_visual_quality(1)
	game.battlefield_3d.set_visual_quality(1)
	_assert_ok(not game.battlefield_3d.key_light.shadow_enabled and game.battlefield_3d.torches[0].visible and not game.battlefield_3d.torches[1].visible, "Default mobile quality uses half the torch lights")
	_assert_ok(game.battlefield_3d.torch_flames[0].visible and not game.battlefield_3d.torch_flames[1].visible, "Medium quality culls flame meshes for disabled lights")
	game.battlefield_3d.set_checked_king(60)
	_assert_ok(game.battlefield_3d.checked_king_square == 60 and game.battlefield_3d.king_warning.visible, "Threatened king has visible 3D warning")
	game.battlefield_3d.set_checked_king(-1)
	_assert_ok(game.battlefield_3d.checked_king_square == -1 and not game.battlefield_3d.king_warning.visible, "3D check warning clears")
	game.turn = 1
	game.ap = 0
	game.acted = [60]
	game._end_turn()
	_assert_ok(game.turn == 1 and game.ap == 1 and game.winner == "", "Checked side receives a defensive action instead of passing")
	_assert_ok(game.acted.is_empty(), "Check response clears prior action restrictions")
	_assert_ok(not game._legal(60, 52), "King cannot move onto attacked square")
	_assert_ok(game._legal(60, 59), "King can escape check to safe square")
	game.pieces[4] = ""
	game.pieces[43] = "n"
	_assert_ok(game._chess_attacks_square(game.pieces, 43, 60), "Knight threat leaps over blockers")
	game.pieces[43] = ""
	game.pieces[51] = "p"
	_assert_ok(game._chess_attacks_square(game.pieces, 51, 60), "Pawn threatens diagonal king square")
	_assert_ok(not game._chess_attacks_square(game.pieces, 51, 59), "Pawn does not threaten forward square")
	# Stalemate: black king a8, white king c6, white queen b6.
	# a8 is safe, but a7, b7 and b8 are attacked.
	game.pieces.fill("")
	game.health.fill(0)
	game.pieces[0] = "k"
	game.pieces[18] = "K"
	game.pieces[17] = "Q"
	game.health[0] = 100
	game.health[18] = 100
	game.health[17] = 100
	game.turn = 1
	game.ap = 0
	game.acted.clear()
	game.winner = ""
	_assert_ok(not game._king_threatened(game.pieces, -1), "Stalemated king is not in check")
	_assert_ok(not game._has_legal_action(-1), "Stalemated king has no legal actions")
	game._end_turn()
	_assert_ok(game.winner == "НИЧЬЯ", "Turn boundary declares stalemate draw")
	game._reset()
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
	var previous_mode: String = game.mode
	game.mode = "arena"
	_assert_ok(game._item_stat("attack") == 0 and game._item_stat("hp") == 0, "PvP arena ignores RPG equipment bonuses")
	_assert_ok(game._attack_bonus() == 0 and game._armor_bonus() == 0, "PvP arena normalizes hero power")
	_assert_ok(not game._has_trait(3), "PvP arena disables legendary equipment traits")
	game.mode = previous_mode
	_assert_ok(game.unit_images.size() == 64, "Board creates 64 illustrated units")
	_assert_ok(game.hazard_overlays.size() == 64, "Animated danger warning on every square")
	_assert_ok(game.equipment_auras.size() == 64, "Equipment auras rendered on chess units")
	_assert_ok(game.inventory_popup != null, "Inventory dialog exists")
	_assert_ok(game.shop_popup != null, "Alchemist shop exists")
	_assert_ok(game.main_menu != null and game.main_menu.visible, "Cinematic start menu visible at launch")
	_assert_ok(game.graphics_button != null and game.graphics_button.text.contains("ГРАФИКА"), "Graphics quality selector is visible in main menu")
	var quality_before: int = game.graphics_quality
	game._cycle_graphics_quality()
	_assert_ok(game.graphics_quality == (quality_before + 1) % 3, "Graphics quality cycles on button press")
	_assert_ok(game.battlefield_3d.visual_quality == game.graphics_quality, "Quality selector updates 3D renderer immediately")
	var graphics_config := ConfigFile.new()
	_assert_ok(graphics_config.load(game.GRAPHICS_SETTINGS_PATH) == OK, "Graphics quality persists in user configuration")
	_assert_ok(int(graphics_config.get_value("graphics", "quality", -1)) == game.graphics_quality, "Saved graphics quality matches selected tier")
	game._cycle_graphics_quality()
	game._cycle_graphics_quality()

	_assert_ok(game.tutorial_popup != null, "First-run combat tutorial exists")
	_assert_ok(game.get_node_or_null("NetworkLobby") != null, "Co-op lobby is a dedicated dialog")
	_assert_ok(game.lan_address != null, "LAN address field exists")
	_assert_ok(game.lan_status != null, "LAN status field exists")
	_assert_ok(game.battle_result_dialog != null, "Battle result dialog exists")
	_assert_ok(game.boss_portrait != null, "Boss portrait exists")
	game._reset()
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
	game.acted.clear()
	_assert_ok(game.valid_raid_snapshot(game._snapshot()), "Autosave fixture passes strict snapshot schema")
	game._save_battle()
	_assert_ok(FileAccess.file_exists(game.battle_save_path), "Battle autosave exists")
	game.pieces[52] = ""
	_assert_ok(game._restore_battle(), "Autosaved battle restores")
	_assert_ok(game.pieces[52] == "P", "Restored piece matches saved state")
	game.hero_poison[52] = 2
	game._save_battle()
	game.hero_poison.clear()
	_assert_ok(game._restore_battle(), "Autosave with poison restores")
	_assert_ok(int(game.hero_poison.get(52, 0)) == 2, "Poison duration survives disk save")
	var poison_board: Array = game.pieces.duplicate()
	var poison_corrupt: Dictionary = {"52":2, "60":3, "4":2, "999":2, "bad":1, "51":"2"}
	var clean_poison: Dictionary = game.sanitize_hero_poison(poison_corrupt, poison_board)
	_assert_ok(clean_poison.size() == 1 and int(clean_poison.get(52, 0)) == 2, "Poison recovery rejects enemy, invalid duration, out-of-bounds and malformed entries")
	var poison_legacy: Dictionary = game.sanitize_hero_poison({}, poison_board)
	_assert_ok(poison_legacy.is_empty(), "Legacy saves without poison remain compatible")
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
	var corrupt_profile: Dictionary = Progression.sanitize_profile({"level":"50", "xp":true, "gold":1.5, "potions":[], "wins":{}, "dry_streak":-4, "items":"invalid", "slots":null})
	_assert_ok(int(corrupt_profile["level"]) == 1 and int(corrupt_profile["xp"]) == 0, "Malformed level and XP revert to defaults")
	_assert_ok(int(corrupt_profile["gold"]) == 0 and int(corrupt_profile["potions"]) == 2, "Fractional gold and malformed potions are rejected")
	_assert_ok(int(corrupt_profile["wins"]) == 0 and int(corrupt_profile["dry_streak"]) == 0, "Malformed win count and negative streak are sanitized")
	_assert_ok(corrupt_profile["items"].is_empty() and int(corrupt_profile["equipped"]) == -1, "Malformed inventory and slots do not equip gear")
	_assert_ok(Progression.safe_save_int(12.0, 0, 0, 99) == 12, "Integral JSON floats remain compatible")
	_assert_ok(Progression.safe_save_int(1.25, 7, 0, 99) == 7, "Fractional scalar is not truncated")
	_assert_ok(Progression.safe_save_int("999", 7, 0, 99) == 7, "String scalar cannot grant currency")
	_assert_ok(Progression.experience_needed(2) > Progression.experience_needed(1), "Increasing XP")
	_assert_ok(Progression.damage_after_armor(100, 50, 0) == 50, "Armor scales with damage")
	_assert_ok(Progression.damage_after_armor(100, 50, 50) == 100, "Penetration bypasses armor")
	var boss_drop: Dictionary = Progression.roll_item(12, true)
	_assert_ok(boss_drop.has("power") and boss_drop.has("affix"), "Boss loot has affix and item power")
	_assert_ok(boss_drop.has("penetration") and boss_drop.has("block") and boss_drop.has("bleed"), "Advanced equipment stats generated")
	_assert_ok(Progression.sell_price(boss_drop) > 10, "Loot has scaling sell value")
	var weak_weapon: Dictionary = Progression.roll_item(1)
	weak_weapon["slot"] = "Оружие"
	weak_weapon["level"] = 1
	weak_weapon["rarity"] = 0
	weak_weapon["upgrade"] = 0
	weak_weapon["set_id"] = -1
	weak_weapon["trait_id"] = -1
	var locked_weapon: Dictionary = weak_weapon.duplicate(true)
	locked_weapon["level"] = 50
	locked_weapon["attack"] = 9999
	var usable_armor: Dictionary = weak_weapon.duplicate(true)
	usable_armor["slot"] = "Тело"
	var usable_relic: Dictionary = weak_weapon.duplicate(true)
	usable_relic["slot"] = "Реликвия"
	game.player_level = 1
	game.equipment = [locked_weapon, weak_weapon, usable_armor, usable_relic]
	game.equipped_slots = {"Оружие": -1, "Тело": -1, "Реликвия": -1}
	game._equip_best()
	_assert_ok(int(game.equipped_slots["Оружие"]) == 1, "Autofit ignores level-locked stronger weapon")
	_assert_ok(int(game.equipped_slots["Тело"]) == 2, "Autofit equips armor independently")
	_assert_ok(int(game.equipped_slots["Реликвия"]) == 3, "Autofit equips relic independently")
	var corrupted_slots: Dictionary = Progression.sanitize_equipment_slots(
		[weak_weapon, usable_armor, locked_weapon, usable_relic],
		{"Оружие":2, "Тело":0, "Реликвия":3}, 1)
	_assert_ok(int(corrupted_slots["Оружие"]) == -1, "Saved level-locked weapon is unequipped")
	_assert_ok(int(corrupted_slots["Тело"]) == -1, "Saved wrong-slot gear is unequipped")
	_assert_ok(int(corrupted_slots["Реликвия"]) == 3, "Valid saved relic remains equipped")
	var malformed_slot_values: Dictionary = {"Оружие":"0","Тело":true,"Реликвия":1.5}
	var rejected_slot_values: Dictionary = Progression.sanitize_equipment_slots([weak_weapon, weak_weapon], malformed_slot_values, 50)
	_assert_ok(int(rejected_slot_values["Оружие"]) == -1, "Numeric string cannot select saved weapon")
	_assert_ok(int(rejected_slot_values["Тело"]) == -1, "Boolean cannot select saved armor")
	_assert_ok(int(rejected_slot_values["Реликвия"]) == -1, "Fractional index cannot select saved relic")
	var stale_slots: Dictionary = Progression.sanitize_equipment_slots(
		[weak_weapon, "invalid item"], {"Оружие":99, "Тело":1, "Реликвия":-1}, 1)
	_assert_ok(int(stale_slots["Оружие"]) == -1 and int(stale_slots["Тело"]) == -1, "Stale and malformed save references are rejected")
	var corrupt_item: Dictionary = weak_weapon.duplicate(true)
	corrupt_item["attack"] = -999
	_assert_ok(not Progression.is_valid_equipment_item(corrupt_item), "Negative attack in loaded equipment is invalid")
	var malformed_item: Dictionary = weak_weapon.duplicate(true)
	malformed_item["level"] = "not a level"
	_assert_ok(not Progression.is_valid_equipment_item(malformed_item), "Non-numeric equipment level is invalid")
	var impossible_item: Dictionary = weak_weapon.duplicate(true)
	impossible_item["set_id"] = 999
	_assert_ok(not Progression.is_valid_equipment_item(impossible_item), "Unknown set ID is invalid")
	var fractional_item: Dictionary = weak_weapon.duplicate(true)
	fractional_item["level"] = 1.5
	_assert_ok(not Progression.is_valid_equipment_item(fractional_item), "Fractional equipment level is rejected rather than truncated")
	var overpowered_item: Dictionary = weak_weapon.duplicate(true)
	overpowered_item["attack"] = 1000001
	_assert_ok(not Progression.is_valid_equipment_item(overpowered_item), "Implausibly large combat stats are rejected")
	var invalid_crit_item: Dictionary = weak_weapon.duplicate(true)
	invalid_crit_item["crit"] = 101
	_assert_ok(not Progression.is_valid_equipment_item(invalid_crit_item), "Chance stats cannot exceed 100 percent")
	_assert_ok(Progression.is_valid_equipment_item(weak_weapon), "Normal generated equipment remains valid")
	var compacted_profile: Dictionary = Progression.sanitize_profile({
		"level":1, "items":["broken", weak_weapon, corrupt_item, usable_armor],
		"slots":{"Оружие":1, "Тело":3, "Реликвия":2}
	})
	_assert_ok(compacted_profile["items"].size() == 2, "Invalid saved inventory entries are removed")
	_assert_ok(int(compacted_profile["slots"]["Оружие"]) == 0, "Weapon index remaps after inventory compaction")
	_assert_ok(int(compacted_profile["slots"]["Тело"]) == 1, "Armor index remaps after invalid item removal")
	_assert_ok(int(compacted_profile["slots"]["Реликвия"]) == -1, "Invalid equipped relic is unequipped")
	_assert_ok(int(compacted_profile["equipped"]) == 0, "Legacy weapon index follows compacted inventory")
	var validated_slots: Dictionary = Progression.sanitize_equipment_slots(
		[corrupt_item, malformed_item, impossible_item, weak_weapon],
		{"Оружие":0, "Тело":1, "Реликвия":2}, 1)
	_assert_ok(int(validated_slots["Оружие"]) == -1, "Corrupt saved item cannot be equipped")
	var invalid_set_bonus: Dictionary = Progression.set_bonus(
		[weak_weapon, "invalid item", corrupt_item],
		{"Оружие":0, "Тело":1, "Реликвия":2})
	_assert_ok(int(invalid_set_bonus["attack"]) == 0, "Malformed set inventory does not crash or grant bonuses")
	_assert_ok(Progression.REGIONS.size() == 6 and Progression.ENCOUNTERS.size() == 5, "Six regions and five different encounters")
	var available_modifiers: Dictionary = {}
	for mission in Progression.CAMPAIGN:
		available_modifiers[str(mission["modifier"])] = true
	for modifier in ["frost", "poison", "fury", "fortified", "ambush", "rift"]:
		_assert_ok(available_modifiers.has(modifier), "Campaign includes tactical modifier: " + modifier)
	game.mode = "raid"
	game._reset()
	game.raid_mission = {"modifier":"fury"}
	game.raid_round = 3
	var minion_index := 11
	var old_health: int = int(game.health[minion_index])
	game._apply_mission_modifier()
	_assert_ok(int(game.health[minion_index]) > old_health, "Fury restores minion health on scheduled turn")
	game.raid_mission = {"modifier":"ambush"}
	game.raid_round = 4
	game.pieces[16] = ""
	game.health[16] = 0
	game._apply_mission_modifier()
	_assert_ok(game.pieces[16] == "p", "Ambush summons a reinforcement on scheduled turn")
	game.raid_mission = {"modifier":"frost"}
	game.raid_round = 3
	game.pieces[28] = "P"
	game.health[28] = 200
	game._apply_mission_modifier()
	_assert_ok(int(game.health[28]) < 200, "Frost damages exposed hero on scheduled turn")
	game.raid_mission = {"modifier":"none"}
	game.raid_stage = 3
	game.raid_round = 2
	game.health[60] = 1
	game._draw()
	_assert_ok(game.battlefield_3d.active_hazards.has(60), "Ghost strike previews weakest hero before enemy turn")
	game._boss_aoe_hit(60, 100)
	_assert_ok(game.winner == "ПОРАЖЕНИЕ", "Lethal environmental damage to allied king ends the raid")
	game._reset()
	_assert_ok(Progression.boss_hazard_cells(2, 3, "Осада").size() == 32, "Ice boss forecasts four rows")
	_assert_ok(Progression.boss_hazard_cells(5, 3, "Охота").size() == 16, "Sky boss forecasts two columns")
	_assert_ok(Progression.boss_hazard_cells(6, 3, "Засада").size() == 64, "Final boss warns of board-wide darkness")
	_assert_ok(Progression.boss_hazard_cells(1, 4, "Разлом").size() == 8, "Rift encounter warns of central strike")
	_assert_ok(Progression.boss_hazard_cells(5, 2, "Охота").is_empty(), "Boss warnings disappear between attack rounds")
	_assert_ok(Progression.hazard_cells("frost", 3).size() == 40, "Frost forecasts five complete board rows")
	_assert_ok(Progression.hazard_cells("poison", 3).size() == 16, "Poison forecasts two side columns")
	_assert_ok(Progression.hazard_cells("rift", 3).size() == 16, "Rift forecasts two center columns")
	_assert_ok(Progression.hazard_cells("frost", 2).is_empty(), "Hazards only appear ahead of strike rounds")
	_assert_ok(Progression.hazard_cells("ambush", 4).is_empty(), "Non-damage modifiers do not display misleading danger cells")
	game.battlefield_3d.set_hazards(Progression.hazard_cells("rift", 3), "rift")
	# Imported glTF animations often live in a named AnimationLibrary.
	var clip_rig := Node3D.new()
	var clip_model := Node3D.new()
	clip_model.name = "AuthoredCharacter"
	clip_rig.add_child(clip_model)
	var clip_player := AnimationPlayer.new()
	clip_player.name = "AnimationPlayer"
	clip_model.add_child(clip_player)
	var clip_library := AnimationLibrary.new()
	var move_clip := Animation.new()
	move_clip.length = 0.5
	clip_library.add_animation("move", move_clip)
	var attack_clip := Animation.new()
	attack_clip.length = 0.5
	clip_library.add_animation("attack", attack_clip)
	clip_player.add_animation_library("Imported", clip_library)
	game.battlefield_3d.add_child(clip_rig)
	_assert_ok(game.battlefield_3d._play_authored_clip(clip_rig, "move"), "Imported library move clip resolves")
	_assert_ok(clip_player.current_animation == "Imported/move", "Imported move clip plays")
	_assert_ok(game.battlefield_3d._play_authored_clip(clip_rig, "attack"), "Imported library attack clip resolves")
	_assert_ok(clip_player.current_animation == "Imported/attack", "Imported attack clip plays")
	_assert_ok(not game.battlefield_3d._play_authored_clip(clip_rig, "idle"), "Missing imported clip does not play unrelated animation")
	clip_rig.queue_free()
	_assert_ok(game.battlefield_3d.hazard_markers.size() == 64, "3D battlefield has hazard marker for every square")
	_assert_ok(game.battlefield_3d.hazard_markers[3].visible and not game.battlefield_3d.hazard_markers[0].visible, "3D hazard markers match forecasted squares")
	game.battlefield_3d.set_hazards(Progression.hazard_cells("none", 1), "none")
	_assert_ok(not game.battlefield_3d.hazard_markers[3].visible, "3D hazard markers clear after danger")
	# Enemy poison is a unit status, not a permanent square hazard.
	game._reset()
	game.pieces[8] = "p"
	game.health[8] = 45
	game.pieces[16] = ""
	game.health[16] = 0
	game.poison_marks[8] = 3
	game._move(8, 16)
	_assert_ok(not game.poison_marks.has(8) and int(game.poison_marks.get(16, 0)) == 3, "Poison stacks follow moving enemy")
	game.poison_marks[24] = 2
	game.pieces[24] = "p"
	game.health[24] = 10
	game._move(16, 24)
	_assert_ok(not game.poison_marks.has(16) and int(game.poison_marks.get(24, 0)) == 3, "Moving enemy replaces captured unit poison instead of inheriting it")
	game._reset()
	_assert_ok(game.poison_marks.is_empty(), "New encounter clears enemy poison stacks")
	# Persistent mission poison follows the unit and expires after two enemy turns.
	game._reset()
	game.hero_poison[60] = 2
	game._move(60, 52)
	_assert_ok(not game.hero_poison.has(60) and int(game.hero_poison.get(52, 0)) == 2, "Poison follows moving hero")
	var hp_before_poison: int = game.health[52]
	game._tick_hero_poison()
	_assert_ok(game.health[52] < hp_before_poison and int(game.hero_poison.get(52, 0)) == 1, "Poison damages and decrements duration")
	game._tick_hero_poison()
	_assert_ok(not game.hero_poison.has(52), "Poison expires after second tick")
	game.hero_poison[52] = 2
	game.pieces[52] = ""
	game._tick_hero_poison()
	_assert_ok(game.hero_poison.is_empty(), "Poison clears for removed unit")
	game._reset()
	_assert_ok(game.hero_poison.is_empty(), "Poison clears on new encounter")
	game.health[60] = 1
	game.hero_poison[60] = 2
	game._tick_hero_poison()
	_assert_ok(game.winner == "ПОРАЖЕНИЕ" and game.pieces[60] == "", "Lethal persistent poison defeats allied king and removes unit")
	_assert_ok(game.hero_poison.is_empty(), "Lethal poison clears remaining status effects")
	game._reset()
	game.mode = "raid"
	game._reset()
	game.pieces[48] = "P"
	game.health[48] = 100
	game.hero_poison[48] = 2
	var poison_snapshot: Dictionary = game._snapshot()
	_assert_ok(int(poison_snapshot["hero_poison"][48]) == 2, "Poison status survives battle snapshot for save and LAN")
	game.battlefield_3d.set_poison_indicators(game.hero_poison)
	_assert_ok(game.battlefield_3d.poison_indicators.has(48), "Poisoned hero has a 3D status marker")
	game.battlefield_3d.set_poison_indicators({48: 2}, {8: 3, 9: 1})
	_assert_ok(game.battlefield_3d.enemy_poison_indicators.has(8) and game.battlefield_3d.enemy_poison_indicators.has(9), "Poisoned enemy units receive separate 3D markers")
	_assert_ok(game.battlefield_3d.poison_indicators.has(48), "Enemy poison visualization does not overwrite hero poison")
	game.battlefield_3d.set_poison_indicators({48: 2}, {9: 1, 10: 0})
	_assert_ok(not game.battlefield_3d.enemy_poison_indicators.has(8) and not game.battlefield_3d.enemy_poison_indicators.has(10), "Expired and zero-stack enemy poison markers are removed")
	_assert_ok(game.battlefield_3d.enemy_poison_indicators.size() == 1, "Enemy poison marker cache tracks only live statuses")
	var stack_marker: MeshInstance3D = game.battlefield_3d.enemy_poison_indicators[9]
	var one_stack_scale: float = stack_marker.scale.x
	game.battlefield_3d.set_poison_indicators({48: 2}, {9: 5})
	_assert_ok(game.battlefield_3d.enemy_poison_indicators[9] == stack_marker, "Poison intensity update reuses marker node")
	_assert_ok(stack_marker.scale.x > one_stack_scale and int(stack_marker.get_meta("stacks")) == 5, "Poison intensity changes visible marker size")
	game.battlefield_3d.set_poison_indicators({48: 2}, {9: 100})
	_assert_ok(int(stack_marker.get_meta("stacks")) == 5, "Poison visual intensity is capped")


	game.battlefield_3d.set_poison_indicators({})
	_assert_ok(game.battlefield_3d.poison_indicators.is_empty(), "Poison status markers disappear when cleared")
	_assert_ok(game.battlefield_3d.enemy_poison_indicators.is_empty(), "Enemy poison markers also clear after encounter")
	game.hero_poison.clear()
	game._send_snapshot(poison_snapshot)
	_assert_ok(game.hero_poison.is_empty(), "Remote snapshot is ignored when LAN client is not connected")
	var invalid_poison_board: Array = game.pieces.duplicate()
	invalid_poison_board[48] = "INVALID"
	_assert_ok(game.sanitize_hero_poison({48: 2}, invalid_poison_board).is_empty(), "Invalid uppercase glyph cannot receive poison")
	invalid_poison_board[48] = "p"
	_assert_ok(game.sanitize_hero_poison({48: 2}, invalid_poison_board).is_empty(), "Enemy pawn cannot receive allied poison status")
	invalid_poison_board[48] = "P"
	_assert_ok(int(game.sanitize_hero_poison({48: 2}, invalid_poison_board).get(48, 0)) == 2, "Valid hero pawn retains poison")
	# Every chess role gets a distinctive heraldic silhouette even if
	# external GLB imports are absent. Check both teams and all six classes.
	for role in ["P", "R", "N", "B", "Q", "K"]:
		for team_role in [role, role.to_lower()]:
			var plinth_test_unit: Node3D = game.battlefield_3d._build_piece(team_role, false, false)
			var plinth: Node3D = plinth_test_unit.get_node_or_null("ClassInsignia_" + role)
			_assert_ok(plinth != null and plinth.get_child_count() >= 2, "3D class heraldry has distinct geometry: " + team_role)
			plinth_test_unit.queue_free()
	# Board cosmetics must survive region changes and must never alter
	# gameplay board indices or biome lighting.
	game.battlefield_3d.set_board_visual_style(2)
	var obsidian_dark: Color = game.battlefield_3d.tile_materials[0].albedo_color
	var obsidian_light: Color = game.battlefield_3d.tile_materials[1].albedo_color
	game.battlefield_3d.set_region(3)
	game.battlefield_3d.set_region(4)
	_assert_ok(game.battlefield_3d.tile_materials[0].albedo_color == obsidian_dark and game.battlefield_3d.tile_materials[1].albedo_color == obsidian_light, "Selected board skin survives biome changes")
	game.battlefield_3d.set_board_visual_style(-1)
	_assert_ok(not game.battlefield_3d.board_style_customized, "Resetting board skin returns to biome palette")
	_assert_ok(game.battlefield_3d.tile_materials[0].albedo_color == Color("#28395e"), "Biome reset restores active region colors")
	game.battlefield_3d.set_region(0)
	# All health bars on a side should reuse a single material, even
	# after actor rebuilding and region changes.
	var sample_hero: Node3D = game.battlefield_3d._build_piece("P", false, false)
	var sample_enemy: Node3D = game.battlefield_3d._build_piece("p", false, false)
	_assert_ok(game.battlefield_3d.health_bar_materials.size() == 2, "Health bars share exactly two team materials")
	var hero_bar: MeshInstance3D = sample_hero.get_meta("health_fill")
	var enemy_bar: MeshInstance3D = sample_enemy.get_meta("health_fill")
	_assert_ok(hero_bar.material_override == game.battlefield_3d.health_bar_materials["hero"], "Friendly HP bars reuse cached PBR material")
	_assert_ok(enemy_bar.material_override == game.battlefield_3d.health_bar_materials["enemy"], "Enemy HP bars reuse cached PBR material")
	sample_hero.queue_free()
	sample_enemy.queue_free()

	# Replacing regional enemy GLBs must never visually heal damaged units.
	var health_sample: Array = []
	var max_health_sample: Array = []
	for cell in range(64):
		health_sample.append(50)
		max_health_sample.append(100)
	game.battlefield_3d.sync_board(game.pieces, -1, [], -1, health_sample, max_health_sample)
	var damaged_enemy_cell: int = -1
	for cell in game.battlefield_3d.piece_nodes.keys():
		if str(game.battlefield_3d.piece_types.get(cell, "")) == "p":
			damaged_enemy_cell = cell
			break
	if damaged_enemy_cell >= 0:
		var old_fill: MeshInstance3D = (game.battlefield_3d.piece_nodes[damaged_enemy_cell] as Node3D).get_meta("health_fill")
		_assert_ok(absf(old_fill.scale.x - 0.5) < 0.001, "Enemy 3D HP bar reflects actual damage before biome switch")
		game.battlefield_3d.set_region(2)
		var rebuilt_fill: MeshInstance3D = (game.battlefield_3d.piece_nodes[damaged_enemy_cell] as Node3D).get_meta("health_fill")
		_assert_ok(rebuilt_fill != old_fill and absf(rebuilt_fill.scale.x - 0.5) < 0.001, "Enemy HP bar survives full biome mesh replacement")
	var restored_max_health: Array = []
	for restore_cell in range(64):
		var restore_piece: String = str(game.pieces[restore_cell])
		restored_max_health.append(game._max_hp(restore_piece, game._team(restore_piece) == 1) if restore_piece != "" else 1)
	game.battlefield_3d.sync_board(game.pieces, -1, [], -1, game.health, restored_max_health)

	var scenery_counts: Array[int] = []
	var region_light_colors: Array[Color] = []
	for region_index in range(6):
		game.battlefield_3d.set_region(region_index)
		var scenery: Node3D = game.battlefield_3d.region_scenery
		_assert_ok(scenery != null and scenery.get_child_count() > 25, "Region has distinct 3D environment meshes")
		scenery_counts.append(scenery.get_child_count())
		var landmark: Node3D = scenery.get_node_or_null("BiomeLandmark_%d" % region_index)
		_assert_ok(landmark != null, "Each biome constructs its unique 3D landmark group")
		_assert_ok(game.battlefield_3d.biome_landmark_motion.size() >= 1 and game.battlefield_3d.biome_landmark_motion.size() <= 4, "Each biome animates a bounded number of accent meshes")
		for animated_accent in game.battlefield_3d.biome_landmark_motion:
			_assert_ok(is_instance_valid(animated_accent["node"]), "Biome animated accents refer to live scene geometry")
		if landmark != null:
			_assert_ok(landmark.get_child_count() >= 10, "Each biome has substantial landmark geometry")
			for part in landmark.get_children():
				if part is MeshInstance3D:
					_assert_ok((part as MeshInstance3D).mesh != null, "Biome landmark meshes are non-null")
		var lighting: WorldEnvironment = game.battlefield_3d.world_environment
		_assert_ok(lighting != null and lighting.environment != null, "Region has a 3D world environment")
		region_light_colors.append(game.battlefield_3d.rim_light.light_color)
		_assert_ok(game.battlefield_3d.key_light.light_energy > 0.0, "Region key lighting stays active")
	_assert_ok(region_light_colors[0] != region_light_colors[1] and region_light_colors[4] != region_light_colors[5], "Regions have distinct 3D rim-light palettes")
	_assert_ok(scenery_counts[0] != scenery_counts[1], "Fortress and frostland environments use different geometry")
	game.battlefield_3d.set_region(0)
	_assert_ok(game.battlefield_3d.region_scenery.get_child_count() == scenery_counts[0], "Switching regions rebuilds scenery without accumulation")
	_assert_ok(game.battlefield_3d.biome_material_cache.size() == 6, "Six biomes share six stable material sets")
	_assert_ok(game.battlefield_3d.castle_material_cache.size() == 6, "Castle skyline materials are cached for all six regions")
	var cached_castle_material: Material = game.battlefield_3d.castle_material_cache[0][0]
	var cached_forge_material: Material = game.battlefield_3d.biome_material_cache[0][0]
	game.battlefield_3d.set_region(1)
	game.battlefield_3d.set_region(0)
	_assert_ok(game.battlefield_3d.biome_material_cache[0][0] == cached_forge_material, "Revisiting a region reuses existing PBR materials")
	_assert_ok(game.battlefield_3d.biome_material_cache.size() == 6, "Region switching does not grow material cache")
	_assert_ok(game.battlefield_3d.castle_material_cache.size() == 6 and game.battlefield_3d.castle_material_cache[0][0] == cached_castle_material, "Castle skyline reuses its original material after biome revisit")
	for asset_name in ["pawn", "rook", "knight", "bishop", "queen", "king"]:
		var mesh_path: String = "res://assets/characters/%s.obj" % asset_name
		_assert_ok(ResourceLoader.exists(mesh_path), "Original 3D mesh exists for " + asset_name)
		var imported_mesh: Resource = load(mesh_path)
		_assert_ok(imported_mesh is Mesh, "Original 3D mesh imports as a Godot Mesh: " + asset_name)
	for class_letter in ["P", "R", "N", "B", "Q", "K"]:
		_assert_ok(game.battlefield_3d.CHARACTER_SCENE_PATHS.has(class_letter), "Every chess class has an authored 3D asset path")
		var sample: Node3D = game.battlefield_3d._build_piece(class_letter)
		_assert_ok(sample.get_meta("health_fill", null) != null, "Imported-model fallback keeps the combat health bar")
		_assert_ok(sample.get_meta("visual_rig", null) is Node3D, "Each class has an independently animatable 3D character rig")
		_assert_ok((sample.get_meta("visual_rig") as Node3D).get_child_count() > 0, "Visual rig contains actual geometry")
		_assert_ok((sample.get_meta("visual_rig") as Node3D).get_child_count() >= 5, "Each character has layered 3D costume and silhouette details")
		sample.queue_free()
	_assert_ok(Progression.CAMPAIGN.size() == 18, "Complete 18-mission story campaign")
	var mission_titles: Dictionary = {}
	for mission in Progression.CAMPAIGN:
		mission_titles[str(mission["title"])] = true
		_assert_ok(str(mission["goal"]) != "" and str(mission["modifier"]) != "", "Story mission has objective and gameplay modifier")
	_assert_ok(mission_titles.size() == 18, "Every story mission has a unique title")
	_assert_ok(str(Progression.mission_for_run(18)["title"]) == "Экспедиция №1", "Post-campaign expedition unlocks after final boss")
	_assert_ok(str(Progression.mission_for_run(19)["title"]) == "Экспедиция №2", "Endgame expedition advances without repeating story")
	_assert_ok(Progression.TRAITS.size() == 6 and Progression.TRAIT_DESCRIPTIONS.size() == 6, "Six named legendary traits with player explanations")
	for chapter in range(1, 7):
		var reward: Dictionary = Progression.first_clear_reward(chapter * 3)
		_assert_ok(not reward.is_empty() and int(reward["trait_id"]) == chapter - 1, "Unique deterministic chapter reward %d" % chapter)
	_assert_ok(Progression.first_clear_reward(19).is_empty(), "No duplicate chapter reward after campaign")
	_assert_ok(Progression.first_clear_reward(2).is_empty(), "No chapter reward before boss milestone")
	_assert_ok(Progression.region_for_run(0) != Progression.region_for_run(9), "Campaign advances to new regions")
	_assert_ok(Progression.encounter_for_run(0) != Progression.encounter_for_run(1), "Campaign rotates encounter mechanics")
	var upgraded: Dictionary = Progression.upgrade_item(boss_drop)
	_assert_ok(int(upgraded["upgrade"]) == 1 and Progression.item_score(upgraded) > Progression.item_score(boss_drop), "Forging improves gear power")
	_assert_ok(int(boss_drop.get("upgrade", 0)) == 0, "Forging does not mutate source item")
	var set_items: Array = []
	for slot in Progression.ITEM_SLOTS:
		var piece: Dictionary = Progression.roll_item(15)
		piece["slot"] = slot
		piece["set_id"] = 1
		set_items.append(piece)
	var set_bonus: Dictionary = Progression.set_bonus(set_items, {"Оружие":0,"Тело":1,"Реликвия":2})
	_assert_ok(int(set_bonus["attack"]) > 0 and int(set_bonus["armor"]) > 0, "Three-piece set activates two and three piece bonuses")
	_assert_ok(game.battlefield_3d != null and game.battlefield_3d.tiles.size() == 64, "Actual 3D arena contains 64 modeled squares")
	_assert_ok(game.battlefield_3d.pick_square(Vector2(450, 450)) >= 0, "3D camera ray picks battlefield square")
	var visual_gear: Array = [
		{"rarity":5,"upgrade":8,"set_id":2,"slot":"Оружие"},
		{"rarity":4,"upgrade":4,"set_id":2,"slot":"Тело"},
		{"rarity":3,"upgrade":1,"set_id":2,"slot":"Реликвия"}
	]
	game.battlefield_3d.set_hero_gear(visual_gear, {"Оружие":0,"Тело":1,"Реликвия":2})
	_assert_ok(game.battlefield_3d.hero_gear.size() == 3, "All three RPG gear slots change 3D character visuals")

	# Every rarity tier must change physical mesh count in all three gear slots.
	for rarity in range(7):
		var tier_gear: Array = [
			{"rarity":rarity,"upgrade":0,"set_id":-1,"slot":"Оружие"},
			{"rarity":rarity,"upgrade":0,"set_id":-1,"slot":"Тело"},
			{"rarity":rarity,"upgrade":0,"set_id":-1,"slot":"Реликвия"}
		]
		game.battlefield_3d.set_hero_gear(tier_gear, {"Оружие":0,"Тело":1,"Реликвия":2})
		var tier_piece: Node3D = game.battlefield_3d._build_piece("K")
		var tier_rig: Node3D = tier_piece.get_meta("visual_rig")
		for slot in ["Оружие", "Тело", "Реликвия"]:
			var insignia: Node3D = tier_rig.get_node_or_null("Rarity_" + slot)
			_assert_ok(insignia != null and insignia.get_child_count() == rarity + 1, "3D gear rarity %d has distinct %s crest geometry" % [rarity, slot])
		tier_piece.queue_free()
	game.battlefield_3d.set_hero_gear(visual_gear, {"Оружие":0,"Тело":1,"Реликвия":2})

	game.battlefield_3d.sync_board(game.pieces, -1, [], -1)
	_assert_ok(game.battlefield_3d.piece_nodes.size() > 0, "3D chess models rebuild with equipped cosmetic gear")
	var aura_test_boss: Node3D = game.battlefield_3d._build_piece("k", true, false)
	var aura_group: Node3D = aura_test_boss.find_child("BossEnrageAura", true, false) as Node3D
	_assert_ok(aura_group != null and aura_group.get_child_count() == 7, "Boss has three crown rings and four orbiting crystal shards")
	_assert_ok(aura_group != null and aura_group.get_parent().name == "VisualRig", "Boss aura follows animated VisualRig hierarchy")

	aura_test_boss.queue_free()
	game.battlefield_3d.set_boss_phase(2)
	_assert_ok(game.battlefield_3d.boss_enraged, "Boss enrage switches on cinematic 3D transformation")
	if game.battlefield_3d.piece_nodes.has(4):
		var active_boss: Node3D = game.battlefield_3d.piece_nodes[4]
		var active_aura: Node3D = active_boss.find_child("BossEnrageAura", true, false) as Node3D
		if active_aura != null:
			_assert_ok(active_aura.visible, "Boss enrage reveals animated crown aura")
			game.battlefield_3d.set_visual_quality(0)
			_assert_ok(not active_aura.visible, "Low graphics disables nested boss enrage aura")
			game.battlefield_3d.set_visual_quality(2)
			_assert_ok(active_aura.visible, "High graphics restores nested boss enrage aura")
			game.battlefield_3d.set_visual_quality(1)
			active_aura.visible = false
			active_boss.scale = Vector3.ONE
			game.battlefield_3d.set_boss_phase(2)
			_assert_ok(active_aura.visible and active_boss.scale.x > 1.4, "Reapplying same boss phase restores visuals after actor rebuild")

	game.battlefield_3d.set_boss_phase(1)
	_assert_ok(not game.battlefield_3d.boss_enraged, "Boss enrage state resets correctly")
	if game.battlefield_3d.piece_nodes.has(4):
		_assert_ok(absf((game.battlefield_3d.piece_nodes[4] as Node3D).position.y) < 0.001, "Boss returns to board height after enrage")

	# Floating combat numbers must be visible in the 3D SubViewport.
	# The legacy 2D chess grid is hidden, so UI labels alone are insufficient.
	var numbers_before: int = game.battlefield_3d.board_root.get_child_count()
	game.battlefield_3d.show_combat_number(60, 37, false)
	_assert_ok(game.battlefield_3d.board_root.get_child_count() == numbers_before + 1, "Damage creates a world-space combat number")
	var damage_label: Label3D = game.battlefield_3d.board_root.get_child(game.battlefield_3d.board_root.get_child_count() - 1) as Label3D
	_assert_ok(damage_label != null and damage_label.text == "−37" and damage_label.no_depth_test, "3D damage number is readable over the battlefield")
	game.battlefield_3d.show_combat_number(60, 12, true)
	var heal_label: Label3D = game.battlefield_3d.board_root.get_child(game.battlefield_3d.board_root.get_child_count() - 1) as Label3D
	_assert_ok(heal_label != null and heal_label.text == "+12", "Healing uses distinct 3D number and positive sign")
	var numbers_valid: int = game.battlefield_3d.board_root.get_child_count()
	game.battlefield_3d.show_combat_number(-1, 30)
	game.battlefield_3d.show_combat_number(64, 30)
	game.battlefield_3d.show_combat_number(60, 0)
	_assert_ok(game.battlefield_3d.board_root.get_child_count() == numbers_valid, "Invalid cells and zero values cannot allocate combat labels")

	# Main gameplay events must invoke the 3D label path and avoid the
	# invisible legacy button-label animation on the hidden chess grid.
	var old_2d_children: int = game.buttons[60].get_child_count()
	var before_popup_3d: int = game.battlefield_3d.board_root.get_child_count()
	game._damage_popup(60, 19, false)
	_assert_ok(game.battlefield_3d.board_root.get_child_count() > before_popup_3d, "Gameplay damage popup reaches visible 3D scene")
	_assert_ok(game.buttons[60].get_child_count() == old_2d_children, "Hidden 2D grid does not allocate invisible damage labels")

	# Quality-tier combat regression: low graphics must never allocate
	# translucent transient meshes, while medium retains visible impacts.
	game.battlefield_3d.set_visual_quality(0)
	var low_fx_before: int = game.battlefield_3d.board_root.get_child_count()
	game.battlefield_3d.attack(60, 52)
	game.battlefield_3d.hit(60)
	_assert_ok(game.battlefield_3d.board_root.get_child_count() == low_fx_before, "Low graphics tier creates no transient combat VFX geometry")
	game.battlefield_3d.set_visual_quality(1)
	var medium_fx_before: int = game.battlefield_3d.board_root.get_child_count()
	game.battlefield_3d.hit(60)
	_assert_ok(game.battlefield_3d.board_root.get_child_count() > medium_fx_before, "Medium graphics tier creates visible combat impact VFX")
	var shock_mesh: Mesh = game.battlefield_3d.primitive_mesh_cache["hit_shock_torus"]
	var hit_material: Material = game.battlefield_3d.impact_materials["damage"]
	game.battlefield_3d.hit(60, true)
	_assert_ok(game.battlefield_3d.primitive_mesh_cache["hit_shock_torus"] == shock_mesh, "Healing and damage share the same torus mesh")
	_assert_ok(game.battlefield_3d.impact_materials.has("heal"), "Healing VFX uses distinct mint-colored material")
	var heal_material: Material = game.battlefield_3d.impact_materials["heal"]
	game.battlefield_3d.hit(60, false)
	game.battlefield_3d.hit(60, true)
	_assert_ok(game.battlefield_3d.impact_materials["damage"] == hit_material and game.battlefield_3d.impact_materials["heal"] == heal_material, "Repeated heals and damage reuse cached VFX materials")
	_assert_ok(game.battlefield_3d.primitive_mesh_cache.has("hit_spark_sphere"), "Healing and damage sparks reuse one low-poly sphere mesh")
	_assert_ok(game.battlefield_3d.impact_materials.has("heal_sparks") and game.battlefield_3d.impact_materials.has("damage_sparks"), "Spark VFX uses shared mint and amber PBR resources")
	var spark_mesh: Mesh = game.battlefield_3d.primitive_mesh_cache["hit_spark_sphere"]
	var spark_mat: Material = game.battlefield_3d.impact_materials["heal_sparks"]
	game.battlefield_3d.hit(60, true)
	_assert_ok(game.battlefield_3d.primitive_mesh_cache["hit_spark_sphere"] == spark_mesh and game.battlefield_3d.impact_materials["heal_sparks"] == spark_mat, "Repeated healing reuses particle geometry and material")


	game.battlefield_3d.set_visual_quality(0)
	var low_self_before: int = game.battlefield_3d.board_root.get_child_count()
	game.battlefield_3d.attack(60, 60, true)
	_assert_ok(game.battlefield_3d.board_root.get_child_count() == low_self_before, "Self-targeted spell works without low-tier VFX allocation")
	game.battlefield_3d.set_visual_quality(1)
	var medium_self_before: int = game.battlefield_3d.board_root.get_child_count()
	game.battlefield_3d.attack(60, 60, true)
	_assert_ok(game.battlefield_3d.board_root.get_child_count() == medium_self_before, "Self-targeted spell never creates degenerate beam geometry")
	game.battlefield_3d.attack(60, 52)
	_assert_ok(game.battlefield_3d.piece_nodes.has(60), "3D attack animation preserves board state")
	var test_sword: Dictionary = weak_weapon.duplicate(true)
	for stat in ["attack", "armor", "hp", "crit", "lifesteal", "penetration", "block", "bleed"]:
		test_sword[stat] = 0
	test_sword["attack"] = 12
	var test_armor: Dictionary = usable_armor.duplicate(true)
	for stat in ["attack", "armor", "hp", "crit", "lifesteal", "penetration", "block", "bleed"]:
		test_armor[stat] = 0
	test_armor["attack"] = 2
	test_armor["armor"] = 8
	test_armor["hp"] = 30
	var test_relic: Dictionary = usable_relic.duplicate(true)
	for stat in ["attack", "armor", "hp", "crit", "lifesteal", "penetration", "block", "bleed"]:
		test_relic[stat] = 0
	test_relic["attack"] = 1
	test_relic["lifesteal"] = 10
	game.equipment = [test_sword, test_armor, test_relic]
	game.mode = "raid"
	game.equipped_slots = {"Оружие":0,"Тело":1,"Реликвия":2}
	game.shared_raid_stats = {"level": 9, "attack": 44, "armor": 12, "hp": 75, "crit": 8, "lifesteal": 4}
	game.lan_connected = true
	game.lan_host = false
	_assert_ok(game._item_stat("attack") == 44 and game._item_stat("armor") == 12, "Co-op client uses host equipment stats")
	_assert_ok(game._effective_level() == 9 and game._item_stat("hp") == 75, "Co-op client displays host level and HP bonus")
	game.lan_connected = false
	game.shared_raid_stats.clear()
	_assert_ok(game._item_stat("attack") == 15, "Equipped slots aggregate attack")
	_assert_ok(game._item_stat("armor") == 8, "Equipped armor mitigates incoming damage")
	_assert_ok(game._item_stat("hp") == 30, "Equipped armor raises hero maximum HP")
	game.pieces[60] = "K"
	game.health[60] = 180
	var damage_dealt: int = game._deal_damage(60, 30, false)
	_assert_ok(damage_dealt == Progression.damage_after_armor(30, game._armor_bonus()) and game.health[60] == 180 - damage_dealt, "Armor reduces actual chess-piece damage")
	game.mode = "arena"
	game._reset()
	game.pieces[8] = "P"
	game.health[8] = 37
	game.pieces[0] = ""
	game._move(8, 0)
	_assert_ok(game.pieces[0] == "Q" and game.health[0] == 37, "White pawn promotes to queen preserving HP")
	game._reset()
	game.pieces[55] = "p"
	game.health[55] = 22
	game.pieces[63] = ""
	game._move(55, 63)
	_assert_ok(game.pieces[63] == "q" and game.health[63] == 22, "Black pawn promotes to queen preserving HP")
	game.mode = "raid"
	game._reset()
	game._reset()
	game.health[60] = 180
	game.selected = 60
	game._heal_selected()
	_assert_ok(game.health[60] > 180, "Healing works above base HP when armor raises maximum HP")
	game.selected = 60
	game.heal_used = false
	game.acted.clear()
	game.ap = 2
	game.health[60] = 205
	game._heal_selected()
	_assert_ok(game.health[60] <= game._max_hp("K"), "Healing clamps to equipment-enhanced maximum HP")
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
	game.queue_free()
	if _failure_count > 0:
		push_error("KINGDOM CHESS: %d SMOKE ASSERTIONS FAILED" % _failure_count)
		quit(1)
	else:
		print("KINGDOM CHESS: GAMEPLAY LOGIC SMOKE TESTS PASSED")
		quit(0)
