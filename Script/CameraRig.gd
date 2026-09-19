extends Node3D

@onready var cam: Camera3D = $Camera3D
@onready var drill: CharacterBody3D = $"../Drill"

@export var normal_fov: float = 70.0
@export var boost_fov: float = 85.0
@export var fov_speed: float = 6.0

var target_fov: float

func _ready() -> void:
	target_fov = normal_fov
	cam.fov = normal_fov

	# Подписываемся на сигналы буста
	drill.boost_started.connect(_on_boost_started)
	drill.boost_ended.connect(_on_boost_ended)

func _process(delta: float) -> void:
	cam.fov = lerp(cam.fov, target_fov, fov_speed * delta)

func _on_boost_started() -> void:
	target_fov = boost_fov

func _on_boost_ended() -> void:
	target_fov = normal_fov
