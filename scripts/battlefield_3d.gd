extends Node3D
## Real-time 3D battlefield rendered into a SubViewport. Coordinates are shared with chess logic.
const TILE := 1.0
var piece_nodes: Dictionary = {}
var piece_types: Dictionary = {}
var health_fills: Dictionary = {}
var moving_nodes: Dictionary = {}
var clock := 0.0
var camera: Camera3D
var highlights: Array[MeshInstance3D] = []
var hazard_markers: Array[MeshInstance3D] = []
var king_warning: MeshInstance3D
var checked_king_square := -1
var poison_indicators: Dictionary = {}
var enemy_poison_indicators: Dictionary = {}
var active_hazards: Array[int] = []
var hazard_type := ""
var hazard_materials: Dictionary = {}
var tiles: Array[MeshInstance3D] = []
var tile_materials: Array[StandardMaterial3D] = []
# Visual-only chessboard palettes; ownership and selection UI are future work.
# These colors never affect rules, hitboxes, highlights or unit statistics.
const BOARD_STYLES: Array[Dictionary] = [
	{"name":"Королевский мрамор", "dark":"#28384b", "light":"#b7a58c", "edge":"#433246", "metal":"#e0bb74", "gem":"#6ecfcb"},
	{"name":"Ледяной дворец", "dark":"#31577b", "light":"#d4ecf0", "edge":"#243f62", "metal":"#9ad7ed", "gem":"#b0e8ff"},
	{"name":"Обсидиановый трон", "dark":"#30243c", "light":"#8d748d", "edge":"#251b31", "metal":"#b77ce0", "gem":"#e9a4ff"},
	{"name":"Изумрудный сад", "dark":"#2b5545", "light":"#c4d9b0", "edge":"#304535", "metal":"#d9bf70", "gem":"#84f0ac"}
]
var board_style_index := 0
var board_style_customized := false
var castle_levels: Dictionary = {"forge":0,"barracks":0,"treasury":0,"academy":0,"infirmary":0}
var board_edge_material: StandardMaterial3D
var board_inlay_material: StandardMaterial3D
var board_gem_material: StandardMaterial3D
var hero_material: StandardMaterial3D
var enemy_material: StandardMaterial3D
var gold_material: StandardMaterial3D
var dark_material: StandardMaterial3D
var board_root: Node3D
var region_scenery: Node3D
var animated_scenery: Array[MeshInstance3D] = []
var biome_landmark_motion: Array[Dictionary] = []
var torches: Array[OmniLight3D] = []
var world_environment: WorldEnvironment
var key_light: DirectionalLight3D
var rim_light: OmniLight3D
var torch_flames: Array[MeshInstance3D] = []
var board_gems: Array[MeshInstance3D] = []
var board_gem_halos: Array[MeshInstance3D] = []
var ambient_motes: Array[MeshInstance3D] = []
var ambient_mote_origins: Array[Vector3] = []
var current_region := -1
var mission_visual_variant: int = 0
var gear_signature := ""
var hero_gear: Dictionary = {}
var selected_hero_visual: Dictionary = {}
var selected_hero_signature := ""
var boss_crown: Material
var attack_effects: Array[Node3D] = []
var base_camera_position := Vector3(0, 11.8, 8.7)
var boss_enraged := false
var selection_material: StandardMaterial3D
var danger_material: StandardMaterial3D
# Low tier limits dynamic lights and costly shadows for Android GPUs.
var visual_quality := 1
var fx_enabled := true
# Geometry cache: instances retain independent transforms/materials, but identical
# primitive vertex buffers are shared across chess tiles, castle and combat art.
var primitive_mesh_cache: Dictionary = {}
# Reused VFX resources: avoid shader/material allocations on each attack.
var impact_materials: Dictionary = {}
var attack_trail_materials: Dictionary = {}
var biome_material_cache: Dictionary = {}
var gear_material_cache: Dictionary = {}
var equipment_scene_cache: Dictionary = {}
var castle_material_cache: Dictionary = {}
# Smooth biome lighting transitions without allocating materials or extra lights.
var region_light_target: Color = Color("#7c92b1")
var region_background_target: Color = Color("#0b1422")
var region_rim_target: Color = Color("#ff9b4a")
var region_light_transition := 0.0

func set_visual_quality(tier: int) -> void:
	visual_quality = clampi(tier, 0, 2)
	fx_enabled = visual_quality > 0
	if region_scenery != null:
		region_scenery.visible = visual_quality > 0
	if key_light != null:
		key_light.shadow_enabled = visual_quality >= 2
	for index in range(torches.size()):
		var light: OmniLight3D = torches[index]
		light.visible = visual_quality >= 2 or (visual_quality == 1 and index % 2 == 0)
		# Match decorative flame geometry to the light budget; invisible flames must not render.
		if index < torch_flames.size():
			torch_flames[index].visible = light.visible
	if rim_light != null:
		rim_light.visible = visual_quality > 0
	if piece_nodes.has(4):
		var boss_aura: Node3D = (piece_nodes[4] as Node3D).get_node_or_null("BossEnrageAura")
		if boss_aura != null: boss_aura.visible = boss_enraged and visual_quality > 0
	for halo in board_gem_halos:
		halo.visible = visual_quality >= 2
	for mote in ambient_motes:
		mote.visible = visual_quality >= 2
	for cell in piece_nodes.keys():
		var actor: Node3D = piece_nodes[cell]
		if not is_instance_valid(actor): continue
		var rarity_halo: Node3D = actor.find_child("HeroRarityHalo", true, false) as Node3D
		if rarity_halo != null: rarity_halo.visible = visual_quality > 0


var hero_model_cell: int = -1
var move_material: StandardMaterial3D

func _material(color: Color, metallic: float = 0.0, roughness: float = 0.42, emission: Color = Color.BLACK) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.metallic = metallic
	mat.roughness = roughness
	if emission != Color.BLACK:
		mat.emission_enabled = true
		mat.emission = emission
		mat.emission_energy_multiplier = 0.6
	return mat

func _box(size: Vector3, material: Material, parent: Node3D, at: Vector3) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	var cache_key: String = "box:%s" % str(size)
	if not primitive_mesh_cache.has(cache_key):
		var mesh := BoxMesh.new()
		mesh.size = size
		primitive_mesh_cache[cache_key] = mesh
	instance.mesh = primitive_mesh_cache[cache_key]
	instance.material_override = material
	instance.position = at
	parent.add_child(instance)
	return instance

func _cylinder(radius: float, height: float, material: Material, parent: Node3D, at: Vector3, top_radius: float = -1.0) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	var actual_top: float = radius if top_radius < 0.0 else top_radius
	var cache_key: String = "cyl:%s:%s:%s" % [str(radius), str(height), str(actual_top)]
	if not primitive_mesh_cache.has(cache_key):
		var mesh := CylinderMesh.new()
		mesh.bottom_radius = radius
		mesh.top_radius = actual_top
		mesh.height = height
		mesh.radial_segments = 16
		primitive_mesh_cache[cache_key] = mesh
	instance.mesh = primitive_mesh_cache[cache_key]
	instance.material_override = material
	instance.position = at
	parent.add_child(instance)
	return instance

func _sphere(radius: float, material: Material, parent: Node3D, at: Vector3) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	var cache_key: String = "sphere:%s" % str(radius)
	if not primitive_mesh_cache.has(cache_key):
		var mesh := SphereMesh.new()
		mesh.radius = radius
		mesh.height = radius * 2.0
		mesh.radial_segments = 12
		mesh.rings = 6
		primitive_mesh_cache[cache_key] = mesh
	instance.mesh = primitive_mesh_cache[cache_key]
	instance.material_override = material
	instance.position = at
	parent.add_child(instance)
	return instance

func _ring(major_radius: float, tube_radius: float, material: Material, parent: Node3D, at: Vector3) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	var cache_key: String = "ring:%s:%s" % [str(major_radius), str(tube_radius)]
	if not primitive_mesh_cache.has(cache_key):
		var mesh := TorusMesh.new()
		mesh.inner_radius = major_radius - tube_radius
		mesh.outer_radius = major_radius + tube_radius
		mesh.rings = 8
		mesh.ring_segments = 24
		primitive_mesh_cache[cache_key] = mesh
	instance.mesh = primitive_mesh_cache[cache_key]
	instance.material_override = material
	instance.position = at
	parent.add_child(instance)
	return instance

func set_board_visual_style(style_index: int) -> void:
	# -1 returns to the current biome palette; other choices persist across
	# biome changes and remain purely cosmetic.
	board_style_customized = style_index >= 0
	board_style_index = clampi(style_index, 0, BOARD_STYLES.size() - 1)
	if tile_materials.size() < 2: return
	if not board_style_customized:
		var region_palettes: Array = [
			[Color("#273a4c"), Color("#b7a58c")],
			[Color("#243e59"), Color("#92b7d0")],
			[Color("#183d42"), Color("#83ada7")],
			[Color("#39283f"), Color("#947b8e")],
			[Color("#28395e"), Color("#c4b6a2")],
			[Color("#2b182e"), Color("#78617e")]
		]
		var colors: Array = region_palettes[clampi(current_region, 0, 5)]
		tile_materials[0].albedo_color = colors[0]
		tile_materials[1].albedo_color = colors[1]
		return
	var palette: Dictionary = BOARD_STYLES[board_style_index]
	tile_materials[0].albedo_color = Color(str(palette["dark"]))
	tile_materials[1].albedo_color = Color(str(palette["light"]))
	if board_edge_material != null:
		board_edge_material.albedo_color = Color(str(palette["edge"]))
	if board_inlay_material != null:
		board_inlay_material.albedo_color = Color(str(palette["metal"]))
	if board_gem_material != null:
		board_gem_material.albedo_color = Color(str(palette["gem"]))

