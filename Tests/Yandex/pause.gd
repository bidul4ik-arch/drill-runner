extends SceneTree
class PlatformStub:
	extends RefCounted
	func gameplay(_active: bool) -> void:pass
var failures:=0
func _initialize() -> void:call_deferred("run")
func check(ok: bool, label: String) -> void:
	if not ok:failures+=1;push_error(label)
func run() -> void:
	if not "--test" in OS.get_cmdline_user_args():quit(2);return
	var platform=root.get_node("Yandex");var flow=root.get_node("Flow");var profile=root.get_node("Profile")
	platform.bridge=PlatformStub.new()
	profile.data.unlocked=1;profile.data.suspended_run={};profile.data.checkpoint=0
	flow.auto_start=true;await flow.go("res://Scenes/Levels/OldMine.tscn")
	check(current_scene.state=="run","Start run")
	platform._platform_pause([true])
	check(paused and AudioServer.is_bus_mute(0),"Suspend tree and mute")
	check(current_scene.state=="pause","Show pause after interruption")
	platform._platform_pause([false])
	check(not paused and not AudioServer.is_bus_mute(0),"Restore tree/audio")
	check(current_scene.state=="pause","No unexpected auto-resume")
	current_scene.resume();check(current_scene.state=="run","Manual resume")
	AudioServer.set_bus_mute(0,true);platform._platform_pause([true]);platform._platform_pause([false])
	check(AudioServer.is_bus_mute(0),"Preserve previous mute")
	AudioServer.set_bus_mute(0,false)
	await flow.go("res://Scenes/Screens/MainMenu.tscn")
	print("PLATFORM PAUSE: ",failures," failures");quit(failures)
