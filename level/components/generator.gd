class_name Generator extends Node3D

signal unpowered

@export var energy: int = 2
@export var timeToOverload: float = 5.0
var elements: Array[Powerable] = []

@onready var energyStr: Label3D = $Mesh/Screen/Tokens
@onready var elemStr: Label3D = $Mesh/Screen/Elements

var on: bool = false:
	set(value):
		on = value
		if not on:
			energyStr.text = "NO POWER"
			elemStr.text = ""
			shutdown()
		else:
			$Mesh/Button.get_active_material(0).albedo_color = Color.GREEN

var energyLeft: int = energy:
	set(value):
		energyLeft = value
		if energyLeft < 0:
			await get_tree().create_timer(timeToOverload).timeout
			on = false


func _ready():
	energyStr.text = "NO POWER"
	elemStr.text = ""


func _process(delta):
	if not on:
		return
	if energyLeft < 0:
		energyStr.text = "OVERLOADED!"
	else:
		energyStr.text = "Energy " + str(energyLeft) + "/" + str(energy)
	elemStr.text = ""
	for elem in elements:
		elemStr.text += elem.displayName + ": " + ("On" if elem.isPowered else "Off") + "\n"


func shutdown():
	if energyLeft >= 0: return
	for elem in elements:
		elem.unpower()
	$Mesh/Button.get_active_material(0).albedo_color = Color.RED
	unpowered.emit()


func addElement(powerable: Powerable):
	if powerable in elements:
		print("Duplicate registration in ", get_path(), " for element ", powerable.get_path())
	else:
		elements.append(powerable)
		powerable.powered.connect(onElemPowered.bind(powerable))
		powerable.unpowered.connect(onElemUnpowered.bind(powerable))


func onElemPowered(powerable: Powerable):
	energyLeft -= 1


func onElemUnpowered(powerable: Powerable):
	energyLeft += 1


func trigger():
	on = true
