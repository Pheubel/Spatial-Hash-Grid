@tool
extends Node2D
class_name SpatialHashGridNode2D

## The size of the spatial grid. Together with the global position of the node
## this will dictate the overall span of the grid.
@export var _size := Vector2(400,400):
	set(new_size):
		_size = new_size
		queue_redraw()

## The size of the cells inside the grid. The amound of cells on each axis is
## the size of the grid divided by the size of a single cell, rounded upwards.
## [br][br]
## [b]Note[/b]: Cell size must be a value above zero on any axes.
@export var _cell_size := Vector2(10,10):
	set(new_cell_size):
		_cell_size = new_cell_size
		queue_redraw()

@export var _debug_color_bounds := Color(0.2,0.8,0, 0.2):
	set(new_color):
		_debug_color_bounds = new_color
		queue_redraw()

@export var _debug_color_grid := Color(0.8,0.2,0, 0.4):
	set(new_color):
		_debug_color_grid = new_color
		queue_redraw()

## Determines if the grid should always be drawn in the editor.
@export var _debug_draw_always := false:
	set(new_state):
		_debug_draw_always = new_state
		queue_redraw()

var _grid : SpatialHashGrid2D

var _is_selected: bool:
	set(new_state):
		if _is_selected != new_state:
			queue_redraw()
		_is_selected = new_state

## Gets the boundaries of the grid.
func get_bounds() -> Rect2:
	return Rect2(global_position, _size)

## Returns an array of all clients that resides in the cells within the given bounds.
func find_nearby_bounds(bounds: Rect2) -> Array[GridClient2D]:
	return _grid.find_nearby_bounds(bounds)

## Recreates the grid with the current bounds and cell size and orders the clients accordingly.
func queue_recreate_grid() -> void:
	_grid.recreate_grid(get_bounds(), _cell_size)

func _enter_tree() -> void:
	if not _grid:
		_grid = SpatialHashGrid2D.new(get_bounds(), _cell_size)
	
	if Engine.is_editor_hint():
		EditorInterface.get_selection().selection_changed.connect(_on_selection_changed)

func _exit_tree() -> void:
	if Engine.is_editor_hint():
		EditorInterface.get_selection().selection_changed.disconnect(_on_selection_changed)

func _draw() -> void:
	if Engine.is_editor_hint() and (_debug_draw_always or _is_selected):
		draw_set_transform(Vector2.ZERO,-global_rotation, Vector2.ONE / global_scale)
		draw_rect(Rect2(Vector2.ZERO, _size), _debug_color_bounds)
		draw_rect(Rect2(Vector2.ZERO, _size), _debug_color_bounds.darkened(0.2),false, 2)
		
		var vertical_line_count := ceili(_size.x / _cell_size.x) - 1
		var horizontal_line_count := ceili(_size.y / _cell_size.y) - 1
		
		for vertical_line in vertical_line_count:
			draw_line(Vector2((vertical_line * _cell_size.x) + _cell_size.x, 0), Vector2((vertical_line * _cell_size.x) + _cell_size.x, _size.y), _debug_color_grid)
		
		for horizontal_line in horizontal_line_count:
			draw_line(Vector2(0, (horizontal_line * _cell_size.y) + _cell_size.y), Vector2(_size.x, (horizontal_line * _cell_size.y) + _cell_size.y), _debug_color_grid)

func _set(_property: StringName, _value: Variant) -> bool:
	queue_redraw()
	return false

func _on_selection_changed():
	var selected_nodes = EditorInterface.get_selection().get_transformable_selected_nodes()
	_is_selected = self in selected_nodes
