extends Node
var failures:=0
func check(ok: bool, note: String) -> void:
	if not ok:failures+=1;push_error(note)
func _ready() -> void:call_deferred("run")
func run() -> void:
	if not "--test" in OS.get_cmdline_user_args():get_tree().quit(2);return
	check(not get_tree().quit_on_go_back,"System back must not terminate the game")
	for key in Banter.phrases:
		var seen: Array=[]
		for i in Banter.phrases[key].size():
			var line=Banter.take(key)
			check(not line in seen,"Banter repeats before bag exhausted: "+key)
			seen.append(line)
		check(Banter.take(key)!=seen[-1],"Bag boundary repeat")
	var game=load(Profile.level(1).scene).instantiate();add_child(game)
	await get_tree().process_frame
	game.set_physics_process(false)
	var belt=game.belt;belt.rng.seed=8026;belt.reset()
	var last_row: int=-100;var count:=0;var gaps: Array=[]
	for i in 1000:
		var chunk=belt.chunks[0];belt.populate(chunk)
		var present:=int(chunk.get_node("shield").visible)+int(chunk.get_node("magnet").visible)
		check(present<=1,"At most one buff per section")
		if present:
			if last_row>0:check(belt.rows-last_row>=12 and belt.rows-last_row<=22,"Rare pickup interval");gaps.append(belt.rows-last_row)
			last_row=belt.rows;count+=1
	check(count>40 and count<90,"Sparse spawn rate")
	check(gaps.min()!=gaps.max(),"Intervals vary")
	game.powerup("shield");game.powerup("magnet")
	game.queue_free();await get_tree().process_frame
	var screen=load("res://Scenes/Screens/MainMenu.tscn").instantiate();add_child(screen)
	await get_tree().process_frame
	screen.navigate("shop");check(screen.page=="shop","Store navigation")
	screen.toast("TEST");screen.toast("SECOND");check(screen.sheet.get_parent().get_node_or_null("ShopToast")!=null,"Visible shop feedback")
	screen._notification(NOTIFICATION_WM_GO_BACK_REQUEST);check(screen.page=="menu","System back returns from shop")
	screen.navigate("menu");check(screen.page=="menu","Return to menu")
	screen.settings();check(screen.page=="settings","Settings navigation")
	screen.show_page();check(screen.page=="menu","Settings return")
	await RenderingServer.frame_post_draw
	screen.queue_free();await get_tree().process_frame
	print("POLISH TEST: ",failures," failures; pickups per 1000 sections=",count)
	get_tree().quit(failures)
