extends SceneTree
var failures:=0
func _initialize() -> void:call_deferred("run")
func check(ok: bool, label: String) -> void:
	if not ok:failures+=1;push_error(label)
func run() -> void:
	if not "--test" in OS.get_cmdline_user_args():quit(2);return
	var flow=root.get_node("Flow")
	var profile=root.get_node("Profile")
	check(profile.path.ends_with("campaign_test.json"),"Packaged tests use isolated save")
	for asset in ["res://Art/UI/Pickups/shield.svg","res://Art/UI/Pickups/magnet.svg","res://Art/UI/Nav/shop.svg","res://Art/Models/explorer.glb"]:
		check(ResourceLoader.exists(asset),"Included asset: "+asset)
	for asset in ["res://Config/banter.json","res://Config/pickups.json","res://Localization/en.json"]:
		check(FileAccess.file_exists(asset),"Included catalog: "+asset)
	await flow.go("res://Scenes/Screens/MainMenu.tscn")
	check(current_scene.screen=="menu","Packaged main menu")
	current_scene.navigate("shop")
	check(current_scene.page=="shop","Packaged shop")
	current_scene._notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	check(current_scene.page=="menu","Packaged back navigation")
	await flow.go("res://Scenes/Screens/Home.tscn")
	check(current_scene.screen=="home","Packaged cabin transition")
	current_scene.wardrobe()
	check(current_scene.page=="wardrobe","Packaged wardrobe")
	await flow.go(profile.level(1).scene)
	current_scene.start_run()
	check(current_scene.state=="run","Packaged level starts")
	current_scene._notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	check(current_scene.state=="pause","Packaged Android back pauses run")
	current_scene._notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	check(current_scene.state=="run","Packaged Android back resumes run")
	current_scene.powerup("shield")
	current_scene.powerup("magnet")
	await process_frame
	check(current_scene.shield_left>0 and current_scene.magnet_left>0,"Packaged pickup effects")
	await flow.go("res://Scenes/Screens/MainMenu.tscn")
	print("PACKAGED NAVIGATION: ",failures," failures")
	quit(failures)
