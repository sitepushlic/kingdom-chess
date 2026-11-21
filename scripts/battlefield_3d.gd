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
var poison_indicators: Dictionary = {}
var active_hazards: Array[int] = []
var hazard_type := ""
var hazard_materials: Dictionary = {}
var tiles: Array[MeshInstance3D] = []
var hero_material: StandardMaterial3D
var enemy_material: StandardMaterial3D
var gold_material: StandardMaterial3D
var dark_material: StandardMaterial3D
var board_root: Node3D
var region_scenery: Node3D
var animated_scenery: Array[MeshInstance3D] = []
var torches: Array[OmniLight3D] = []
var world_environment: WorldEnvironment
var key_light: DirectionalLight3D
var rim_light: OmniLight3D
var torch_flames: Array[MeshInstance3D] = []
var current_region := -1
var gear_signature := ""
var hero_gear: Dictionary = {}
var boss_crown: Material
var attack_effects: Array[Node3D] = []
var base_camera_position := Vector3(0, 11.8, 8.7)
var boss_enraged := false
var selection_material: StandardMaterial3D
var danger_material: StandardMaterial3D
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
	var mesh := BoxMesh.new()
	mesh.size = size
	instance.mesh = mesh
	instance.material_override = material
	instance.position = at
	parent.add_child(instance)
	return instance

func _cylinder(radius: float, height: float, material: Material, parent: Node3D, at: Vector3, top_radius: float = -1.0) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.bottom_radius = radius
	mesh.top_radius = radius if top_radius < 0.0 else top_radius
	mesh.height = height
	mesh.radial_segments = 16
	instance.mesh = mesh
	instance.material_override = material
	instance.position = at
	parent.add_child(instance)
	return instance

func _sphere(radius: float, material: Material, parent: Node3D, at: Vector3) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 12
	mesh.rings = 6
	instance.mesh = mesh
	instance.material_override = material
	instance.position = at
	parent.add_child(instance)
	return instance

func _ring(major_radius: float, tube_radius: float, material: Material, parent: Node3D, at: Vector3) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	var mesh := TorusMesh.new()
	mesh.inner_radius = major_radius - tube_radius
	mesh.outer_radius = major_radius + tube_radius
	mesh.rings = 8
	mesh.ring_segments = 24
	instance.mesh = mesh
	instance.material_override = material
	instance.position = at
	parent.add_child(instance)
	return instance

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
	for i in range(64):
		var x := float(i % 8) - 3.5
		var z := float(i / 8) - 3.5
		var tile_mat := _material(Color("#28384b") if (i / 8 + i % 8) % 2 == 0 else Color("#b7a58c"), 0.22)
		tiles.append(_box(Vector3(0.985, 0.10, 0.985), tile_mat, board_root, Vector3(x, 0, z)))
		var marker := _cylinder(0.43, 0.025, _material(Color("#63e4bc"), 0.15, 0.4, Color("#4dd5a9")), board_root, Vector3(x, 0.078, z))
		marker.visible = false
		highlights.append(marker)
		var hazard_marker := _cylinder(0.47, 0.017, hazard_materials["frost"], board_root, Vector3(x, 0.096, z))
		hazard_marker.visible = false
		hazard_marker.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		hazard_markers.append(hazard_marker)
	for x in [-4.45, 4.45]:
		for z in [-4.45, 4.45]:
			_cylinder(0.24, 0.18, dark_material, board_root, Vector3(x, -0.12, z))
			_cylinder(0.17, 1.25, _material(Color("#56515c"), 0.3), board_root, Vector3(x, 0.50, z))
			_cylinder(0.29, 0.13, gold_material, board_root, Vector3(x, 1.13, z))
			var flame := _sphere(0.17, _material(Color("#ffb448"), 0.0, 0.2, Color("#ff681c")), board_root, Vector3(x, 1.40, z))
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
	key.shadow_enabled = true
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
	for index in piece_nodes.keys():
		var node: Node3D = piece_nodes[index]
		node.queue_free()
	piece_nodes.clear()
	piece_types.clear()
	moving_nodes.clear()

