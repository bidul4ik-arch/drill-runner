extends RefCounted
# Godot 4.2 does not expose renderer feature tags. Respect the active backend,
# including command-line overrides used by the mobile visual checks.
static func renderer() -> String:
	if RenderingServer.get_rendering_device()==null:return "gl_compatibility"
	var args:=OS.get_cmdline_args()
	var index:=args.find("--rendering-method")
	if index>=0 and index+1<args.size():return args[index+1]
	return str(ProjectSettings.get_setting_with_override("rendering/renderer/rendering_method"))
