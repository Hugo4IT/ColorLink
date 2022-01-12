tool
extends EditorPlugin

var plugin
var colors: Dictionary

func _enter_tree() -> void:
	if not ProjectSettings.has_setting(CL_Constants.PS_LOCATION_COLORS):
		ProjectSettings.set_setting(CL_Constants.PS_LOCATION_COLORS, CL_Constants.DEFAULT_COLORS)
		ProjectSettings.save()
	ProjectSettings.add_property_info({
		"name": CL_Constants.PS_LOCATION_COLORS,
		"type": TYPE_DICTIONARY
	})

	plugin = preload("res://addons/ColorLink/ColorInspectorPlugin.gd").new()
	add_inspector_plugin(plugin)
	add_tool_menu_item("Update ColorLink", self, "update_colorlink")

func _exit_tree() -> void:
	remove_tool_menu_item("Update ColorLink")
	remove_inspector_plugin(plugin)

func list_dir(target_dir: String, target_object: Object, target_function: String) -> void:
	# Recursively crawl res:// and call target_object.target_function(path) on every file

	var dir = Directory.new()
	dir.open(target_dir)
	dir.list_dir_begin(true, true)
	var entry: String = dir.get_next()
	while entry != "":
		var path = target_dir + "/" + entry
		if dir.current_is_dir(): list_dir(path, target_object, target_function)
		target_object.call(target_function, path)
		entry = dir.get_next()
	dir.list_dir_end()

func update_colorlink(_ud) -> void:
	print("Updating ColorLink values...")
	colors = ProjectSettings.get_setting(CL_Constants.PS_LOCATION_COLORS)
	_update_colorlink(get_editor_interface().get_edited_scene_root())

	# Selecting any object will update all its property
	# inspectors, so to update the project settings
	# we simply need to select it once
	get_editor_interface().inspect_object(null) # Deselect first
	get_editor_interface().inspect_object(ProjectSettings)

	list_dir("res://", self, "_update_file")
	get_editor_interface().save_scene()
	get_editor_interface().reload_scene_from_path(get_editor_interface().get_open_scenes()[0])

	print("Done!")

func _update_file(file: String) -> void:
	if file.ends_with(".tres"):
		print(file)
		var res = load(file)
		if res.has_meta("LinkedColors"):
			var meta = res.get_meta("LinkedColors")
			for key in meta.keys():
				res.set(key, colors[meta[key]])
				print(" - ", key, ": ", colors[meta[key]])

func _update_colorlink(node: Node) -> void:
	# Selecting a node will call the custom inspector
	# to update, thereby updating its value.
	get_editor_interface().edit_node(node)
	for child in node.get_children():
		_update_colorlink(child)
