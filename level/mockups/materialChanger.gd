@tool
extends Node3D

@export var material: BaseMaterial3D:
	set(value):
		material = value
		setMaterials(self)


func setMaterials(node):
	if node.name == "EXCLUSION" or node.name.begins_with("ex-"):
		return
	for N in node.get_children():
		if N is MeshInstance3D:
			N.material_override = material
		setMaterials(N)

func _ready():
	setMaterials(self)
