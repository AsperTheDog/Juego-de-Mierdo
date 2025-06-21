class_name Light extends Node3D

@export var emergency: bool

@onready var origIntensity: float = $OmniLight3D.light_energy

var tween: Tween = null

func _ready():
	if emergency:
		turnOn(true)
	else:
		turnOff(true)

func turnOn(immediate: bool = false):
	if immediate:
		$OmniLight3D.light_energy = origIntensity
		$MeshInstance3D.get_active_material(0).emission_energy_multiplier = 0.8
		return
	var tweenTime = 0.4 - inverse_lerp(0.0, origIntensity, $OmniLight3D.light_energy)
	if tween != null:
		tween.kill()
	tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE).set_parallel(true)
	tween.tween_property($OmniLight3D, "light_energy", origIntensity, tweenTime)
	tween.tween_property($MeshInstance3D.get_active_material(0), "emission_energy_multiplier", 0.8, tweenTime)


func turnOff(immediate: bool = false):
	if immediate:
		$OmniLight3D.light_energy = 0.0
		$MeshInstance3D.get_active_material(0).emission_energy_multiplier = 0.0
		return
	var tweenTime = 0.4 - inverse_lerp(origIntensity, 0.0, $OmniLight3D.light_energy)
	if tween != null:
		tween.kill()
	tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE).set_parallel(true)
	tween.tween_property($OmniLight3D, "light_energy", 0.0, tweenTime)
	tween.tween_property($MeshInstance3D.get_active_material(0), "emission_energy_multiplier", 0.0, tweenTime)
