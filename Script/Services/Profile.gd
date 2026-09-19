extends Node
signal changed
var data := {"cap":false,"coins":0,"unlocked":1,"completed":[],"owned":["explorer"],"skin":"explorer","checkpoint":0,"started":false,"best":0,"music":0.35,"effects":0.65,"vibration":true,"quality":1,"claimed":[],"test_premium":0,"test_transactions":[],"test_pending":{},"suspended_run":{},"last_level":1}
var levels: Array = []
var skins: Array = []
var bosses: Dictionary = {}
var path := "user://campaign.json"
var test_store := false
func _ready() -> void:
	if "--test" in OS.get_cmdline_user_args(): path = "user://campaign_test.json"
	elif "--test-store" in OS.get_cmdline_user_args(): path = "user://campaign_sandbox.json"
	test_store = "--test-store" in OS.get_cmdline_user_args() or "--test" in OS.get_cmdline_user_args()
	levels = JSON.parse_string(FileAccess.get_file_as_string("res://Config/levels.json"))
	skins = JSON.parse_string(FileAccess.get_file_as_string("res://Config/skins.json"))
	bosses = JSON.parse_string(FileAccess.get_file_as_string("res://Config/bosses.json"))
	if FileAccess.file_exists(path):
		var saved = JSON.parse_string(FileAccess.get_file_as_string(path))
		if saved is Dictionary: data.merge(saved,true)
	else:
		var old := ConfigFile.new()
		if old.load("user://progress.cfg") == OK and not "--test" in OS.get_cmdline_user_args():
			data.coins = int(old.get_value("progress","coins",0))
			data.best = int(old.get_value("progress","best",0))
			data.music = float(old.get_value("audio","music",.35))
			data.effects = float(old.get_value("audio","effects",.65))
	# JSON numbers return as floats; IDs must remain integers for Array.has().
	data.completed = data.completed.map(func(value): return int(value))
	for key in ["coins", "unlocked", "checkpoint", "last_level", "best", "test_premium"]:
		data[key] = int(data[key])
func save() -> void:
	var f := FileAccess.open(path+".tmp",FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data))
		f.close()
		DirAccess.rename_absolute(path+".tmp",path)
	changed.emit()
func level(id: int) -> Dictionary:
	for item in levels:
		if int(item.id)==id: return item
	return {}
func reward(run_id: String, id: int, earned: int) -> bool:
	if run_id in data.claimed: return false
	data.claimed.append(run_id)
	data.coins += earned
	if id>0:
		if not id in data.completed: data.completed.append(id)
		data.unlocked = maxi(int(data.unlocked),mini(levels.size(),id+1))
		data.checkpoint = 0
	save()
	return true
func buy_skin(id: String) -> String:
	for item in skins:
		if item.id!=id: continue
		if id in data.owned: return tr("Уже приобретено")
		var wallet := "coins" if item.currency=="coins" else "test_premium"
		if item.currency=="premium" and not test_store: return tr("Платный магазин пока не подключён")
		if int(data[wallet])<int(item.price): return tr("Недостаточно валюты")
		data[wallet] -= int(item.price)
		data.owned.append(id)
		save()
		return tr("Скин приобретён")
	return tr("Скин не найден")
func select_skin(id: String) -> void:
	if id in data.owned:
		data.skin=id
		save()
func apply_skin(root: Node, id: String = "") -> void:
	if id.is_empty(): id=data.skin
	var item: Dictionary=skins[0]
	for skin in skins:
		if skin.id==id: item=skin
	for cap in root.find_children("CapAccessory*","MeshInstance3D",true,false): cap.visible=bool(data.cap)
	for mesh in root.find_children("*","MeshInstance3D",true,false):
		for i in mesh.mesh.get_surface_count():
			var mat: Material=mesh.mesh.surface_get_material(i)
			if not mat is StandardMaterial3D: continue
			if mat.resource_name in ["gold","teal"]:
				var copy := mat.duplicate() as StandardMaterial3D
				copy.albedo_color=Color(item.jacket if mat.resource_name=="gold" else item.pack)
				mesh.set_surface_override_material(i,copy)
func buzz() -> void:
	if data.vibration and OS.has_feature("mobile"): Input.vibrate_handheld(70)
