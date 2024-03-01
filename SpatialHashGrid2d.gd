class_name SpatialHashGrid2D

var _bounds: Rect2
var _cell_size: Vector2
var _cells : Array[Array]
var _cell_count_vector : Vector2i
var _query_id: int

func _init(bounds: Rect2, cell_size: Vector2) -> void:
	assert(cell_size.x > 0 && cell_size.y > 0, "cell dimensions must be greater than 0 an all axes.")
	
	_bounds = bounds
	_cell_size = cell_size
	
	_cell_count_vector = Vector2i(
		ceil(bounds.size.x / _cell_size.x),
		ceil(bounds.size.y / _cell_size.y)
		)
	
	_cells = []
	_cells.resize(_cell_count_vector.x * _cell_count_vector.y)
	
	# pre initialize the cells
	for cell_index in _cells.size():
		_cells[cell_index] = Array()

## Gets the amount of cells per row in the grid.
func get_cells_per_row() -> int:
	return _cell_count_vector.x

## Gets the amount of cells per collumn in the grid.
func get_cells_per_collumn() -> int:
	return _cell_count_vector.y

## Recreates the grid with the given bounds and cell size and orders the clients accordingly.
func recreate_grid(bounds: Rect2, cell_size: Vector2) -> void:
	assert(cell_size.x > 0 && cell_size.y > 0, "cell dimensions must be greater than 0 an all axes.")
	
	var clients : Array[GridClient2D] = []
	
	# store clients from the old grid state
	for cell in _cells:
		for client in cell:
			if not clients.has(client):
				clients.append(client)
	
	_bounds = bounds
	_cell_size = cell_size
	
	_cell_count_vector = Vector2i(
		ceil(bounds.size.x / _cell_size.x),
		ceil(bounds.size.y / _cell_size.y)
		)
	
	_cells = []
	_cells.resize(_cell_count_vector.x * _cell_count_vector.y)
	
	# pre initialize the cells
	for cell_index in _cells.size():
		_cells[cell_index] = Array()
	
	# reinsert clients into the grid
	for client in clients:
		_insert_client(client)

## Creates a new client from a transform and a shape and inserts it into the grid.
func insert_new_client(transform: Transform2D, shape: Shape2D) -> GridClient2D:
	var client := GridClient2D.new(transform, shape)
	
	_insert_client(client)
	
	return client

func _insert_client(client: GridClient2D) -> void:
	var lowest_index_vector := get_cell_index_vector(client.get_top_left())
	var highest_index_vector := get_cell_index_vector(client.get_bottom_right())
	
	#client.overlapping_cells = Rect2i(lowest_index_vector, highest_index_vector - lowest_index_vector)
	client.overlapping_cells = []
	
	for x in range(lowest_index_vector.x, highest_index_vector.x + 1):
		for y in range(lowest_index_vector.y, highest_index_vector.y + 1):
			var cell_index = x + (y * _cell_count_vector.x)
			
			var record = ClientCellRecord.new()
			record.cell_position = Vector2i(x, y)
			record.position_in_cell = _cells[cell_index].size()
			
			client.overlapping_cells.append(record)
			_cells[cell_index].append(client)

## Updates the client's representation in the grid.
func update_client(client: GridClient2D) -> void:
	var min_indices = get_cell_index_vector(client.get_top_left())
	var max_indices = get_cell_index_vector(client.get_bottom_right())
	
	var first_cell := client.overlapping_cells[0]
	var last_cell := client.overlapping_cells[-1]
	
	# if the client would stay in the same cells, there is no need to update it on the grid
	if first_cell.cell_position == min_indices and last_cell.cell_position == max_indices:
		return
	
	remove_client(client)
	_insert_client(client)

## Removes the client from the grid.
func remove_client(client: GridClient2D) -> void:
	# Array element swap mechanism, might be able to optimize this further,
	for record in client.overlapping_cells:
		var cell_index : int = record.cell_position.x + (record.cell_position.y * _cell_count_vector.x)
		var cell := _cells[cell_index]
		var back_client := cell[-1] as GridClient2D
		
		# Find the cell in the records
		var b_first_cell_record := back_client.overlapping_cells[0]
		var b_record_count_vector := back_client.overlapping_cells[-1].cell_position - b_first_cell_record.cell_position
		var b_cell_vector := record.cell_position - b_first_cell_record.cell_position
		var b_cell_record_index = b_cell_vector.x + (b_cell_vector.y * b_record_count_vector.x)
		
		back_client.overlapping_cells[b_cell_record_index].position_in_cell = record.position_in_cell
		
		cell.resize(cell.size() - 1)
	
	# Naive erase, becomes more expensive with more clients
	#for x in range(client.overlapping_cells.position.x, client.overlapping_cells.position.x + client.overlapping_cells.size.x + 1):
		#for y in range(client.overlapping_cells.position.y, client.overlapping_cells.position.y + client.overlapping_cells.size.y + 1):
			#_cells[x + (y * _cell_count_vector.x)].erase(client)
			##TODO: replace this by a mechanism that supports random deletions, such as element swapping or linked lists

## Finds all clients in the cells that intersect with [u]bounds[/u].
func find_nearby_bounds(bounds: Rect2) -> Array[GridClient2D]:
	var lowest_index_vector := get_cell_index_vector(bounds.position)
	var highest_index_vector := get_cell_index_vector(bounds.position + bounds.size)
	
	var clients : Array[GridClient2D] = []
	
	var current_query_id := _query_id
	_query_id += 1
	
	for x in range(lowest_index_vector.x, highest_index_vector.x + 1):
		for y in range(lowest_index_vector.y, highest_index_vector.y + 1):
			for client: GridClient2D in _cells[x + (y * _cell_count_vector.x)]:
				if client._query_id != current_query_id:
					clients.append(client)
					client._query_id = current_query_id
	
	return clients

## Returns the closes 2d integer vector of coordinates localized to the grid.
func get_cell_index_vector(position: Vector2) -> Vector2i:
	var x = clampf((position.x - _bounds.position.x) / _bounds.size.x, 0, 0.999999)
	var y = clampf((position.y - _bounds.position.y) / _bounds.size.y, 0, 0.999999)
	
	var xIndex = floori(x * _cell_count_vector.x)
	var yIndex = floori(y * _cell_count_vector.y)
	
	return Vector2i(xIndex, yIndex)

## Returns the index of the closest cell to a given position. 
func get_cell_index(position: Vector2) -> Vector2i:
	var vector = get_cell_index_vector(position)
	
	return vector.x + (vector.y * _cell_count_vector.x)