func _gear_material(slot: String) -> Material:
	if not hero_gear.has(slot): return gold_material
	var item: Dictionary = hero_gear[slot]
	var rarity := clampi(int(item.get("rarity", 0)), 0, 6)
	var palette := [Color("#b9c6d5"), Color("#62c7b6"), Color("#548dea"), Color("#aa78f5"), Color("#efac57"), Color("#e96d86"), Color("#fff0a4")]
	return _material(palette[rarity], 0.82, 0.23, palette[rarity] * (0.18 + float(int(item.get("upgrade", 0))) * 0.04))

# Physical rarity marks are deliberately countable at mobile scale; the seven tiers
# have distinct silhouettes, not only different shader colors.
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
	# Prefer original authored OBJ mesh if supplied; imported rigged GLB remains supported.
	var obj_path := "res://assets/characters/%s.obj" % str({"P":"pawn","R":"rook","N":"knight","B":"bishop","Q":"queen","K":"king"}.get(kind, ""))
	if ResourceLoader.exists(obj_path):
		var mesh_resource: Resource = load(obj_path)
		if mesh_resource is Mesh:
			var instance := MeshInstance3D.new()
			instance.name = "AuthoredCharacter"
			instance.mesh = mesh_resource as Mesh
			instance.material_override = hero_material if parent.get_meta("hero", true) else enemy_material
			parent.add_child(instance)
			return true
	var path: String = str(CHARACTER_SCENE_PATHS.get(kind, ""))
	if path == "" or not ResourceLoader.exists(path): return false
	var scene: Resource = load(path)
	if not (scene is PackedScene): return false
	var model: Node = (scene as PackedScene).instantiate()
	if not (model is Node3D):
		model.free()
		return false
	model.name = "AuthoredCharacter"
	parent.add_child(model)
	return true

func _build_piece(letter: String, is_boss: bool = false) -> Node3D:
	var unit := Node3D.new()
	var white := letter == letter.to_upper()
	unit.set_meta("hero", white)
	var material := hero_material if white else enemy_material
	var accent := gold_material if white else dark_material
	_cylinder(0.31, 0.16, accent, unit, Vector3(0, 0.08, 0))
	_cylinder(0.24, 0.09, material, unit, Vector3(0, 0.21, 0))
	# Layered cast-metal plinth, raised rim and a sculpted class-specific heraldic emblem.
	_ring(0.29, 0.028, gold_material if white else boss_crown, unit, Vector3(0, 0.155, 0))
	_ring(0.235, 0.016, accent, unit, Vector3(0, 0.265, 0))

	var kind := letter.to_upper()
	if not _load_authored_character(kind, unit):
		# Procedural fallback remains usable until each class receives an original GLB.
		if kind == "P":
			_cylinder(0.17, 0.45, material, unit, Vector3(0, 0.47, 0), 0.11)
			_sphere(0.16, accent, unit, Vector3(0, 0.78, 0))
		elif kind == "R":
			_cylinder(0.22, 0.7, material, unit, Vector3(0, 0.58, 0))
			_cylinder(0.31, 0.14, accent, unit, Vector3(0, 0.98, 0))
			for n in range(4):
				var a := float(n) * TAU / 4.0
				_box(Vector3(0.17, 0.19, 0.17), accent, unit, Vector3(cos(a) * 0.22, 1.13, sin(a) * 0.22))
		elif kind == "N":
			_cylinder(0.2, 0.34, material, unit, Vector3(0, 0.40, 0), 0.13)
			_box(Vector3(0.27, 0.58, 0.24), material, unit, Vector3(0, 0.76, -0.10))
			_box(Vector3(0.27, 0.22, 0.44), accent, unit, Vector3(0, 1.01, -0.22))
			_sphere(0.055, gold_material, unit, Vector3(-0.15, 0.94, -0.31))
		elif kind == "B":
			_cylinder(0.22, 0.62, material, unit, Vector3(0, 0.57, 0), 0.11)
			_sphere(0.22, accent, unit, Vector3(0, 0.97, 0))
			_cylinder(0.05, 0.20, gold_material, unit, Vector3(0, 1.25, 0))
		elif kind == "Q":
			_cylinder(0.23, 0.75, material, unit, Vector3(0, 0.62, 0), 0.13)
			_cylinder(0.28, 0.11, accent, unit, Vector3(0, 1.04, 0))
			for n in range(5):
				var a := float(n) * TAU / 5.0
				_sphere(0.095, gold_material, unit, Vector3(cos(a) * 0.23, 1.19, sin(a) * 0.23))
		else:
			_cylinder(0.24, 0.82, material, unit, Vector3(0, 0.65, 0), 0.14)
			_cylinder(0.27, 0.12, accent, unit, Vector3(0, 1.12, 0))
			_box(Vector3(0.12, 0.47, 0.12), gold_material, unit, Vector3(0, 1.41, 0))
			_box(Vector3(0.37, 0.10, 0.12), gold_material, unit, Vector3(0, 1.48, 0))
	# Each class has an identifiable elevated crest, even at portrait mobile scale.
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
		var shadow_ring := _cylinder(0.43, 0.035, boss_crown, unit, Vector3(0, 0.12, 0))
		shadow_ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
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
	if white and not hero_gear.is_empty():
		if hero_gear.has("Тело"):
			var armor_mat := _gear_material("Тело")
			_add_rarity_insignia("Тело", unit, Vector3(0, 0.52, -0.26))
			_cylinder(0.29, 0.15, armor_mat, unit, Vector3(0, 0.32, 0))
			for side in [-1.0, 1.0]:
				_box(Vector3(0.12, 0.28, 0.28), armor_mat, unit, Vector3(side * 0.27, 0.48, 0))
		if hero_gear.has("Оружие"):
			var weapon_mat := _gear_material("Оружие")
			_add_rarity_insignia("Оружие", unit, Vector3(0.42, 1.15, 0))
			_cylinder(0.045, 0.82, weapon_mat, unit, Vector3(0.42, 0.68, 0))
			_box(Vector3(0.33, 0.065, 0.13), weapon_mat, unit, Vector3(0.42, 0.87, 0))
			_cylinder(0.09, 0.21, weapon_mat, unit, Vector3(0.42, 1.13, 0), 0.015)
		if hero_gear.has("Реликвия"):
			var relic_mat := _gear_material("Реликвия")
			_add_rarity_insignia("Реликвия", unit, Vector3(-0.39, 0.83, 0))
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

