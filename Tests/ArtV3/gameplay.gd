extends Node
func _ready() -> void:call_deferred("run")
func shot(name: String) -> void:
	for i in 8:await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://Tests/ArtV3/"+name+".png")
func run() -> void:
	Flow.resume_checkpoint=false;Flow.resume_run=false
	for id in [1,2,3]:
		var game=load(Profile.level(id).scene).instantiate();add_child(game)
		await get_tree().process_frame
		game.set_physics_process(false);game.start_run()
		for i in 150:game._physics_process(1.0/60)
		if game.state!="run":
			push_error("Capture must show a live run")
			get_tree().quit(1)
			return
		game.drill.anim.play("run");game.drill.anim.seek(.17,true);game.drill.anim.pause()
		await shot("gameplay-%d" % id)
		game.begin_boss()
		for i in 250:game._physics_process(1.0/60)
		game.drill.anim.play("run");game.drill.anim.seek(.17,true);game.drill.anim.pause()
		await shot("boss-%d" % id)
		game.queue_free();await get_tree().process_frame;await get_tree().process_frame
	print("FINAL GAMEPLAY CAPTURED")
	get_tree().quit()
