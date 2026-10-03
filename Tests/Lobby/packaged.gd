extends SceneTree
var failures:=0
func check(ok: bool,label: String) -> void:
	if not ok:failures+=1;push_error(label)
func _initialize() -> void:call_deferred("run")
func run() -> void:
	if not "--test" in OS.get_cmdline_user_args():quit(2);return
	var profile=root.get_node("Profile");var goals=root.get_node("Goals");var flow=root.get_node("Flow")
	check(profile.path.ends_with("campaign_test.json"),"Isolated profile")
	for path in ["res://Art/UI/Lobby/menu.png","res://Art/UI/Lobby/splash.png","res://Art/Models/explorer.glb"]:check(ResourceLoader.exists(path),"Packaged visual: "+path)
	check(FileAccess.file_exists("res://Config/goals.json"),"Packaged goals catalog")
	await flow.go("res://Scenes/Screens/MainMenu.tscn")
	check(current_scene.lobby.visible and not current_scene.sheet.visible,"Packaged illustrated menu")
	current_scene.navigate("missions");check(current_scene.page=="missions","Packaged daily page")
	var item=goals.entries(true)[0]
	profile.data.daily.claimed=[];goals.record(item.metric,int(item.target))
	check(goals.claim(item.id,true)==int(item.reward),"Packaged daily claim")
	check(goals.claim(item.id,true)==0,"No duplicate coins")
	current_scene.navigate("achievements");check(current_scene.page=="achievements","Packaged achievement page")
	current_scene.navigate("menu")
	profile.data.unlocked=2;profile.data.suspended_run={};profile.data.checkpoint=0
	current_scene.play_next()
	while flow.busy:await process_frame
	check(current_scene.get("level_id")==2 and current_scene.state=="run","One tap starts next unlocked level")
	await flow.go("res://Scenes/Screens/Home.tscn")
	profile.data.cap=true;profile.apply_skin(current_scene.hero)
	check(current_scene.hero.find_child("HairUnderCap",true,false).visible,"Packaged cap hairstyle")
	check(not current_scene.hero.find_child("HairOriginal",true,false).visible,"Long hair hidden under cap")
	print("PACKAGED LOBBY: ",failures," failures")
	quit(failures)
