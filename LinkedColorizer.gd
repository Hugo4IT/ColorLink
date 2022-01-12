extends Node

onready var colors: Dictionary = ProjectSettings.get_setting(CL_Constants.PS_LOCATION_COLORS)

func get_color(key: String) -> Color:
	return colors[key]

func _ready() -> void:
	get_tree().connect("node_added", self, "_node_added")
	call_deferred("spawn_tracker") # Tracks scene changes
	call_deferred("recurse_tree", get_tree().root) # Tracks scene changes

func spawn_tracker() -> void:
	var tracker = Node.new()
	tracker.connect("tree_exited", self, "call_deferred", ["tracker_lost"])
	get_tree().root.call_deferred("add_child", tracker)

func tracker_lost() -> void:
	spawn_tracker()
	recurse_tree(get_tree().root)

func recurse_tree(node: Node) -> void:
	_node_added(node)
	for child in node.get_children():
		recurse_tree(child)

func _node_added(node: Node) -> void:
	if node.has_meta("LinkedColors"):
		var meta: Dictionary = node.get_meta("LinkedColors")
		for prop in meta.keys():
			node.set(prop, get_color(meta[prop]))
