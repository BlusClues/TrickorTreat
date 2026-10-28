extends CharacterBody3D

@onready var neck := $Neck
@onready var camera := $Neck/Camera3D

var sprint_speed = 1
var candy_amount = 0

const SPEED = 5.0
const JUMP_VELOCITY = 10 #4.5

signal candy_increased(amount: int)


func _ready() -> void:
	GameManager.got_candy.connect(_on_house_got_candy)
	GameManager.got_tricked.connect(_on_house_got_tricked)

# for handling mouse movement and camera movement
func _unhandled_input(event: InputEvent) -> void:
	# allow the user to click in and outo of the scene to remove mouse cursor
	if event is InputEventMouseButton:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	elif event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	# when mouse move, move camera
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		if event is InputEventMouseMotion:
			neck.rotate_y(-event.relative.x * 0.01)
			camera.rotate_x(-event.relative.y * 0.01)
			camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-30), deg_to_rad(60))


func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	
	if Input.is_action_just_pressed("sprint"):
		sprint_speed = 10
	
	if Input.is_action_just_released("sprint"):
		sprint_speed = 1
	
	# Get the input direction and handle the movement/deceleration.
	var input_dir := Input.get_vector("left", "right", "forward", "backward")
	var direction = (neck.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED * sprint_speed
		velocity.z = direction.z * SPEED * sprint_speed
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()
	
	
func _on_house_got_tricked(house) -> void:
	print("its working!!!!!!!!!!!!     Got tricker I guess")

func _on_house_got_candy(house) -> void:
	print("GOT CANDY DAWG NM      its working!!!!!!!!!!!!")
	candy_amount += 1
	candy_increased.emit(candy_amount)
	print(candy_amount)