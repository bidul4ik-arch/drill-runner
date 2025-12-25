# res://Script/Main.gd
extends Node3D

@onready var drill: CharacterBody3D = $Drill
@onready var score_label: Label = $UI/ScoreLabel

var score: int = 0
var touch_start_pos: Vector2
var touch_active := false

func _process(delta: float) -> void:
	# условный скор (растёт со временем)
	score += int(60 * delta)
	score_label.text = "Score: %d" % score

func _unhandled_input(event: InputEvent) -> void:
	# ПК для теста
	if event.is_action_pressed("ui_left"):
		drill.go_left()
	elif event.is_action_pressed("ui_right"):
		drill.go_right()

	# мобилка: свайпы
	if event is InputEventScreenTouch:
		if event.pressed:
			touch_start_pos = event.position
			touch_active = true
		else:
			touch_active = false

	if event is InputEventScreenDrag and touch_active:
		var delta_pos = event.position - touch_start_pos
		if abs(delta_pos.x) > 60: # порог
			if delta_pos.x > 0:
				drill.go_right()
			else:
				drill.go_left()
			touch_start_pos = event.position
