extends Node
func _ready() -> void:call_deferred("run")
func shot(name: String) -> void:
	for i in 12:await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://Tests/Mobile/"+name+".png")
func run() -> void:
	if not "--test" in OS.get_cmdline_user_args():
		push_error("Run this test with -- --test to protect player saves")
		get_tree().quit(2)
		return
	for language in ["ru","en"]:
		TranslationServer.set_locale(language)
		var menu=load("res://Scenes/Screens/MainMenu.tscn").instantiate();add_child(menu)
		await shot("menu-"+language)
		menu.queue_free();await get_tree().process_frame
		var home=load("res://Scenes/Screens/Home.tscn").instantiate();add_child(home)
		await get_tree().process_frame
		Profile.data.cap=true;Profile.apply_skin(home.hero);home.wardrobe()
		await shot("wardrobe-"+language)
		home.queue_free();await get_tree().process_frame
	Profile.data.cap=false;Profile.save()
	get_tree().quit()
