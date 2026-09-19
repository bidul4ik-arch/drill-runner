extends Node
var failures:=0
func check(ok: bool,label: String) -> void:
	if not ok:failures+=1;push_error(label)
func _ready() -> void:call_deferred("run")
func run() -> void:
	var player=preload("res://Scenes/Actors/Player.tscn").instantiate();add_child(player)
	await get_tree().process_frame
	player.reset();player.tick(.016);check(player.last_anim=="run","Normal run")
	player.base_speed=20;player.tick(.016);check(player.last_anim=="sprint","Fast run")
	player.go_left();player.tick(.016);check(player.last_anim=="lane_left","Left lane")
	player.go_right();player.tick(.016);check(player.last_anim=="lane_right","Right lane")
	player.jump();player.tick(.1);check(player.last_anim=="jump","Jump ascent")
	for i in 25:player.tick(.016)
	check(player.last_anim=="fall","Jump descent")
	for i in 60:
		player.tick(.016)
		if player.last_anim=="land":break
	check(player.last_anim=="land","Landing")
	player.slide();player.tick(.1);check(player.last_anim=="slide","Prone slide")
	check(not player.slide(),"Repeated slide cannot extend collider beyond animation")
	var sk: Skeleton3D=player.visual.find_child("Skeleton3D",true,false)
	player.anim.play("idle");player.anim.seek(.1,true);player.anim.pause();sk.force_update_all_bone_transforms()
	var standing: float=sk.get_bone_global_pose(sk.find_bone("head")).origin.y
	player.anim.play("slide");player.anim.seek(.4,true);player.anim.pause();sk.force_update_all_bone_transforms()
	var sliding: float=sk.get_bone_global_pose(sk.find_bone("head")).origin.y
	check(sliding<standing*.45,"Slide skeleton genuinely lowers head")
	check(player.visual.scale==Vector3.ONE,"No squash")
	player.reset();player.boost_pose();player.tick(.016);check(player.last_anim=="boost","Drill burst")
	for clip in ["idle","run","sprint","jump","fall","land","slide","lane_left","lane_right","boost","hit","victory"]:
		check(player.anim.has_animation(clip),"Clip "+clip)
		player.play(clip);player.anim.seek(.1,true)
	await RenderingServer.frame_post_draw
	player.queue_free();await get_tree().process_frame;await get_tree().process_frame
	print("HERO CONTROLLER: ",failures," failures")
	get_tree().quit(failures)
