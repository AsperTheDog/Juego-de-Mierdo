extends CharacterBody3D

@export_category("Movement")
@export var defaultSpeed: float = 4.0
@export var walkingMult: float = 1.0
@export var sprintingMult: float = 1.8
@export var crouchingMult: float = 0.6
@export var accelRate: float = 10.0
@export_category("Camera")
@export var mouseSensibility: float = 0.1
@export var crouchingDepth: float = -0.6
@export var crouchSpeed: float = 10.0
@export_group("Head Bobbing")
@export_subgroup("Speed")
@export var bobbingDefaultSpeed: float = 14.0
@export var bobbingSprintSpeedMult: float = 1.6
@export var bobbingCrouchSpeedMult: float = 0.6
@export var bobbingStandingSpeedMult: float = 0.2
@export_subgroup("Intensity")
@export var bobbingDefaultIntensity: float = 0.07
@export var bobbingSprintIntensityMult: float = 2
@export var bobbingCrouchIntensityMult: float = 0.5
@export var bobbingStandingIntensityMult: float = 0.2
@export_subgroup("Tilt")
@export var bobbingDefaultTiltIntensity: float = 1.0
@export var bobbingSprintTiltIntensity: float = 1.0
@export var bobbingCrouchTiltMult: float = 0.5
@export_subgroup("Other")
@export var bobbingLerpSpeed: float = 10.0
@export var bobbingAxisRatio: float = 1.7
@export var bobbingStandingAxisMult: float = 0.2
@export_group("Head Tilt")
@export_subgroup("Intensity")
@export var tiltDefaultIntensity: float = 0.05
@export var tiltWalkIntensityMult: float = 0.8
@export var tiltSprintIntensityMult: float = 1.5
@export var tiltCrouchIntensityMult: float = 0.6
@export_subgroup("Other")
@export var tiltMaxTurn: float = 40.0
@export var tiltLerpSpeed: float = 10.0

@onready var speed: float = defaultSpeed

@onready var neck: Node3D = $Neck
@onready var upperNeck: Node3D = $Neck/UpperNeck
@onready var eyes: Node3D = $Neck/UpperNeck/Head/Eyes
@onready var rayCast3D: RayCast3D = $RayCast3D
@onready var standingCollision: CollisionShape3D = $StandingCollision
@onready var crouchingCollision: CollisionShape3D = $CrouchingCollision
@onready var head: Node3D = $Neck/UpperNeck/Head
@onready var headHeight: float = head.position.y

@onready var lookRay: RayCast3D = $Neck/UpperNeck/Head/Eyes/Camera3D/Look

var direction: Vector3 = Vector3.ZERO

@onready var bobbingIntensity: float = bobbingDefaultIntensity
var bobbingVector: Vector2 = Vector2.ZERO
var bobbingIndex: float = 0.0

var sprinting: bool = false
var crouching: bool = false

var targetTilt: float = 0.0
var tilt: float = 0.0

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _input(event: InputEvent):
	if event is InputEventMouseMotion:
		rotate_y(deg_to_rad(-event.relative.x * mouseSensibility))
		head.rotate_x(deg_to_rad(-event.relative.y * mouseSensibility))
		head.rotation.x = clamp(head.rotation.x, deg_to_rad(-89.9), deg_to_rad(89.9))
		var tiltIntensity = tiltDefaultIntensity
		if crouching: tiltIntensity *= tiltCrouchIntensityMult
		elif sprinting: tiltIntensity *= tiltSprintIntensityMult
		else: tiltIntensity *= tiltWalkIntensityMult
		targetTilt = clamp(inverse_lerp(0.0, tiltMaxTurn, -event.relative.x), -1.0, 1.0) * tiltIntensity
	elif event.is_action_pressed("interact"):
		if lookRay.is_colliding():
			lookRay.get_collider().trigger()


func _process(delta: float):
	$Control/Point.visible = lookRay.is_colliding() and not Input.is_action_pressed("interact")
	$Control/Hand.visible = lookRay.is_colliding() and Input.is_action_pressed("interact")


func _physics_process(delta: float) -> void:
	var inputDir := Input.get_vector("left", "right", "forward", "backward")
	direction = lerp(direction, (transform.basis * Vector3(inputDir.x, 0, inputDir.y)).normalized(), delta * accelRate)
	sprinting = false
	crouching = false
	var nextBobbingIndex = bobbingIndex
	var bobbingTiltIntensity = bobbingDefaultTiltIntensity
	if Input.is_action_pressed("crouch") or rayCast3D.is_colliding():
		speed = defaultSpeed * crouchingMult
		head.position.y = lerp(head.position.y, headHeight + crouchingDepth, delta * crouchSpeed)
		standingCollision.disabled = true
		crouchingCollision.disabled = false
		bobbingIntensity = bobbingDefaultIntensity * bobbingCrouchIntensityMult
		nextBobbingIndex += bobbingDefaultSpeed * bobbingCrouchSpeedMult * delta
		crouching = true
		bobbingTiltIntensity *= bobbingCrouchTiltMult
	else:
		head.position.y = lerp(head.position.y, headHeight, delta * crouchSpeed)
		standingCollision.disabled = false
		crouchingCollision.disabled = true
		if Input.is_action_pressed("sprint") and inputDir.dot(Vector2.UP) >= 0.5:
			speed = defaultSpeed * sprintingMult
			bobbingIntensity = bobbingDefaultIntensity * bobbingSprintIntensityMult
			nextBobbingIndex += bobbingDefaultSpeed * bobbingSprintSpeedMult * delta
			sprinting = true
			bobbingTiltIntensity *= bobbingSprintTiltIntensity
		else:
			speed = defaultSpeed * walkingMult
			bobbingIntensity = bobbingDefaultIntensity
			nextBobbingIndex += bobbingDefaultSpeed * delta
	
	if is_on_floor():
		var bobbingFinalAxisMult: float = 1.0
		var bobbingTiltEnableMult: float = 0.0
		if inputDir != Vector2.ZERO:
			bobbingIndex = nextBobbingIndex
			bobbingTiltEnableMult = 1.0
		else:
			bobbingIndex = bobbingIndex + bobbingDefaultSpeed * bobbingStandingSpeedMult * delta
			bobbingIntensity = bobbingDefaultIntensity * bobbingStandingIntensityMult
			bobbingFinalAxisMult = bobbingStandingAxisMult
		bobbingVector.y = sin(bobbingIndex)
		bobbingVector.x = sin(bobbingIndex / 2.0) + 0.5
		eyes.position.y = lerp(eyes.position.y, bobbingVector.y * (bobbingIntensity / bobbingAxisRatio), delta * bobbingLerpSpeed)
		eyes.position.x = lerp(eyes.position.x, bobbingVector.x * bobbingIntensity * bobbingFinalAxisMult, delta * bobbingLerpSpeed)
		upperNeck.rotation.z = lerp(upperNeck.rotation.z, -(bobbingVector.x - 0.5) * bobbingTiltEnableMult * bobbingTiltIntensity, delta * bobbingLerpSpeed)
	
	tilt = lerp(tilt, targetTilt, get_physics_process_delta_time() * tiltLerpSpeed)
	neck.rotation.z = tilt
		
	if not is_on_floor():
		velocity += get_gravity() * delta
		
	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)

	move_and_slide()