func _ready() -> void:
	hero_material = _material(Color("#d8e4f3"), 0.55)
	enemy_material = _material(Color("#57283e"), 0.45)
	gold_material = _material(Color("#d9ad57"), 0.78, 0.25)
	dark_material = _material(Color("#1a2638"), 0.4)
	boss_crown = _material(Color("#e56587"), 0.65, 0.22, Color("#9a193e"))
	selection_material = _material(Color("#f6c76b"), 0.2, 0.3, Color("#9d5732"))
	danger_material = _material(Color("#ed5c65"), 0.2, 0.3, Color("#9d5732"))
	move_material = _material(Color("#61d7b6"), 0.2, 0.3, Color("#9d5732"))
	hazard_materials = {"frost": _material(Color("#68d6ff"), 0.15, 0.24, Color("#2a8acb")), "poison": _material(Color("#a9e967"), 0.15, 0.24, Color("#5d9c2b")), "rift": _material(Color("#d78aff"), 0.15, 0.24, Color("#903bd2")), "boss": _material(Color("#ff6c77"), 0.18, 0.22, Color("#cf3346"))}
	var world := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("#0b1422")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#7c92b1")
	env.ambient_light_energy = 0.6
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	world.environment = env
	world_environment = world
	add_child(world)
	board_root = Node3D.new()
	add_child(board_root)
	region_scenery = Node3D.new()
	region_scenery.name = "RegionScenery"
	board_root.add_child(region_scenery)
	_box(Vector3(9.2, 0.48, 9.2), _material(Color("#29202a"), 0.45), board_root, Vector3(0, -0.43, 0))
	_box(Vector3(8.6, 0.13, 8.6), gold_material, board_root, Vector3(0, -0.13, 0))
	tile_materials = [_material(Color("#28384b"), 0.22), _material(Color("#b7a58c"), 0.22)]
	# A sculpted chessboard frame and coordinate markers make the 3D RPG
	# arena immediately recognizable as chess, even without the HUD.
	var edge_wood: StandardMaterial3D = _material(Color("#433246"), 0.18, 0.32)
	board_edge_material = edge_wood
	var inlay: StandardMaterial3D = _material(Color("#e0bb74"), 0.72, 0.22)
	board_inlay_material = inlay
	for side in [-1, 1]:
		_box(Vector3(9.1, 0.16, 0.18), edge_wood, board_root, Vector3(0, -0.035, float(side) * 4.13))
		_box(Vector3(0.18, 0.16, 9.1), edge_wood, board_root, Vector3(float(side) * 4.13, -0.035, 0))
		_box(Vector3(8.3, 0.035, 0.025), inlay, board_root, Vector3(0, 0.049, float(side) * 4.075))
		_box(Vector3(0.025, 0.035, 8.3), inlay, board_root, Vector3(float(side) * 4.075, 0.049, 0))
	# Bronze studs and sculpted crests sit outside the 8x8 play area.
	var trim_bronze: StandardMaterial3D = _material(Color("#a77d4d"), 0.75, 0.24)
	var trim_shadow: StandardMaterial3D = _material(Color("#2b2431"), 0.35, 0.55)
	for side in [-1, 1]:
		for offset in [-3.4, -2.4, -1.4, -0.4, 0.4, 1.4, 2.4, 3.4]:
			var stud_z: MeshInstance3D = _sphere(0.048, trim_bronze, board_root, Vector3(offset, 0.052, float(side) * 4.14))
			stud_z.scale = Vector3(1.0, 0.55, 1.0)
			var stud_x: MeshInstance3D = _sphere(0.048, trim_bronze, board_root, Vector3(float(side) * 4.14, 0.052, offset))
			stud_x.scale = Vector3(1.0, 0.55, 1.0)
	for side_x in [-1, 1]:
		for side_z in [-1, 1]:
			var crest: Node3D = Node3D.new()
			crest.position = Vector3(float(side_x) * 4.29, -0.01, float(side_z) * 4.29)
			board_root.add_child(crest)
			_cylinder(0.22, 0.075, trim_shadow, crest, Vector3.ZERO)
			_cylinder(0.16, 0.09, trim_bronze, crest, Vector3(0, 0.052, 0), 0.11)
			_sphere(0.075, trim_bronze, crest, Vector3(0, 0.12, 0))
	# Two-tone inset rails: low-poly, shared meshes and zero additional lights.
	var filigree_dark: StandardMaterial3D = _material(Color("#312b38"), 0.48, 0.38)
	for side in [-1, 1]:
		_box(Vector3(7.55, 0.025, 0.042), filigree_dark, board_root, Vector3(0, 0.057, float(side) * 4.02))
		_box(Vector3(0.042, 0.025, 7.55), filigree_dark, board_root, Vector3(float(side) * 4.02, 0.057, 0))
	# Eight heraldic corner plates give the frame depth without overlapping tiles.
	for side_x in [-1, 1]:
		for side_z in [-1, 1]:
			for step in [0, 1]:
				var ornament: MeshInstance3D = _box(Vector3(0.23, 0.055, 0.075), trim_bronze, board_root, Vector3(float(side_x) * (4.28 + float(step) * 0.12), 0.085, float(side_z) * 4.28))
				ornament.rotation.y = float(side_z) * 0.785398
	# Four carved corner plinths with gem insets, outside the playable
	# squares. Keep them static and under the mobile light budget.
	var corner_stone: StandardMaterial3D = _material(Color("#625168"), 0.28, 0.47)
	var corner_gem: StandardMaterial3D = _material(Color("#6ecfcb"), 0.22, 0.24, Color("#327d9b"))
	board_gem_material = corner_gem
	for corner_x in [-1, 1]:
		for corner_z in [-1, 1]:
			var corner_at := Vector3(float(corner_x) * 4.25, -0.04, float(corner_z) * 4.25)
			var pedestal: MeshInstance3D = _cylinder(0.21, 0.22, corner_stone, board_root, corner_at, 0.14)
			pedestal.name = "BoardCornerPlinth_%d_%d" % [corner_x, corner_z]
			_box(Vector3(0.33, 0.055, 0.33), inlay, board_root, corner_at + Vector3(0, 0.13, 0))
			var gem: MeshInstance3D = _sphere(0.085, corner_gem, board_root, corner_at + Vector3(0, 0.22, 0))
			gem.name = "BoardCornerGem_%d_%d" % [corner_x, corner_z]
			gem.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			board_gems.append(gem)
			# High-quality-only emissive rings add animated arcane detail
			# without spawning four additional dynamic lights.
			var halo: MeshInstance3D = _ring(0.14, 0.018, corner_gem, board_root, corner_at + Vector3(0, 0.22, 0))
			halo.name = "BoardGemHalo_%d_%d" % [corner_x, corner_z]
			halo.rotation.x = PI * 0.5
			halo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			halo.visible = false
			board_gem_halos.append(halo)
	for index in range(8):
		var coordinate: String = "ABCDEFGH".substr(index, 1)
		var rank_text: String = str(8 - index)
		for side in [-1, 1]:
			var file_label := Label3D.new()
			file_label.name = "FileCoordinate_%s_%d" % [coordinate, side]
			file_label.text = coordinate
			file_label.font_size = 24
			file_label.pixel_size = 0.0035
			file_label.modulate = Color("#f4dca8")
			file_label.position = Vector3(float(index) - 3.5, 0.075, float(side) * 4.26)
			file_label.rotation_degrees = Vector3(-90, 0, 0)
			file_label.no_depth_test = false
			board_root.add_child(file_label)
			var rank_label := Label3D.new()
			rank_label.name = "RankCoordinate_%s_%d" % [rank_text, side]
			rank_label.text = rank_text
			rank_label.font_size = 24
			rank_label.pixel_size = 0.0035
			rank_label.modulate = Color("#f4dca8")
			rank_label.position = Vector3(float(side) * 4.26, 0.075, float(index) - 3.5)
			rank_label.rotation_degrees = Vector3(-90, 0, 0)
			rank_label.no_depth_test = false
			board_root.add_child(rank_label)
	# Reuse a single highlight material instead of allocating 64 identical PBR materials.
	var highlight_material: StandardMaterial3D = _material(Color("#63e4bc"), 0.15, 0.4, Color("#4dd5a9"))
	for i in range(64):
		var x := float(i % 8) - 3.5
		var z := float(i / 8) - 3.5
		var tile_mat: StandardMaterial3D = tile_materials[(int(i / 8) + i % 8) % 2]
		tiles.append(_box(Vector3(0.985, 0.10, 0.985), tile_mat, board_root, Vector3(x, 0, z)))
		var marker := _cylinder(0.43, 0.025, highlight_material, board_root, Vector3(x, 0.078, z))
		marker.visible = false
		highlights.append(marker)
		var hazard_marker := _cylinder(0.47, 0.017, hazard_materials["frost"], board_root, Vector3(x, 0.096, z))
		hazard_marker.visible = false
		hazard_marker.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		hazard_markers.append(hazard_marker)
	# Separate elevated crown warning: does not hide movement or hazard markers.
	king_warning = _ring(0.48, 0.055, danger_material, board_root, Vector3.ZERO)
	king_warning.name = "KingCheckWarning"
	king_warning.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	king_warning.visible = false
	for x in [-4.45, 4.45]:
		for z in [-4.45, 4.45]:
			_cylinder(0.24, 0.18, dark_material, board_root, Vector3(x, -0.12, z))
			_cylinder(0.17, 1.25, _material(Color("#56515c"), 0.3), board_root, Vector3(x, 0.50, z))
			_cylinder(0.29, 0.13, gold_material, board_root, Vector3(x, 1.13, z))
			var flame := _sphere(0.17, _material(Color("#ffb448"), 0.0, 0.2, Color("#ff681c")), board_root, Vector3(x, 1.40, z))
			# Emissive decorative fire does not need to cast four dynamic shadows.
			flame.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			torch_flames.append(flame)
			var firelight := OmniLight3D.new()
			firelight.position = Vector3(x, 1.5, z)
			firelight.light_color = Color("#ff9b4a")
			firelight.light_energy = 1.2
			firelight.omni_range = 3.8
			add_child(firelight)
			torches.append(firelight)
	for n in range(18):
		var angle := float(n) * TAU / 18.0
		var radius := 6.4 + float(n % 3) * 0.65
		var x := cos(angle) * radius
		var z := sin(angle) * radius
		var height := 1.4 + float(n % 5) * 0.38
		_cylinder(0.43, height, _material(Color("#2b3344") if n % 2 == 0 else Color("#3d3948"), 0.12), board_root, Vector3(x, height * 0.5 - 0.65, z), 0.35)
		_box(Vector3(0.98, 0.23, 0.98), dark_material, board_root, Vector3(x, height - 0.45, z))
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-55, -28, 0)
	key.light_color = Color("#ffe2b7")
	key.light_energy = 1.5
	key.shadow_enabled = false # Medium mobile default; high quality enables shadows.
	add_child(key)
	key_light = key
	var rim := OmniLight3D.new()
	rim.position = Vector3(-3, 5, -3)
	rim.light_color = Color("#729bff")
	rim.light_energy = 1.6
	rim.omni_range = 16.0
	add_child(rim)
	rim_light = rim
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 12.7
	camera.position = base_camera_position
	add_child(camera)
	camera.look_at(Vector3(0, 0, 0))
	camera.current = true
	set_visual_quality(1)

func _square_position(index: int) -> Vector3:
	return Vector3(float(index % 8) - 3.5, 0.11, float(index / 8) - 3.5)

func set_hero_gear(items: Array, slots: Dictionary) -> void:
	var signature := ""
	var next_gear: Dictionary = {}
	for slot in ["Оружие", "Тело", "Реликвия"]:
		var index: int = int(slots.get(slot, -1))
		if index >= 0 and index < items.size():
			var item: Dictionary = items[index]
			next_gear[slot] = item
			signature += "%s:%d:%d:%d|" % [slot, int(item.get("rarity", 0)), int(item.get("upgrade", 0)), int(item.get("set_id", -1))]
	if signature == gear_signature: return
	gear_signature = signature
	hero_gear = next_gear
	# Rebuild only the bearer of the selected hero's equipment.
	# Do not destroy every chess piece (or interrupt in-flight movement)
	# when the player changes one equipment slot.
	if hero_model_cell >= 0 and piece_nodes.has(hero_model_cell) and not moving_nodes.has(hero_model_cell):
		piece_types[hero_model_cell] = ""

func _gear_material(slot: String) -> Material:
	if not hero_gear.has(slot): return gold_material
	var item: Dictionary = hero_gear[slot]
	var rarity: int = clampi(int(item.get("rarity", 0)), 0, 6)
	var upgrade: int = maxi(0, int(item.get("upgrade", 0)))
	var key: String = "%s:%d:%d" % [slot, rarity, upgrade]
	if not gear_material_cache.has(key):
		var palette: Array = [Color("#b9c6d5"), Color("#62c7b6"), Color("#548dea"), Color("#aa78f5"), Color("#efac57"), Color("#e96d86"), Color("#fff0a4")]
		gear_material_cache[key] = _material(palette[rarity], 0.82, 0.23, palette[rarity] * (0.18 + float(upgrade) * 0.04))
	return gear_material_cache[key]

func _get_equipment_scene(path: String) -> PackedScene:
	if equipment_scene_cache.has(path):
		return equipment_scene_cache[path] as PackedScene
	if not ResourceLoader.exists(path):
		return null
	var scene: Resource = load(path)
	if scene is PackedScene:
		equipment_scene_cache[path] = scene
		return scene as PackedScene
	return null

# Physical rarity marks are deliberately countable at mobile scale; the seven tiers
# have distinct silhouettes, not only different shader colors.
func _has_modular_equipment(slot: String) -> bool:
	if not hero_gear.has(slot): return false
	var key: String = str({"Оружие":"weapon", "Тело":"armor", "Реликвия":"relic"}.get(slot, ""))
	if key == "": return false
	var tier: int = clampi(int(hero_gear[slot].get("rarity", 0)), 0, 6)
	return ResourceLoader.exists("res://assets/equipment/%s_tier_%d.glb" % [key, tier])

func _add_equipment_geometry(slot: String, parent: Node3D) -> void:
	if not hero_gear.has(slot): return
	var tier: int = clampi(int(hero_gear[slot].get("rarity", 0)), 0, 6)
	# Imported modular equipment replaces procedural geometry when generated
	# GLBs exist. Socket transforms keep weapon, armor and relic independent.
	var slot_key: String = str({"Оружие":"weapon", "Тело":"armor", "Реликвия":"relic"}.get(slot, ""))
	if slot_key != "":
		var gear_path: String = "res://assets/equipment/%s_tier_%d.glb" % [slot_key, tier]
		var gear_scene: PackedScene = _get_equipment_scene(gear_path)
		if gear_scene != null:
			var gear_model: Node = gear_scene.instantiate()
			if gear_model is Node3D:
				var socket := Node3D.new()
				socket.name = "GearSocket_" + slot_key
				var attachment_parent: Node3D = parent
				# Follow imported shoulder pivots so held items actually
				# animate with the arms, not remain floating beside them.
				var character: Node = parent.get_node_or_null("AuthoredCharacter")
				if character != null:
					if slot_key == "armor":
						# Weighted torso flexes at SpineChest; attach chest
						# armor to that imported bone when Godot exposes it.
						var chest_bone_found: bool = false
						for candidate in character.find_children("*", "Skeleton3D", true, false):
							var skeleton: Skeleton3D = candidate as Skeleton3D
							if skeleton.find_bone("SpineChest") >= 0:
								var chest_attachment := BoneAttachment3D.new()
								chest_attachment.name = "BoneSocket_SpineChest"
								chest_attachment.bone_name = "SpineChest"
								skeleton.add_child(chest_attachment)
								attachment_parent = chest_attachment
								chest_bone_found = true
								break
						if not chest_bone_found:
							var torso: Node = character.find_child("BodyRig", true, false)
							if torso is Node3D:
								attachment_parent = torso as Node3D
					else:
						var joint_name: String = "Arm1" if slot_key == "weapon" else "Arm-1"
						var joint: Node = character.find_child(joint_name, true, false)
						if joint is Node3D:
							attachment_parent = joint as Node3D
						else:
							# Godot imports skinned glTF joints as Skeleton3D
							# bones, not necessarily named Node3D pivots.
							# A BoneAttachment3D follows the animated bone.
							for candidate in character.find_children("*", "Skeleton3D", true, false):
								var skeleton: Skeleton3D = candidate as Skeleton3D
								if skeleton.find_bone(joint_name) >= 0:
									var bone_socket := BoneAttachment3D.new()
									bone_socket.name = "BoneSocket_" + joint_name
									bone_socket.bone_name = joint_name
									skeleton.add_child(bone_socket)
									attachment_parent = bone_socket
									break
				match slot_key:
					"weapon":
						socket.position = Vector3(0.13, -0.19, -0.08) if attachment_parent != parent else Vector3(0.43, 0.87, -0.08)
						socket.scale = Vector3.ONE * 0.64
					"armor":
						socket.position = Vector3(0, -0.18, -0.08) if attachment_parent is BoneAttachment3D else Vector3(0, 0.83, -0.08)
						socket.scale = Vector3.ONE * 0.95
					"relic":
						socket.position = Vector3(-0.27, -0.17, -0.16) if attachment_parent != parent else Vector3(-0.39, 0.89, -0.16)
						socket.scale = Vector3.ONE * 0.72
				attachment_parent.add_child(socket)
				socket.add_child(gear_model)
				# Preserve the stable rarity marker used by UI/tests and
				# provide an attachment point for additional tier VFX.
				var rarity_marker := Node3D.new()
				rarity_marker.name = "Rarity_" + slot
				socket.add_child(rarity_marker)
				# High-rarity gear gains subtle, socket-bound magic rings.
				# Quality level controls count; no lights or per-frame particles.
				if tier >= 4 and fx_enabled and visual_quality > 0:
					var glow: StandardMaterial3D = _gear_material(slot)
					var ring_count: int = mini(tier - 3, visual_quality)
					for effect_index in range(ring_count):
						var halo: MeshInstance3D = _ring(0.18 + effect_index * 0.085, 0.012, glow, socket, Vector3(0, 0.19 + effect_index * 0.08, 0))
						halo.name = "EnchantmentHalo_%d" % effect_index
						halo.rotation.x = PI * 0.5
						halo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				return
			gear_model.free()
	var mat: Material = _gear_material(slot)
	match slot:
		"Оружие":
			# Seven progressive silhouettes: blade, axe, polearm, twin-prong,
			# radiant glaive, runic staff, and six-wing sovereign weapon.
			match tier:
				0:
					_box(Vector3(0.075, 0.46, 0.06), mat, parent, Vector3(0.43, 0.89, -0.08))
				1:
					_box(Vector3(0.26, 0.24, 0.08), mat, parent, Vector3(0.43, 1.00, -0.08))
				2:
					_cylinder(0.045, 0.92, mat, parent, Vector3(0.43, 0.88, -0.08), 0.012)
				3:
					for side in [-1.0, 1.0]:
						_box(Vector3(0.08, 0.48, 0.07), mat, parent, Vector3(0.43 + side * 0.10, 0.96, -0.08))
				4:
					var wing := _box(Vector3(0.38, 0.13, 0.07), mat, parent, Vector3(0.43, 1.13, -0.08))
					wing.rotation.z = 0.38
					_sphere(0.08, mat, parent, Vector3(0.43, 1.26, -0.08))
				5:
					_cylinder(0.07, 0.87, mat, parent, Vector3(0.43, 0.86, -0.08), 0.015)
					_sphere(0.17, mat, parent, Vector3(0.43, 1.34, -0.08))
				6:
					for i in range(6):
						var angle: float = TAU * float(i) / 6.0
						var wing := _box(Vector3(0.065, 0.34, 0.09), mat, parent, Vector3(0.43 + cos(angle) * 0.16, 1.14 + sin(angle) * 0.16, -0.08))
						wing.rotation.z = -angle
			# Countable in-world rank studs make all seven weapon tiers distinct.
			for stud in range(tier):
				_sphere(0.023, mat, parent, Vector3(0.30 + float(stud) * 0.043, 0.66, -0.16))
		"Тело":
			# Each tier changes breastplate shape and shoulder profile.
			var width: float = 0.34 + float(tier) * 0.028
			_box(Vector3(width, 0.34, 0.12), mat, parent, Vector3(0, 0.80, -0.19))
			for side in [-1.0, 1.0]:
				var shoulder := _box(Vector3(0.17 + tier * 0.022, 0.12 + tier * 0.028, 0.25), mat, parent, Vector3(side * 0.29, 1.00, -0.04))
				shoulder.rotation.z = side * float(tier) * 0.06
			for i in range(tier):
				_box(Vector3(0.06, 0.05, 0.05), mat, parent, Vector3(-0.16 + i * 0.055, 0.75, -0.26))
		"Реликвия":
			# Seven increasingly elaborate physical amulets.
			_sphere(0.09 + float(tier) * 0.014, mat, parent, Vector3(-0.39, 0.89, -0.16))
			for i in range(tier + 1):
				var angle: float = TAU * float(i) / float(tier + 1)
				var bead := _sphere(0.028 + tier * 0.004, mat, parent, Vector3(-0.39 + cos(angle) * 0.17, 0.89 + sin(angle) * 0.17, -0.16))
				bead.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func _add_rarity_insignia(slot: String, parent: Node3D, at: Vector3) -> void:
	if not hero_gear.has(slot): return
	var rarity: int = clampi(int(hero_gear[slot].get("rarity", 0)), 0, 6)
	var crest := Node3D.new()
	crest.name = "Rarity_" + slot
	crest.position = at
	parent.add_child(crest)
	var mat: Material = _gear_material(slot)
	# Tier zero has a single plain rivet; each higher tier adds a raised gem.
	_sphere(0.055, mat, crest, Vector3.ZERO)
	for n in range(rarity):
		var angle: float = TAU * float(n) / float(maxi(rarity, 1))
		var gem := _sphere(0.038, mat, crest, Vector3(cos(angle) * 0.13, 0.045, sin(angle) * 0.13))
		gem.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

