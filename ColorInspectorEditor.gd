tool
extends EditorProperty

const SCENE: PackedScene = preload("res://addons/ColorLink/ColorInspector.tscn")
var picker: VBoxContainer = SCENE.instance()

onready var regular_picker: ColorPickerButton = picker.get_node("Small/Regular")
onready var linked_picker: ToolButton = picker.get_node("Small/UseLinkedColors")
onready var linked_menu: PanelContainer = picker.get_node("Expanded")
onready var unlink: Button = picker.get_node("Expanded/VBox/Unlink")
onready var linked_color_grid: GridContainer = picker.get_node("Expanded/VBox/ColorGrid")
onready var add_color_button: ToolButton = picker.get_node("Expanded/VBox/ColorGrid/Add")
onready var popup: PopupPanel = picker.get_node("PopupPanel")

var lock: bool = false
var has_alpha: bool
var current_value: Color

func _init(_has_alpha: bool) -> void:
	has_alpha = _has_alpha
	add_child(picker)

func _ready() -> void:
	linked_menu.visible = false
	linked_picker.pressed = false
	regular_picker.edit_alpha = has_alpha
	add_focusable(add_color_button)
	add_focusable(popup.get_node("Components/Input/Color"))
	add_focusable(popup.get_node("Components/Input/Name"))
	add_focusable(popup.get_node("Components/Navigation/Close"))
	add_focusable(popup.get_node("Components/Navigation/Confirm"))
	add_focusable(unlink)
	add_focusable(linked_menu)
	add_focusable(linked_picker)
	add_focusable(regular_picker)

	linked_picker.connect("toggled", self, "menu_toggled")
	unlink.connect("pressed", self, "unlinked")
	regular_picker.connect("color_changed", self, "regular_changed")
	add_color_button.connect("pressed", self, "new_color")
	popup.get_node("Components/Navigation/Close").connect("pressed", self, "popup_cancel")
	popup.get_node("Components/Navigation/Confirm").connect("pressed", self, "popup_confirm")

	unlink.visible = is_linked()

func is_linked() -> bool:
	return get_edited_object().has_meta("LinkedColors") and \
		get_edited_object().get_meta("LinkedColors").has(get_edited_property())

func regular_changed(value: Color) -> void:
	unlinked()
	emit_changed(get_edited_property(), value) # Apply custom color
	current_value = value

func menu_toggled(state: bool) -> void:
	if lock: return
	linked_menu.visible = state
	if state:
		for child in linked_color_grid.get_children():
			if child is ColorRect:
				linked_color_grid.remove_child(child)
		var colors = get_colors()
		for i in range(len(colors.keys())):
			var key = colors.keys()[i]
			var value = colors[key]
			var color_rect = ColorRect.new()
			color_rect.rect_min_size = add_color_button.rect_size
			color_rect.color = value
			color_rect.connect("gui_input", self, "selection_gui_input", [i])
			linked_color_grid.add_child(color_rect)
		linked_color_grid.move_child(linked_color_grid.get_child(0),
			linked_color_grid.get_child_count() - 1)

func unlinked() -> void:
	if is_linked():
		remove_key(get_edited_property())
		unlink.visible = false

func add_key(prop: String, color) -> void:
	unlink.visible = true
	if not get_edited_object().has_meta("LinkedColors"):
		get_edited_object().set_meta("LinkedColors", {prop: color})
	else:
		get_edited_object().get_meta("LinkedColors")[prop] = color
	emit_changed(prop, get_colors()[color])

func set_key(prop: String, color: String) -> void:
	if not is_linked():
		add_key(prop, color)
		return

	get_edited_object().get_meta("LinkedColors")[prop] = color
	emit_changed(prop, get_colors()[color])

func remove_key(prop: String) -> void:
	get_edited_object().get_meta("LinkedColors").erase(prop)
	if len(get_edited_object().get_meta("LinkedColors")) == 0:
		get_edited_object().remove_meta("LinkedColors")

func selection_gui_input(event: InputEvent, index: int) -> void:
	if not event.is_echo() and event is InputEventMouseButton:
		if event.is_pressed() and event.button_index == BUTTON_LEFT:
			set_key(get_edited_property(), get_colors().keys()[index])

func reset_default_colors() -> void:
	ProjectSettings.set_setting(CL_Constants.PS_LOCATION_COLORS, CL_Constants.DEFAULT_COLORS)
	ProjectSettings.save()

func get_colors() -> Dictionary:
	if not ProjectSettings.has_setting(CL_Constants.PS_LOCATION_COLORS):
		reset_default_colors()

	var colors = ProjectSettings.get_setting(CL_Constants.PS_LOCATION_COLORS)
	if not colors is Dictionary: reset_default_colors()
	if len(colors.keys()) == 0: reset_default_colors()
	return colors

func update_property() -> void:
	var _value = get_edited_object()[get_edited_property()]
	if is_linked():
		var __value = get_colors()[get_edited_object().get_meta("LinkedColors")[get_edited_property()]]
		if _value != __value: emit_changed(get_edited_property(), __value)
		_value = __value

	if _value == current_value: return
	if _value == null: return

	lock = true
	current_value = _value
	regular_picker.color = current_value
	lock = false

func new_color() -> void:
	popup.popup_centered()

func popup_cancel() -> void:
	popup.hide()

func popup_confirm() -> void:
	get_colors()[popup.get_node("Components/Input/Name").text] = \
		popup.get_node("Components/Input/Color").color
	popup.hide()

	ProjectSettings.save()
	property_list_changed_notify()
