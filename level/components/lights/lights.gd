extends Powerable


func _on_power():
	switchPower(false, true)
	switchPower(true, false)


func _on_unpower():
	switchPower(false, false)
	await get_tree().create_timer(1.0).timeout
	switchPower(true, true)


func switchPower(emergency: bool, on: bool, immediate: bool = false):
	for light in get_children():
		if light is not Light or not light.emergency == emergency: continue
		if on:
			light.turnOn(immediate)
		else:
			light.turnOff(immediate)
