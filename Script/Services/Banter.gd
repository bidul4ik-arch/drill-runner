extends Node
var phrases: Dictionary
var bags: Dictionary={}
var last: Dictionary={}
func _ready() -> void:
	phrases=JSON.parse_string(FileAccess.get_file_as_string("res://Config/banter.json"))
func take(key: String) -> String:
	if not phrases.has(key):return ""
	if not bags.has(key) or bags[key].is_empty():
		bags[key]=phrases[key].duplicate()
		bags[key].shuffle()
		if bags[key].size()>1 and bags[key][-1]==last.get(key,""):
			var swap=bags[key][0];bags[key][0]=bags[key][-1];bags[key][-1]=swap
	var line: String=bags[key].pop_back()
	last[key]=line
	return tr(line)
