extends SceneTree
var game
func _initialize() -> void: call_deferred("run")
func shot(name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://Tests/"+name+".png")
func run() -> void:
	game=load("res://Main/main_scene.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_physics_process(false)
	await shot("menu")
	game.belt.rng.seed = 19
	game.start_run()
	for i in 170:
		game.immunity=10
		game._physics_process(1.0/60)
	game.drill.anim.advance(.1)
	await shot("gameplay")
	game.toggle_pause()
	await shot("pause")
	game.resume();game.immunity=0;game.hit()
	await shot("results")
	game.show_help()
	root.size=Vector2i(480,800)
	await shot("portrait-help")
	game.queue_free()
	await process_frame
	quit()
