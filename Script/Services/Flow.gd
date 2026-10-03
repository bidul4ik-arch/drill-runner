extends Node
var busy := false
var auto_start:=false
var menu_page:=""
var resume_checkpoint := false
var resume_run := false
func _ready() -> void:
	get_tree().quit_on_go_back=false
func go(path: String) -> void:
	if busy: return
	busy=true
	var layer := CanvasLayer.new()
	layer.layer=100
	get_tree().root.add_child(layer)
	var shade := Control.new()
	layer.add_child(shade);shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);shade.modulate.a=0
	var art:=TextureRect.new();art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;shade.add_child(art);art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	art.texture=preload("res://Art/UI/Lobby/splash.png");art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;art.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
	var label:=Label.new();shade.add_child(label);label.text=tr("Загрузка…")
	label.anchor_top=.86;label.anchor_bottom=.91;label.anchor_right=1;label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;label.add_theme_font_size_override("font_size",24)
	var bar:=ProgressBar.new();shade.add_child(bar);bar.anchor_top=.92;bar.anchor_bottom=.94;bar.anchor_left=.15;bar.anchor_right=.85;bar.show_percentage=false
	var tween := create_tween()
	tween.tween_property(shade,"modulate:a",1,.18)
	await tween.finished
	ResourceLoader.load_threaded_request(path)
	var progress: Array=[]
	while ResourceLoader.load_threaded_get_status(path,progress)==ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		if not progress.is_empty():bar.value=float(progress[0])*100
		await get_tree().process_frame
	bar.value=100
	if ResourceLoader.load_threaded_get_status(path)==ResourceLoader.THREAD_LOAD_LOADED:
		var packed := ResourceLoader.load_threaded_get(path) as PackedScene
		get_tree().change_scene_to_packed(packed)
		await get_tree().process_frame
	else: push_error("Scene failed: "+path)
	tween=create_tween()
	tween.tween_property(shade,"modulate:a",0,.18)
	await tween.finished
	layer.queue_free()
	busy=false
func start_level(id: int, checkpoint: bool = false, resume_saved: bool = false) -> void:
	if id>int(Profile.data.unlocked): return
	resume_checkpoint=checkpoint
	resume_run=resume_saved
	go(Profile.level(id).scene)
