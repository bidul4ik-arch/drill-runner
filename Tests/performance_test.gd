extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var game=load("res://Main/main_scene.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.start_run()
	var start := Time.get_ticks_msec()
	for i in 600:
		game.immunity=10
		if game.state=="pause": game.resume()
		await process_frame
	var seconds := (Time.get_ticks_msec()-start)/1000.0
	print("RENDER PERFORMANCE: ",600/seconds," frames/s average; ",seconds," seconds; objects ",get_node_count())
	game.queue_free()
	await process_frame
	quit()
