extends Camera3D

@export var drill_path: NodePath = NodePath("../Drill")

@export var normal_fov: float = 70.0
@export var boost_fov: float = 82.0
@export var smooth: float = 6.0

var drill: Drill

func _ready() -> void:
	drill = get_node(drill_path) as Drill
	if drill == null:
		push_error("CameraBoost: Drill not found. Проверь drill_path в инспекторе (обычно ../Drill).")

func _process(delta: float) -> void:
	if drill == null:
		return

	var target_fov := boost_fov if drill.is_boosting else normal_fov
	fov = lerp(fov, target_fov, smooth * delta)