const CHARACTER_SCENE_PATHS := {
	"P": "res://assets/characters/pawn.glb",
	"R": "res://assets/characters/rook.glb",
	"N": "res://assets/characters/knight.glb",
	"B": "res://assets/characters/bishop.glb",
	"Q": "res://assets/characters/queen.glb",
	"K": "res://assets/characters/king.glb"
}

func _load_authored_character(kind: String, parent: Node3D) -> bool:
	# Original generated GLB blockouts are available when the art pipeline ran.
	# Authored hero-ID meshes supersede the six class-only legacy placeholders.
	var path: String = str(CHARACTER_SCENE_PATHS.get(kind, ""))
	if not bool(parent.get_meta("hero", true)):
		if bool(parent.get_meta("boss", false)):
			path = "res://assets/characters/boss_region_%d.glb" % clampi(current_region, 0, 5)
		else:
			path = "res://assets/characters/enemy_%s_region_%d.glb" % [kind.to_lower(), clampi(current_region, 0, 5)]
	elif bool(parent.get_meta("hero", false)) and bool(parent.get_meta("selected_hero_piece", false)) and not selected_hero_visual.is_empty() and str(selected_hero_visual.get("piece", "")) == kind:
		var hero_id: String = str(selected_hero_visual.get("id", ""))
		if hero_id.is_valid_filename() and hero_id.begins_with("hero_"):
			path = "res://assets/characters/%s.glb" % hero_id
	if path != "" and ResourceLoader.exists(path):
		var scene: Resource = load(path)
		if scene is PackedScene:
			var model: Node = (scene as PackedScene).instantiate()
			if model is Node3D:
				model.name = "AuthoredCharacter"
				parent.add_child(model)
				# Start a looping idle clip when the imported asset supplies one.
				# Use the model itself as the rig's direct authored child.
				var player: AnimationPlayer = model.find_child("AnimationPlayer", true, false) as AnimationPlayer
				if player != null:
					var idle_name := ""
					if player.has_animation("idle"):
						idle_name = "idle"
					else:
						for library_name in player.get_animation_library_list():
							var library: AnimationLibrary = player.get_animation_library(library_name)
							if library != null and library.has_animation("idle"):
								idle_name = "idle" if library_name == "" else library_name + "/idle"
								break
					if idle_name != "":
						var idle_animation: Animation = player.get_animation(idle_name)
						if idle_animation != null:
							idle_animation.loop_mode = Animation.LOOP_LINEAR
						player.play(idle_name)
						# Return to idle after one-shot hit, move, attack or cast.
						# Signal is emitted by AnimationPlayer on clip completion.
						player.animation_finished.connect(func(finished: StringName) -> void:
							if not is_instance_valid(player) or not is_instance_valid(model):
								return
							# Death is terminal. Never restart idle on a defeated
							# character while its disappearance tween is running.
							if str(finished) == "death" or str(finished).ends_with("/death"):
								return
							if str(finished) != idle_name and player.has_animation(idle_name):
								player.play(idle_name)
						)
				return true
			model.free()
	# An original static OBJ remains the art fallback if no GLB is available.
	var obj_path: String = "res://assets/characters/%s.obj" % str({"P":"pawn","R":"rook","N":"knight","B":"bishop","Q":"queen","K":"king"}.get(kind, ""))
	if not ResourceLoader.exists(obj_path): return false
	var mesh_resource: Resource = load(obj_path)
	if not (mesh_resource is Mesh): return false
	var instance := MeshInstance3D.new()
	instance.name = "AuthoredCharacter"
	instance.mesh = mesh_resource as Mesh
	instance.material_override = hero_material if bool(parent.get_meta("hero", true)) else enemy_material
	parent.add_child(instance)
	return true

func _add_character_surface_detail(kind: String, white: bool, parent: Node3D) -> void:
	# Low-poly OBJ art gains a legible, class-specific layered metal costume.
	# Details are children of VisualRig and participate in all character animations.
	var armor := _material(Color("#b5c6d4") if white else Color("#704d64"), 0.78, 0.29)
	var edge := _material(Color("#f3d58b") if white else Color("#c85679"), 0.83, 0.22)
	var gem := _material(Color("#63d8f3") if white else Color("#f15a99"), 0.22, 0.20, Color("#2289c0") if white else Color("#a91f57"))
	match kind:
		"P":
			_ring(0.20, 0.028, armor, parent, Vector3(0, 0.44, 0))
			_sphere(0.075, gem, parent, Vector3(0, 0.68, -0.13))
		"R":
			for side in [-1.0, 1.0]:
				_box(Vector3(0.10, 0.36, 0.16), armor, parent, Vector3(side * 0.23, 0.67, 0))
			_ring(0.21, 0.035, edge, parent, Vector3(0, 0.94, 0))
		"N":
			_box(Vector3(0.34, 0.18, 0.15), armor, parent, Vector3(0, 0.66, 0.14))
			_sphere(0.065, gem, parent, Vector3(0, 0.98, -0.30))
		"B":
			_ring(0.18, 0.026, edge, parent, Vector3(0, 0.79, 0))
			_sphere(0.09, gem, parent, Vector3(0, 1.11, -0.04))
		"Q":
			for n in range(5):
				var angle := float(n) * TAU / 5.0
				_sphere(0.058, gem, parent, Vector3(cos(angle) * 0.23, 1.12, sin(angle) * 0.23))
			_ring(0.23, 0.027, edge, parent, Vector3(0, 0.98, 0))
		"K":
			_ring(0.23, 0.038, edge, parent, Vector3(0, 1.09, 0))
			_sphere(0.08, gem, parent, Vector3(0, 1.38, -0.06))

func set_selected_hero_visual(hero: Dictionary) -> void:
	var next_signature: String = str(hero.get("id", ""))
	if selected_hero_signature == next_signature: return
	selected_hero_signature = next_signature
	selected_hero_visual = hero.duplicate(true)
	hero_model_cell = -1
	# Refresh only the previous hero bearer. The next sync chooses a new
	# eligible bearer without destroying every unit of the same class.
	for cell in piece_nodes.keys():
		var bearer: Node3D = piece_nodes[cell]
		if bool(bearer.get_meta("selected_hero_piece", false)):
			piece_types[cell] = ""

func _add_hero_signature_costume(hero_number: int, rarity: int, parent: Node3D, mat: Material) -> void:
	# Thirty deterministic costume combinations: five major silhouettes times six
	# individually shaped signature crests, with tier-dependent physical ornament.
	# This is procedural in-game geometry, not a substitute for authored rigged GLBs.
	var family: int = (hero_number - 1) % 5
	var signature: int = int((hero_number - 1) / 5)
	match family:
		0: # Royal herald: layered mantle and angular epaulettes.
			_box(Vector3(0.53, 0.55, 0.12), mat, parent, Vector3(0, 0.77, 0.23))
			for side in [-1.0, 1.0]:
				var plate := _box(Vector3(0.23, 0.13, 0.30), mat, parent, Vector3(side * 0.29, 1.02, 0))
				plate.rotation.z = side * 0.23
		1: # Raider: asymmetrical shoulder guard and serrated waist skirt.
			_box(Vector3(0.32, 0.21, 0.33), mat, parent, Vector3(-0.28, 0.97, 0))
			for i in range(4):
				var flap := _box(Vector3(0.10, 0.29, 0.09), mat, parent, Vector3(-0.18 + i * 0.12, 0.46, -0.14))
				flap.rotation.z = (float(i) - 1.5) * 0.16
		2: # Ranger: swept-back hood, quiver and travel cloak.
			var hood := _cylinder(0.22, 0.20, mat, parent, Vector3(0, 1.41, 0), 0.075)
			hood.rotation.x = -0.12
			_box(Vector3(0.38, 0.56, 0.10), mat, parent, Vector3(0, 0.80, 0.20))
			for i in range(3):
				_cylinder(0.022, 0.45, mat, parent, Vector3(-0.28 + float(i) * 0.06, 1.05, 0.21))
		3: # Forge sentinel: heavy plated breast and reinforced knee guards.
			_box(Vector3(0.46, 0.40, 0.34), mat, parent, Vector3(0, 0.82, -0.015))
			for side in [-1.0, 1.0]:
				_box(Vector3(0.20, 0.20, 0.23), mat, parent, Vector3(side * 0.14, 0.43, -0.08))
		4: # Arcane sage: layered robe, floating focus and high collar.
			_cylinder(0.33, 0.43, mat, parent, Vector3(0, 0.53, 0), 0.19)
			_ring(0.25, 0.035, mat, parent, Vector3(0, 1.04, 0))
			_sphere(0.10, mat, parent, Vector3(-0.38, 1.05, -0.12))
	# Signature 0-5 changes the head outline, never only the palette.
	match signature:
		0:
			_cylinder(0.22, 0.13, mat, parent, Vector3(0, 1.43, 0))
		1:
			for side in [-1.0, 1.0]:
				var antler := _cylinder(0.038, 0.34, mat, parent, Vector3(side * 0.19, 1.52, 0), 0.006)
				antler.rotation.z = side * 0.28
		2:
			_cylinder(0.18, 0.42, mat, parent, Vector3(0, 1.51, 0), 0.015)
		3:
			for i in range(3):
				var blade := _box(Vector3(0.065, 0.25 + float(i % 2) * 0.15, 0.09), mat, parent, Vector3((float(i) - 1.0) * 0.14, 1.49, 0))
				blade.rotation.z = (float(i) - 1.0) * 0.13
		4:
			_ring(0.23, 0.04, mat, parent, Vector3(0, 1.46, 0))
			_sphere(0.08, mat, parent, Vector3(0, 1.59, 0))
		5:
			_box(Vector3(0.40, 0.14, 0.20), mat, parent, Vector3(0, 1.38, -0.06))
			_cylinder(0.045, 0.31, mat, parent, Vector3(0, 1.56, 0), 0.01)
	# High-rarity hero costumes earn extra visible metalwork.
	for i in range(rarity):
		var angle: float = TAU * float(i) / float(maxi(1, rarity))
		_sphere(0.037, mat, parent, Vector3(cos(angle) * 0.26, 0.86, sin(angle) * 0.26))

func _add_selected_hero_identity(kind: String, parent: Node3D) -> void:
	if selected_hero_visual.is_empty() or str(selected_hero_visual.get("piece", "")) != kind: return
	var identifier: String = str(selected_hero_visual.get("id", "hero_01"))
	var number: int = clampi(int(identifier.trim_prefix("hero_")), 1, 30)
	var rarity: int = clampi(int(selected_hero_visual.get("rarity", 0)), 0, 6)
	var hue: float = fmod(float(number * 47), 360.0) / 360.0
	var base: Color = Color.from_hsv(hue, 0.58, 0.88)
	var crest_mat: StandardMaterial3D = _material(base, 0.68, 0.22, base.darkened(0.48))
	var emblem := Node3D.new()
	emblem.name = "HeroIdentity_%02d" % number
	parent.add_child(emblem)
	# Keep a lightweight identity marker for UI/tests. The imported hero GLB
	# already contains the actual costume and class heraldry, so the full
	# procedural outfit is needed only by the OBJ/procedural fallback.
	var authored_model: Node = parent.get_node_or_null("AuthoredCharacter")
	if authored_model == null or not (authored_model is Node3D):
		_add_hero_signature_costume(number, rarity, emblem, crest_mat)
	# A distinct silhouette, hue and insignia for each roster identity.
	var spikes: int = 2 + (number % 5)
	for i in range(spikes):
		var angle: float = TAU * float(i) / float(spikes)
		var stone := _box(Vector3(0.065, 0.14 + 0.035 * float(rarity), 0.07), crest_mat, emblem, Vector3(cos(angle) * 0.25, 1.26, sin(angle) * 0.25))
		stone.rotation.y = angle
	_sphere(0.095 + float(rarity) * 0.008, crest_mat, emblem, Vector3(0, 1.31, -0.16))
	if rarity >= 3:
		var halo := _ring(0.28, 0.02, crest_mat, emblem, Vector3(0, 1.14, 0))
		halo.name = "HeroRarityHalo"
		halo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		halo.visible = visual_quality > 0
	emblem.set_meta("hero_id", identifier)

