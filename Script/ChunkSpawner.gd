extends Node3D
# Fixed-size moving belt. One obstacle row every 24m: >=1.2s at speed cap.
const LENGTH := 24.0
const COUNT := 8
const MODELS := [preload("res://Scenes/Props/crate.tscn"), preload("res://Scenes/Props/pipe.tscn"), preload("res://Scenes/Props/cart.tscn"), preload("res://Scenes/Props/gap.tscn"), preload("res://Scenes/Props/falling_rocks.tscn"), preload("res://Scenes/Props/moving_gate.tscn"), preload("res://Art/Models/ore_train.glb"), preload("res://Art/Models/long_conduit.glb")]
const KINDS := 8
var random_enabled := true
var allowed: Array = [0,1,2]
var track_scene: PackedScene = preload("res://Art/Models/track.glb")
var motion_time := 0.0
var chunks: Array[Node3D] = []
var rng := RandomNumberGenerator.new()
var safe_lane := 0
var rows := 0
var next_pickup_row := 12
var pickup_rules: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://Config/pickups.json"))
var game: Node

func _ready() -> void:
	game = get_parent()
	rng.randomize()
	if game.get("level_id") != null and int(game.level_id)>0:
		var settings: Dictionary=Profile.level(game.level_id)
		allowed=settings.hazards
		track_scene=load(settings.track)
	for i in COUNT:
		var c := Node3D.new()
		add_child(c)
		c.add_child(track_scene.instantiate())
		for side in [-1, 1]:
			var lantern := OmniLight3D.new()
			lantern.position = Vector3(side * 3.58, 2.65, 6)
			lantern.light_color = Color("ffb34e")
			lantern.light_energy = 1.1
			lantern.omni_range = 6.0
			c.add_child(lantern)
		var hazards: Array[Node3D] = []
		for lane in 3:
			for kind in KINDS:
				var h: Node3D = MODELS[kind].instantiate()
				c.add_child(h)
				h.position.x = (lane - 1) * 2.5
				h.set_meta("kind", kind)
				hazards.append(h)
		c.set_meta("hazards", hazards)
		var coins: Array[Node3D] = []
		for j in 5:
			var coin: Node3D = preload("res://Scenes/Props/coin.tscn").instantiate()
			c.add_child(coin)
			coins.append(coin)
		c.set_meta("coins", coins)
		for key in ["shield", "magnet"]:
			var p := Sprite3D.new()
			p.texture=load("res://Art/UI/Pickups/"+key+".svg")
			p.pixel_size=.006
			p.double_sided=true
			p.shaded=false
			p.name = key
			p.scale=Vector3.ONE
			c.add_child(p)
		chunks.append(c)
	reset()

func reset() -> void:
	rows = 0
	next_pickup_row=rng.randi_range(int(pickup_rules.first_minimum_row),int(pickup_rules.first_maximum_row))
	safe_lane = 0
	for i in COUNT:
		chunks[i].position.z = 12 - i * LENGTH
		populate(chunks[i], i < 2)

