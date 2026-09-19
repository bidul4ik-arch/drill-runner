extends Node
func _ready() -> void:call_deferred("run")
func shot(name: String) -> void:
	for i in 25:await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://Tests/Polish/"+name+".png")
func run() -> void:
	if not "--test" in OS.get_cmdline_user_args():get_tree().quit(2);return
	Profile.data.skin="explorer";Profile.data.owned=["explorer"];Profile.data.coins=300;Profile.data.cap=false
	for lang in ["ru","en"]:
		TranslationServer.set_locale(lang)
		var menu=load("res://Scenes/Screens/MainMenu.tscn").instantiate();add_child(menu)
		await shot("menu-"+lang)
		menu.navigate("shop");await shot("shop-"+lang)
		menu.queue_free();await get_tree().process_frame
	var game=load(Profile.level(1).scene).instantiate();add_child(game)
	await get_tree().process_frame
	game.start_run();game.immunity=999;game.set_physics_process(false)
	for i in 350:game._physics_process(1.0/60)
	game.powerup("magnet");await shot("pickup-comic")
	game.queue_free();await get_tree().process_frame
	get_tree().quit()
