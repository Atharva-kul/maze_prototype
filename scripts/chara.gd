extends CharacterBody2D

@export var bullet_scene: PackedScene

@export var speed: float = 300.0
@export var damage_cooldown: float = 0.5

# Directly reference the label child node
@onready var health_label = $"../Health"
@onready var point_label = $"../points"

const BULLET_TEXTURE = preload("res://assets/bullet.png")
const BULLET_SCRIPT = preload("res://scripts/bullet.gd")


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
			
	handle_gun()
	
	if Input.is_action_just_pressed("click"):
		if not get_viewport().gui_get_focus_owner():
			print("clicked")
			shoot()
	
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


func handle_gun() -> void:
	var gun = $Gun as Sprite2D
	if not gun:
		return
		
	var mouse_pos := get_global_mouse_position()
	var looking_left := mouse_pos.x < global_position.x
	
	# 1. Keep the gun anchored cleanly at the character's center
	gun.position = Vector2.ZERO
	
	# 2. Handle the visual flip without altering the texture position coordinates
	if looking_left:
		gun.flip_v = true
	else:
		gun.flip_v = false
		
	# Keep the offset at (0,0) so it matches your editor layout perfectly 
	# and stops leaving the Nozzle node behind!
	gun.offset = Vector2.ZERO
		
	# 3. Rotate the gun node branch directly toward your mouse cursor target
	gun.look_at(mouse_pos)


func shoot() -> void:
	# UI Safety Guard: Prevent shooting if clicking on a UI Button
	if get_viewport().gui_get_focus_owner() != null:
		return

	# Find the Nozzle Marker2D attached to your gun
	var nozzle = $Gun/Nozzle as Marker2D
	if not nozzle: 
		print("Error: Nozzle node not found under Gun!")
		return
	else:
		print("nozzel found")
	
	# 1. Instantiate the sprite node dynamically using RAM memory cache
	var bullet = Sprite2D.new()
	bullet.texture = BULLET_TEXTURE
	bullet.scale = Vector2(1.0, 1.0) 
	bullet.set_script(BULLET_SCRIPT) 
	
	# 2. FIXED POSITION LOGIC: 
	# Because the Nozzle moves, rotates, and flips with the gun automatically,
	# its global_position is ALWAYS the exact pixel coordinate of the barrel tip!
	bullet.global_position = nozzle.global_position
	
	# 3. Calculate target trajectory direction toward the mouse position pointer
	var target_dir = (get_global_mouse_position() - bullet.global_position).normalized()
	bullet.rotation = target_dir.angle()
	
	# Assign the moving direction variable directly inside the bullet instance
	bullet.direction = target_dir
	
	# 4. Add it to the active game world layout container
	get_tree().current_scene.add_child(bullet)
