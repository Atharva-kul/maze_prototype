extends CharacterBody2D

@export var speed: float = 300.0
@export var damage_cooldown: float = 0.5

# Directly reference the label child node
@onready var health_label = $"../Health"
@onready var point_label = $"../points"

var times = 0 
var health = 10
var points = 0
var can_take_damage = true


func _ready() -> void:
	motion_mode = MOTION_MODE_FLOATING
	update_health_ui() # Set initial text
	update_point_ui()

func _physics_process(_delta: float) -> void:
	var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if direction != Vector2.ZERO:
		velocity = direction.normalized() * speed
	else:
		velocity = velocity.move_toward(Vector2.ZERO, speed)
		
	var collision_count = get_slide_collision_count()
	
	# 2. Loop through each collision
	# 2. Loop through each collision
	for i in collision_count:
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		
		# Check if the collider actually exists before using it
		if collider == null:
			continue # Skip this loop iteration if it's null
		
		# Now it is safe to access .name
		print("Collided with: ", collider.name)
		
		if collider.is_in_group("enemy"):
			take_damage()
			print(health)
			
		if collider.is_in_group("coin"):
			print("collided with coin")
			add_points(collider) # Passing the coin object as fixed previously
			
	
	move_and_slide()

func take_damage() -> void:
	if not can_take_damage:
		return
		
	health -= 1
	times += 1
	
	update_health_ui() # Update text immediately on hit
	
	if health <= 0:
		die()
		return
	
	can_take_damage = false
	await get_tree().create_timer(damage_cooldown).timeout
	can_take_damage = true
	
func add_points(coin_instance: Node2D):
	points += 1
	print(points)
	kill_coin(coin_instance)
	update_point_ui()
	print("added")
	
func kill_coin(coin_instance: Node2D):
	if is_instance_valid(coin_instance):
		coin_instance.queue_free()
		print("coin killed")

# Simple function to update the text
func update_health_ui() -> void:
	if health_label:
		health_label.text = "HP: " + str(health)

func update_point_ui() -> void:
	if point_label:
		point_label.text = "Point:" +str(points)

func die() -> void:
	print("Player died! Restarting level...")
	get_tree().reload_current_scene()
