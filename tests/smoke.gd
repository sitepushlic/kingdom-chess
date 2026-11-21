extends SceneTree

const Progression = preload("res://scripts/progression.gd")
const HeroRoster = preload("res://scripts/hero_roster.gd")
const MainScene = preload("res://scenes/main.tscn")

func _initialize() -> void:
	_run()

func _assert_ok(condition: bool, description: String) -> void:
	if not condition:
		push_error("TEST FAILED: " + description)
		quit(1)

func _run() -> void:
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
	_assert_ok(game.battlefield_3d != null, "3D battlefield initialized before chess warning assertions")
	# Chess-first RPG movement: threat geometry, king safety and pinned pieces.
	game.mode = "arena"
	game._reset()
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
	_assert_ok(game.battlefield_3d != null, "3D board exists for check warning")
	game.battlefield_3d.set_visual_quality(0)
	_assert_ok(not game.battlefield_3d.key_light.shadow_enabled and not game.battlefield_3d.rim_light.visible, "Low mobile quality disables shadows and rim light")
	_assert_ok(game.battlefield_3d.torches.all(func(light): return not light.visible), "Low mobile quality disables dynamic torch lights")
	game.battlefield_3d.set_visual_quality(2)
	_assert_ok(game.battlefield_3d.key_light.shadow_enabled and game.battlefield_3d.rim_light.visible, "High quality restores shadow and rim light")
	_assert_ok(game.battlefield_3d.torches.all(func(light): return light.visible), "High quality restores torch lighting")
	game.battlefield_3d.set_visual_quality(1)
	_assert_ok(not game.battlefield_3d.key_light.shadow_enabled and game.battlefield_3d.torches[0].visible and not game.battlefield_3d.torches[1].visible, "Default mobile quality uses half the torch lights")
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
	game.battlefield_3d.set_poison_indicators({})
	_assert_ok(game.battlefield_3d.poison_indicators.is_empty(), "Poison status markers disappear when cleared")
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
	var scenery_counts: Array[int] = []
	var region_light_colors: Array[Color] = []
	for region_index in range(6):
		game.battlefield_3d.set_region(region_index)
		var scenery: Node3D = game.battlefield_3d.region_scenery
		_assert_ok(scenery != null and scenery.get_child_count() > 25, "Region has distinct 3D environment meshes")
		scenery_counts.append(scenery.get_child_count())
		var lighting: WorldEnvironment = game.battlefield_3d.world_environment
		_assert_ok(lighting != null and lighting.environment != null, "Region has a 3D world environment")
		region_light_colors.append(game.battlefield_3d.rim_light.light_color)
		_assert_ok(game.battlefield_3d.key_light.light_energy > 0.0, "Region key lighting stays active")
	_assert_ok(region_light_colors[0] != region_light_colors[1] and region_light_colors[4] != region_light_colors[5], "Regions have distinct 3D rim-light palettes")
	_assert_ok(scenery_counts[0] != scenery_counts[1], "Fortress and frostland environments use different geometry")
	game.battlefield_3d.set_region(0)
	_assert_ok(game.battlefield_3d.region_scenery.get_child_count() == scenery_counts[0], "Switching regions rebuilds scenery without accumulation")
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
	game.battlefield_3d.set_boss_phase(2)
	_assert_ok(game.battlefield_3d.boss_enraged, "Boss enrage switches on cinematic 3D transformation")
	game.battlefield_3d.set_boss_phase(1)
	_assert_ok(not game.battlefield_3d.boss_enraged, "Boss enrage state resets correctly")
	game.battlefield_3d.attack(60, 52)
	_assert_ok(game.battlefield_3d.piece_nodes.has(60), "3D attack animation preserves board state")
	var test_sword: Dictionary = weak_weapon.duplicate(true)
	test_sword["attack"] = 12
	var test_armor: Dictionary = usable_armor.duplicate(true)
	test_armor["attack"] = 2
	test_armor["armor"] = 8
	test_armor["hp"] = 30
	var test_relic: Dictionary = usable_relic.duplicate(true)
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
	print("KINGDOM CHESS: GAMEPLAY LOGIC SMOKE TESTS PASSED")
	game.queue_free()
	quit(0)
