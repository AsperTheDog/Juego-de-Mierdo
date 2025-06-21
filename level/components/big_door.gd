extends Powerable


func _on_power():
	$AnimationPlayer.play("action")


func _on_unpower():
	$AnimationPlayer.play_backwards("action")
