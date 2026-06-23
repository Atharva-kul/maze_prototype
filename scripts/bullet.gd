extends Sprite2D

@export var speed: float = 700.0
var direction: Vector2 = Vector2.ZERO

# Safety framework to allow the bullet to exit walls on spawn
var frames_alive: int = 0
const IMMUNITY_FRAMES: int = 2 # Number of frames to ignore wall collisions at start

func _ready() -> void:
	var detection_area = Area2D.new()
	var collision_shape = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	
	circle.radius = 4.0 
	collision_shape.shape = circle
	
	detection_area.add_child(collision_shape)
	add_child(detection_area)
	
	detection_area.body_entered.connect(_on_impact.bind(self))

func _physics_process(delta: float) -> void:
	if direction == Vector2.ZERO:
		return
		
	# Increment frame counter
	frames_alive += 1
	global_position += direction * speed * delta

func _on_impact(body: Node2D, bullet_ref: Sprite2D) -> void:
	# Ignore the player who shot it
	if body.is_in_group("player") or body.name == "Chara":
		return
		
	if body.is_in_group("enemy"):
		print("Enemy hit by bullet!")
		if body.has_method("die"):
			body.die() 
		else:
			body.queue_free() 
		bullet_ref.queue_free()
		
	elif body is TileMapLayer:
		# BYPASS LOGIC: If the bullet just spawned, ignore the wall collision
		if frames_alive <= IMMUNITY_FRAMES:
			return
			
		bullet_ref.queue_free() # Vaporize only if it hits a wall later in flight
