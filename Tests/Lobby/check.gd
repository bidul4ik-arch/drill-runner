extends Node
var failures:=0
func check(ok: bool, message: String) -> void:
	if not ok:failures+=1;push_error(message)
func _ready() -> void:call_deferred("run")
func run() -> void:
	if not "--test" in OS.get_cmdline_user_args():get_tree().quit(2);return
	Profile.data.stats={};Profile.data.achievement_claims=[];Profile.data.daily={};Profile.data.coins=0
	Goals.refresh_day("2099-01-01")
	var first: Array=Profile.data.daily.ids.duplicate()
	check(first.size()==3,"Exactly three daily missions")
	check(not Goals.refresh_day("2099-01-01") and first==Profile.data.daily.ids,"Same day preserves missions")
	check(Goals.claim("first_run",false)==0,"Cannot claim unfinished achievement")
	Goals.record("runs")
	check(Goals.claim("first_run",false)==30,"Achievement gives real coins")
	check(Goals.claim("first_run",false)==0 and Profile.data.coins==30,"No repeated reward")
	for item in Goals.entries(true):
		Goals.record(item.metric,int(item.target))
		var earned:=Goals.claim(item.id,true)
		check(earned==int(item.reward),"Daily reward")
		check(Goals.claim(item.id,true)==0,"Daily reward cannot repeat")
	var saved: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(Profile.path))
	check(saved.daily.claimed.size()==3 and "first_run" in saved.achievement_claims,"Rewards persisted")
	check(not Goals.refresh_day("2098-12-31"),"Clock rollback does not reopen claims")
	check(Goals.refresh_day("2099-01-02") and Profile.data.daily.claimed.is_empty(),"New day resets daily claims")
	check(Goals.claimed("first_run",false),"Achievements survive day rollover")
	var model=preload("res://Art/Models/explorer.glb").instantiate();add_child(model)
	for cap in [false,true,false]:
		Profile.data.cap=cap;Profile.apply_skin(model)
		check(model.find_child("CapAccessory",true,false).visible==cap,"Separate cap toggled")
		check(model.find_child("HairOriginal",true,false).visible==not cap,"Original hair toggled")
		check(model.find_child("HairUnderCap",true,false).visible==cap,"Cap hair toggled")
		check(model.find_child("GogglesAccessory",true,false).visible==not cap,"Goggles toggled")
		await RenderingServer.frame_post_draw
	model.queue_free()
	var menu=load("res://Scenes/Screens/MainMenu.tscn").instantiate();add_child(menu);await get_tree().process_frame
	check(menu.page=="menu" and not menu.sheet.visible and menu.lobby.visible,"Illustrated home screen")
	check(not menu.nav_buttons.has("levels"),"No level selector in navigation")
	menu.navigate("missions");check(menu.page=="missions" and menu.sheet.visible,"Daily screen opens")
	menu.navigate("achievements");check(menu.page=="achievements","Achievements open")
	menu.reward_popup(50);menu._notification(NOTIFICATION_WM_GO_BACK_REQUEST);await get_tree().process_frame
	check(not is_instance_valid(menu.reward_modal),"Back closes reward modal")
	menu.navigate("menu");menu.settings();check(menu.page=="settings","Settings")
	menu.show_page();check(menu.page=="menu","Settings return")
	menu.queue_free();await get_tree().process_frame
	Profile.data.suspended_run={};Profile.data.checkpoint=0;Profile.data.unlocked=2
	Flow.auto_start=true
	var game=load(Profile.level(2).scene).instantiate();add_child(game)
	await get_tree().process_frame;await get_tree().process_frame
	check(game.state=="run" and not Flow.auto_start,"Direct start skips second confirmation")
	game.queue_free();await get_tree().process_frame
	print("LOBBY TEST: ",failures," failures")
	get_tree().quit(failures)
