extends Node
var failures:=0
func check(ok: bool, label: String) -> void:
	if not ok: failures+=1;push_error(label)
func _ready() -> void:call_deferred("run")
func run() -> void:
	Flow.resume_checkpoint=false;Flow.resume_run=false
	var game=load(Profile.level(1).scene).instantiate();add_child(game)
	await get_tree().process_frame
	game.set_physics_process(false);game.start_run();game.belt.clear_dangers()
	game.elapsed=8
	check(game.run_speed()==17,"Acceleration reaches max within 8 seconds")
	for lane in [-1,1]:
		game.drill.lane=lane
		for i in 40:game._physics_process(1.0/60)
		check(absf(game.camera.position.x-game.drill.position.x)<.2,"Camera follows edge lane")
	game.drill.position=Vector3.ZERO;game.drill.lane=0
	game.powerup("magnet");game.update_presentation(.016)
	var chunk=game.belt.chunks[0]
	var coins: Array=chunk.get_meta("coins")
	var count: int=game.coins
	for i in 3:
		coins[i].show();coins[i].global_position=Vector3((i-1)*2.5,1,-5);coins[i].set_meta("attracting",false)
	game.belt.tick(.016,0)
	check(game.coins==count,"Magnet animates rather than instant collecting")
	for i in 3:check(coins[i].global_position.z> -5,"All lanes attract coins")
	for i in 40:game.belt.tick(.016,0)
	check(game.coins==count+3,"Magnet collects all three lanes exactly once")
	check(chunk.get_node("shield").scale.x<.4,"Small buff pickups")
	game.begin_boss();game.boss.begin_weak();game.drill.lane=game.boss.weak_lane;game.drill.position.x=game.boss.weak_lane*2.5
	var hp: int=game.boss.hp
	check(game.boss.try_boost(),"First combo tap accepted")
	check(game.boss.hp==hp,"One tap does not complete combo")
	check(not game.boss.try_boost(),"Held/repeated same-frame input cannot complete combo")
	game.boss.tick(.2);check(game.boss.try_boost(),"Second tap")
	game.boss.tick(.2);check(game.boss.try_boost(),"Third tap")
	check(game.boss.hp==hp-1 and game.boss.stage=="hurt","Combo damages boss")
	game.boss.begin_weak();game.drill.position.x=game.boss.weak_lane*2.5;game.boss.tick(.2);game.boss.try_boost();game.boss.tick(1.4)
	check(game.boss.combo_step==0,"Slow combo expires")
	game.shield_left=0;game.immunity=0;game.hit();game.start_run()
	check(game.state=="run" and game.distance==0 and game.boss==null,"Defeat restarts full level")
	check(Profile.data.checkpoint==0,"No boss checkpoint remains after defeat")
	game.drill.slide();game.drill.tick(.2)
	check(game.drill.visual.scale==Vector3.ONE,"Slide uses animation without squashing")
	game.queue_free();await get_tree().process_frame
	print("REVISION4 MECHANICS: ",failures," failures")
	get_tree().quit(failures)