func set_boss_phase(phase: int) -> void:
	var enraged := phase >= 2
	if boss_enraged == enraged: return
	boss_enraged = enraged
	if piece_nodes.has(4) and piece_types.get(4, "") == "k":
		var boss: Node3D = piece_nodes[4]
		var burst := create_tween()
		burst.tween_property(boss, "scale", Vector3.ONE * (1.42 if enraged else 1.12), 0.24).set_trans(Tween.TRANS_BACK)
		boss_crown.albedo_color = Color("#ff2c5f") if enraged else Color("#e56587")
		boss_crown.emission_energy_multiplier = 2.8 if enraged else 0.6

func _rebuild_region_scenery(region_index: int, palette: Array) -> void:
	# All scenery remains outside the playable 8x8 grid; animate only four landmark accents.
	animated_scenery.clear()
	for child in region_scenery.get_children():
		region_scenery.remove_child(child)
		child.queue_free()
	var region := clampi(region_index, 0, 5)
	var stone := _material(palette[0].lightened(0.20), 0.25, 0.68)
	var trim := _material(palette[1].darkened(0.28), 0.48, 0.38)
	var magic := _material(palette[2], 0.22, 0.20, palette[2] * 0.65)
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
	for index in range(tiles.size()):
		var mat: StandardMaterial3D = tiles[index].material_override
		mat.albedo_color = palette[0] if (int(index / 8) + index % 8) % 2 == 0 else palette[1]
	for torch in torches:
		torch.light_color = palette[2]
	# Region lighting changes the actual 3D scene, not just tile colours.
	# Keep ambient illumination high enough to distinguish pieces on mobile.
	var environment: Environment = world_environment.environment
	environment.background_color = palette[0].darkened(0.72)
	environment.ambient_light_color = palette[1].lightened(0.20)
	key_light.light_color = palette[1].lightened(0.35)
	rim_light.light_color = palette[2]
	rim_light.light_energy = 1.25 if region_index == 5 else 1.6
	_rebuild_region_scenery(region_index, palette)

