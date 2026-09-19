extends CharacterBody3D
class_name Drill
signal boost_started
signal boost_ended
var lane := 0
var lane_offset := 2.5
var base_speed := 11.0
var is_boosting := false
var jump_velocity := 0.0
var slide_left := 0.0
var active := false
var anim: AnimationPlayer
var visual: Node3D
var last_anim := ""
var land_left := 0.0
var lane_left := 0.0
var lane_clip := "lane_left"
var boost_pose_left := 0.0

func _ready() -> void:
	visual = preload("res://Art/Models/explorer.glb").instantiate()
	add_child(visual)
	if has_node("/root/Profile"): get_node("/root/Profile").apply_skin(visual)
	anim = visual.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if anim:
		for key in anim.get_animation_list():
			if key.ends_with("run") or key.ends_with("idle") or key.ends_with("sprint"):
				anim.get_animation(key).loop_mode = Animation.LOOP_LINEAR
	play("idle")

func reset() -> void:
	lane = 0
	position = Vector3.ZERO
	jump_velocity = 0
	slide_left = 0
	land_left = 0
	lane_left = 0
	boost_pose_left = 0
	visual.rotation = Vector3.ZERO
	visual.scale = Vector3.ONE
	active = true
	play("run")

func tick(delta: float) -> void:
	var previous_x := position.x
	position.x = move_toward(position.x, lane * lane_offset, 15.0 * delta)
	jump_velocity -= 23.0 * delta
	var was_air := position.y > 0.0
	position.y = maxf(0, position.y + jump_velocity * delta)
	if position.y == 0:
		jump_velocity = 0
		if was_air: land_left = .22
	slide_left = maxf(0, slide_left - delta)
	land_left = maxf(0, land_left - delta)
	lane_left = maxf(0, lane_left - delta)
	boost_pose_left=maxf(0,boost_pose_left-delta)
	visual.scale = Vector3.ONE
	visual.rotation.z = lerpf(visual.rotation.z, (previous_x - position.x) * 1.0, delta * 12)
	if position.y > .05: play("jump" if jump_velocity>0 else "fall")
	elif slide_left > 0: play("slide")
	elif boost_pose_left>0: play("boost")
	elif land_left > 0: play("land")
	elif lane_left > 0: play(lane_clip)
	else: play("sprint" if base_speed>=17.5 else "run")
	if anim: anim.speed_scale=clampf(base_speed/14.0,.85,1.35) if last_anim in ["run","sprint"] else 1.0

func play(key: String) -> void:
	if key == last_anim: return
	last_anim = key
	if anim:
		for clip in anim.get_animation_list():
			if clip == key or clip.ends_with("/" + key) or clip.ends_with(key):
				anim.play(clip, .10)
				return

func go_left() -> void:
	lane = maxi(-1, lane - 1)
	lane_left = .24
	lane_clip="lane_left"
func go_right() -> void:
	lane = mini(1, lane + 1)
	lane_left = .24
	lane_clip="lane_right"
func jump() -> bool:
	if position.y > .01 or slide_left > 0: return false
	jump_velocity = 9.5
	return true
func slide() -> bool:
	if position.y > .01 or slide_left > 0: return false
	slide_left = .8
	return true
func get_current_speed() -> float:
	return base_speed

func boost_pose() -> void:
	boost_pose_left=.48
	last_anim=""
	play("boost")