func _add_humanoid_costume(kind: String, white: bool, parent: Node3D) -> void:
	# Mobile-friendly layered armor and weapons. Class silhouettes remain legible
	# at the portrait camera's distance; authored GLB meshes still take priority.
	var steel: Material = _material(Color("#b6c5d2") if white else Color("#75667d"), 0.7, 0.29)
	var cloth: Material = _material(Color("#246e8a") if white else Color("#6e304f"), 0.15, 0.74)
	var trim: Material = gold_material if white else boss_crown
	var skin: Material = _material(Color("#d9a47e") if white else Color("#a87b83"), 0.0, 0.79)
	# Legs, boots, torso, articulated arms and a face give a recognizable
	# humanoid silhouette instead of the earlier abstract chess totem.
	for side in [-1.0, 1.0]:
		var suffix: String = "L" if side < 0.0 else "R"
		var leg_pivot := Node3D.new()
		leg_pivot.name = "Leg_" + suffix
		leg_pivot.position = Vector3(side * 0.115, 0.60, 0)
		parent.add_child(leg_pivot)
		_cylinder(0.072, 0.34, steel, leg_pivot, Vector3(0, -0.17, 0), 0.085)
		_box(Vector3(0.16, 0.12, 0.22), trim, leg_pivot, Vector3(0, -0.31, -0.055))
		var arm_pivot := Node3D.new()
		arm_pivot.name = "Arm_" + suffix
		arm_pivot.position = Vector3(side * 0.255, 0.93, 0)
		parent.add_child(arm_pivot)
		var shoulder := _sphere(0.125, steel, arm_pivot, Vector3.ZERO)
		shoulder.scale = Vector3(1.0, 0.76, 1.12)
		var arm := _cylinder(0.065, 0.38, cloth, arm_pivot, Vector3(side * 0.04, -0.21, 0))
		arm.rotation.z = side * 0.17
		_sphere(0.065, skin, arm_pivot, Vector3(side * 0.065, -0.41, -0.025))
	_cylinder(0.21, 0.51, cloth, parent, Vector3(0, 0.75, 0), 0.17)
	_box(Vector3(0.36, 0.16, 0.28), steel, parent, Vector3(0, 0.93, 0))
	_box(Vector3(0.28, 0.05, 0.06), trim, parent, Vector3(0, 0.72, -0.175))
	_cylinder(0.065, 0.13, skin, parent, Vector3(0, 1.075, 0))
	_sphere(0.16, skin, parent, Vector3(0, 1.24, 0))
	# Eyes and class-specific headwear distinguish the front of each character.
	for side in [-1.0, 1.0]:
		_sphere(0.024, dark_material, parent, Vector3(side * 0.065, 1.26, -0.144))
	match kind:
		"P": # Scout: hood, short dagger and travel satchel.
			_cylinder(0.19, 0.19, cloth, parent, Vector3(0, 1.37, 0), 0.09)
			_box(Vector3(0.17, 0.22, 0.11), trim, parent, Vector3(-0.27, 0.68, 0.12))
			_box(Vector3(0.045, 0.32, 0.065), steel, parent, Vector3(0.35, 0.48, -0.06))
		"R": # Guardian: tower shield and heavy crown helm.
			_box(Vector3(0.35, 0.59, 0.10), steel, parent, Vector3(-0.39, 0.76, -0.12))
			_box(Vector3(0.08, 0.40, 0.13), trim, parent, Vector3(-0.39, 0.76, -0.19))
			_cylinder(0.20, 0.18, steel, parent, Vector3(0, 1.37, 0))
		"N": # Knight: crested visor and a long sword.
			_box(Vector3(0.32, 0.11, 0.12), steel, parent, Vector3(0, 1.27, -0.13))
			_cylinder(0.045, 0.32, trim, parent, Vector3(0, 1.50, 0), 0.005)
			_box(Vector3(0.07, 0.63, 0.055), steel, parent, Vector3(0.39, 0.83, -0.08))
			_box(Vector3(0.25, 0.055, 0.075), trim, parent, Vector3(0.39, 0.56, -0.08))
		"B": # Mystic: tall hood, staff and luminous focus.
			_cylinder(0.20, 0.32, cloth, parent, Vector3(0, 1.42, 0), 0.02)
			_cylinder(0.038, 0.91, trim, parent, Vector3(0.39, 0.83, -0.02))
			_sphere(0.115, _material(Color("#77e9ff"), 0.12, 0.20, Color("#277caa")), parent, Vector3(0.39, 1.33, -0.02))
		"Q": # Battlemage: split crown, two orbiting gems, spell wand.
			for side in [-1.0, 1.0]:
				_cylinder(0.055, 0.28, trim, parent, Vector3(side * 0.13, 1.48, 0), 0.005)
				_sphere(0.072, cloth, parent, Vector3(side * 0.29, 1.06, -0.17))
			_cylinder(0.035, 0.66, trim, parent, Vector3(0.37, 0.79, 0))
		"K": # Sovereign: royal cape, tall crown and scepter.
			_box(Vector3(0.50, 0.58, 0.10), cloth, parent, Vector3(0, 0.76, 0.19))
			_cylinder(0.21, 0.12, trim, parent, Vector3(0, 1.41, 0))
			for side in [-1.0, 0.0, 1.0]:
				_cylinder(0.048, 0.22, trim, parent, Vector3(side * 0.14, 1.54, 0), 0.005)
			_cylinder(0.045, 0.80, trim, parent, Vector3(0.38, 0.84, 0))
			_sphere(0.09, trim, parent, Vector3(0.38, 1.30, 0))

func _add_region_boss_costume(parent: Node3D) -> void:
	# Six visually different boss profiles; stage changes the armor and weapon
	# outline rather than relying on a generic crown and a palette swap.
	var region: int = clampi(current_region, 0, 5)
	var metal: Material = boss_crown
	match region:
		0: # Ash tyrant: heavy furnace pauldrons and paired horns.
			for side in [-1.0, 1.0]:
				_box(Vector3(0.29, 0.28, 0.38), metal, parent, Vector3(side * 0.34, 1.04, 0))
				var horn := _cylinder(0.08, 0.56, metal, parent, Vector3(side * 0.22, 1.59, 0), 0.008)
				horn.rotation.z = side * 0.30
		1: # Ice revenant: sharp vertical ice spikes and frozen staff.
			for i in range(5):
				_cylinder(0.075, 0.35 + i * 0.12, metal, parent, Vector3((float(i) - 2.0) * 0.13, 1.47, 0), 0.008)
			_cylinder(0.065, 1.15, metal, parent, Vector3(0.43, 0.91, 0), 0.01)
		2: # Thorn colossus: branching antlers and wide root pauldrons.
			for side in [-1.0, 1.0]:
				var branch := _cylinder(0.07, 0.85, metal, parent, Vector3(side * 0.27, 1.62, 0), 0.02)
				branch.rotation.z = side * 0.42
				_box(Vector3(0.40, 0.15, 0.28), metal, parent, Vector3(side * 0.34, 1.0, 0))
		3: # Rift oracle: three rotating arcane halos and tall mask.
			for i in range(3):
				var halo := _ring(0.25 + i * 0.10, 0.035, metal, parent, Vector3(0, 1.43 + i * 0.12, 0))
				halo.rotation.x = 0.30 + float(i) * 0.25
			_box(Vector3(0.22, 0.43, 0.10), metal, parent, Vector3(0, 1.33, -0.16))
		4: # Storm warden: conducting antennae and blade-like wings.
			for side in [-1.0, 1.0]:
				var wing := _box(Vector3(0.13, 0.68, 0.32), metal, parent, Vector3(side * 0.43, 1.15, 0.15))
				wing.rotation.z = side * 0.45
				_cylinder(0.045, 0.73, metal, parent, Vector3(side * 0.20, 1.62, 0), 0.005)
		5: # Void sovereign: split crown, four spines and eclipse disc.
			for i in range(4):
				var angle: float = TAU * float(i) / 4.0
				var spike := _cylinder(0.07, 0.80, metal, parent, Vector3(cos(angle) * 0.27, 1.55, sin(angle) * 0.27), 0.005)
				spike.rotation.z = cos(angle) * 0.32
				spike.rotation.x = sin(angle) * 0.32
			var disc := _ring(0.38, 0.06, metal, parent, Vector3(0, 1.40, 0.20))
			disc.rotation.x = PI * 0.45

func _add_chess_class_plinth(kind: String, white: bool, parent: Node3D) -> void:
	# Readable role silhouettes on the chess base, even when an authored
	# GLB has not imported. Emblems sit below feet and never obscure animation.
	var insignia := Node3D.new()
	insignia.name = "ClassInsignia_" + kind
	parent.add_child(insignia)
	var metal: Material = gold_material if white else boss_crown
	var base: Material = hero_material if white else enemy_material
	match kind:
		"P": # Vanguard: four simple studs mark a basic recruit.
			for side in [-1.0, 1.0]:
				_sphere(0.035, metal, insignia, Vector3(side * 0.16, 0.286, -0.15))
		"R": # Fortress: square corner battlements.
			for side in [-1.0, 1.0]:
				_box(Vector3(0.10, 0.09, 0.10), metal, insignia, Vector3(side * 0.18, 0.30, -0.12))
				_box(Vector3(0.07, 0.06, 0.08), base, insignia, Vector3(side * 0.18, 0.36, -0.12))
		"N": # Cavalry: diagonal steel chevrons.
			for side in [-1.0, 1.0]:
				var slash: MeshInstance3D = _box(Vector3(0.07, 0.035, 0.23), metal, insignia, Vector3(side * 0.12, 0.292, -0.15))
				slash.rotation.y = side * 0.65
		"B": # Mystic: twin concentric ritual halos.
			_ring(0.18, 0.019, metal, insignia, Vector3(0, 0.29, 0))
			_ring(0.10, 0.014, base, insignia, Vector3(0, 0.298, 0))
		"Q": # Sovereign mage: five-point jewel crown around the base.
			for i in range(5):
				var theta: float = TAU * float(i) / 5.0
				_sphere(0.040, metal, insignia, Vector3(cos(theta) * 0.17, 0.30, sin(theta) * 0.17))
		"K": # King: crossed bars under a central crown gem.
			_box(Vector3(0.35, 0.04, 0.06), metal, insignia, Vector3(0, 0.29, 0))
			_box(Vector3(0.06, 0.04, 0.35), metal, insignia, Vector3(0, 0.30, 0))
			_sphere(0.075, metal, insignia, Vector3(0, 0.34, 0))

func _build_piece(letter: String, is_boss: bool = false, selected_hero_piece: bool = true) -> Node3D:
	var unit := Node3D.new()
	var white := letter == letter.to_upper()
	unit.set_meta("hero", white)
	unit.set_meta("boss", is_boss)
	unit.set_meta("selected_hero_piece", selected_hero_piece)
	var material := hero_material if white else enemy_material
	var accent := gold_material if white else dark_material
	_cylinder(0.31, 0.16, accent, unit, Vector3(0, 0.08, 0))
	_cylinder(0.24, 0.09, material, unit, Vector3(0, 0.21, 0))
	# Layered cast-metal plinth, raised rim and a sculpted class-specific heraldic emblem.
	_ring(0.29, 0.028, gold_material if white else boss_crown, unit, Vector3(0, 0.155, 0))
	_ring(0.235, 0.016, accent, unit, Vector3(0, 0.265, 0))

	var kind := letter.to_upper()
	_add_chess_class_plinth(kind, white, unit)
	var imported_character: bool = _load_authored_character(kind, unit)
	if not imported_character:
		_add_humanoid_costume(kind, white, unit)
		# Imported GLBs already contain face, armor and chess-role details.
		# Do not draw another static costume on top of animated geometry.
		_add_character_surface_detail(kind, white, unit)
	if white and selected_hero_piece: _add_selected_hero_identity(kind, unit)
	# Class heraldry is already authored into imported GLBs. Keep the
	# procedural class emblem only for a missing-asset fallback.
	if not imported_character:
		if kind == "N":
			for side in [-1.0, 1.0]:
				var ear := _cylinder(0.055, 0.24, accent, unit, Vector3(side * 0.11, 1.20, -0.05), 0.0)
				ear.rotation.z = side * 0.24
		elif kind == "B":
			_ring(0.17, 0.025, gold_material, unit, Vector3(0, 1.03, 0))
		elif kind == "Q":
			_sphere(0.105, gold_material, unit, Vector3(0, 1.30, 0))
		elif kind == "P":
			_ring(0.145, 0.021, accent, unit, Vector3(0, 0.65, 0))
	if is_boss:
		_add_boss_enrage_aura(unit)
		# Imported bosses already carry their own regional horns, crystals,
		# wings and relics. Avoid masking them with a generic second costume.
		if unit.get_node_or_null("AuthoredCharacter") == null:
			_add_region_boss_costume(unit)
		var shadow_ring := _cylinder(0.43, 0.035, boss_crown, unit, Vector3(0, 0.12, 0))
		shadow_ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		if unit.get_node_or_null("AuthoredCharacter") == null:
			var dark_crown := _cylinder(0.33, 0.20, boss_crown, unit, Vector3(0, 1.23, 0))
			dark_crown.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
			for n in range(7):
				var angle := float(n) * TAU / 7.0
				var horn := _cylinder(0.065, 0.34, boss_crown, unit, Vector3(cos(angle) * 0.28, 1.47, sin(angle) * 0.28), 0.0)
				horn.rotation.z = sin(angle) * 0.28
				horn.rotation.x = cos(angle) * 0.28
			for side in [-1.0, 1.0]:
				_sphere(0.11, boss_crown, unit, Vector3(side * 0.29, 0.93, -0.16))
		unit.scale = Vector3.ONE * 1.17
	var bar_back := _box(Vector3(0.73, 0.085, 0.085), dark_material, unit, Vector3(0, 1.76, 0))
	bar_back.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var bar_fill := _box(Vector3(0.69, 0.055, 0.10), _material(Color("#4edca4") if white else Color("#f26a76"), 0.15, 0.28, Color("#194735") if white else Color("#48121c")), unit, Vector3(0, 1.76, 0.02))
	bar_fill.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	unit.set_meta("health_fill", bar_fill)
	if white and selected_hero_piece and not hero_gear.is_empty():
		if hero_gear.has("Тело"):
			var armor_mat := _gear_material("Тело")
			_add_rarity_insignia("Тело", unit, Vector3(0, 0.52, -0.26))
			_add_equipment_geometry("Тело", unit)
			# Legacy accessory geometry only when the modular GLB is absent.
			if not _has_modular_equipment("Тело"):
				_cylinder(0.29, 0.15, armor_mat, unit, Vector3(0, 0.32, 0))
				for side in [-1.0, 1.0]:
					_box(Vector3(0.12, 0.28, 0.28), armor_mat, unit, Vector3(side * 0.27, 0.48, 0))
		if hero_gear.has("Оружие"):
			var weapon_mat := _gear_material("Оружие")
			_add_rarity_insignia("Оружие", unit, Vector3(0.42, 1.15, 0))
			_add_equipment_geometry("Оружие", unit)
			if not _has_modular_equipment("Оружие"):
				_cylinder(0.045, 0.82, weapon_mat, unit, Vector3(0.42, 0.68, 0))
				_box(Vector3(0.33, 0.065, 0.13), weapon_mat, unit, Vector3(0.42, 0.87, 0))
				_cylinder(0.09, 0.21, weapon_mat, unit, Vector3(0.42, 1.13, 0), 0.015)
		if hero_gear.has("Реликвия"):
			var relic_mat := _gear_material("Реликвия")
			_add_rarity_insignia("Реликвия", unit, Vector3(-0.39, 0.83, 0))
			_add_equipment_geometry("Реликвия", unit)
			if not _has_modular_equipment("Реликвия"):
				_sphere(0.13, relic_mat, unit, Vector3(-0.39, 0.81, 0))
				_cylinder(0.05, 0.32, gold_material, unit, Vector3(-0.39, 0.57, 0))
		var set_count := 0
		var set_id := -1
		for slot in hero_gear:
			var current_id: int = int(hero_gear[slot].get("set_id", -1))
			if current_id >= 0:
				if set_id < 0: set_id = current_id
				if current_id == set_id: set_count += 1
		if set_count >= 2:
			var aura_mat := _gear_material("Оружие") if hero_gear.has("Оружие") else gold_material
			var ring := _cylinder(0.39, 0.025, aura_mat, unit, Vector3(0, 0.12, 0))
			ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Separate visible character rig from the health UI so action animation never tilts the bar.
	var visual_rig := Node3D.new()
	visual_rig.name = "VisualRig"
	unit.add_child(visual_rig)
	for child in unit.get_children():
		if child == visual_rig or child == bar_back or child == bar_fill: continue
		(child as Node3D).reparent(visual_rig, false)
	unit.set_meta("visual_rig", visual_rig)
	unit.scale = Vector3.ONE * (1.12 if is_boss else 0.84)
	board_root.add_child(unit)
	return unit

