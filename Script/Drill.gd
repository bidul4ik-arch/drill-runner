extends CharacterBody3D
class_name Drill

@export var lane_offset: float = 2.5
@export var lane_change_speed: float = 12.0

@export var base_speed: float = 10.0
@export var boost_speed: float = 18.0
@export var boost_time: float = 1.2

var lane: int = 0 # -1,0,1
var is_boosting: bool = false

var _boost_left: float = 0.0
var _target_x: float = 0.0

func _ready() -> void:
	_target_x = lane * lane_offset

func _physics_process(delta: float) -> void:
	# lane move (плавно)
	_target_x = lane * lane_offset
	var p := global_position
	p.x = lerp(p.x, _target_x, lane_change_speed * delta)
	global_position = p

	# boost timer
	if _boost_left > 0.0:
		_boost_left -= delta
		if _boost_left <= 0.0:
			_boost_left = 0.0
			is_boosting = false

	# (если хочешь — тут можно добавить столкновения/прыжки и т.д.)

func go_left() -> void:
	lane = clamp(lane - 1, -1, 1)

func go_right() -> void:
	lane = clamp(lane + 1, -1, 1)

func start_boost() -> void:
	is_boosting = true
	_boost_left = boost_time

func get_current_speed() -> float:
	return boost_speed if is_boosting else base_speed
