extends CharacterBody2D


const SPEED = 300.0

var curr_dir = Vector2.ZERO

const direction = [
	Vector2.LEFT,
	Vector2.RIGHT,
	Vector2.UP,
	Vector2.DOWN
]

func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	random_dir()


func _physics_process(delta: float) -> void:
	velocity = (curr_dir * SPEED) / 4
	
	var collided = move_and_slide()
	
	if collided:
		random_dir()
	
	
func random_dir() -> void:
	var valid_dir = []
	
	for dir in direction:
		if dir != curr_dir:
			valid_dir.append(dir)
			
	curr_dir = valid_dir.pick_random()
