extends Node
var fails := 0
func _ready() -> void: call_deferred("run")
func shot(name: String) -> void:
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://Tests/Campaign/"+name+".png")
func navigate(path: String) -> void:
	Flow.go(path)
	while Flow.busy: await get_tree().process_frame
func run() -> void:
	get_tree().current_scene=null
	await navigate("res://Scenes/Screens/MainMenu.tscn")
	await shot("main-menu")
	await navigate("res://Scenes/Screens/Home.tscn")
	await shot("home")
	get_tree().current_scene.wardrobe()
	await shot("wardrobe")
	await navigate("res://Scenes/Screens/LevelSelect.tscn")
	await shot("level-select")
	for id in [1,2,3]:
		await navigate(Profile.level(id).scene)
		var game=get_tree().current_scene
		game.set_physics_process(false)
		game.start_run()
		await shot("level-%d" % id)
		game.begin_boss()
		for i in 250: game._physics_process(1.0/60)
		await shot("boss-%d" % id)
		game.boss.begin_weak()
		game._physics_process(.01)
		await shot("weak-%d" % id)
	await navigate("res://Scenes/Screens/Home.tscn")
	await get_tree().process_frame
	var before:=get_tree().get_node_count()
	for i in 6:
		await navigate("res://Scenes/Screens/MainMenu.tscn")
		await navigate("res://Scenes/Screens/Home.tscn")
	await get_tree().process_frame
	print("TRANSITION NODES: ",before," -> ",get_tree().get_node_count())
	if before!=get_tree().get_node_count():fails+=1
	print("SCREENS TEST: ",fails," failures")
	get_tree().quit(fails)