func _add_boss_enrage_aura(parent: Node3D) -> void:
	# An unmistakable phase-two silhouette visible above the boss plinth.
	# Three rotating crown arcs share one material and existing cached ring meshes.
	var aura := Node3D.new()
	aura.name = "BossEnrageAura"
	aura.visible = boss_enraged and visual_quality > 0
	parent.add_child(aura)
	for i in range(3):
		var ring: MeshInstance3D = _ring(0.49 + float(i) * 0.13, 0.028, boss_crown, aura, Vector3(0, 0.65 + float(i) * 0.21, 0))
		ring.rotation.x = float(i) * 0.24
		ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for i in range(4):
		var angle: float = TAU * float(i) / 4.0
		var crystal: MeshInstance3D = _sphere(0.065, boss_crown, aura, Vector3(cos(angle) * 0.52, 1.11, sin(angle) * 0.52))
		crystal.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func set_boss_phase(phase: int) -> void:
	var enraged: bool = phase >= 2
	var phase_changed: bool = boss_enraged != enraged
	boss_enraged = enraged
	# _draw() may recreate the boss actor without changing its logical phase.
	# Always reapply aura, tint and scale to the current instance.
	if piece_nodes.has(4) and piece_types.get(4, "") == "k":
		var boss: Node3D = piece_nodes[4]
		if not is_instance_valid(boss): return
		var aura: Node3D = boss.get_node_or_null("BossEnrageAura")
		if aura != null: aura.visible = enraged and visual_quality > 0
		var target_scale: Vector3 = Vector3.ONE * (1.42 if enraged else 1.12)
		if phase_changed:
			var burst := create_tween()
			burst.tween_property(boss, "scale", target_scale, 0.24).set_trans(Tween.TRANS_BACK)
		else:
			boss.scale = target_scale
		if not enraged:
			boss.position.y = 0.0
	if boss_crown != null:
		boss_crown.albedo_color = Color("#ff2c5f") if enraged else Color("#e56587")
		boss_crown.emission_energy_multiplier = 2.8 if enraged else 0.6

func set_castle_visual_levels(levels: Dictionary) -> void:
	# Persistent base progression affects only decorative geometry.
	var keys := ["forge", "barracks", "treasury", "academy", "infirmary"]
	for key in keys:
		castle_levels[key] = clampi(int(levels.get(key, 0)), 0, 100)
	_update_castle_visual_levels()

func _update_castle_visual_levels() -> void:
	if region_scenery == null:
		return
	var skyline: Node3D = region_scenery.get_node_or_null("CastleSkyline")
	if skyline == null:
		return
	var keys := ["forge", "barracks", "treasury", "academy", "infirmary"]
	for i in range(keys.size()):
		var building: Node3D = skyline.get_node_or_null("CastleBuilding_%d" % i)
		if building == null:
			continue
		var level: int = int(castle_levels.get(keys[i], 0))
		var stage: int = mini(4, int(level / 5))
		# A low-level structure remains visible; every fifth upgrade
		# visibly expands its silhouette up to the fifth construction tier.
		building.scale = Vector3(1.0 + stage * 0.13, 1.0 + stage * 0.19, 1.0 + stage * 0.13)
		building.set_meta("upgrade_stage", stage)
		building.set_meta("building_level", level)
		for n in range(4):
			var ornament: Node3D = building.get_node_or_null("UpgradeOrnament_%d" % n)
			if ornament != null:
				ornament.visible = n < stage

func _build_castle_skyline(region: int, palette: Array) -> void:
	# Five distinct architectural landmarks beyond the tactical board.
	# Purely visual: never intersect squares, hit tests or combat rules.
	# Named anchors let smoke tests assert real geometry, not placeholders.
	if not castle_material_cache.has(region):
		castle_material_cache[region] = [
			_material(palette[0].lightened(0.11), 0.18, 0.75),
			_material(palette[1].darkened(0.13), 0.35, 0.38),
			_material(palette[2].lightened(0.17), 0.76, 0.24),
			_material(palette[2], 0.24, 0.18, palette[2] * 0.38)
		]
	var castle_materials: Array = castle_material_cache[region]
	var masonry: StandardMaterial3D = castle_materials[0]
	var roof: StandardMaterial3D = castle_materials[1]
	var gilding: StandardMaterial3D = castle_materials[2]
	var glass: StandardMaterial3D = castle_materials[3]
	var skyline := Node3D.new()
	skyline.name = "CastleSkyline"
	region_scenery.add_child(skyline)
	# Elevated outer curtain, parapet and four corner towers.
	var wall: MeshInstance3D = _box(Vector3(10.8, 1.30, 0.55), masonry, skyline, Vector3(0, 0.34, 9.20))
	wall.name = "CastleCurtainWall"
	_box(Vector3(11.2, 0.14, 0.75), roof, skyline, Vector3(0, 1.05, 9.20))
	for side in [-1.0, 1.0]:
		var tower := Node3D.new()
		tower.name = "CastleWatchtower_%d" % int(side)
		tower.position = Vector3(side * 5.30, 0, 9.20)
		skyline.add_child(tower)
		_cylinder(0.66, 2.60, masonry, tower, Vector3(0, 0.78, 0))
		_cylinder(0.78, 0.19, roof, tower, Vector3(0, 2.13, 0))
		_cylinder(0.64, 0.62, roof, tower, Vector3(0, 2.48, 0), 0.05)
		_sphere(0.11, glass, tower, Vector3(0, 2.86, 0))
		for n in range(6):
			var angle: float = TAU * float(n) / 6.0
			_box(Vector3(0.22, 0.30, 0.22), masonry, tower, Vector3(cos(angle) * 0.61, 2.37, sin(angle) * 0.61))
	for i in range(20):
		var battlement: MeshInstance3D = _box(Vector3(0.30, 0.28, 0.57), masonry, skyline, Vector3(-4.8 + float(i) * 0.51, 1.25, 9.20))
		battlement.name = "CastleMerlon_%02d" % i
	# Gatehouse with open central arch silhouette, lintel and banners.
	for side in [-1.0, 1.0]:
		_box(Vector3(0.40, 1.28, 0.72), roof, skyline, Vector3(side * 0.92, 0.30, 8.78))
		var banner: MeshInstance3D = _box(Vector3(0.29, 0.68, 0.045), glass, skyline, Vector3(side * 1.23, 0.45, 8.36))
		banner.name = "CastleBanner_%d" % int(side)
	_box(Vector3(2.20, 0.35, 0.82), roof, skyline, Vector3(0, 1.08, 8.80))
	_ring(0.30, 0.045, gilding, skyline, Vector3(0, 1.27, 8.36))
	# Five recognizable workshop silhouettes: forge, barracks, treasury,
	# academy and infirmary. All sit behind the gate on the skyline.
	for building_index in range(5):
		var building := Node3D.new()
		building.name = "CastleBuilding_%d" % building_index
		building.position = Vector3((float(building_index) - 2.0) * 1.70, 0, 10.85)
		skyline.add_child(building)
		var height: float = 1.15 + float(building_index % 3) * 0.35
		_box(Vector3(1.16, height, 1.08), masonry, building, Vector3(0, height * 0.5 - 0.18, 0))
		_box(Vector3(1.32, 0.15, 1.25), roof, building, Vector3(0, height - 0.08, 0))
		match building_index:
			0: # Forge chimney and glowing furnace mouth.
				_box(Vector3(0.30, 0.80, 0.32), roof, building, Vector3(0.35, height + 0.30, 0))
				_box(Vector3(0.38, 0.31, 0.05), glass, building, Vector3(-0.20, 0.34, -0.57))
			1: # Barracks spear rack and guard standards.
				for side in [-1.0, 1.0]:
					_cylinder(0.035, 0.95, gilding, building, Vector3(side * 0.40, height + 0.40, 0), 0.01)
			2: # Treasury vault dome and gold finial.
				_cylinder(0.48, 0.54, gilding, building, Vector3(0, height + 0.20, 0), 0.03)
				_sphere(0.12, glass, building, Vector3(0, height + 0.55, 0))
			3: # Academy observatory and arcane ring.
				_cylinder(0.32, 0.95, roof, building, Vector3(0, height + 0.40, 0), 0.10)
				_ring(0.37, 0.045, glass, building, Vector3(0, height + 0.95, 0))
			4: # Infirmary healing cross and roof lantern.
				_box(Vector3(0.15, 0.56, 0.12), gilding, building, Vector3(0, height + 0.28, -0.03))
				_box(Vector3(0.43, 0.14, 0.12), gilding, building, Vector3(0, height + 0.30, -0.03))
		# Physical gilded battlements unlock at building levels 5/10/15/20.
		# Each ornament is built once per region and toggled without rebuilding
		# the chess pieces or the entire environment after an upgrade.
		for ornament_index in range(4):
			var ornament := Node3D.new()
			ornament.name = "UpgradeOrnament_%d" % ornament_index
			building.add_child(ornament)
			var ornament_y: float = height + 0.35 + float(ornament_index) * 0.23
			_ring(0.33 + float(ornament_index) * 0.06, 0.027, gilding, ornament, Vector3(0, ornament_y, 0))
			ornament.visible = false
	# Architectural depth pass: roof ridges, lantern windows, gate portcullis
	# and repeated masonry details. Kept beyond the 8x8 hit-test footprint.
	for x in range(-8, 9):
		var stone_x: float = float(x) * 0.59
		_box(Vector3(0.055, 0.16, 0.045), roof, skyline, Vector3(stone_x, 0.32, 8.89))
		_box(Vector3(0.055, 0.16, 0.045), roof, skyline, Vector3(stone_x, 0.74, 8.89))
	for x in range(-3, 4):
		var bar := _cylinder(0.028, 1.03, gilding, skyline, Vector3(float(x) * 0.22, 0.37, 8.34), 0.008)
		bar.name = "CastleGateBar_%02d" % (x + 3)
	for y in [0.22, 0.69]:
		_box(Vector3(1.50, 0.045, 0.07), gilding, skyline, Vector3(0, y, 8.32))
	for building_index in range(5):
		var building_node: Node3D = skyline.get_node("CastleBuilding_%d" % building_index)
		var height: float = 1.15 + float(building_index % 3) * 0.35
		var ridge := _box(Vector3(1.35, 0.10, 0.14), gilding, building_node, Vector3(0, height + 0.06, 0))
		ridge.name = "RoofRidge"
		for side in [-1.0, 1.0]:
			var window := _box(Vector3(0.17, 0.26, 0.05), glass, building_node, Vector3(side * 0.33, 0.48, -0.57))
			window.name = "CastleWindow_%d" % int(side)
			_box(Vector3(0.22, 0.045, 0.075), gilding, building_node, Vector3(side * 0.33, 0.64, -0.59))
	for side in [-1.0, 1.0]:
		var tower_node: Node3D = skyline.get_node("CastleWatchtower_%d" % int(side))
		for level in range(2):
			_ring(0.68, 0.035, gilding, tower_node, Vector3(0, 0.92 + float(level) * 0.80, 0))
		for direction in [-1.0, 1.0]:
			_box(Vector3(0.16, 0.38, 0.07), glass, tower_node, Vector3(direction * 0.44, 1.30, -0.42))
	_update_castle_visual_levels()
	# Region color, not building power, drives the backdrop.
	skyline.set_meta("region", region)

