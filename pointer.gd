extends Node2D

@export var _grid: SpatialHashGridNode2D 

@export var _scan_shape: Shape2D:
	set(new_shape):
		_scan_shape = new_shape
		queue_redraw()

var last_clients: Array[GridClient2D]

func _ready() -> void:
	if not _scan_shape:
		_scan_shape = CircleShape2D.new()
		_scan_shape.radius = 0.001

func _process(_delta: float) -> void:
	global_position = get_global_mouse_position()

func _physics_process(_delta: float) -> void:
	var bounds = _scan_shape.get_rect()
	bounds.position += global_position
	
	var nearby_clients := _grid.find_nearby_bounds(bounds)
	
	for client in last_clients:
		(client.data as GridClientNode2D).modulate = Color.WHITE
	
	# do an intersection test on all clients hat are eligable
	for client in nearby_clients:
		
		# mark as orange for being checked
		var client_node : GridClientNode2D = client.data as GridClientNode2D
		client_node.modulate = Color.ORANGE
		
		if client_node.get_shape().collide(client_node.global_transform, _scan_shape, global_transform):
			client_node.modulate = Color.GREEN
	
	last_clients = nearby_clients

func _draw() -> void:
	_scan_shape.draw(get_canvas_item(), Color.AQUA)
