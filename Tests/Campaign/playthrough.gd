extends Node
@onready var root = get_tree().root
var failures := 0
func check(value: bool, message: String) -> void:
	if not value:
		push_error(message)
		failures+=1
func _ready() -> void: call_deferred("run")
func steer(game, target: int) -> void:
	while game.drill.lane<target: game.drill.go_right()
	while game.drill.lane>target: game.drill.go_left()
func solve(game) -> void:
	if game.state=="run":
		var nearest: Node3D
		for c in game.belt.chunks:
			if c.position.z<6.2 and (nearest==null or c.position.z>nearest.position.z): nearest=c
		if nearest: steer(game,int(nearest.get_meta("safe_lane")))
	elif game.state=="boss":
		var b=game.boss
		if b.stage=="weak":
			steer(game,b.weak_lane)
			if absf(game.drill.position.x-b.weak_lane*2.5)<.6: game.boost()
		elif b.stage in ["warning","attack"]:
			var free: int=b.pattern.find(-1)
			if free>=0: steer(game,free-1)
			else:
				steer(game,0)
				if b.stage=="attack" and b.row_z> -5.5:
					if int(b.pattern[1])==0: game.drill.jump()
					elif int(b.pattern[1])==1: game.drill.slide()
func run() -> void:
	if not "--test" in OS.get_cmdline_user_args():get_tree().quit(2);return
	Profile.data.unlocked=1
	Profile.data.completed=[]
	Profile.data.claimed=[]
	Profile.data.coins=0
	Profile.data.checkpoint=0
	Profile.data.owned=["explorer"]
	Profile.data.skin="explorer"
	Profile.data.test_premium=0
	Profile.data.test_transactions=[]
	var ids: Array=[1] if "--first" in OS.get_cmdline_user_args() else [1,2,3]
	for id in ids:
		var game=load(Profile.level(id).scene).instantiate()
		root.add_child(game)
		await get_tree().process_frame
		game.set_physics_process(false)
		game.start_run()
		var ticks:=0
		while game.state in ["run","boss"] and ticks<18000:
			solve(game)
			game._physics_process(1.0/60)
			ticks+=1
		check(game.state=="victory","Level %d completed; state=%s at %.1fm boss=%s" % [id,game.state,game.distance,str(game.boss.stage) if game.boss else "none"])
		if game.boss:
			check(game.boss.phase_seen==[true,true],"Both phases level %d" % id)
			check(game.boss.hit_count==game.boss.max_hp,"All damage via boost")
		check(id in Profile.data.completed,"Completion saved")
		var balance: int=Profile.data.coins
		game.victory()
		check(Profile.data.coins==balance,"Reward not duplicated")
		print("LEVEL ",id," state=",game.state," ticks=",ticks," attacks=",game.boss.attack_count if game.boss else 0," balance=",Profile.data.coins)
		game.queue_free()
		await get_tree().process_frame
		await get_tree().process_frame
		if failures>0: break
	print("CAMPAIGN TEST: ",failures," failures")
	get_tree().quit(1 if failures else 0)
