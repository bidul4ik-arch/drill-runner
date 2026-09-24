extends Node
func _ready() -> void:call_deferred("run")
func run() -> void:
	if not "--test" in OS.get_cmdline_user_args():get_tree().quit(2);return
	Profile.data.skin="explorer";Profile.data.cap=false;Profile.data.quality=1
	TranslationServer.set_locale("ru")
	for id in [1,2,3]:
		var game=load(Profile.level(id).scene).instantiate();add_child(game)
		await get_tree().process_frame
		game.start_run();game.immunity=999;game.set_physics_process(false)
		game.belt.rng.seed=2409;game.belt.reset()
		for i in 170:
			var nearest: Node3D
			for chunk in game.belt.chunks:
				if chunk.position.z<6.2 and (nearest==null or chunk.position.z>nearest.position.z):nearest=chunk
			if nearest:
				var lane=int(nearest.get_meta("safe_lane"))
				while game.drill.lane<lane:game.drill.go_right()
				while game.drill.lane>lane:game.drill.go_left()
			game._physics_process(1.0/60)
		game.fx_left=0;game.flash.color.a=0
		for i in 8:await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var renderer=preload("res://Script/Services/Graphics.gd").renderer()
		get_viewport().get_texture().get_image().save_png("res://Tests/Environment/level-%s-%s.png"%[id,renderer])
		game.queue_free();await get_tree().process_frame
	get_tree().quit()
