extends Node
var busy := false
var resume_checkpoint := false
var resume_run := false
func go(path: String) -> void:
	if busy: return
	busy=true
	var layer := CanvasLayer.new()
	layer.layer=100
	get_tree().root.add_child(layer)
	var shade := ColorRect.new()
	layer.add_child(shade)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color=Color(0.02,.04,.06,0)
	var label := Label.new()
	shade.add_child(label)
	label.text=tr("Загрузка…")
	label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	var tween := create_tween()
	tween.tween_property(shade,"color:a",1,.18)
	await tween.finished
	ResourceLoader.load_threaded_request(path)
	while ResourceLoader.load_threaded_get_status(path)==ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		await get_tree().process_frame
	if ResourceLoader.load_threaded_get_status(path)==ResourceLoader.THREAD_LOAD_LOADED:
		var packed := ResourceLoader.load_threaded_get(path) as PackedScene
		get_tree().change_scene_to_packed(packed)
		await get_tree().process_frame
	else: push_error("Scene failed: "+path)
	tween=create_tween()
	tween.tween_property(shade,"color:a",0,.18)
	await tween.finished
	layer.queue_free()
	busy=false
func start_level(id: int, checkpoint: bool = false, resume_saved: bool = false) -> void:
	if id>int(Profile.data.unlocked): return
	resume_checkpoint=checkpoint
	resume_run=resume_saved
	go(Profile.level(id).scene)