func set_hazards(cells: Array[int], modifier: String) -> void:
	if active_hazards == cells and hazard_type == modifier: return
	active_hazards = cells.duplicate()
	hazard_type = modifier
	var material: Material = hazard_materials.get(modifier, hazard_materials["frost"])
	for index in range(hazard_markers.size()):
		var marker: MeshInstance3D = hazard_markers[index]
		marker.visible = cells.has(index)
		if marker.visible: marker.material_override = material

func set_poison_indicators(statuses: Dictionary) -> void:
	for cell in poison_indicators.keys():
		if not statuses.has(cell):
			(poison_indicators[cell] as MeshInstance3D).queue_free()
			poison_indicators.erase(cell)
	for cell in statuses.keys():
		if typeof(cell) != TYPE_INT or cell < 0 or cell >= 64: continue
		if int(statuses[cell]) <= 0 or poison_indicators.has(cell): continue
		var marker := _sphere(0.13, hazard_materials["poison"], board_root, _square_position(cell) + Vector3(0, 2.25, 0))
		marker.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		poison_indicators[cell] = marker

func sync_board(pieces: Array, selected: int, legal_squares: Array, danger: int, health: Array = [], max_health: Array = []) -> void:
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
			var node := _build_piece(piece, index == 4 and piece == "k")
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

func animate_move(source: int, target: int) -> void:
	if not piece_nodes.has(source): return
	var actor: Node3D = piece_nodes[source]
	if piece_nodes.has(target):
		var victim: Node3D = piece_nodes[target]
		var vanish := create_tween()
		vanish.tween_property(victim, "scale", Vector3.ZERO, 0.18)
		vanish.tween_callback(victim.queue_free)
		piece_nodes.erase(target)
		piece_types.erase(target)
	piece_nodes.erase(source)
	piece_types[target] = piece_types[source]
	piece_types.erase(source)
	piece_nodes[target] = actor
	moving_nodes[target] = true
	var destination := _square_position(target)
	var move_rig: Node3D = actor.get_meta("visual_rig", null)
	if move_rig != null:
		var lean := create_tween()
		lean.tween_property(move_rig, "rotation:z", -0.16, 0.15)
		lean.tween_property(move_rig, "rotation:z", 0.08, 0.18)
		lean.tween_property(move_rig, "rotation:z", 0.0, 0.10)
		var authored: Node = move_rig.get_node_or_null("AuthoredCharacter")
		if authored != null:
			var move_player: AnimationPlayer = authored.find_child("AnimationPlayer", true, false) as AnimationPlayer
			if move_player != null and move_player.has_animation("move"):
				move_player.play("move")
	var tween := create_tween()
	tween.tween_property(actor, "position", destination + Vector3(0, 0.9, 0), 0.19).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(actor, "position", destination, 0.22).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func(): moving_nodes.erase(target))

