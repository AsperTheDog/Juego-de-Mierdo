extends Node3D

var canInteract: bool = true

@export var powerable: Powerable
var triggered: bool = false:
	set(value):
		if triggered == value: return
		triggered = value
		if triggered:
			$AnimationPlayer.play("action")
			powerable.power()
		else:
			$AnimationPlayer.play_backwards("action")
			powerable.unpower()
		canInteract = false
		await get_tree().create_timer(1.0).timeout
		canInteract = true

@onready var area: Area = powerable.findArea()

func _ready():
	area.generator.unpowered.connect(forceUnpower)


func trigger():
	if not canInteract: return
	if not area.generator.on:
		$AnimationPlayer.play("jam")
		canInteract = false
		await get_tree().create_timer(0.5).timeout
		canInteract = true
		return
	triggered = not triggered


func forceUnpower():
	triggered = false