func _build_biome_landmarks(region: int, stone: Material, trim: Material, magic: Material) -> void:
	# Six authored landmark compositions, each outside the 8x8 gameplay grid.
	biome_landmark_motion.clear()
	# They use shared primitive meshes and no extra dynamic light sources.
	var landmark := Node3D.new()
	landmark.name = "BiomeLandmark_%d" % region
	region_scenery.add_child(landmark)
	match region:
		0: # Forge city: two furnaces with layered iron stacks and molten basins.
			for side in [-1.0, 1.0]:
				var x: float = side * 4.95
				_box(Vector3(0.96, 0.42, 0.94), stone, landmark, Vector3(x, 0.04, -2.8))
				_box(Vector3(0.76, 1.16, 0.70), trim, landmark, Vector3(x, 0.76, -2.8))
				_cylinder(0.23, 1.1, stone, landmark, Vector3(x, 1.78, -2.8), 0.17)
				_ring(0.38, 0.06, magic, landmark, Vector3(x, 0.31, -2.8))
				for tooth in range(4):
					var theta: float = float(tooth) * TAU / 4.0
					_box(Vector3(0.16, 0.27, 0.16), stone, landmark, Vector3(x + cos(theta) * 0.34, 1.47, -2.8 + sin(theta) * 0.30))
		1: # Frost cathedral: fractured glacier fins and a suspended frozen core.
			for side in [-1.0, 1.0]:
				for tier in range(4):
					var height: float = 1.15 + float(tier) * 0.46
					var x: float = side * (4.9 + float(tier % 2) * 0.34)
					var z: float = -3.2 + float(tier) * 0.74
					var fin := _cylinder(0.22, height, stone if tier % 2 == 0 else magic, landmark, Vector3(x, height * 0.5 - 0.20, z), 0.0)
					fin.rotation.z = side * (0.16 + float(tier) * 0.05)
				_ring(0.46, 0.045, trim, landmark, Vector3(side * 5.15, 0.08, -2.25))
			_sphere(0.34, magic, landmark, Vector3(0, 2.75, 7.15))
		2: # Ancient forest: braided roots, branch crowns and floating pollen.
			for side in [-1.0, 1.0]:
				var x: float = side * 5.15
				_cylinder(0.32, 2.45, trim, landmark, Vector3(x, 0.97, -2.5), 0.18)
				for branch_index in range(5):
					var theta: float = float(branch_index) * TAU / 5.0
					var branch := _cylinder(0.10, 1.15, trim, landmark, Vector3(x + cos(theta) * 0.36, 2.16, -2.5 + sin(theta) * 0.36), 0.02)
					branch.rotation.z = cos(theta) * 0.68
					branch.rotation.x = sin(theta) * 0.68
					_sphere(0.34, stone if branch_index % 2 == 0 else magic, landmark, Vector3(x + cos(theta) * 0.80, 2.52, -2.5 + sin(theta) * 0.80))
				for root_index in range(3):
					var root := _cylinder(0.11, 0.85, trim, landmark, Vector3(x + (float(root_index) - 1.0) * 0.33, 0.06, -2.5), 0.03)
					root.rotation.z = (float(root_index) - 1.0) * 0.56
		3: # Astral observatory: four rune pylons and concentric portal gates.
			for side in [-1.0, 1.0]:
				var x: float = side * 5.05
				for tier in range(3):
					_box(Vector3(0.56 - float(tier) * 0.09, 0.60, 0.56 - float(tier) * 0.09), stone, landmark, Vector3(x, 0.20 + float(tier) * 0.58, -2.55))
					_ring(0.34 - float(tier) * 0.04, 0.025, magic, landmark, Vector3(x, 0.54 + float(tier) * 0.58, -2.55))
				_sphere(0.20, magic, landmark, Vector3(x, 2.14, -2.55))
			for ring_index in range(3):
				var portal := _ring(0.75 + float(ring_index) * 0.22, 0.05, magic, landmark, Vector3(0, 2.35, 7.3))
				portal.rotation.x = PI * 0.5 + float(ring_index) * 0.13
		4: # Storm battery: twin lightning capacitors and crossed conductors.
			for side in [-1.0, 1.0]:
				var x: float = side * 5.15
				_cylinder(0.31, 0.65, stone, landmark, Vector3(x, 0.12, -2.7))
				for tier in range(3):
					_ring(0.29 + float(tier) * 0.06, 0.055, magic, landmark, Vector3(x, 0.72 + float(tier) * 0.43, -2.7))
					_cylinder(0.08, 0.43, trim, landmark, Vector3(x, 0.77 + float(tier) * 0.43, -2.7), 0.06)
				_sphere(0.27, magic, landmark, Vector3(x, 2.28, -2.7))
				for prong in [-1.0, 1.0]:
					var antenna := _cylinder(0.055, 0.9, trim, landmark, Vector3(x + prong * 0.25, 2.58, -2.7), 0.0)
					antenna.rotation.z = prong * 0.23
		5: # Void crypt: broken gravestones, ritual discs and a shattered crown.
			for side in [-1.0, 1.0]:
				var x: float = side * 5.2
				for tier in range(4):
					var height: float = 0.75 + float(tier % 3) * 0.35
					var grave := _box(Vector3(0.36, height, 0.18), stone, landmark, Vector3(x + (float(tier) - 1.5) * 0.36, height * 0.35, -3.15 + float(tier % 2) * 0.67))
					grave.rotation.z = (float(tier) - 1.5) * 0.12
				for circle_index in range(3):
					_ring(0.36 + float(circle_index) * 0.19, 0.035, magic, landmark, Vector3(x, 0.04 + float(circle_index) * 0.015, -2.5))
			for spike_index in range(7):
				var theta: float = TAU * float(spike_index) / 7.0
				var spike := _cylinder(0.10, 0.68, trim, landmark, Vector3(cos(theta) * 0.58, 2.68, 7.3 + sin(theta) * 0.28), 0.0)
				spike.rotation.z = cos(theta) * 0.30
				spike.rotation.x = sin(theta) * 0.30
	# Animate only four accent meshes per biome; never animate every tree or wall.
	for part in landmark.get_children():
		if biome_landmark_motion.size() >= 4: break
		if part is MeshInstance3D and (part as MeshInstance3D).material_override == magic:
			var accent_mesh: MeshInstance3D = part as MeshInstance3D
			biome_landmark_motion.append({"node": accent_mesh, "position": accent_mesh.position, "rotation": accent_mesh.rotation})

func _rebuild_region_scenery(region_index: int, palette: Array) -> void:
	# All scenery remains outside the playable 8x8 grid; animate only four landmark accents.
	animated_scenery.clear()
	for child in region_scenery.get_children():
		region_scenery.remove_child(child)
		child.queue_free()
	var region := clampi(region_index, 0, 5)
	if not biome_material_cache.has(region):
		biome_material_cache[region] = [
			_material(palette[0].lightened(0.20), 0.25, 0.68),
			_material(palette[1].darkened(0.28), 0.48, 0.38),
			_material(palette[2], 0.22, 0.20, palette[2] * 0.65)
		]
	var region_materials: Array = biome_material_cache[region]
	var stone: StandardMaterial3D = region_materials[0]
	var trim: StandardMaterial3D = region_materials[1]
	var magic: StandardMaterial3D = region_materials[2]
	for n in range(12):
		var angle := (float(n) + 0.5) * TAU / 12.0
		var radius := 5.25 + float(n % 3) * 0.34
		var pos := Vector3(cos(angle) * radius, 0, sin(angle) * radius)
		var height := 0.95 + float(n % 4) * 0.22
		match region:
			0: # Ember fortress: crenellated battlements and braziers.
				_cylinder(0.27, height, stone, region_scenery, pos + Vector3(0, height * 0.5 - 0.25, 0))
				_box(Vector3(0.68, 0.16, 0.68), trim, region_scenery, pos + Vector3(0, height - 0.26, 0))
				for side in [-1.0, 1.0]:
					_box(Vector3(0.14, 0.23, 0.16), stone, region_scenery, pos + Vector3(side * 0.24, height - 0.08, 0))
			1: # Frostlands: asymmetric ice spires.
				var shard := _cylinder(0.30, height * 1.7, magic, region_scenery, pos + Vector3(0, height * 0.75 - 0.4, 0), 0.015)
				shard.rotation.z = sin(angle * 3.0) * 0.16
				_cylinder(0.38, 0.17, stone, region_scenery, pos + Vector3(0, -0.12, 0))
			2: # Overgrown ruins: trunks and tiered canopies.
				_cylinder(0.13, height, trim, region_scenery, pos + Vector3(0, height * 0.5 - 0.25, 0), 0.10)
				for tier in range(3):
					_cylinder(0.48 - tier * 0.10, 0.40, stone if tier == 0 else magic, region_scenery, pos + Vector3(0, height * 0.6 + tier * 0.28, 0), 0.08)
			3: # Arcane catacombs: obelisks with floating runes.
				_box(Vector3(0.37, height * 1.5, 0.37), stone, region_scenery, pos + Vector3(0, height * 0.65, 0))
				_ring(0.29, 0.035, magic, region_scenery, pos + Vector3(0, height * 1.4, 0))
			4: # Storm citadel: lightning rods and suspended energy orbs.
				_cylinder(0.20, height, stone, region_scenery, pos + Vector3(0, height * 0.5 - 0.2, 0), 0.11)
				_cylinder(0.045, 0.60, trim, region_scenery, pos + Vector3(0, height + 0.12, 0), 0.0)
				_sphere(0.17, magic, region_scenery, pos + Vector3(0, height + 0.48, 0))
			5: # Void throne: broken black pillars and corruption halos.
				var column := _cylinder(0.26, height * 1.45, stone, region_scenery, pos + Vector3(0, height * 0.58 - 0.2, 0), 0.14)
				column.rotation.z = sin(angle * 2.0) * 0.20
				_ring(0.38, 0.038, magic, region_scenery, pos + Vector3(0, 0.12, 0))
	# Region-specific large architectural silhouettes, all outside the board.
	# Keep landmark count bounded for GL Compatibility/mobile.
	match region:
		0: # Furnace gate: double watchtowers, portcullis and fire altar.
			for side in [-1.0, 1.0]:
				_box(Vector3(0.86, 2.30, 0.86), stone, region_scenery, Vector3(side * 2.35, 0.75, 6.25))
				_box(Vector3(1.10, 0.28, 1.10), trim, region_scenery, Vector3(side * 2.35, 1.99, 6.25))
			_box(Vector3(3.80, 0.37, 0.50), trim, region_scenery, Vector3(0, 1.75, 6.25))
			for i in range(6):
				_box(Vector3(0.12, 1.30, 0.16), stone, region_scenery, Vector3(-1.45 + i * 0.58, 0.86, 6.0))
		1: # Glacier arch: asymmetrical crystalline columns and ice bridge.
			for side in [-1.0, 1.0]:
				for i in range(3):
					var ice := _cylinder(0.35 - i * 0.05, 1.8 + i * 0.45, magic, region_scenery, Vector3(side * (2.0 + i * 0.65), 0.70, 6.1), 0.01)
					ice.rotation.z = side * (0.13 + i * 0.12)
			_box(Vector3(4.20, 0.20, 0.45), stone, region_scenery, Vector3(0, 1.72, 6.3))
		2: # Ancient grove: sacred tree, roots and hanging canopy.
			_cylinder(0.44, 2.7, trim, region_scenery, Vector3(0, 1.04, 6.5), 0.25)
			for i in range(5):
				var angle: float = TAU * float(i) / 5.0
				var branch := _cylinder(0.12, 1.35, trim, region_scenery, Vector3(cos(angle) * 0.64, 2.15, 6.5 + sin(angle) * 0.64), 0.035)
				branch.rotation.z = cos(angle) * 0.78
				branch.rotation.x = sin(angle) * 0.78
				_sphere(0.55, magic, region_scenery, Vector3(cos(angle) * 1.15, 2.6, 6.5 + sin(angle) * 1.15))
		3: # Astral library: monumental doorway, levitating rings and pylons.
			for side in [-1.0, 1.0]:
				_box(Vector3(0.55, 2.70, 0.65), stone, region_scenery, Vector3(side * 1.65, 0.95, 6.35))
			_box(Vector3(3.80, 0.45, 0.70), trim, region_scenery, Vector3(0, 2.38, 6.35))
			for i in range(3):
				var portal := _ring(0.60 + i * 0.24, 0.035, magic, region_scenery, Vector3(0, 1.20, 6.10))
				portal.rotation.x = PI * 0.5
				portal.rotation.y = float(i) * 0.30
		4: # Tempest observatory: lightning conductors and suspended core.
			for side in [-1.0, 1.0]:
				_cylinder(0.32, 2.75, stone, region_scenery, Vector3(side * 2.0, 1.10, 6.25), 0.09)
				_cylinder(0.045, 1.10, trim, region_scenery, Vector3(side * 2.0, 2.88, 6.25), 0.0)
			_sphere(0.52, magic, region_scenery, Vector3(0, 2.35, 6.4))
			_ring(0.75, 0.06, trim, region_scenery, Vector3(0, 2.35, 6.4))
		5: # Corrupted throne: fractured steps, black spires, red eclipse.
			for i in range(4):
				_box(Vector3(3.5 - i * 0.45, 0.18, 1.10), stone, region_scenery, Vector3(0, -0.18 + i * 0.18, 5.65 + i * 0.36))
			_box(Vector3(1.20, 2.15, 0.55), trim, region_scenery, Vector3(0, 1.15, 7.10))
			for side in [-1.0, 1.0]:
				var spike := _cylinder(0.22, 2.40, stone, region_scenery, Vector3(side * 1.20, 1.0, 6.70), 0.005)
				spike.rotation.z = side * 0.22
			var eclipse := _ring(0.95, 0.10, magic, region_scenery, Vector3(0, 2.70, 7.30))
			eclipse.rotation.x = PI * 0.5
	_build_biome_landmarks(region, stone, trim, magic)
	_build_castle_skyline(region, palette)
	# A bounded halo of 12 drifting particles around the arena.
	# Geometry only, no particle emitter or extra light source. Hidden
	# completely in low and medium visual-quality presets.
	ambient_motes.clear()
	ambient_mote_origins.clear()
	for mote_index in range(12):
		var mote_angle: float = TAU * float(mote_index) / 12.0
		var mote_radius: float = 5.1 + float(mote_index % 3) * 0.27
		var mote_pos := Vector3(cos(mote_angle) * mote_radius, 0.8 + float(mote_index % 4) * 0.28, sin(mote_angle) * mote_radius)
		var mote: MeshInstance3D = _sphere(0.055, magic, region_scenery, mote_pos)
		mote.name = "AmbientMote_%02d" % mote_index
		mote.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mote.visible = visual_quality >= 2
		ambient_motes.append(mote)
		ambient_mote_origins.append(mote_pos)
	# Mission-specific visual dressing outside the playable 8x8 board.
	# Layout 0: standards, layout 1: runic obelisks, layout 2: ward circles.
	for side in [-1.0, 1.0]:
		var anchor_pos := Vector3(side * 5.65, 0, 2.15)
		match mission_visual_variant:
			0:
				_cylinder(0.055, 1.65, trim, region_scenery, anchor_pos + Vector3(0, 0.63, 0))
				var banner := _box(Vector3(0.47, 0.70, 0.075), magic, region_scenery, anchor_pos + Vector3(side * 0.20, 1.05, 0))
				banner.rotation.z = side * 0.12
				_sphere(0.09, magic, region_scenery, anchor_pos + Vector3(0, 1.55, 0))
			1:
				var obelisk := _cylinder(0.24, 1.85, stone, region_scenery, anchor_pos + Vector3(0, 0.68, 0), 0.05)
				obelisk.rotation.z = side * 0.13
				_sphere(0.13, magic, region_scenery, anchor_pos + Vector3(0, 1.72, 0))
			2:
				for circle_index in range(3):
					var ward := _ring(0.31 + circle_index * 0.16, 0.035, magic, region_scenery, anchor_pos + Vector3(0, -0.09 + circle_index * 0.02, 0))
					ward.rotation.x = 0.0
				_cylinder(0.14, 0.62, trim, region_scenery, anchor_pos + Vector3(0, 0.12, 0))
	# Four larger landmarks establish a silhouette behind the arena without obstructing play.
	for corner_x in [-1.0, 1.0]:
		for corner_z in [-1.0, 1.0]:
			var corner := Vector3(corner_x * 5.75, 0, corner_z * 5.75)
			_cylinder(0.48, 1.7, trim, region_scenery, corner + Vector3(0, 0.50, 0), 0.34)
			_ring(0.40, 0.055, magic, region_scenery, corner + Vector3(0, 1.35, 0))
			if region in [1, 3, 4, 5]:
				var orb := _sphere(0.13, magic, region_scenery, corner + Vector3(0, 1.60, 0))
				orb.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				animated_scenery.append(orb)

func set_mission_visual_variant(variant: int) -> void:
	# Three deterministic arena dressing layouts per biome: 18 mission looks.
	var next_variant: int = clampi(variant, 0, 2)
	if mission_visual_variant == next_variant: return
	mission_visual_variant = next_variant
	if current_region >= 0 and region_scenery != null and tile_materials.size() >= 2:
		var accent: Color = rim_light.light_color
		_rebuild_region_scenery(current_region, [tile_materials[0].albedo_color, tile_materials[1].albedo_color, accent])
		region_scenery.visible = visual_quality > 0

