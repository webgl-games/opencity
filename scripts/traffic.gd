extends Node3D
## Ambient traffic manager. Spawns cars that cruise the road grid, keep to the
## right-hand lane and pick a random turn at each intersection.
##
## Grid constants mirror city.gd - if the city layout changes, change these too.

const TrafficCar := preload("res://scripts/traffic_car.gd")

const BLOCK_SIZE := 46.0
const GRID := 7
const LANE_OFFSET := 3.5
const CAR_COUNT := 22

const TONES: Array[Color] = [
	Color(0.85, 0.72, 0.12),  # taxi yellow
	Color(0.88, 0.88, 0.90),
	Color(0.12, 0.12, 0.14),
	Color(0.55, 0.57, 0.60),
	Color(0.20, 0.32, 0.62),
	Color(0.24, 0.45, 0.28),
	Color(0.48, 0.14, 0.12),
	Color(0.60, 0.44, 0.24),
]

## Interior road centrelines (the map-edge half-roads are left out so traffic
## never has to deal with the boundary walls).
var lines: Array[float] = []

var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.seed = 7171
	var extent := GRID * BLOCK_SIZE
	for k in range(1, GRID):
		lines.append(-extent * 0.5 + k * BLOCK_SIZE)
	for n in CAR_COUNT:
		_spawn()


func _spawn() -> void:
	var i := _rng.randi_range(0, lines.size() - 1)
	var j := _rng.randi_range(0, lines.size() - 1)
	var dirs := [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	var d: Vector2i = dirs[_rng.randi() % 4]
	if not _valid(i + d.x, j + d.y):
		d = -d

	var car: RigidBody3D = TrafficCar.new()
	car.manager = self
	car.grid_i = i
	car.grid_j = j
	car.dir = d
	car.is_truck = _rng.randf() < 0.25
	car.cruise = _rng.randf_range(6.0, 9.0) if car.is_truck else _rng.randf_range(7.0, 12.5)
	car.colour = TONES[_rng.randi() % TONES.size()]
	add_child(car)

	var d3 := Vector3(d.x, 0.0, d.y)
	var right3 := Vector3(-d.y, 0.0, d.x)
	car.global_position = Vector3(lines[i], 0.05, lines[j]) \
		+ right3 * LANE_OFFSET + d3 * _rng.randf_range(4.0, BLOCK_SIZE - 8.0)
	car.rotation.y = atan2(d3.x, d3.z)


func _valid(i: int, j: int) -> bool:
	return i >= 0 and i < lines.size() and j >= 0 and j < lines.size()


## Where a car heading `d` should aim when driving toward intersection (i, j):
## the intersection centre, shifted into the right-hand lane.
func lane_waypoint(i: int, j: int, d: Vector2i) -> Vector3:
	var right3 := Vector3(-d.y, 0.0, d.x)
	return Vector3(lines[i], 0.0, lines[j]) + right3 * LANE_OFFSET


## Choose the next direction at intersection (i, j). Straight is listed twice
## to weight it; left/right get one entry each. Falls back to a U-turn at
## dead ends (map corners).
func pick_turn(i: int, j: int, current: Vector2i) -> Vector2i:
	var options: Array[Vector2i] = []
	for c: Vector2i in [current, current,
			Vector2i(current.y, -current.x), Vector2i(-current.y, current.x)]:
		if _valid(i + c.x, j + c.y):
			options.append(c)
	if options.is_empty():
		return -current
	return options[_rng.randi() % options.size()]


## After being rammed and recovering, a car has drifted off its route. Snap its
## logical position to the nearest intersection and give it a fresh direction.
func reattach(car: RigidBody3D) -> void:
	var flat := Vector3(car.global_position.x, 0.0, car.global_position.z)
	var best := INF
	var bi := 0
	var bj := 0
	for a in lines.size():
		for b in lines.size():
			var dsq := flat.distance_squared_to(Vector3(lines[a], 0.0, lines[b]))
			if dsq < best:
				best = dsq
				bi = a
				bj = b
	car.grid_i = bi
	car.grid_j = bj
	car.dir = pick_turn(bi, bj, car.dir)
	car.refresh_waypoint()
