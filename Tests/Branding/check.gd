extends SceneTree
var failures:=0
func check(ok: bool,label: String) -> void:
	print(label,": ","PASS" if ok else "FAIL")
	if not ok:failures+=1
func _initialize() -> void:call_deferred("run")
func run() -> void:
	if not "--test" in OS.get_cmdline_user_args():quit(2);return
	var flow=root.get_node("Flow");var profile=root.get_node("Profile")
	check(profile.path.ends_with("campaign_test.json"),"Isolated profile")
	var track=load("res://Audio/gamejam.mp3")
	check(track is AudioStreamMP3 and track.get_length()>30 and track.loop,"Imported looping MP3")
	print("Track duration: ",track.get_length())
	check(load(ProjectSettings.get_setting("application/config/icon")) is Texture2D,"Application icon")
	await flow.go("res://Scenes/Screens/MainMenu.tscn")
	check(current_scene.lobby.get_node("BrandLogo") is TextureRect,"Graphic logo")
	check(current_scene.menu_music.stream==track and current_scene.menu_music.playing,"Menu music playing")
	check(is_equal_approx(current_scene.menu_music.pitch_scale,1.0),"Original music speed")
	current_scene.menu_music.seek(track.get_length()-.2)
	await create_timer(.65).timeout
	check(current_scene.menu_music.playing and current_scene.menu_music.get_playback_position()<2,"Music wraps at track end")
	profile.data.music=0;current_scene.sync_audio()
	check(current_scene.menu_music.volume_db<=-79,"Menu mute")
	profile.data.music=.35;current_scene.sync_audio()
	for dims in ([] if "--packaged" in OS.get_cmdline_user_args() else [Vector2i(640,960),Vector2i(430,932)]):
		root.size=dims
		for i in 12:await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://Tests/Branding/menu-%d.png"%dims.x)
	profile.data.unlocked=1;profile.data.suspended_run={};profile.data.checkpoint=0
	current_scene.play_next()
	while flow.busy:await process_frame
	check(current_scene.music.stream==track and current_scene.music.playing,"Run music playing")
	current_scene.music_volume=0;current_scene.apply_volume()
	check(current_scene.music.stream_paused,"Run mute")
	current_scene.music_volume=.35;current_scene.apply_volume()
	check(not current_scene.music.stream_paused,"Run unmute")
	await flow.go("res://Scenes/Screens/MainMenu.tscn")
	print("BRANDING AND MUSIC: ",failures," failures")
	quit(failures)
