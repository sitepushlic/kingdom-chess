extends Node3D
## Real-time 3D battlefield rendered into a SubViewport. Coordinates are shared with chess logic.
const TILE := 1.0
var piece_nodes: Dictionary = {}
var piece_types: Dictionary = {}
var moving_nodes: Dictionary = {}
var clock := 0.0
var camera: Camera3D
var highlights: Array[MeshInstance3D] = []
var tiles: Array[MeshInstance3D] = []
var hero_material: StandardMaterial3D
var enemy_material: StandardMaterial3D
var gold_material: StandardMaterial3D
var dark_material: StandardMaterial3D
var board_root: Node3D

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

func _ready() -> void:
	hero_material = _material(Color("#d8e4f3"), 0.55)
	enemy_material = _material(Color("#57283e"), 0.45)
	gold_material = _material(Color("#d9ad57"), 0.78, 0.25)
	dark_material = _material(Color("#1a2638"), 0.4)
	var world := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("#0b1422")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#7c92b1")
	env.ambient_light_energy = 0.6
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	world.environment = env
	add_child(world)
	board_root = Node3D.new()
	add_child(board_root)
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
	for x in [-4.45, 4.45]:
		for z in [-4.45, 4.45]:
			_cylinder(0.19, 0.85, gold_material, board_root, Vector3(x, -0.15, z))
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-55, -28, 0)
	key.light_color = Color("#ffe2b7")
	key.light_energy = 1.5
	key.shadow_enabled = true
	add_child(key)
	var rim := OmniLight3D.new()
	rim.position = Vector3(-3, 5, -3)
	rim.light_color = Color("#729bff")
	rim.light_energy = 1.6
	rim.omni_range = 16.0
	add_child(rim)
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 12.7
	camera.position = Vector3(0, 11.8, 8.7)
	add_child(camera)
	camera.look_at(Vector3(0, 0, 0))
	camera.current = true

func _square_position(index: int) -> Vector3:
	return Vector3(float(index % 8) - 3.5, 0.11, float(index / 8) - 3.5)

func _build_piece(letter: String) -> Node3D:
	var unit := Node3D.new()
	var white := letter == letter.to_upper()
	var material := hero_material if white else enemy_material
	var accent := gold_material if white else dark_material
	_cylinder(0.31, 0.16, accent, unit, Vector3(0, 0.08, 0))
	_cylinder(0.24, 0.09, material, unit, Vector3(0, 0.21, 0))
	var kind := letter.to_upper()
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
	unit.scale = Vector3.ONE * 0.84
	board_root.add_child(unit)
	return unit

func sync_board(pieces: Array, selected: int, legal_squares: Array, danger: int) -> void:
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
			var node := _build_piece(piece)
			node.position = _square_position(index)
			piece_nodes[index] = node
			piece_types[index] = piece
		highlights[index].visible = index == selected or legal_squares.has(index) or index == danger
		if highlights[index].visible:
			highlights[index].material_override = _material(Color("#f6c76b") if index == selected else (Color("#ed5c65") if index == danger else Color("#61d7b6")), 0.2, 0.3, Color("#9d5732"))
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
	var tween := create_tween()
	tween.tween_property(actor, "position", destination + Vector3(0, 0.9, 0), 0.19).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(actor, "position", destination, 0.22).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func(): moving_nodes.erase(target))

func hit(index: int, healing: bool = false) -> void:
	if not piece_nodes.has(index): return
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
	for index in piece_nodes.keys():
		if moving_nodes.has(index): continue
		var actor: Node3D = piece_nodes[index]
		if is_instance_valid(actor):
			actor.rotation.y = sin(clock * 0.6 + float(index)) * 0.035