func set_region(region_index: int) -> void:
	if current_region == region_index: return
	current_region = region_index
	var palettes := [
		[Color("#273a4c"), Color("#b7a58c"), Color("#ff9b4a")],
		[Color("#243e59"), Color("#92b7d0"), Color("#79d9ff")],
		[Color("#183d42"), Color("#83ada7"), Color("#42e5bd")],
		[Color("#39283f"), Color("#947b8e"), Color("#e783ed")],
		[Color("#28395e"), Color("#c4b6a2"), Color("#b7a4ff")],
		[Color("#2b182e"), Color("#78617e"), Color("#ed4c78")]
	]
	var palette: Array = palettes[clampi(region_index, 0, palettes.size() - 1)]
	# Two shared materials replace 64 independent tile materials and avoid repeated updates.
	tile_materials[0].albedo_color = palette[0]
	tile_materials[1].albedo_color = palette[1]
	# Region lighting and architecture change independently of purchased board skins.
	if board_style_customized:
		set_board_visual_style(board_style_index)
	for torch in torches:
		torch.light_color = palette[2]
	# Region lighting changes the actual 3D scene, not just tile colours.
	# Keep ambient illumination high enough to distinguish pieces on mobile.
	var environment: Environment = world_environment.environment
	region_background_target = palette[0].darkened(0.72)
	region_light_target = palette[1].lightened(0.20)
	region_rim_target = palette[2]
	rim_light.light_color = palette[2]
	region_light_transition = 1.0
	key_light.light_color = palette[1].lightened(0.35)
	rim_light.light_energy = 1.25 if region_index == 5 else 1.6
	_rebuild_region_scenery(region_index, palette)
	region_scenery.visible = visual_quality > 0
	# All regional enemies, not only the boss, must refresh when changing
	# biomes. Keep board indices, health state and in-flight units intact.
	for cell in piece_nodes.keys():
		if moving_nodes.has(cell): continue
		var kind: String = str(piece_types.get(cell, ""))
		if kind == "" or kind != kind.to_lower(): continue
		var old_enemy: Node3D = piece_nodes[cell]
		old_enemy.queue_free()
		var new_enemy: Node3D = _build_piece(kind, cell == 4 and kind == "k", false)
		new_enemy.position = _square_position(cell)
		piece_nodes[cell] = new_enemy

func set_hazards(cells: Array[int], modifier: String) -> void:
	if active_hazards == cells and hazard_type == modifier: return
	active_hazards = cells.duplicate()
	hazard_type = modifier
	var material: Material = hazard_materials.get(modifier, hazard_materials["frost"])
	for index in range(hazard_markers.size()):
		var marker: MeshInstance3D = hazard_markers[index]
		marker.visible = cells.has(index)
		if marker.visible: marker.material_override = material

func set_poison_indicators(statuses: Dictionary, enemy_statuses: Dictionary = {}) -> void:
	# Hero debuffs and enemy poison stacks use separate floating 3D indicators.
	# The effect is attached to a board cell but rebuilt as the unit moves.
	_update_poison_marker_group(poison_indicators, statuses, hazard_materials["poison"], 2.25)
	_update_poison_marker_group(enemy_poison_indicators, enemy_statuses, hazard_materials["poison"], 2.03)

func _update_poison_marker_group(markers: Dictionary, statuses: Dictionary, material: Material, height: float) -> void:
	for cell in markers.keys():
		if not statuses.has(cell) or int(statuses.get(cell, 0)) <= 0:
			if is_instance_valid(markers[cell]):
				(markers[cell] as MeshInstance3D).queue_free()
			markers.erase(cell)
	for cell in statuses.keys():
		if typeof(cell) != TYPE_INT or cell < 0 or cell >= 64: continue
		var stacks: int = clampi(int(statuses[cell]), 0, 5)
		if stacks <= 0: continue
		if not markers.has(cell):
			var marker: MeshInstance3D = _sphere(0.13, material, board_root, _square_position(cell) + Vector3(0, height, 0))
			marker.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			markers[cell] = marker
		var active_marker: MeshInstance3D = markers[cell]
		active_marker.set_meta("stacks", stacks)
		# A stronger poison effect is visibly larger, without allocating
		# extra geometry or materials for every stack.
		active_marker.scale = Vector3.ONE * (0.85 + float(stacks) * 0.13)

func set_checked_king(index: int) -> void:
	checked_king_square = index if index >= 0 and index < 64 else -1
	if king_warning == null: return
	king_warning.visible = checked_king_square >= 0
	if king_warning.visible:
		king_warning.position = _square_position(checked_king_square) + Vector3(0, 0.14, 0)

func sync_board(pieces: Array, selected: int, legal_squares: Array, danger: int, health: Array = [], max_health: Array = []) -> void:
	# Only one unit represents the equipped hero. Preserve its identity across
	# movement and rebuilds, and choose a deterministic new bearer if captured.
	var chosen_piece: String = str(selected_hero_visual.get("piece", ""))
	if hero_model_cell < 0 or hero_model_cell >= 64 or str(pieces[hero_model_cell]) != chosen_piece:
		hero_model_cell = -1
		for candidate in range(64):
			if chosen_piece != "" and str(pieces[candidate]) == chosen_piece:
				hero_model_cell = candidate
				break
	for cell in piece_nodes.keys():
		var existing: Node3D = piece_nodes[cell]
		if bool(existing.get_meta("selected_hero_piece", false)) != (cell == hero_model_cell):
			piece_types[cell] = ""
	for index in range(64):
		var piece: String = str(pieces[index])
		if piece == "":
			if piece_nodes.has(index) and not moving_nodes.has(index):
				var old: Node3D = piece_nodes[index]
				old.queue_free()
				piece_nodes.erase(index)
				piece_types.erase(index)
		elif not piece_nodes.has(index) or str(piece_types.get(index, "")) != piece:
			if piece_nodes.has(index):
				(piece_nodes[index] as Node3D).queue_free()
			var node := _build_piece(piece, index == 4 and piece == "k", index == hero_model_cell)
			node.position = _square_position(index)
			piece_nodes[index] = node
			piece_types[index] = piece
		if piece != "" and piece_nodes.has(index) and health.size() == 64 and max_health.size() == 64:
			var piece_node: Node3D = piece_nodes[index]
			var fill: MeshInstance3D = piece_node.get_meta("health_fill")
			var ratio := clampf(float(health[index]) / float(maxi(1, int(max_health[index]))), 0.0, 1.0)
			fill.scale.x = maxi(0.001, ratio)
			fill.position.x = -0.345 * (1.0 - ratio)
		highlights[index].visible = index == selected or legal_squares.has(index) or index == danger
		if highlights[index].visible:
			highlights[index].material_override = selection_material if index == selected else (danger_material if index == danger else move_material)
	for index in piece_nodes.keys():
		if not moving_nodes.has(index):
			var piece_node: Node3D = piece_nodes[index]
			piece_node.position = _square_position(index)

# Imported glTF clips may be namespaced by an AnimationLibrary (e.g. default/move).
# Resolve exact names first, then qualified names; never play an unrelated clip.
func _play_authored_clip(rig: Node3D, clip: String) -> bool:
	var model: Node = rig.get_node_or_null("AuthoredCharacter")
	if model == null: return false
	var player: AnimationPlayer = model.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if player == null: return false
	if player.has_animation(clip):
		player.play(clip)
		return true
	# Imported GLB clips are stored in named libraries; resolve by library rather than
	# relying on a flattened animation list or on a particular import prefix.
	for library_name in player.get_animation_library_list():
		var library: AnimationLibrary = player.get_animation_library(library_name)
		if library != null and library.has_animation(clip):
			var qualified: String = clip if library_name == "" else library_name + "/" + clip
			player.play(qualified)
			return true
	return false

func animate_move(source: int, target: int) -> void:
	if not piece_nodes.has(source): return
	var actor: Node3D = piece_nodes[source]
	if piece_nodes.has(target):
		if hero_model_cell == target: hero_model_cell = -1
		var victim: Node3D = piece_nodes[target]
		var victim_rig: Node3D = victim.get_meta("visual_rig", null)
		if victim_rig != null:
			_play_authored_clip(victim_rig, "death")
			_animate_limbs(victim_rig, "hit")
		# Leave enough time to read the death pose, without delaying the
		# chess move or keeping the captured unit in the logical board.
		var vanish := create_tween()
		# The authored death clip lasts 0.70s; keep its final pose visible
		# before shrinking the defeated unit out of the scene.
		vanish.tween_interval(0.70)
		vanish.tween_property(victim, "scale", victim.scale * 0.92, 0.12)
		vanish.tween_property(victim, "scale", Vector3.ZERO, 0.22).set_trans(Tween.TRANS_CUBIC)
		vanish.tween_callback(victim.queue_free)
		piece_nodes.erase(target)
		piece_types.erase(target)
	piece_nodes.erase(source)
	piece_types[target] = piece_types[source]
	piece_types.erase(source)
	piece_nodes[target] = actor
	if hero_model_cell == source: hero_model_cell = target
	moving_nodes[target] = true
	var destination := _square_position(target)
	var move_rig: Node3D = actor.get_meta("visual_rig", null)
	if move_rig != null:
		var lean := create_tween()
		lean.tween_property(move_rig, "rotation:z", -0.16, 0.15)
		lean.tween_property(move_rig, "rotation:z", 0.08, 0.18)
		lean.tween_property(move_rig, "rotation:z", 0.0, 0.10)
		_play_authored_clip(move_rig, "move")
		_animate_limbs(move_rig, "move")
	var tween := create_tween()
	tween.tween_property(actor, "position", destination + Vector3(0, 0.9, 0), 0.19).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(actor, "position", destination, 0.22).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func(): moving_nodes.erase(target))

func attack(source: int, target: int, magical: bool = false) -> void:
	if not piece_nodes.has(source): return
	var attacker: Node3D = piece_nodes[source]
	var start: Vector3 = _square_position(source)
	var end: Vector3 = _square_position(target)
	var distance_vector: Vector3 = end - start
	# Self-targeted spells and previews must not construct a zero-axis quaternion.
	var direction: Vector3 = distance_vector.normalized() if distance_vector.length_squared() > 0.0001 else Vector3.FORWARD
	var rig: Node3D = attacker.get_meta("visual_rig", null)
	if rig != null:
		var swing := create_tween()
		swing.tween_property(rig, "rotation", Vector3(-0.18, 0.24 if magical else -0.22, -0.26), 0.12).set_trans(Tween.TRANS_QUAD)
		swing.tween_property(rig, "rotation", Vector3(0.22, -0.28 if magical else 0.32, 0.30), 0.13).set_trans(Tween.TRANS_QUART)
		swing.tween_property(rig, "rotation", Vector3.ZERO, 0.18).set_trans(Tween.TRANS_BACK)
		_play_authored_clip(rig, "attack")
		_animate_limbs(rig, "attack")
	var anticipation := create_tween()
	anticipation.tween_property(attacker, "position", start - direction * 0.16 + Vector3(0, 0.10, 0), 0.11).set_trans(Tween.TRANS_CUBIC)
	anticipation.tween_property(attacker, "position", start + direction * 0.25 + Vector3(0, 0.19, 0), 0.12).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	anticipation.tween_property(attacker, "position", start, 0.17).set_trans(Tween.TRANS_BACK)
	_spawn_attack_trail(source, target, magical)
	_spawn_hit_impact(target, magical)
	# Low graphics tier intentionally omits translucent attack geometry and
	# camera shake; it still plays the complete actor animation.
	if fx_enabled and visual_quality > 0 and board_root != null and distance_vector.length_squared() > 0.0001:
		var beam := MeshInstance3D.new()
		var beam_mesh := CylinderMesh.new()
		beam_mesh.top_radius = 0.045 if magical else 0.075
		beam_mesh.bottom_radius = 0.09 if magical else 0.13
		beam_mesh.height = maxf(0.1, start.distance_to(end))
		beam_mesh.radial_segments = 8 if visual_quality == 1 else 12
		beam.mesh = beam_mesh
		var color := Color("#a978ff") if magical else Color("#ffd08a")
		var mat := _material(color, 0.15, 0.18, color)
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		beam.material_override = mat
		beam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		beam.position = (start + end) * 0.5 + Vector3(0, 0.8, 0)
		beam.quaternion = Quaternion(Vector3.UP, direction)
		beam.scale = Vector3(0.01, 0.01, 0.01)
		board_root.add_child(beam)
		var slash := create_tween()
		slash.tween_property(beam, "scale", Vector3.ONE, 0.10).set_trans(Tween.TRANS_CUBIC)
		slash.tween_property(beam, "transparency", 1.0, 0.24)
		slash.tween_callback(beam.queue_free)
		if camera != null and visual_quality >= 2:
			var camera_shake := create_tween()
			camera_shake.tween_property(camera, "position", base_camera_position + Vector3(0.09, -0.06, 0), 0.045)
			camera_shake.tween_property(camera, "position", base_camera_position + Vector3(-0.07, 0.04, 0), 0.055)
			camera_shake.tween_property(camera, "position", base_camera_position, 0.11)

func _spawn_hit_impact(target: int, magical: bool) -> void:
	# An impact must read at chessboard scale without adding GPU lights.
	# All geometry is short-lived and released by its own tween.
	if not fx_enabled or visual_quality == 0 or board_root == null: return
	var center: Vector3 = _square_position(target) + Vector3(0, 0.16, 0)
	var tint: Color = Color("#b79bff") if magical else Color("#ffbf72")
	var key: String = "magic" if magical else "physical"
	if not impact_materials.has(key):
		var fresh: StandardMaterial3D = _material(tint, 0.0, 0.2, tint)
		fresh.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		fresh.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		impact_materials[key] = fresh
	var material: StandardMaterial3D = impact_materials[key]
	var shockwave: MeshInstance3D = _ring(0.24, 0.026, material, board_root, center)
	shockwave.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	shockwave.scale = Vector3(0.35, 0.3, 0.35)
	var ripple := create_tween()
	ripple.set_parallel(true)
	ripple.tween_property(shockwave, "scale", Vector3(2.6, 0.3, 2.6), 0.32).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	ripple.tween_property(shockwave, "transparency", 1.0, 0.32)
	ripple.chain().tween_callback(shockwave.queue_free)
	var count: int = 4 if visual_quality == 1 else 8
	for i in range(count):
		var angle: float = TAU * float(i) / float(count)
		var radial: Vector3 = Vector3(cos(angle), 0, sin(angle))
		var spark: MeshInstance3D = _sphere(0.045 if magical else 0.035, material, board_root, center + radial * 0.08)
		spark.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var burst := create_tween()
		burst.set_parallel(true)
		burst.tween_property(spark, "position", center + radial * (0.34 if magical else 0.26) + Vector3(0, 0.36 + float(i % 3) * 0.09, 0), 0.26).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		burst.tween_property(spark, "scale", Vector3.ZERO, 0.26)
		burst.chain().tween_callback(spark.queue_free)

