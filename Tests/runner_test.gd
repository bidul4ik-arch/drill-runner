extends SceneTree
var game
var failures := 0
func check(ok: bool, message: String) -> void:
	if not ok:
		push_error(message)
		failures += 1
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	game = load("res://Main/main_scene.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_physics_process(false)
	check(game.state == "menu", "Initial menu")
	game.start_run()
	game.drill.go_left()
	for i in 30: game.drill.tick(1.0/60)
	check(absf(game.drill.position.x+2.5)<.01, "Left lane")
	game.drill.go_right();game.drill.go_right()
	for i in 30: game.drill.tick(1.0/60)
	check(absf(game.drill.position.x-2.5)<.01,"Right lane")
	check(game.drill.jump(),"Jump starts")
	var peak := 0.0
	for i in 60:
		game.drill.tick(1.0/60)
		peak = maxf(peak,game.drill.position.y)
	check(peak>1.7 and game.drill.position.y==0,"Jump clears crate and lands")
	check(game.drill.slide(),"Slide starts")
	check(not game.belt.hits(1,0,game.drill.slide_left),"Slide clears beam")
	check(game.belt.hits(1,0,0),"Standing hits beam")
	check(not game.belt.hits(0,1.2,0),"Jump clears crate")
	check(game.belt.hits(2,2,0),"Cart cannot be jumped")
	game.collect_coin();check(game.coins==1,"Coin increment")
	game.powerup("shield");game.hit();check(game.state=="run" and game.shield_left==0,"Shield absorbs collision")
	game.immunity=0;game.hit();check(game.state=="over","Defeat screen")
	for i in 5:
		game.start_run();check(game.coins==0 and game.distance==0,"Restart resets")
	game.toggle_pause()
	var before: float=game.distance
	game._physics_process(.5)
	check(game.distance==before,"Pause freezes simulation")
	game.resume();check(game.state=="run","Resume")
	game.music_volume=.2;game.effects_volume=.4;game.save_progress()
	game.music_volume=.9;game.load_progress();check(is_equal_approx(game.music_volume,.2),"Settings persisted")
	check(game.drill.anim != null,"Animation player imported")
	print("ANIMATIONS: ",game.drill.anim.get_animation_list())
	for key in ["idle","run","jump","slide","hit","land","lane"]:
		game.drill.play(key)
		check(not game.drill.anim.current_animation.is_empty(),"Animation "+key)
	# Verify routed keyboard/swipe events, actual pickups and obstacle contacts.
	game.start_run()
	var key := InputEventKey.new()
	key.pressed = true
	key.keycode = KEY_LEFT
	game._unhandled_input(key)
	check(game.drill.lane == -1, "Keyboard input routed")
	var touch := InputEventScreenTouch.new()
	touch.index = 0; touch.pressed = true; touch.position = Vector2(100,100)
	game._unhandled_input(touch)
	var drag := InputEventScreenDrag.new()
	drag.index = 0; drag.position = Vector2(180,100)
	game._unhandled_input(drag)
	check(game.drill.lane == 0, "Touch swipe routed")
	game.start_run()
	for c in game.belt.chunks:
		for h in c.get_meta("hazards"): h.visible = false
	var chunk: Node3D = game.belt.chunks[2]
	chunk.position.z = -2
	var hazard: Node3D = chunk.get_meta("hazards")[5]
	hazard.visible = true
	game.belt.tick(.1,20)
	check(game.state == "over", "Belt contact triggers defeat")
	game.start_run()
	game.powerup("magnet")
	for c in game.belt.chunks:
		for h in c.get_meta("hazards"): h.visible = false
	chunk = game.belt.chunks[2]
	chunk.position.z = 0
	var coin: Node3D = chunk.get_meta("coins")[0]
	coin.position = Vector3(2.5,1,-2);coin.visible = true
	game.belt.tick(.01,11)
	check(not coin.visible and game.coins > 0, "Magnet pulls from adjacent lane")
	# 30 simulated minutes at 20 m/s; fixed pools and safe path invariants.
	game.start_run()
	var nodes := get_node_count()
	for frame in 108000:
		game.immunity=10
		game.belt.tick(1.0/60,20)
		for c in game.belt.chunks:
			var safe: int=c.get_meta("safe_lane")
			for h in c.get_meta("hazards"):
				check(not h.visible or absf(h.position.x-safe*2.5)>.1,"Guaranteed empty lane")
	check(get_node_count()==nodes,"Object count stable over 30 minutes")
	print("POOL NODES: ",nodes," -> ",get_node_count())
	print("TEST RESULT: ",failures," failures; 30 minutes simulated; 5 restarts")
	game.queue_free()
	await process_frame
	await process_frame
	quit(1 if failures else 0)
