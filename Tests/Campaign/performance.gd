extends Node
func _ready() -> void: call_deferred("run")
func run() -> void:
	for id in [1,2,3]:
		var game=load(Profile.level(id).scene).instantiate()
		add_child(game)
		await get_tree().process_frame
		game.start_run()
		game.begin_boss()
		var start:=Time.get_ticks_msec()
		for i in 300:
			game.immunity=10
			if game.state=="pause": game.resume()
			await get_tree().process_frame
		var duration: float=(Time.get_ticks_msec()-start)/1000.0
		print("LEVEL ",id," BOSS FPS ",300.0/duration," node count ",get_tree().get_node_count())
		game.queue_free()
		await get_tree().process_frame
		await get_tree().process_frame
	get_tree().quit()
