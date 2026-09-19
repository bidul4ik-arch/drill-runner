extends Node
var failures:=0
func check(value: bool, message: String) -> void:
	if not value: failures+=1;push_error(message)
func _ready() -> void: call_deferred("run")
func run() -> void:
	if not "--test" in OS.get_cmdline_user_args():
		push_error("Run this test with -- --test to protect player saves")
		get_tree().quit(2)
		return
	Profile.data.coins=500
	Profile.data.owned=["explorer"]
	Profile.data.skin="explorer"
	Profile.data.test_premium=0
	Profile.data.test_transactions=[]
	Profile.data.test_pending={}
	Profile.data.unlocked=3
	check(Profile.buy_skin("cave")=="Скин приобретён","Normal skin purchase")
	check(Profile.data.coins==380,"Correct currency debit")
	Profile.buy_skin("cave")
	check(Profile.data.coins==380,"Duplicate purchase protected")
	Profile.select_skin("cave")
	Profile.save()
	var disk: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(Profile.path))
	check(disk.skin=="cave" and "cave" in disk.owned,"Skin persistence")
	Profile.data.completed=[1,2]
	Profile.save()
	Profile._ready()
	check(Profile.data.completed.has(1) and Profile.data.completed.has(2),"Completed level IDs survive JSON reload")
	check(Profile.data.unlocked==3 and Profile.data.skin=="cave","Unlock and selected skin survive reload")
	for state in ["cancelled","failed","pending","unverified"]:
		StoreBridge.test_purchase("crystals_60",state,"a-"+state)
	check(Profile.data.test_premium==0,"Unconfirmed transactions do not pay")
	disk=JSON.parse_string(FileAccess.get_file_as_string(Profile.path))
	check(disk.test_pending.has("a-pending"),"Pending purchase survives restart")
	StoreBridge.test_purchase("crystals_60","verified","a-pending")
	StoreBridge.test_purchase("crystals_60","verified","a-pending")
	check(Profile.data.test_premium==60,"Transaction deduplicated")
	Profile.data.coins=500
	Profile.buy_skin("aurora")
	Profile.buy_skin("aurora")
	check(Profile.data.test_premium==60 and Profile.data.coins==50,"Wardrobe uses coins once, not premium wallet")
	Profile.data.coins=0
	check(Profile.buy_skin("engineer")=="Недостаточно валюты","Insufficient funds")
	for id in [1,2,3]:
		Flow.resume_checkpoint=true
		var game=load(Profile.level(id).scene).instantiate()
		add_child(game)
		await get_tree().process_frame
		game.set_physics_process(false)
		game.start_run()
		check(game.state=="boss","Checkpoint enters boss")
		check(not game.belt.random_enabled,"Random track disabled in boss")
		var b=game.boss
		check(not b.try_boost(),"Boost cannot damage protected boss")
		game._physics_process(.5)
		game.toggle_pause()
		var time: float=b.timer
		game._physics_process(3)
		check(b.timer==time,"Boss timer frozen during pause")
		game.show_settings("pause")
		game._return_to_pause()
		game.resume()
		check(game.state=="boss","Settings returns to boss correctly")
		game._notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
		check(game.state=="pause","Background auto pauses")
		game.resume()
		game.immunity=0;game.shield_left=0;game.hit()
		check(game.state=="over","Boss collision defeats player")
		game.start_run()
		check(game.state=="run" and game.distance==0 and game.boss==null,"Defeat restarts full level")
		check(Profile.data.checkpoint==0,"Defeat clears checkpoint")
		game.begin_boss()
		game.boss.begin_weak()
		game.drill.position.x=5
		check(not game.boss.try_boost(),"Wrong lane does not damage weak point")
		for c in game.belt.chunks:
			for h in c.get_meta("hazards"): check(not h.visible,"No random hazard in boss arena")
		game.queue_free()
		await get_tree().process_frame
		await get_tree().process_frame
	Flow.resume_checkpoint=false
	var first=load(Profile.level(1).scene).instantiate()
	add_child(first)
	await get_tree().process_frame
	first.set_physics_process(false)
	first.start_run()
	first.distance=123.5
	first.coins=7
	first.toggle_pause()
	disk=JSON.parse_string(FileAccess.get_file_as_string(Profile.path))
	check(float(disk.suspended_run.distance)==123.5 and int(disk.suspended_run.coins)==7,"Suspended run saved")
	first.queue_free()
	await get_tree().process_frame
	Flow.resume_run=true
	var restored=load(Profile.level(1).scene).instantiate()
	add_child(restored)
	await get_tree().process_frame
	restored.set_physics_process(false)
	restored.start_run()
	check(restored.distance==123.5 and restored.coins==7,"Continue restores distance and coins")
	restored.queue_free()
	await get_tree().process_frame
	# Every attack has an empty lane or a fully actionable jump/slide wave.
	for key in Profile.bosses:
		for phase in Profile.bosses[key].phases:
			for raw in phase:
				var pattern: Array=raw.map(func(v):return int(v))
				check(pattern.has(-1) or pattern==[0,0,0] or pattern==[1,1,1],"Attack has a valid dodge")
	Profile.save()
	print("SYSTEMS TEST: ",failures," failures")
	get_tree().quit(failures)
