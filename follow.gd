extends PathFollow2D

@export var speed: float = 10

func _physics_process(delta: float) -> void:
	self.set_progress(self.get_progress() + speed * delta)
