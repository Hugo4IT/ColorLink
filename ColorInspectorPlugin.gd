tool
extends EditorInspectorPlugin

const LinkedColorsEditorProperty: GDScript = preload("res://addons/ColorLink/ColorInspectorEditor.gd")

func can_handle(object: Object) -> bool:
	return true

func parse_property(object: Object, type: int, path: String, hint: int, hint_text: String, usage: int) -> bool:
	if type == TYPE_COLOR:
		var has_alpha: bool = hint != PROPERTY_HINT_COLOR_NO_ALPHA
		add_property_editor(path, LinkedColorsEditorProperty.new(has_alpha))
		return true
	return false
