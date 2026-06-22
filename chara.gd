extends CharacterBody2D

@export var bullet_scene: PackedScene

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
	
	# 1. Keep the gun node anchored right at the player's center (or shoulder)
	gun.position = Vector2(0, 0) 
	
	# 2. Shift the texture offset so the handle is at (0,0) and muzzle extends right
	# Adjust the X value (e.g., 16) based on half the width of your gun sprite
	var handle_offset_x: float = 16.0 
	
	if looking_left:
		gun.flip_v = true
		# When flipped, the texture offset needs to stay positive to project outward correctly
		gun.offset = Vector2(handle_offset_x, 0)
	else:
		gun.flip_v = false
		gun.offset = Vector2(handle_offset_x, 0)
		
	# 3. Rotate the gun node around its local (0,0) origin
	gun.look_at(mouse_pos)


func shoot() -> void:
	# 1. UI Safety Guard: Prevent shooting if clicking on a UI Button
	# if the mouse is currently interacting with an active UI component, exit early
	if get_viewport().gui_get_focus_owner() != null:
		return

	var gun = $Gun as Sprite2D
	if not gun: 
		return
	
	# 2. Dynamically instantiate the bullet Sprite2D
	var bullet = Sprite2D.new()
	bullet.texture = load("res://assets/bullet.png") 
	bullet.scale = Vector2(1, 1)       
	bullet.set_script(load("res://scripts/bullet.gd")) 
	
	# =========================================================================
	# NOZZLE ATTACHMENT WITH WALL BUFFER
	# =========================================================================
	# Get the texture width based on your asset file dimensions
	var texture_width = gun.texture.get_size().x
	
	# Calculate the exact pixel distance from handle to barrel end.
	# We add a small '+ 10.0' pixel buffer here. This pushes the bullet spawn 
	# point slightly out of your character's body and out of wall tiles so it 
	# doesn't instantly collide with the TileMapLayer on frame 1.
	var actual_gun_length = (texture_width * gun.scale.x) + 10.0
	
	var gun_length_offset := Vector2(actual_gun_length, 0.0) 
	
	# Transform local coordinate system to active scene global map positioning
	bullet.global_position = gun.global_transform * gun_length_offset
	# =========================================================================
	
	# 3. Calculate target trajectory direction toward the mouse position pointer
	var target_dir = (get_global_mouse_position() - bullet.global_position).normalized()
	bullet.rotation = target_dir.angle()
	
	# Assign the moving direction variable directly inside the bullet instance
	bullet.direction = target_dir
	
	# 4. Add it to the active game world layout container
	get_tree().current_scene.add_child(bullet)
