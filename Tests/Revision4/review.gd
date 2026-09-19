extends Node
func _ready() -> void:call_deferred("run")
func shot(name: String) -> void:
	for i in 8:await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://Tests/Revision4/"+name+".png")
func run() -> void:
	Flow.resume_checkpoint=false;Flow.resume_run=false
	var game=load(Profile.level(1).scene).instantiate();add_child(game)
	await get_tree().process_frame
	game.set_physics_process(false);game.start_run();game.immunity=999
	for i in 120:game._physics_process(1.0/60)
	game.drill.anim.play("run");game.drill.anim.seek(.17,true);game.drill.anim.pause()
	await shot("gameplay")
	for side in [-1,1]:
		game.drill.lane=side
		for i in 25:game._physics_process(1.0/60)
		game.drill.anim.play("run");game.drill.anim.seek(.17,true);game.drill.anim.pause()
		await shot("lane-"+str(side))
	game.drill.lane=0
	for i in 25:game._physics_process(1.0/60)
	game.drill.slide();game._physics_process(.1)
	game.drill.anim.play("slide");game.drill.anim.seek(.4,true);game.drill.anim.pause()
	await shot("slide")
	game.powerup("shield");game.powerup("magnet");game.elapsed=10;game.drill.slide_left=0
	game._physics_process(.016)
	await shot("buffs")
	game.begin_boss()
	for i in 200:game._physics_process(1.0/60)
	game.boss.begin_weak();game.drill.position.x=game.boss.weak_lane*2.5;game.drill.lane=game.boss.weak_lane
	game.update_presentation(.5);game.boost()
	await shot("combo")
	game.queue_free();await get_tree().process_frame;await get_tree().process_frame
	var home=load("res://Scenes/Screens/Home.tscn").instantiate();add_child(home)
	await get_tree().process_frame
	home.wardrobe()
	await shot("wardrobe")
	print("REVISION4 VISUAL CAPTURE COMPLETE")
	get_tree().quit()