func populate(c: Node3D, empty: bool = false) -> void:
	rows += 1
	# Safe path moves at most one lane between rows, with no obstacles between.
	safe_lane = clampi(safe_lane + rng.randi_range(-1, 1), -1, 1)
	c.set_meta("safe_lane", safe_lane)
	# Three side-decoration rhythms; no geometry is created during recycling.
	var variant := rows % 3
	var decor := c.get_child(0)
	for crystal in decor.find_children("Crystal*", "MeshInstance3D", true, false):
		crystal.visible = variant != 1 or crystal.position.x > 0
	for rock in decor.find_children("Rock*", "MeshInstance3D", true, false):
		rock.visible = variant != 2 or rock.position.x < 0
	for h in c.get_meta("hazards"):
		h.visible = false
	if not empty and random_enabled:
		for lane in range(-1, 2):
			if lane == safe_lane: continue
			if rng.randf() < .78:
				var pool: Array=allowed.duplicate() if rows>4 else [0,1,2]
				if rows>6: pool.append(6)
				if rows>10: pool.append(7)
				var kind: int=int(pool[rng.randi_range(0,pool.size()-1)])
				c.get_meta("hazards")[(lane + 1) * KINDS + kind].visible = true
	var j := 0
	for coin in c.get_meta("coins"):
		coin.set_meta("attracting",false)
		coin.position = Vector3(safe_lane * 2.5, 1.0, 6 - j * 2.3)
		coin.visible = not empty and random_enabled
		j += 1
	var selected := ""
	if not empty and random_enabled and rows>=next_pickup_row:
		selected="shield" if rng.randf()<.5 else "magnet"
		next_pickup_row=rows+rng.randi_range(int(pickup_rules.minimum_gap_rows),int(pickup_rules.maximum_gap_rows))
	for key in ["shield", "magnet"]:
		var p := c.get_node(key) as Node3D
		p.visible = key==selected
		p.position = Vector3(safe_lane * 2.5, 1.1, -8)

func tick(delta: float, speed: float) -> void:
	motion_time+=delta
	for c in chunks:
		var old_z := c.position.z
		c.position.z += speed * delta
		for h in c.get_meta("hazards"):
			if not h.visible: continue
			if int(h.get_meta("kind"))==4: h.position.y=maxf(0,-c.position.z*.15)
			if int(h.get_meta("kind"))==5: h.rotation.y=sin(motion_time*3)*.4
			# Swept interval prevents tunneling at low frame rates.
			var half_length:=5.4 if int(h.get_meta("kind"))==6 else 3.0 if int(h.get_meta("kind"))==7 else .5
			if old_z < half_length+.5 and c.position.z > -half_length-.5:
				if absf(h.global_position.x - game.drill.position.x) < 1.05:
					var kind: int = h.get_meta("kind")
					if hits(kind, game.drill.position.y, game.drill.slide_left):
						h.visible = false
						game.hit()
						if game.state != "run": return
		for coin in c.get_meta("coins"):
			if not coin.visible: continue
			coin.rotation.y += delta * 2
			var p: Vector3 = coin.global_position
			var target: Vector3=game.drill.position+Vector3(0,1,0)
			var magnetic: bool = game.magnet_left > 0 and (p.distance_to(target)<9.0 or coin.get_meta("attracting",false))
			if magnetic:
				coin.set_meta("attracting",true)
				coin.global_position=(p-Vector3(0,0,speed*delta)).move_toward(target,25*delta)
			if (magnetic and coin.global_position.distance_to(target)<.45) or (absf(p.x - game.drill.position.x) < .85 and p.z>=-.8 and p.z-speed*delta<=.8 and game.drill.position.y < 1.6):
				coin.visible = false
				game.collect_coin()
		for key in ["shield", "magnet"]:
			var p := c.get_node(key) as Node3D
			p.rotation.y = sin(motion_time*1.7)*.35
			p.position.y=1.0+sin(motion_time*2.6)*.09
			if p.visible and old_z+p.position.z<=1 and c.position.z+p.position.z>=-1 and absf(p.global_position.x - game.drill.position.x) < 1 and game.drill.position.y < 1.6:
				p.visible = false
				game.powerup(key)
		if c.position.z > 30:
			var back := 0.0
			for other in chunks: back = minf(back, other.position.z)
			c.position.z = back - LENGTH
			populate(c)

static func hits(kind: int, height: float, slide_time: float) -> bool:
	if kind in [0,3]: return height < 1.05
	if kind in [1,7]: return slide_time <= 0 or height > .1
	return true

func clear_dangers() -> void:
	random_enabled=false
	for c in chunks:
		for h in c.get_meta("hazards"): h.hide()
		for coin in c.get_meta("coins"): coin.hide()
		c.get_node("shield").hide()
		c.get_node("magnet").hide()