func _spawn_attack_trail(source: int, target: int, magical: bool) -> void:
	# Layered rising energy trail. All transient geometry is released after the tween.
	if not fx_enabled or board_root == null or visual_quality <= 0: return
	var origin: Vector3 = _square_position(source) + Vector3(0, 0.75, 0)
	var destination: Vector3 = _square_position(target) + Vector3(0, 0.75, 0)
	var direction: Vector3 = destination - origin
	if direction.length_squared() < 0.01: return
	var segments: int = 4 if visual_quality == 1 else 8
	var tint: Color = Color("#b69bff") if magical else Color("#ffd68b")
	var trail_key: String = "magic" if magical else "physical"
	if not attack_trail_materials.has(trail_key):
		var trail_glow: StandardMaterial3D = _material(tint, 0.0, 0.15, tint)
		trail_glow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		trail_glow.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		attack_trail_materials[trail_key] = trail_glow
	var glow: StandardMaterial3D = attack_trail_materials[trail_key]
	var mesh_key: String = "trail_mesh:" + trail_key
	if not primitive_mesh_cache.has(mesh_key):
		var trail_mesh := SphereMesh.new()
		trail_mesh.radius = 0.075 if magical else 0.052
		trail_mesh.height = 0.15 if magical else 0.104
		trail_mesh.radial_segments = 6
		trail_mesh.rings = 4
		primitive_mesh_cache[mesh_key] = trail_mesh
	var mesh: Mesh = primitive_mesh_cache[mesh_key]
	for step in range(segments):
		var ratio: float = float(step + 1) / float(segments + 1)
		var spark := MeshInstance3D.new()
		spark.mesh = mesh
		spark.material_override = glow
		spark.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var lift: float = sin(ratio * PI) * (0.52 if magical else 0.32)
		var start: Vector3 = origin.lerp(destination, ratio) + Vector3(0, lift, 0)
		spark.position = start
		spark.scale = Vector3.ONE * 0.01
		board_root.add_child(spark)
		var tween := create_tween()
		tween.tween_interval(ratio * 0.12)
		tween.tween_property(spark, "scale", Vector3.ONE * (1.15 - ratio * 0.3), 0.08).set_trans(Tween.TRANS_CUBIC)
		tween.tween_property(spark, "position", start + direction.normalized() * 0.17 + Vector3(0, 0.13, 0), 0.15)
		tween.tween_property(spark, "scale", Vector3.ZERO, 0.16)
		tween.tween_callback(spark.queue_free)

func _spawn_impact_sparks(index: int, healing: bool) -> void:
	# Short-lived geometry-only particles avoid a GPU particle dependency on Android.
	if not fx_enabled or board_root == null or index < 0 or index >= 64: return
	var count: int = 5 if visual_quality == 1 else 9
	var origin: Vector3 = _square_position(index) + Vector3(0, 0.65, 0)
	var tint: Color = Color("#75ffd0") if healing else Color("#ffbd65")
	var spark_mat: StandardMaterial3D = _material(tint, 0.12, 0.22, tint)
	spark_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	spark_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var spark_mesh := SphereMesh.new()
	spark_mesh.radius = 0.045
	spark_mesh.height = 0.09
	spark_mesh.radial_segments = 6
	spark_mesh.rings = 3
	for n in range(count):
		var angle: float = TAU * float(n) / float(count) + float(index) * 0.37
		var spark := MeshInstance3D.new()
		spark.mesh = spark_mesh
		spark.material_override = spark_mat
		spark.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		spark.position = origin
		board_root.add_child(spark)
		var travel: Vector3 = Vector3(cos(angle) * 0.55, 0.2 + float(n % 3) * 0.14, sin(angle) * 0.55)
		var burst := create_tween()
		burst.set_parallel(true)
		burst.tween_property(spark, "position", origin + travel, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		burst.tween_property(spark, "scale", Vector3.ZERO, 0.35)
		burst.chain().tween_callback(spark.queue_free)

func hit(index: int, healing: bool = false) -> void:
	if not piece_nodes.has(index): return
	_spawn_impact_sparks(index, healing)
	# Keep hit reactions on low-end devices without translucent shock meshes.
	if fx_enabled and visual_quality > 0 and board_root != null:
		var shock := MeshInstance3D.new()
		if not primitive_mesh_cache.has("hit_shock_torus"):
			var shock_mesh := TorusMesh.new()
			shock_mesh.inner_radius = 0.23
			shock_mesh.outer_radius = 0.33
			shock_mesh.rings = 12
			shock_mesh.ring_segments = 20
			primitive_mesh_cache["hit_shock_torus"] = shock_mesh
		shock.mesh = primitive_mesh_cache["hit_shock_torus"]
		var hit_key: String = "heal" if healing else "damage"
		if not impact_materials.has(hit_key):
			var flash_material := _material(Color("#6ef7c2") if healing else Color("#ff855d"), 0.0, 0.3, Color("#4de6a8") if healing else Color("#ff431e"))
			flash_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			impact_materials[hit_key] = flash_material
		shock.material_override = impact_materials[hit_key]
		shock.position = _square_position(index) + Vector3(0, 0.10, 0)
		shock.scale = Vector3.ONE * 0.2
		board_root.add_child(shock)
		var shock_tween := create_tween()
		shock_tween.set_parallel(true)
		shock_tween.tween_property(shock, "scale", Vector3.ONE * 2.3, 0.42).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		shock_tween.tween_property(shock, "transparency", 1.0, 0.42)
		shock_tween.chain().tween_callback(shock.queue_free)
	var actor: Node3D = piece_nodes[index]
	var hit_rig: Node3D = actor.get_meta("visual_rig", null)
	if hit_rig != null:
		if not healing: _play_authored_clip(hit_rig, "hit")
		else: _play_authored_clip(hit_rig, "cast")
		_animate_limbs(hit_rig, "heal" if healing else "hit")
	var start_scale: Vector3 = actor.scale
	var tween := create_tween()
	tween.tween_property(actor, "scale", start_scale * (1.18 if healing else 0.78), 0.10)
	tween.tween_property(actor, "scale", start_scale, 0.20).set_trans(Tween.TRANS_BACK)

func pick_square(pixel: Vector2) -> int:
	var origin := camera.project_ray_origin(pixel)
	var direction := camera.project_ray_normal(pixel)
	if absf(direction.y) < 0.001: return -1
	var distance := -origin.y / direction.y
	if distance < 0: return -1
	var point := origin + direction * distance
	var col := int(floor(point.x + 4.0))
	var row := int(floor(point.z + 4.0))
	if col < 0 or col > 7 or row < 0 or row > 7: return -1
	return row * 8 + col

func _animate_limbs(rig: Node3D, clip: String) -> void:
	# Procedural articulated clips for fallback characters; authored animation
	# players remain responsible for imported rigged GLB characters.
	if rig.get_node_or_null("AuthoredCharacter") != null: return
	var left_arm: Node3D = rig.get_node_or_null("Arm_L")
	var right_arm: Node3D = rig.get_node_or_null("Arm_R")
	var left_leg: Node3D = rig.get_node_or_null("Leg_L")
	var right_leg: Node3D = rig.get_node_or_null("Leg_R")
	if left_arm == null or right_arm == null or left_leg == null or right_leg == null: return
	var duration: float = 0.36 if clip == "move" else 0.20
	if clip == "move":
		for limb in [left_arm, right_leg]:
			var motion := create_tween()
			motion.tween_property(limb, "rotation:x", -0.55, duration * 0.4)
			motion.tween_property(limb, "rotation:x", 0.42, duration * 0.35)
			motion.tween_property(limb, "rotation:x", 0.0, duration * 0.25)
		for limb in [right_arm, left_leg]:
			var motion := create_tween()
			motion.tween_property(limb, "rotation:x", 0.55, duration * 0.4)
			motion.tween_property(limb, "rotation:x", -0.42, duration * 0.35)
			motion.tween_property(limb, "rotation:x", 0.0, duration * 0.25)
	elif clip == "attack":
		var swing := create_tween()
		swing.tween_property(right_arm, "rotation:x", -1.35, 0.10)
		swing.tween_property(right_arm, "rotation:x", 0.65, 0.13)
		swing.tween_property(right_arm, "rotation:x", 0.0, 0.18).set_trans(Tween.TRANS_BACK)
	elif clip == "hit":
		for limb in [left_arm, right_arm]:
			var recoil := create_tween()
			recoil.tween_property(limb, "rotation:x", -0.72, 0.09)
			recoil.tween_property(limb, "rotation:x", 0.0, 0.22)
	elif clip == "heal":
		for limb in [left_arm, right_arm]:
			var cast := create_tween()
			cast.tween_property(limb, "rotation:z", 0.85 if limb == left_arm else -0.85, 0.18)
			cast.tween_property(limb, "rotation:z", 0.0, 0.28)

func _process(delta: float) -> void:
	clock += delta
	# A short palette crossfade makes each new region visually distinct.
	if region_light_transition > 0.0 and world_environment != null:
		var blend: float = minf(1.0, delta * 3.5)
		var env: Environment = world_environment.environment
		env.background_color = env.background_color.lerp(region_background_target, blend)
		env.ambient_light_color = env.ambient_light_color.lerp(region_light_target, blend)
		if rim_light != null:
			rim_light.light_color = rim_light.light_color.lerp(region_rim_target, blend)
		region_light_transition = maxf(0.0, region_light_transition - delta)
		if region_light_transition == 0.0:
			env.background_color = region_background_target
			env.ambient_light_color = region_light_target
			if rim_light != null: rim_light.light_color = region_rim_target
	# Hidden lights and low-quality flames do not need per-frame updates.
	if fx_enabled:
		for i in range(torch_flames.size()):
			if not torches[i].visible: continue
			var flicker := sin(clock * (6.0 + float(i) * 0.27) + float(i) * 1.7)
			torch_flames[i].scale = Vector3(0.85 + flicker * 0.12, 1.2 + flicker * 0.24, 0.85 + flicker * 0.12)
			torches[i].light_energy = 1.15 + flicker * 0.22
	# Shared shader-free gem animation: no per-frame material allocation,
	# no physics, and no extra dynamic lights on mobile.
	if fx_enabled:
		for gem_index in range(board_gems.size()):
			var gem: MeshInstance3D = board_gems[gem_index]
			var phase: float = clock * 1.9 + float(gem_index) * 1.57
			gem.scale = Vector3.ONE * (1.0 + 0.10 * sin(phase))
			if visual_quality >= 2 and gem_index < board_gem_halos.size():
				var halo: MeshInstance3D = board_gem_halos[gem_index]
				halo.rotation.z = clock * 0.45 + float(gem_index)
				halo.scale = Vector3.ONE * (0.88 + 0.14 * sin(phase + 0.8))
	if visual_quality >= 2:
		for mote_index in range(ambient_motes.size()):
			var mote: MeshInstance3D = ambient_motes[mote_index]
			if not is_instance_valid(mote):
				continue
			var origin: Vector3 = ambient_mote_origins[mote_index]
			var wave: float = clock * (0.7 + float(mote_index % 4) * 0.12) + float(mote_index) * 0.91
			match current_region:
				0: # Forge embers rise in uneven hot-air columns.
					mote.position = origin + Vector3(0.12 * sin(wave), 0.35 * sin(wave * 0.7), 0.08 * cos(wave))
				1: # Snow crystals fall slowly and drift horizontally.
					mote.position = origin + Vector3(0.28 * sin(wave * 0.4), -0.32 * sin(wave * 0.6), 0.14 * cos(wave * 0.5))
				2: # Fireflies circle the forest canopy.
					mote.position = origin + Vector3(0.23 * cos(wave), 0.16 * sin(wave * 1.2), 0.23 * sin(wave))
				3: # Arcane dust orbits on slow ellipses.
					mote.position = origin + Vector3(0.33 * sin(wave * 0.9), 0.21 * cos(wave), 0.17 * cos(wave * 0.9))
				4: # Charged motes jitter rapidly in storm gusts.
					mote.position = origin + Vector3(0.16 * sin(wave * 4.1), 0.10 * sin(wave * 6.2), 0.18 * cos(wave * 3.6))
				5: # Void ash descends in a spiralling vortex.
					mote.position = origin + Vector3(0.20 * cos(wave * 1.3), -0.25 * sin(wave * 0.8), 0.20 * sin(wave * 1.3))
				_:
					mote.position = origin
	if fx_enabled:
		for n in range(biome_landmark_motion.size()):
			var accent: Dictionary = biome_landmark_motion[n]
			var landmark_mesh: MeshInstance3D = accent["node"]
			if not is_instance_valid(landmark_mesh): continue
			var phase: float = clock * (0.65 + float(n) * 0.13) + float(n) * 1.27
			var rest: Vector3 = accent["position"]
			landmark_mesh.position = rest + Vector3(0, sin(phase) * 0.085, 0)
			var rest_rotation: Vector3 = accent["rotation"]
			landmark_mesh.rotation = rest_rotation + Vector3(0, sin(phase * 0.65) * 0.15, 0)
	for n in range(animated_scenery.size()):
		if not fx_enabled: break
		var orb: MeshInstance3D = animated_scenery[n]
		if is_instance_valid(orb):
			orb.position.y = 1.60 + sin(clock * 1.8 + float(n) * 1.57) * 0.15
			orb.scale = Vector3.ONE * (0.85 + sin(clock * 2.7 + float(n)) * 0.12)
	if king_warning != null and king_warning.visible:
		var pulse: float = 1.0 + 0.12 * sin(clock * 7.0)
		king_warning.scale = Vector3(pulse, 1.0, pulse)
		king_warning.rotation.y = clock * 0.8
	for marker in hazard_markers:
		if marker.visible and fx_enabled:
			marker.scale = Vector3(0.91 + 0.07 * sin(clock * 5.0), 1.0, 0.91 + 0.07 * sin(clock * 5.0))
	if fx_enabled:
		for cell in poison_indicators.keys():
			var marker: MeshInstance3D = poison_indicators[cell]
			if is_instance_valid(marker):
				marker.position.y = 2.25 + 0.10 * sin(clock * 3.2 + float(cell) * 0.3)
		for cell in enemy_poison_indicators.keys():
			var marker: MeshInstance3D = enemy_poison_indicators[cell]
			if is_instance_valid(marker):
				marker.position.y = 2.03 + 0.13 * sin(clock * 4.1 + float(cell) * 0.45)
	if boss_enraged and visual_quality > 0 and piece_nodes.has(4):
		var boss_aura: Node3D = (piece_nodes[4] as Node3D).get_node_or_null("BossEnrageAura")
		if boss_aura != null and boss_aura.visible:
			boss_aura.rotation.y = clock * 0.8
			boss_aura.position.y = sin(clock * 2.1) * 0.06
	for index in piece_nodes.keys():
		if moving_nodes.has(index): continue
		var actor: Node3D = piece_nodes[index]
		if is_instance_valid(actor):
			if visual_quality > 0 and bool(actor.get_meta("selected_hero_piece", false)):
				var halo: Node3D = actor.find_child("HeroRarityHalo", true, false) as Node3D
				if halo != null:
					halo.rotation.y = clock * 0.65
					halo.position.y = 1.14 + 0.05 * sin(clock * 1.8)
			var idle_phase: float = clock * (0.83 if index == 4 else 1.15) + float(index) * 0.41
			actor.rotation.y = sin(idle_phase) * (0.09 if index == 4 and boss_enraged else 0.035)
			# Distinct subtle idle silhouettes: breathing and weight shift only.
			# No square-coordinate displacement; movement tweens own the actor while active.
			actor.rotation.z = sin(idle_phase * 0.72) * (0.014 if visual_quality >= 1 else 0.0)
			if index == 4 and boss_enraged:
				actor.position.y = 0.11 + sin(clock * 3.0) * 0.07
