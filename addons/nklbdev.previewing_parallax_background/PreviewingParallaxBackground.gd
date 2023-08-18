@tool @icon("type_icon.svg")
extends ParallaxBackground
class_name PreviewingParallaxBackground

var __previous_canvas_transform: Transform2D
var __previous_viewport_size: Vector2i
@onready var __is_editor: bool = Engine.is_editor_hint()
@export var preview_enabled: bool = true : set = __set_preview_enabled
func __set_preview_enabled(value: bool) -> void:
	if preview_enabled == value:
		return
	preview_enabled = value
	if __is_editor:
		if preview_enabled:
			__update_children(true)
		else:
			__reset_children()

func _enter_tree() -> void:
	# reset positions that was changed in editor and saved in scene
	if not __is_editor:
		__reset_children()

func __reset_children() -> void:
	get_children()
	var parallax_layer: ParallaxLayer
	for child in get_children():
		parallax_layer = child as ParallaxLayer
		if parallax_layer != null:
			parallax_layer.position = Vector2.ZERO

func _process(_delta: float) -> void:
	if __is_editor and preview_enabled:
		__update_children()

func __update_children(force: bool = false) -> void:
	var viewport: Viewport = get_viewport()
	var canvas_transform: Transform2D = viewport.global_canvas_transform
	var viewport_size: Vector2i = viewport.get_visible_rect().size

	if not force and canvas_transform == __previous_canvas_transform and viewport_size == __previous_viewport_size:
		return
	__previous_canvas_transform = canvas_transform
	__previous_viewport_size == viewport_size

	var inverted_canvas_transform: Transform2D = canvas_transform.affine_inverse()
	var screen_offset: Vector2 = -inverted_canvas_transform.origin

	var scroll_ofs: Vector2 = scroll_base_offset + screen_offset * scroll_base_scale

	scroll_ofs = -scroll_ofs
	if scroll_limit_begin.x < scroll_limit_end.x:
		if scroll_ofs.x < scroll_limit_begin.x:
			scroll_ofs.x = scroll_limit_begin.x
		elif scroll_ofs.x + viewport_size.x > scroll_limit_end.x:
			scroll_ofs.x = scroll_limit_end.x - viewport_size.x

	if scroll_limit_begin.y < scroll_limit_end.y:
		if scroll_ofs.y < scroll_limit_begin.y:
			scroll_ofs.y = scroll_limit_begin.y
		elif scroll_ofs.y + viewport_size.y > scroll_limit_end.y:
			scroll_ofs.y = scroll_limit_end.y - viewport_size.y
	scroll_ofs = -scroll_ofs;

	var scroll_scale: float = inverted_canvas_transform.get_scale().dot(Vector2.ONE)
	scroll_ofs = (scroll_ofs + screen_offset * (scroll_scale - 1)) / scroll_scale

	var parallax_layer: ParallaxLayer
	for child in get_children():
		parallax_layer = child as ParallaxLayer
		if parallax_layer != null:
			parallax_layer.position = \
				scroll_ofs * parallax_layer.motion_scale + \
				parallax_layer.motion_offset * scale - \
				screen_offset * scale
