@tool
extends EditorScript
func _run() -> void:
	var settings:=get_editor_interface().get_editor_settings()
	var java:=OS.get_environment("JAVA_HOME")
	var sdk:=OS.get_environment("ANDROID_HOME")
	if java.is_empty() and OS.get_name()=="macOS": java="/Applications/Android Studio.app/Contents/jbr/Contents/Home"
	if sdk.is_empty() and OS.get_name()=="macOS": sdk=OS.get_environment("HOME")+"/Library/Android/sdk"
	if not java.is_empty(): settings.set_setting("export/android/java_sdk_path",java)
	if not sdk.is_empty(): settings.set_setting("export/android/android_sdk_path",sdk)
	print("Android paths configured. Set your local debug keystore in Editor Settings.")
