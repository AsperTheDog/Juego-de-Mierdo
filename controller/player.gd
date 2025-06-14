extends CharacterBody3D

@export_group("Movement")
@export var defaultSpeed: float = 4.0
@export var walkingMult: float = 1.0
@export var sprintingMult: float = 1.8
@export var crouchingMult: float = 0.6
@export var accelRate: float = 10.0
@export_group("Camera")
@export var mouseSensibility: float = 1.0
@export var crouchingDepth: float = -0.6
@export var crouchSpeed: float = 10.0
@export_subgroup("Head Bobbing")
@export var bobbingDefaultSpeed: float = 14.0
@export var bobbingSprintSpeedMult: float = 1.6
@export var bobbingCrouchSpeedMult: float = 0.6
@export var bobbingDefaultIntensity: float = 0.1
@export var bobbingSprintIntensityMult: float = 2
@export var bobbingCrouchIntensityMult: float = 0.5
@export var bobbingLerpSpeed: float = 10.0
@export var bobbingAxisRatio: float = 1.7
@export_subgroup("Head Tilt")
@export var tiltDefaultIntensity: float = 0.2
@export var tiltWalkIntensityMult: float = 1.0
@export var tiltSprintIntensityMult: float = 1.6
@export var tiltCrouchIntensityMult: float = 0.6
@export var tiltMaxTurn: float = 40.0
@export var tiltLerpSpeed: float = 10.0

@onready var speed: float = defaultSpeed

@onready var neck: Node3D = $Neck
@onready var eyes: Node3D = $Neck/Head/Eyes
@onready var rayCast3D: RayCast3D = $RayCast3D
@onready var standingCollision: CollisionShape3D = $StandingCollision
@onready var crouchingCollision: CollisionShape3D = $CrouchingCollision
@onready var head: Node3D = $Neck/Head
@onready var headHeight: float = head.position.y

var direction: Vector3 = Vector3.ZERO

@onready var bobbingIntensity: float = bobbingDefaultIntensity
var bobbingVector: Vector2 = Vector2.ZERO
var bobbingIndex: float = 0.0

var sprinting: bool = false
var crouching: bool = false

var tilt: float = 0.0

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _input(event: InputEvent):
	if event is InputEventMouseMotion:
		rotate_y(deg_to_rad(-event.relative.x * mouseSensibility))
		head.rotate_x(deg_to_rad(-event.relative.y * mouseSensibility))
		head.rotation.x = clamp(head.rotation.x, deg_to_rad(-89.9), deg_to_rad(89.9))
		var targetTilt = 0.0
		var tiltIntensity = tiltDefaultIntensity
		if crouching: tiltIntensity *= tiltCrouchIntensityMult
		elif sprinting: tiltIntensity *= tiltSprintIntensityMult
		else: tiltIntensity *= tiltWalkIntensityMult
		targetTilt = clamp(inverse_lerp(0.0, tiltMaxTurn, -event.relative.x), -1.0, 1.0) * tiltIntensity
		tilt = lerp(tilt, targetTilt, get_physics_process_delta_time() * tiltLerpSpeed)
		neck.rotation.z = tilt


func _physics_process(delta: float) -> void:
	var inputDir := Input.get_vector("left", "right", "forward", "backward")
	direction = lerp(direction, (transform.basis * Vector3(inputDir.x, 0, inputDir.y)).normalized(), delta * accelRate)
	sprinting = false
	crouching = false
	if Input.is_action_pressed("crouch") or rayCast3D.is_colliding():
		speed = defaultSpeed * crouchingMult
		head.position.y = lerp(head.position.y, headHeight + crouchingDepth, delta * crouchSpeed)
		standingCollision.disabled = true
		crouchingCollision.disabled = false
		bobbingIntensity = bobbingDefaultIntensity * bobbingCrouchIntensityMult
		bobbingIndex += bobbingDefaultSpeed * bobbingCrouchSpeedMult * delta
		crouching = true
	else:
		head.position.y = lerp(head.position.y, headHeight, delta * crouchSpeed)
		standingCollision.disabled = false
		crouchingCollision.disabled = true
		if Input.is_action_pressed("sprint") and inputDir.dot(Vector2.UP) >= 0.5:
			speed = defaultSpeed * sprintingMult
			bobbingIntensity = bobbingDefaultIntensity * bobbingSprintIntensityMult
			bobbingIndex += bobbingDefaultSpeed * bobbingSprintSpeedMult * delta
			sprinting = true
		else:
			speed = defaultSpeed * walkingMult
			bobbingIntensity = bobbingDefaultIntensity
			bobbingIndex += bobbingDefaultSpeed * delta
	
	if is_on_floor() && inputDir != Vector2.ZERO:
		bobbingVector.y = sin(bobbingIndex)
		bobbingVector.x = sin(bobbingIndex / 2.0) + 0.5
		eyes.position.y = lerp(eyes.position.y, bobbingVector.y * (bobbingIntensity / bobbingAxisRatio), delta * bobbingLerpSpeed)
		eyes.position.x = lerp(eyes.position.x, bobbingVector.x * bobbingIntensity, delta * bobbingLerpSpeed)
	
	if not is_on_floor():
		velocity += get_gravity() * delta
		
	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)

	move_and_slide()
