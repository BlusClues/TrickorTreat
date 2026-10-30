extends Node3D

@onready var road = preload("res://Scenes/Road.tscn")
@onready var house1 = preload("res://Art/Houses/House1.tscn")
@onready var house2 = preload("res://Art/Houses/House2.tscn")
@onready var house3 = preload("res://Art/Houses/House3.tscn")
@onready var house4 = preload("res://Art/Houses/House4.tscn")
@onready var house5 = preload("res://Art/Houses/House5.tscn")
@onready var house_list = [house1, house2, house3, house4, house5]
@onready var decoration1 = preload("res://Art/Decorations/Pumpkins/Pumpkin1.tscn")
@onready var decoration2 = preload("res://Art/Decorations/Pumpkins/Pumpkin2.tscn")
@onready var decoration3 = preload("res://Art/Decorations/Blood.tscn")
@onready var decoration4 = preload("res://Art/Decorations/Skull.tscn")

@export var road_length = 50.0
@export var roads_each_side = 3
@export var world_seed = 12345
@export var map_size = 120.0 # houses before the pattern repeats
@export var max_frequency = 60
@export var noise_exponent = 0.5 # -1 red, -0.5 pink, 0 white, 0.5 blue, 1 violet
@export var run_test = false
@export var save_strips = false

var render_distance 
var last_collided_road_id = 0
var current_road_list = []
var current_moving_direction = 1
var max_id
var min_id
var phases = [] # one random phase per frequency
var noise_scale = 1.0


func _ready() -> void:
	render_distance = roads_each_side
	
	# run test for results for paper
	if run_test:
		run_noise_test()

	if save_strips:
		save_noise_strips()
	
	setup_noise()
	
	# spawn road you start on
	spawn_object()
	
	# Start with a set amount of roads
	for i in range(roads_each_side):
		spawn_object()
	
	# spawn roads behind player
	current_moving_direction = -1
	for i in range(roads_each_side):
		spawn_object()
	
	# reset direction to default
	current_moving_direction = 1
	

func spawn_object():
	print("Moving road")
	#create the object in memory
	var new_road = road.instantiate()
	
	# make signal connection to the manager
	new_road.spawn_road.connect(_on_road_spawn_road)
	new_road.current_road_id.connect(_on_road_current_road_id)
	
	# figure out the id and direction of the road
	if current_road_list.is_empty():
		new_road.id = 0
		current_road_list.append(new_road)
	elif current_moving_direction == -1:
		new_road.id = min_id - 1
		current_road_list.push_front(new_road)
	else:
		new_road.id = max_id + 1
		current_road_list.append(new_road)
	
	# assign new min and max ids
	min_id = current_road_list[0].id
	max_id = current_road_list.back().id
	
	# create our own rng system so then we can seed it (Make sure object spawn consistently random)
	var rng = RandomNumberGenerator.new()
	rng.seed = hash([world_seed, new_road.id])

	#where to place it
	new_road.position = Vector3(new_road.id * road_length, 0, 0)

	#add it to the active game world tree
	add_child(new_road)
	
	#make a list for each of the houses on that segment
	var current_house_list = []
	var spots = new_road.get_node("HouseSpots").get_children()
	
	# add houses to the street
	for spot_index in spots.size():
		var spot = spots[spot_index]
		
		# pick a house at random
		var house_model = house_list[rng.randi_range(0, house_list.size() - 1)]
		
		# create the house and move it
		var new_house = house_model.instantiate()
		new_house.position = spot.position
		new_house.rotation = spot.rotation
		new_road.add_child(new_house)
		
		#Add the house scariness and add it to the list
		var global_index = new_road.id * spots.size() + spot_index
		var house_scariness = blue_scariness(global_index)
		current_house_list.append(house_scariness)
		new_house.scariness = house_scariness
		print("house ", global_index, " scariness: ", house_scariness)
		
		var allowed_list = get_allowed_decor(house_scariness)
		var fill_chance = lerp(0.3, 1.0, house_scariness)
		var decor_node = new_house.get_node("Decor")

		for item in decor_node.get_children():
			# Leave spot empty
			if rng.randf() > fill_chance:
				continue
			
			# pick a number to transform the scale
			var weight = pow(rng.randf(), 2.0)
			var scale_factor = lerp(0.8, 1.4, weight)
			
			# choose model to use and move it
			var decor_model = allowed_list[rng.randi_range(0, allowed_list.size() - 1)]
			var new_decor = decor_model.instantiate()
			new_decor.position = item.position
			new_decor.rotation = item.rotation
			new_decor.scale *= scale_factor
			decor_node.add_child(new_decor)
	
	new_road.house_list = current_house_list
	

# return the allowed list of decorations that can spawn at houses
func get_allowed_decor(house_scariness):
	var allowed_list = []
	if house_scariness > 0.0:
		allowed_list.append(decoration1)
		allowed_list.append(decoration2)
	if house_scariness > 0.4:
		allowed_list.append(decoration4)
	if house_scariness > 0.7:
		allowed_list.append(decoration3)	
	
	return allowed_list

	
# function to cull the road after leaving render distance
func cull_road(road_to_kill):
	road_to_kill.queue_free()


# create our own rng system so then we can seed it (Make sure object spawn consistently random)	
# https://www.redblobgames.com/articles/noise/introduction.html
func setup_noise():
	var rng = RandomNumberGenerator.new()
	rng.seed = world_seed

	# phase = random.uniform(0, 2*pi), one per frequency
	phases.clear()
	for f in range(1, max_frequency + 1):
		phases.append(rng.randf_range(0.0, 2.0 * PI))

	# used later to squash the sum into 0-1
	var power = 0.0
	for f in range(1, max_frequency + 1):
		power += amplitude(f) * amplitude(f)
	noise_scale = sqrt(power / 2.0)


