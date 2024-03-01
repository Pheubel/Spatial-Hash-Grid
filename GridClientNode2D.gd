@tool
extends Node2D
class_name GridClientNode2D

enum update_modes {
	## The client will not be updated automatically.
	## [br][br]
	## [b]Note[/b]: This mode can be used to manually time the updating of 
	## the node to spread out the load of processing the updated clients.
	MANUAL,
	## The client will be updated every iteration of the process loop.
	PROCESSING,
	## The client will be updated every iteration of the physics process loop.
	## The frequency can be altered in the project settings.
	PHSYSICS_PROCESSING
}

var _grid_client: GridClient2D
var _grid: SpatialHashGrid2D

var _is_selected: bool:
	set(new_state):
		if _is_selected != new_state:
			queue_redraw()
		_is_selected = new_state

## The shape of the client inserted into the grid.
## If no shape is given, the shape will be treated as an infinitly small circle.
@export var _shape: Shape2D:
	set(new_shape):
		_shape = new_shape
		if _shape:
			_shape.changed.connect(func() -> void:
				_update_shape() 
				queue_redraw()
			)
		_update_shape()
		queue_redraw()

## Dictates how the client should be updated
@export var update_mode: update_modes = update_modes.MANUAL:
	set(new_mode):
		update_mode = new_mode
		if Engine.is_editor_hint():
			set_process(false)
			set_physics_process(false)
		else:
			set_process(update_mode == update_modes.PROCESSING)
			set_physics_process(update_mode == update_modes.PHSYSICS_PROCESSING)

@export var debug_color: Color = Color(0, 0.6, 0.69, 0.41):
	set(new_color):
		debug_color = new_color
		queue_redraw()

func _init(grid: SpatialHashGrid2D = null) -> void:
	if Engine.is_editor_hint():
		set_process(false)
		set_physics_process(false)
	
	_grid = grid

func _ready() -> void:
	if Engine.is_editor_hint():
		set_process(false)
		set_physics_process(false)
		return
	
	# double take to make sure the right processing mode is active
	set_process(update_mode == update_modes.PROCESSING)
	set_physics_process(update_mode == update_modes.PHSYSICS_PROCESSING)

func _enter_tree() -> void:
	if Engine.is_editor_hint():
		set_process(false)
		set_physics_process(false)
		
		EditorInterface.get_selection().selection_changed.connect(_on_selection_changed)
		return
	
	if not _grid:
		var root := get_tree().root
		var parent: Node = get_parent()
		
		# look through parents to find a spatial hash grid node
		while parent != root:
			if parent is SpatialHashGridNode2D:
				_grid = (parent as SpatialHashGridNode2D)._grid
				break
			
			parent = parent.get_parent()
	
	assert(_grid, "Client could not be connected to a grid, make sure that you assign one when instatiating the node or have this node in a .")
	
	var client_shape = _shape
	if not client_shape:
		client_shape = CircleShape2D.new()
		client_shape.radius = 0
	
	_grid_client = _grid.insert_new_client(global_transform, client_shape)
	_grid_client.data = self

func _exit_tree() -> void:
	if Engine.is_editor_hint():
		EditorInterface.get_selection().selection_changed.disconnect(_on_selection_changed)

func _on_selection_changed() -> void:
	var selected_nodes = EditorInterface.get_selection().get_transformable_selected_nodes()
	_is_selected = self in selected_nodes

func _draw() -> void:
	if Engine.is_editor_hint() and _is_selected:
		if _shape == null:
			draw_circle(Vector2.ZERO, 2, debug_color)
			return
		
		_shape.draw(get_canvas_item(), debug_color)

func _update_shape() -> void:
	print("starting shape update")
	if not (_grid and _grid_client):
		return
		
	var client_shape = _shape
	if not client_shape:
		client_shape = CircleShape2D.new()
		client_shape.radius = 0
	
	_grid_client.set_shape(client_shape)
	_grid.update_client(_grid_client)

## Gets the shape of the grid client.
func get_shape() -> Shape2D:
	return _grid_client.get_shape()

## Updates the transform of the client to be the same of the authoring node.
func update_transform() -> void:
	_grid_client.set_transform(global_transform)
	_grid.update_client(_grid_client)

func _process(_delta: float) -> void:
	update_transform()

func _physics_process(_delta: float) -> void:
	update_transform()
