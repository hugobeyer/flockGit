class_name SpatialHash

var cell_size: float
var cells: Dictionary = {}

func _init(new_cell_size: float):
	self.cell_size = new_cell_size

func hash(position: Vector3) -> Vector3:
	return Vector3(
		floor(position.x / cell_size),
		floor(position.y / cell_size),
		floor(position.z / cell_size)
	)

func insert(object):
	var cell = hash(object.global_position)
	if not cells.has(cell):
		cells[cell] = []
	cells[cell].append(object)

func query_radius(position: Vector3, radius: float) -> Array:
	var result = []
	var min_cell = hash(position - Vector3.ONE * radius)
	var max_cell = hash(position + Vector3.ONE * radius)
	
	for x in range(min_cell.x, max_cell.x + 1):
		for y in range(min_cell.y, max_cell.y + 1):
			for z in range(min_cell.z, max_cell.z + 1):
				var cell = Vector3(x, y, z)
				if cells.has(cell):
					for object in cells[cell]:
						if object.global_position.distance_to(position) <= radius:
							result.append(object)
	
	return result

func clear():
	cells.clear()

func update(objects: Array):
	clear()
	for object in objects:
		insert(object)