# article's amplitude(f): f^exponent picks the colour of noise
func amplitude(f : int) -> float:
	return pow(f, noise_exponent)


# article's noise(freq): a sine wave shifted by a random phase
func noise(freq : int, x : float) -> float:
	return sin(2.0 * PI * freq * x / map_size + phases[freq - 1])


# article's weighted sum over all frequencies, evaluated at position x
func blue_noise(x : float) -> float:
	var total = 0.0
	for f in range(1, max_frequency + 1):
		total += amplitude(f) * noise(f, x)
	return total


# turn the raw sum into a 0-1 scariness value
func blue_scariness(index : int) -> float:
	return clamp(0.5 + blue_noise(index) / (6.0 * noise_scale), 0.0, 1.0)
	

func _on_road_spawn_road() -> void:
	print("spawn check | dir: ", current_moving_direction, " last: ", last_collided_road_id, " min: ", min_id, " max: ", max_id)
	
	# spawn new road segment
	if current_moving_direction == 1:
		if (max_id - last_collided_road_id) < render_distance:
			spawn_object()
	elif current_moving_direction == -1:
		if (last_collided_road_id - min_id) < render_distance:
			spawn_object()
	
	# cull the oldest object
	if (last_collided_road_id - current_road_list.front().id) > render_distance:
		print("culling back")
		cull_road(current_road_list.pop_front())
	if (current_road_list.back().id - last_collided_road_id) > render_distance:
		cull_road(current_road_list.pop_back())
	
	# replace the max and min values	
	min_id = current_road_list.front().id
	max_id = current_road_list.back().id


# check the current moving direction of the player
# forward = 1 | backwards = -1
func _on_road_current_road_id(current_id: int) -> void:
	if current_id > last_collided_road_id:
		current_moving_direction = 1
	elif current_id < last_collided_road_id:
		current_moving_direction = -1	
	
	last_collided_road_id = current_id





## Tests for PCG Assignment
# function to run test to show comparisons for paper analysis
func run_noise_test(num_seeds : int = 200, scary_cutoff : float = 0.7) -> void:
	# remember the real settings so the test doesn't change the game
	var original_seed = world_seed
	var original_exponent = noise_exponent
	
	var colours = {
		"uniform": 0.0,
		"red": -1.0,
		"pink": -0.5,
		"white": 0.0,
		"blue": 0.5,
		"violet": 1.0,
	}
	
	for colour in colours:
		noise_exponent = colours[colour]
		
		var scary_count = 0
		var total_count = 0
		var back_to_back = 0
		var gap_sum = 0
		var gap_count = 0
		var product_sum = 0.0
		var square_sum = 0.0

		# many seeds = many independent streets, so one lucky street can't skew results
		for s in range(num_seeds):
			world_seed = s
			setup_noise()
			var rng = RandomNumberGenerator.new()
			rng.seed = s
			
			var last_scary = -1
			var previous = 0.0
			
			for i in range(int(map_size)):
				var value = rng.randf() if colour == "uniform" else blue_scariness(i)
				
				total_count += 1
				if value > scary_cutoff:
					scary_count += 1
					if last_scary >= 0:
						gap_sum += i - last_scary
						gap_count += 1
					last_scary = i
					
				if i > 0:
					product_sum += (previous - 0.5) * (value - 0.5)
					square_sum += (value - 0.5) * (value - 0.5)
					if previous > scary_cutoff and value > scary_cutoff:
						back_to_back += 1
				previous = value
		
		var avg_gap = float(gap_sum) / max(gap_count, 1)
		print("%s scary: %.3f | avg gap: %.2f | back-to-back: %.3f | neighbour corr: %+.3f" % [
			colour.rpad(7),
			float(scary_count) / total_count,
			avg_gap,
			float(back_to_back) / total_count,
			product_sum / max(square_sum, 0.0001)
		])

	# put everything back the way it was
	world_seed = original_seed
	noise_exponent = original_exponent
	setup_noise()


func save_noise_strips(seed_to_use : int = 7, count : int = 120, scary_cutoff : float = 0.7) -> void:
	var original_seed = world_seed
	var original_exponent = noise_exponent

	# top to bottom order in the image
	var rows = [
		["uniform", 0.0],
		["red", -1.0],
		["pink", -0.5],
		["white", 0.0],
		["blue", 0.5],
		["violet", 1.0],
		]

	var cell = 10          # pixels per house
	var row_height = 40
	var gap = 12           # white space between rows

	var img = Image.create(count * cell, rows.size() * (row_height + gap), false, Image.FORMAT_RGB8)
	img.fill(Color.WHITE)

	# same seed for every row, so all colours share the same random phases
	world_seed = seed_to_use
	var rng = RandomNumberGenerator.new()
	rng.seed = seed_to_use

	for r in rows.size():
		var label = rows[r][0]
		noise_exponent = rows[r][1]
		setup_noise()
		var y0 = r * (row_height + gap)

		for i in count:
			var value = rng.randf() if label == "uniform" else blue_scariness(i)

			# heat colour for the house
			var heat = Color(0.1, 0.05, 0.2).lerp(Color(1.0, 0.5, 0.0), value)
			img.fill_rect(Rect2i(i * cell, y0, cell, row_height), heat)

			# red bar under houses above the cutoff
			if value > scary_cutoff:
				img.fill_rect(Rect2i(i * cell, y0 + row_height - 6, cell, 6), Color.BLUE)

	var path = "user://noise_strips.png"
	img.save_png(path)
	print("Saved strips to: ", ProjectSettings.globalize_path(path))

	# put everything back the way it was
	world_seed = original_seed
	noise_exponent = original_exponent
	setup_noise()		
		
		
		