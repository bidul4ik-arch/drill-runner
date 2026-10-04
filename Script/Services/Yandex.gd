extends Node
# Native builds remain unaffected. Web shell initializes SDK before the engine.
var bridge
var pause_callback
var loaded:=false
var suspended:=false
var previous_mute:=false
var previous_pause:=false
func _ready() -> void:
	process_mode=Node.PROCESS_MODE_ALWAYS
	if not OS.has_feature("web"):set_process(false);return
	bridge=JavaScriptBridge.get_interface("DrillDropPlatform")
	if bridge==null:set_process(false);return
	pause_callback=JavaScriptBridge.create_callback(_platform_pause)
	bridge.setPauseCallback(pause_callback)
func _platform_pause(args: Array) -> void:
	var hidden:=bool(args[0])
	if hidden==suspended:return
	suspended=hidden
	if hidden:
		bridge.gameplay(false)
		previous_mute=AudioServer.is_bus_mute(0)
		previous_pause=get_tree().paused
		var scene=get_tree().current_scene
		if scene and "state" in scene and scene.state in ["run","boss"]:scene.toggle_pause()
		Profile.save()
		AudioServer.set_bus_mute(0,true)
		get_tree().paused=true
	else:
		get_tree().paused=previous_pause
		AudioServer.set_bus_mute(0,previous_mute)
func _process(_delta: float) -> void:
	var scene=get_tree().current_scene
	if not scene:return
	if not loaded and not Flow.busy and "lobby" in scene and is_instance_valid(scene.lobby):
		loaded=true
		await RenderingServer.frame_post_draw
		bridge.ready()
	bridge.gameplay(not suspended and not get_tree().paused and not Flow.busy and "state" in scene and scene.state in ["run","boss"])
