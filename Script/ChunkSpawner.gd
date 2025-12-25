extends Node3D

@export var chunk_scene: PackedScene
@export var chunks_count: int = 10
@export var chunk_length: float = 12.0
@export var spawn_z_start: float = -24.0

@export var recycle_margin: float = 6.0  # чтобы переразмещение было "за камерой", без поп-ин

@onready var drill: CharacterBody3D = $"../Drill"
@onready var cam: Camera3D = $"../Camera3D"

var chunks: Array[Node3D] = []

func _ready() -> void:
	if chunk_scene == null:
		push_error("ChunkSpawner: chunk_scene not assigned!")
		return

	randomize()

	# создаём "ленту" из чанков: один за другим в минус Z
	for i in range(chunks_count):
		var c: Node3D = chunk_scene.instantiate()
		add_child(c)
		c.global_position = Vector3(0.0, 0.0, spawn_z_start - float(i) * chunk_length)
		_add_obstacles(c)
		chunks.append(c)

func _physics_process(delta: float) -> void:
	if chunks.is_empty():
		return

	var speed: float = 10.0
	# если у Drill есть метод скорости — используем
	if drill.has_method("get_current_speed"):
		speed = float(drill.call("get_current_speed"))

	# двигаем чанки к камере (в +Z)
	for c in chunks:
		c.global_position.z += speed * delta

	# переразмещение чанка, когда он УЖЕ ЗА КАМЕРОЙ (чтобы не было видно стыков)
	var recycle_z: float = cam.global_position.z + recycle_margin

	var first: Node3D = chunks[0]
	if first.global_position.z > recycle_z:
		var last: Node3D = chunks[chunks.size() - 1]

		# переносим первый чанк в конец ленты (далеко вперед/назад по -Z)
		first.global_position.z = last.global_position.z - chunk_length

		_clear_obstacles(first)
		_add_obstacles(first)

		chunks.pop_front()
		chunks.append(first)

func _add_obstacles(chunk: Node3D) -> void:
	# 0..2 препятствия на чанк
	var n: int = randi() % 3
	for i in range(n):
		var o: StaticBody3D = StaticBody3D.new()
		o.name = "Obstacle"
		chunk.add_child(o)

		var mesh: MeshInstance3D = MeshInstance3D.new()
		mesh.mesh = BoxMesh.new()
		mesh.scale = Vector3(0.7, 0.9, 0.7)
		o.add_child(mesh)

		var col: CollisionShape3D = CollisionShape3D.new()
		var shape: BoxShape3D = BoxShape3D.new()
		shape.size = Vector3(1.0, 1.2, 1.0)
		col.shape = shape
		o.add_child(col)

		# три полосы: -1,0,1
		var lane: int = (randi() % 3) - 1
		var x: float = float(lane) * 2.5

		# ставим препятствие ВНУТРИ чанка по -Z (перед игроком)
		var z: float = -2.0 - float(randi() % 8)
		o.position = Vector3(x, 0.6, z)

func _clear_obstacles(chunk: Node3D) -> void:
	for child in chunk.get_children():
		if child is Node and child.name == "Obstacle":
			child.queue_free()
