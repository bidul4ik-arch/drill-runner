extends Node
var failures:=0
func check(ok: bool,what: String) -> void:
	if not ok:failures+=1;push_error(what)
func _ready() -> void:call_deferred("run")
func run() -> void:
	if not "--test" in OS.get_cmdline_user_args():
		push_error("Run this test with -- --test to protect player saves")
		get_tree().quit(2)
		return
	check(Locale.choose("ru_RU")=="ru" and Locale.choose("ru-BY")=="ru","Russian phone locale")
	check(Locale.choose("en_US")=="en" and Locale.choose("de_DE")=="en","English fallback")
	TranslationServer.set_locale("en")
	check(tr("Гардероб")=="Wardrobe","English menu")
	check(tr("%d / %d м") % [1,2]=="1 / 2 m","English formatted HUD")
	TranslationServer.set_locale("ru")
	check(tr("Гардероб")=="Гардероб","Russian menu")
	Profile.data.cap=true;Profile.save()
	var model=preload("res://Art/Models/explorer.glb").instantiate();add_child(model);Profile.apply_skin(model)
	var cap=model.find_child("CapAccessory*",true,false)
	check(cap!=null and cap.visible,"Cap equipped")
	Profile.data.cap=false;Profile.apply_skin(model)
	check(cap!=null and not cap.visible,"Cap removed")
	Profile.save();var disk: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(Profile.path))
	check(disk.has("cap") and not disk.cap,"Accessory persisted")
	var game=load(Profile.level(1).scene).instantiate();add_child(game)
	await get_tree().process_frame
	game.set_physics_process(false);game.start_run();game.immunity=999
	var belt=game.belt;belt.rng.seed=519
	var found_train:=false;var found_pipe:=false
	for i in 250:
		var chunk=belt.chunks[0];belt.populate(chunk)
		var safe: int=int(chunk.get_meta("safe_lane"))
		for h in chunk.get_meta("hazards"):
			if not h.visible:continue
			check(absf(h.position.x-safe*2.5)>1.05,"Full-length obstacle preserves safe lane")
			if h.get_meta("kind")==6:found_train=true
			if h.get_meta("kind")==7:found_pipe=true
	check(found_train and found_pipe,"Both extended obstacle types spawn")
	check(belt.hits(6,2,1),"Long train cannot be jumped through")
	check(not belt.hits(7,0,.5) and belt.hits(7,0,0),"Long conduit needs slide")
	for skin in Profile.skins:check(skin.currency=="coins","Every wardrobe price uses coins")
	await RenderingServer.frame_post_draw
	game.queue_free();model.queue_free();await get_tree().process_frame;await get_tree().process_frame
	print("MOBILE FEATURES: ",failures," failures")
	get_tree().quit(failures)
