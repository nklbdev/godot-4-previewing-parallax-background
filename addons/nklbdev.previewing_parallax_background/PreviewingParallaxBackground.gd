@tool
extends ParallaxBackground
class_name PreviewingParallaxBackground

var __editor_viewport: Viewport
var __previous_canvas_transform: Transform2D
@onready var __is_editor: bool = Engine.is_editor_hint()
@export var preview_enabled: bool = true : set = __set_preview_enabled
func __set_preview_enabled(value: bool) -> void:
	if preview_enabled == value:
		return
	preview_enabled = value
	if __is_editor and __editor_viewport:
		if preview_enabled:
			__update_children(true)
		else:
			__reset_children()

func _ready() -> void:
	if __is_editor:
		var edited_scene_root: Node = get_tree().edited_scene_root
		if edited_scene_root:
			__editor_viewport = edited_scene_root.get_viewport()

func _enter_tree() -> void:
	# reset positions that was changed in editor and saved in scene
	if not __is_editor:
		__reset_children()

func __reset_children() -> void:
	for child in get_children():
		if child is ParallaxLayer:
			child.position = Vector2.ZERO

func _process(_delta: float) -> void:
	if preview_enabled and __is_editor and __editor_viewport:
		__update_children()

func __update_children(force: bool = false) -> void:
	var canvas_transform: Transform2D = __editor_viewport.global_canvas_transform
	if not force and canvas_transform == __previous_canvas_transform:
		return
	__previous_canvas_transform = canvas_transform
	
	var vps: Vector2i = __editor_viewport.size
	var inverted_canvas_transform: Transform2D = canvas_transform.affine_inverse()
	var screen_offset: Vector2 = -(inverted_canvas_transform * Vector2(vps / 2))

	var scroll_ofs: Vector2 = scroll_base_offset + screen_offset * scroll_base_scale
	
	scroll_ofs = -scroll_ofs
	if scroll_limit_begin.x < scroll_limit_end.x:
		if scroll_ofs.x < scroll_limit_begin.x:
			scroll_ofs.x = scroll_limit_begin.x
		elif scroll_ofs.x + vps.x > scroll_limit_end.x:
			scroll_ofs.x = scroll_limit_end.x - vps.x

	if scroll_limit_begin.y < scroll_limit_end.y:
		if scroll_ofs.y < scroll_limit_begin.y:
			scroll_ofs.y = scroll_limit_begin.y
		elif scroll_ofs.y + vps.y > scroll_limit_end.y:
			scroll_ofs.y = scroll_limit_end.y - vps.y
	scroll_ofs = -scroll_ofs;
	
	var scroll_scale: float = inverted_canvas_transform.get_scale().dot(Vector2.ONE)
	scroll_ofs = (scroll_ofs + screen_offset * (scroll_scale - 1)) / scroll_scale

	for child in get_children():
		if child is ParallaxLayer:
			child.position = scroll_ofs * child.motion_scale + child.motion_offset - screen_offset
