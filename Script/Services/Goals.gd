extends Node
signal updated
var catalog: Dictionary
var save_clock:=0.0
var dirty:=false
func _ready() -> void:
	catalog=JSON.parse_string(FileAccess.get_file_as_string("res://Config/goals.json"))
	if not Profile.data.get("stats") is Dictionary:
		Profile.data.stats={"runs":1 if Profile.data.started else 0,"bosses":Profile.data.completed.size()}
	if not Profile.data.get("achievement_claims") is Array:Profile.data.achievement_claims=[]
	if not Profile.data.get("daily") is Dictionary:Profile.data.daily={}
	refresh_day()
func refresh_day(day: String = "") -> bool:
	if day.is_empty():day=Time.get_date_string_from_system()
	# A backwards clock change cannot reopen previously claimed local rewards.
	if day<=str(Profile.data.daily.get("day","")):return false
	var pool: Array=catalog.daily.duplicate()
	var rng:=RandomNumberGenerator.new();rng.seed=day.hash()
	var chosen: Array=[]
	while chosen.size()<3:
		var i:=rng.randi_range(0,pool.size()-1)
		chosen.append(pool[i].id);pool.remove_at(i)
	Profile.data.daily={"day":day,"ids":chosen,"progress":{},"claimed":[]}
	Profile.save();updated.emit();return true
func record(metric: String, amount: float = 1.0) -> void:
	if amount<=0:return
	refresh_day()
	Profile.data.stats[metric]=float(Profile.data.stats.get(metric,0))+amount
	var progress: Dictionary=Profile.data.daily.progress
	progress[metric]=float(progress.get(metric,0))+amount
	dirty=true
func entries(daily: bool) -> Array:
	refresh_day()
	if not daily:return catalog.achievements
	return catalog.daily.filter(func(item):return item.id in Profile.data.daily.ids)
func progress(item: Dictionary, daily: bool) -> int:
	var counters: Dictionary=Profile.data.daily.progress if daily else Profile.data.stats
	return mini(int(item.target),int(counters.get(item.metric,0)))
func claimed(id: String, daily: bool) -> bool:
	return id in (Profile.data.daily.claimed if daily else Profile.data.achievement_claims)
func claim(id: String, daily: bool) -> int:
	for item in entries(daily):
		if item.id!=id or claimed(id,daily) or progress(item,daily)<int(item.target):continue
		if daily:Profile.data.daily.claimed.append(id)
		else:Profile.data.achievement_claims.append(id)
		Profile.data.coins+=int(item.reward)
		Profile.save();dirty=false;updated.emit();return int(item.reward)
	return 0
func available(daily: bool) -> int:
	var count:=0
	for item in entries(daily):
		if not claimed(item.id,daily) and progress(item,daily)>=int(item.target):count+=1
	return count
func _process(delta: float) -> void:
	save_clock+=delta
	if save_clock>=5:
		save_clock=0;refresh_day()
		if dirty:Profile.save();dirty=false
