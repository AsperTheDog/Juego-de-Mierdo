class_name Powerable extends Node3D

signal powered
signal unpowered

@export var displayName: String

var isPowered: bool = false:
	set(value):
		if value == isPowered: return
		isPowered = value
		if isPowered:
			powered.emit()
			_on_power()
		else:
			unpowered.emit()
			_on_unpower()


func _ready():
	var area = findArea()
	if area == null:
		print("Error: Powerable not in an area")
	else:
		area.generator.addElement(self)

func power():
	isPowered = true


func unpower():
	isPowered = false


func _on_power():
	pass


func _on_unpower():
	pass


func findArea():
	var area = self
	while area:
		if area is Area:
			return area
		area = area.get_parent()
	return null
