extends Node
var language := "en"
func _enter_tree() -> void:
	var table: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://Localization/en.json"))
	var english:=Translation.new()
	english.locale="en"
	for key in table: english.add_message(key,table[key])
	TranslationServer.add_translation(english)
	var russian:=Translation.new()
	russian.locale="ru"
	for key in table: russian.add_message(key,key)
	TranslationServer.add_translation(russian)
	refresh()
func choose(locale: String) -> String:
	return "ru" if locale.to_lower().begins_with("ru") else "en"
func refresh() -> void:
	language=choose(OS.get_locale_language())
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--language="):language=choose(arg.trim_prefix("--language="))
	TranslationServer.set_locale(language)
func _notification(what: int) -> void:
	if what==NOTIFICATION_APPLICATION_RESUMED: refresh()
