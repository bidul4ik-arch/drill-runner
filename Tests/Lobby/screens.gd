extends Node
func _ready() -> void:call_deferred("run")
func shot(name: String) -> void:
	for i in 15:await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://Tests/Lobby/"+name+("-tall" if "--tall" in OS.get_cmdline_user_args() else "")+".png")
func run() -> void:
	if not "--test" in OS.get_cmdline_user_args():get_tree().quit(2);return
	if "--tall" in OS.get_cmdline_user_args():get_window().size=Vector2i(430,932)
	Profile.data.coins=980;Profile.data.best=18450;Profile.data.stats={"runs":1,"coins":68,"jumps":14};Profile.data.achievement_claims=[]
	Profile.data.daily={};Goals.refresh_day();Goals.record("coins",40);Goals.record("distance",680)
	for lang in ["ru","en"]:
		TranslationServer.set_locale(lang)
		var menu=load("res://Scenes/Screens/MainMenu.tscn").instantiate();add_child(menu)
		await shot("menu-"+lang)
		menu.navigate("missions");await shot("daily-"+lang)
		menu.navigate("achievements");await shot("achievements-"+lang)
		menu.reward_popup(80);await shot("reward-"+lang)
		menu.queue_free();await get_tree().process_frame
	var home=load("res://Scenes/Screens/Home.tscn").instantiate();add_child(home)
	for cap in [false,true]:
		Profile.data.cap=cap;Profile.apply_skin(home.hero)
		await shot("cap-on" if cap else "cap-off")
	home.queue_free();await get_tree().process_frame
	get_tree().quit()