func attack(source: int, target: int, magical: bool = false) -> void:
	if not piece_nodes.has(source): return
	var attacker: Node3D = piece_nodes[source]
	var start: Vector3 = _square_position(source)
	var end: Vector3 = _square_position(target)
	var direction: Vector3 = (end - start).normalized()
	var rig: Node3D = attacker.get_meta("visual_rig", null)
	if rig != null:
		var swing := create_tween()
		swing.tween_property(rig, "rotation", Vector3(-0.18, 0.24 if magical else -0.22, -0.26), 0.12).set_trans(Tween.TRANS_QUAD)
		swing.tween_property(rig, "rotation", Vector3(0.22, -0.28 if magical else 0.32, 0.30), 0.13).set_trans(Tween.TRANS_QUART)
		swing.tween_property(rig, "rotation", Vector3.ZERO, 0.18).set_trans(Tween.TRANS_BACK)
		var model: Node = rig.get_node_or_null("AuthoredCharacter")
		if model != null:
			var player: AnimationPlayer = model.find_child("AnimationPlayer", true, false) as AnimationPlayer
			if player != null and player.has_animation("attack"):
				player.play("attack")
	var anticipation := create_tween()
	anticipation.tween_property(attacker, "position", start - direction * 0.16 + Vector3(0, 0.10, 0), 0.11).set_trans(Tween.TRANS_CUBIC)
	anticipation.tween_property(attacker, "position", start + direction * 0.25 + Vector3(0, 0.19, 0), 0.12).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	anticipation.tween_property(attacker, "position", start, 0.17).set_trans(Tween.TRANS_BACK)
	var beam := MeshInstance3D.new()
	var beam_mesh := CylinderMesh.new()
	beam_mesh.top_radius = 0.045 if magical else 0.075
	beam_mesh.bottom_radius = 0.09 if magical else 0.13
	beam_mesh.height = maxi(0.1, start.distance_to(end))
	beam_mesh.radial_segments = 10
	beam.mesh = beam_mesh
	var color := Color("#a978ff") if magical else Color("#ffd08a")
	var mat := _material(color, 0.15, 0.18, color)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	beam.material_override = mat
	beam.position = (start + end) * 0.5 + Vector3(0, 0.8, 0)
	beam.quaternion = Quaternion(Vector3.UP, (end - start).normalized())
	beam.scale = Vector3(0.01, 0.01, 0.01)
	board_root.add_child(beam)
	var slash := create_tween()
	slash.tween_property(beam, "scale", Vector3(1, 1, 1), 0.10).set_trans(Tween.TRANS_CUBIC)
	slash.tween_property(beam, "transparency", 1.0, 0.24)
	slash.tween_callback(beam.queue_free)
	var camera_shake := create_tween()
	camera_shake.tween_property(camera, "position", base_camera_position + Vector3(0.09, -0.06, 0), 0.045)
	camera_shake.tween_property(camera, "position", base_camera_position + Vector3(-0.07, 0.04, 0), 0.055)
	camera_shake.tween_property(camera, "position", base_camera_position, 0.11)

func hit(index: int, healing: bool = false) -> void:
	if not piece_nodes.has(index): return
	var shock := MeshInstance3D.new()
	var shock_mesh := TorusMesh.new()
	shock_mesh.inner_radius = 0.23
	shock_mesh.outer_radius = 0.33
	shock_mesh.rings = 12
	shock_mesh.ring_segments = 20
	shock.mesh = shock_mesh
	var flash_material := _material(Color("#6ef7c2") if healing else Color("#ff855d"), 0.0, 0.3, Color("#4de6a8") if healing else Color("#ff431e"))
	flash_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	shock.material_override = flash_material
	shock.position = _square_position(index) + Vector3(0, 0.10, 0)
	shock.scale = Vector3.ONE * 0.2
	board_root.add_child(shock)
	var shock_tween := create_tween()
	shock_tween.set_parallel(true)
	shock_tween.tween_property(shock, "scale", Vector3.ONE * 2.3, 0.42).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	shock_tween.tween_property(shock, "transparency", 1.0, 0.42)
	shock_tween.chain().tween_callback(shock.queue_free)
	var actor: Node3D = piece_nodes[index]
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

func _process(delta: float) -> void:
	clock += delta
	for i in range(torch_flames.size()):
		var flicker := sin(clock * (6.0 + float(i) * 0.27) + float(i) * 1.7)
		torch_flames[i].scale = Vector3(0.85 + flicker * 0.12, 1.2 + flicker * 0.24, 0.85 + flicker * 0.12)
		torches[i].light_energy = 1.15 + flicker * 0.22
	for n in range(animated_scenery.size()):
		var orb: MeshInstance3D = animated_scenery[n]
		if is_instance_valid(orb):
			orb.position.y = 1.60 + sin(clock * 1.8 + float(n) * 1.57) * 0.15
			orb.scale = Vector3.ONE * (0.85 + sin(clock * 2.7 + float(n)) * 0.12)
	for marker in hazard_markers:
		if marker.visible:
			marker.scale = Vector3(0.91 + 0.07 * sin(clock * 5.0), 1.0, 0.91 + 0.07 * sin(clock * 5.0))
	for index in piece_nodes.keys():
		if moving_nodes.has(index): continue
		var actor: Node3D = piece_nodes[index]
		if is_instance_valid(actor):
			actor.rotation.y = sin(clock * 0.6 + float(index)) * (0.09 if index == 4 and boss_enraged else 0.035)
			if index == 4 and boss_enraged:
				actor.position.y = 0.11 + sin(clock * 3.0) * 0.07
