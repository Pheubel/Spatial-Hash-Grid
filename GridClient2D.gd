extends RefCounted
class_name GridClient2D

## The grid cells this client is stored in, normalized to the grid dimension.
var overlapping_cells: Array[ClientCellRecord]

## Additional data attached to this client.
## [br][br]
## [b]Note[/b]: When using a [b][i]GridClientNode2D[/i][/b], the value wil be set to the authoring node.
var data: Variant

var _bounds: Rect2
var _transform: Transform2D
var _shape: Shape2D
@warning_ignore("unused_private_class_variable")
var _query_id: int = 0

func _init(global_transform: Transform2D, shape: Shape2D) -> void:
	# do sanitation to make sure that the size is never negative and position is top left.
	_shape = shape
	_transform = global_transform
	_recalculate_bounds()

func _recalculate_bounds():
	_bounds = _transform * _shape.get_rect()

## Gets the transform of the grid client.
func get_transform() -> Transform2D:
	return _transform

## Sets the transform of the grid client.
func set_transform(transform: Transform2D) -> void:
	_transform = transform
	_recalculate_bounds()

## Gets the shape of the grid client.
func get_shape() -> Shape2D:
	return _shape

## Sets the shape of the grid client.
func set_shape(shape: Shape2D) -> void:
	_shape = shape
	_recalculate_bounds()

## Gets the bounding box of the grid client.
func get_bounds() -> Rect2:
	return _bounds

## Gets the center position of the bounding box. This is the same as the transform's position.
func get_center_position() -> Vector2:
	return _bounds.get_center()

## Gets the top left position of the bounding box.
func get_top_left() -> Vector2:
	return _bounds.position

## Gets the top right position of the bounding box.
func get_top_right() -> Vector2:
	return _bounds.position + Vector2(_bounds.size.x, 0)

## Gets the bottom left position of the bounding box.
func get_bottom_left() -> Vector2:
	return _bounds.position + Vector2(0, _bounds.size.y)

## Gets the bottom right position of the bounding box.
func get_bottom_right() -> Vector2:
	return _bounds.position + _bounds.size
