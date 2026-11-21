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
	for region_index in range(6):
		game.battlefield_3d.set_region(region_index)
		var scenery: Node3D = game.battlefield_3d.region_scenery
		_assert_ok(scenery != null and scenery.get_child_count() > 25, "Region has distinct 3D environment meshes")
		scenery_counts.append(scenery.get_child_count())
	_assert_ok(scenery_counts[0] != scenery_counts[1], "Fortress and frostland environments use different geometry")
	game.battlefield_3d.set_region(0)
	_assert_ok(game.battlefield_3d.region_scenery.get_child_count() == scenery_counts[0], "Switching regions rebuilds scenery without accumulation")
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
	var set_items: Array = [
		{"slot":"Оружие","set_id":1}, {"slot":"Тело","set_id":1}, {"slot":"Реликвия","set_id":1}
	]
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
	game.battlefield_3d.sync_board(game.pieces, -1, [], -1)
	_assert_ok(game.battlefield_3d.piece_nodes.size() > 0, "3D chess models rebuild with equipped cosmetic gear")
	game.battlefield_3d.set_boss_phase(2)
	_assert_ok(game.battlefield_3d.boss_enraged, "Boss enrage switches on cinematic 3D transformation")
	game.battlefield_3d.set_boss_phase(1)
	_assert_ok(not game.battlefield_3d.boss_enraged, "Boss enrage state resets correctly")
	game.battlefield_3d.attack(60, 52)
	_assert_ok(game.battlefield_3d.piece_nodes.has(60), "3D attack animation preserves board state")
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
	_assert_ok(damage_dealt == 26 and game.health[60] == 154, "Armor reduces actual chess-piece damage")
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
